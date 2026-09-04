-- Equator-ring mainland: X-wrapping land belt, open polar oceans, jagged N/S coasts from fractal.

-- Tunables (fraction of map height for half-band; total thickness ~= 2 * half).
local RING_HALF_THICK_FRAC = 0.21;
local RING_COAST_NOISE_AMP = 3; -- tiles of N/S coast wobble
local RING_MIN_COL_THICK = 8;
local RING_POLAR_OCEAN_ROWS = 2; -- keep at least this many ocean rows at each pole

function LekLandmass_EquatorRing_Build(self, env)
	if LekPipelineFlow then LekPipelineFlow("EquatorRing_Build_entry"); end
	local iW = self.iNumPlotsX;
	local iH = self.iNumPlotsY;
	local water_percent = env.water_percent;
	local grain = env.grain;
	local numPlates = env.numPlates;
	local adjustment = env.adjustment;
	local hills_ridge_flags = env.hills_ridge_flags;
	local peaks_ridge_flags = env.peaks_ridge_flags;
	local hillsBottom1 = env.hillsBottom1;
	local hillsTop1 = env.hillsTop1;
	local hillsBottom2 = env.hillsBottom2;
	local hillsTop2 = env.hillsTop2;
	local hillsClumps = env.hillsClumps;
	local hillsNearMountains = env.hillsNearMountains;
	local mountains = env.mountains;

	self.continentsFrac = nil;
	self:InitFractal{ continent_grain = 7, rift_grain = -1 };
	local iWaterThreshold = self.continentsFrac:GetHeight(water_percent);

	local mid = math.floor(iH / 2);
	local half = math.max(RING_MIN_COL_THICK, math.floor(iH * RING_HALF_THICK_FRAC + 0.5));
	local yMinPole = RING_POLAR_OCEAN_ROWS;
	local yMaxPole = iH - 1 - RING_POLAR_OCEAN_ROWS;

	-- Base land/ocean ring from per-column jagged coasts.
	for x = 0, iW - 1 do
		local wobbleS = Map.Rand(2 * RING_COAST_NOISE_AMP + 1, "ringCoastS") - RING_COAST_NOISE_AMP;
		local wobbleN = Map.Rand(2 * RING_COAST_NOISE_AMP + 1, "ringCoastN") - RING_COAST_NOISE_AMP;
		-- Mix in fractal so neighboring columns correlate a bit.
		local n1 = self.continentsFrac:GetHeight(x, mid);
		local n2 = self.continentsFrac:GetHeight((x + math.floor(iW / 3)) % iW, mid);
		if n1 > iWaterThreshold then wobbleS = wobbleS + 1; end
		if n2 > iWaterThreshold then wobbleN = wobbleN - 1; end
		local ySouth = mid - half + wobbleS;
		local yNorth = mid + half + wobbleN;
		if ySouth < yMinPole then ySouth = yMinPole; end
		if yNorth > yMaxPole then yNorth = yMaxPole; end
		if yNorth < ySouth + RING_MIN_COL_THICK - 1 then
			yNorth = math.min(yMaxPole, ySouth + RING_MIN_COL_THICK - 1);
		end
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			if y >= ySouth and y <= yNorth then
				self.plotTypes[i] = PlotTypes.PLOT_LAND;
			else
				self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end

	-- Ring seal: no all-ocean column in the equatorial band.
	for x = 0, iW - 1 do
		local hasLand = false;
		local firstY = nil;
		for y = yMinPole, yMaxPole do
			local i = y * iW + x + 1;
			if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
				hasLand = true;
				break;
			end
			if firstY == nil then firstY = y; end
		end
		if not hasLand then
			local y0 = mid - math.floor(RING_MIN_COL_THICK / 2);
			local y1 = y0 + RING_MIN_COL_THICK - 1;
			if y0 < yMinPole then y0 = yMinPole; end
			if y1 > yMaxPole then y1 = yMaxPole; end
			for y = y0, y1 do
				self.plotTypes[y * iW + x + 1] = PlotTypes.PLOT_LAND;
			end
		end
	end

	-- Hills / mountains on land only (no polar tectonic islands).
	self.hillsFrac = Fractal.Create(iW, iH, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.mountainsFrac = Fractal.Create(iW, iH, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.hillsFrac:BuildRidges(numPlates, hills_ridge_flags, 1, 2);
	self.mountainsFrac:BuildRidges((numPlates * 2) / 3, peaks_ridge_flags, 6, 1);

	local iHillsBottom1 = self.hillsFrac:GetHeight(hillsBottom1);
	local iHillsTop1 = self.hillsFrac:GetHeight(hillsTop1);
	local iHillsBottom2 = self.hillsFrac:GetHeight(hillsBottom2);
	local iHillsTop2 = self.hillsFrac:GetHeight(hillsTop2);
	local iHillsNearMountains = self.mountainsFrac:GetHeight(hillsNearMountains);
	local iMountainThreshold = self.mountainsFrac:GetHeight(mountains);
	local iPassThreshold = self.hillsFrac:GetHeight(hillsNearMountains);

	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
				local mountainVal = self.mountainsFrac:GetHeight(x, y);
				local hillVal = self.hillsFrac:GetHeight(x, y);
				if mountainVal >= iMountainThreshold then
					if hillVal >= iPassThreshold then
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					else
						local iIsMount = Map.Rand(100, "Ring Mountain Spawn Chance");
						local iIsMountAdj = 48 - adjustment;
						if iIsMount >= iIsMountAdj then
							self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
						else
							local iIsHill = Map.Rand(100, "Ring Hill Spawn Chance");
							local iIsHillAdj = 30 - adjustment;
							if iIsHill >= iIsHillAdj then
								self.plotTypes[i] = PlotTypes.PLOT_HILLS;
							else
								self.plotTypes[i] = PlotTypes.PLOT_LAND;
							end
						end
					end
				elseif mountainVal >= iHillsNearMountains then
					self.plotTypes[i] = PlotTypes.PLOT_HILLS;
				elseif (hillVal >= iHillsBottom1 and hillVal <= iHillsTop1)
					or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2) then
					self.plotTypes[i] = PlotTypes.PLOT_HILLS;
				else
					self.plotTypes[i] = PlotTypes.PLOT_LAND;
				end
			end
		end
	end

	-- Keep ring centered on equator (Y only; no X shift — would tear wrap).
	local sumY, nLand = 0, 0;
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
				sumY = sumY + y;
				nLand = nLand + 1;
			end
		end
	end
	local yshift, yshiftamt = 0, 0;
	if nLand > 0 then
		local cy = sumY / nLand;
		yshiftamt = math.ceil(mid - cy);
		if yshiftamt > 0 then
			yshift = 1;
		elseif yshiftamt < 0 then
			yshift = 2;
		end
	end

	if LekPipelineFlow then LekPipelineFlow("EquatorRing_Build_ok", "nLandApprox"); end
	return {
		ok = true,
		xshift = 0,
		yshift = yshift,
		xshiftamt = 0,
		yshiftamt = yshiftamt,
		skipMarginClear = true,
		skipXShift = true,
		iWaterThreshold = iWaterThreshold,
	};
end
