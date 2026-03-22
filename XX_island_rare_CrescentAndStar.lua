-- Crescent of land with a bay gap, a few peaks in the water, and thickened noisy outer ring.

include("X_IslandHelpers");

local function pidx(x, y, iW)
	return y * iW + x;
end

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[pidx(x, y, iW)];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function isWater(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	return plotTypes[pidx(x, y, iW)] == PlotTypes.PLOT_OCEAN;
end

function TryPlaceCrescentIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.crescent then return false; end
	local pullBack = params.pullBack or 3;
	local effMin = params.effMin or 3;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local ring1 = GetHexRingAtRadius(cx, cy, 1, params.iW, params.iH, params.wrapX, params.wrapY);
	local ring2 = GetHexRingAtRadius(cx, cy, 2, params.iW, params.iH, params.wrapX, params.wrapY);
	local ring3 = GetHexRingAtRadius(cx, cy, 3, params.iW, params.iH, params.wrapX, params.wrapY);
	if #ring1 < 6 or #ring2 < 12 or #ring3 < 18 then return false; end

	local gapSize = 4;
	local gapStart = 1 + Map.Rand(#ring2, "");
	local gapSet = {};
	for k = 0, gapSize - 1 do
		local i = ((gapStart + k - 1) % #ring2) + 1;
		gapSet[i] = true;
	end

	local crescent = {};
	for i = 1, #ring2 do
		if not gapSet[i] then crescent[#crescent + 1] = ring2[i]; end
	end

	local gapTiles = {};
	for i = 1, #ring2 do if gapSet[i] then gapTiles[#gapTiles + 1] = ring2[i]; end end

	local function adjToGap(ax, ay)
		for _, gt in ipairs(gapTiles) do if IsHexAdjacent(ax, ay, gt[1], gt[2]) then return true; end end
		return false;
	end
	local thickenSet = {};
	local thicken = {};
	for _, r3 in ipairs(ring3) do
		local nCrescent = 0;
		for _, c in ipairs(crescent) do
			if IsHexAdjacent(r3[1], r3[2], c[1], c[2]) then nCrescent = nCrescent + 1; end
		end
		if nCrescent >= 1 then
			local key = r3[1] .. "," .. r3[2];
			if not thickenSet[key] then thickenSet[key] = true; thicken[#thicken + 1] = r3; end
		end
	end

	local footprint = {};
	for _, t in ipairs(crescent) do footprint[#footprint + 1] = t; end
	for _, t in ipairs(thicken) do footprint[#footprint + 1] = t; end
	for _, t in ipairs(ring1) do footprint[#footprint + 1] = t; end

	local footprintOk = true;
	for _, t in ipairs(footprint) do
		if not isWater(plotTypes, t[1], t[2], params.iW, params.iH) then footprintOk = false; break; end
	end
	if not footprintOk and #thicken > 0 then
		thicken = {};
		footprint = {};
		for _, t in ipairs(crescent) do footprint[#footprint + 1] = t; end
		for _, t in ipairs(ring1) do footprint[#footprint + 1] = t; end
		for _, t in ipairs(footprint) do
			if not isWater(plotTypes, t[1], t[2], params.iW, params.iH) then return false; end
		end
	elseif not footprintOk then
		return false;
	end

	for _, t in ipairs(crescent) do
		local idx = pidx(t[1], t[2], params.iW);
		local isTip = adjToGap(t[1], t[2]);
		local r = Map.Rand(100, "");
		local mt;
		if r < 6 then mt = PlotTypes.PLOT_MOUNTAIN;
		elseif r < 55 then mt = PlotTypes.PLOT_HILLS;
		else mt = PlotTypes.PLOT_LAND; end
		if isTip and Map.Rand(100, "") < 18 then mt = PlotTypes.PLOT_MOUNTAIN; end
		plotTypes[idx] = mt;
	end
	for _, t in ipairs(thicken) do
		local r = Map.Rand(100, "");
		plotTypes[pidx(t[1], t[2], params.iW)] = (r < 5) and PlotTypes.PLOT_MOUNTAIN or ((r < 58) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND);
	end

	plotTypes[pidx(cx, cy, params.iW)] = PlotTypes.PLOT_MOUNTAIN;
	local ring1Shuffle = {};
	for _, t in ipairs(ring1) do ring1Shuffle[#ring1Shuffle + 1] = t; end
	for i = #ring1Shuffle, 2, -1 do
		local j = 1 + Map.Rand(i, "");
		ring1Shuffle[i], ring1Shuffle[j] = ring1Shuffle[j], ring1Shuffle[i];
	end
	for i = 1, 2 do
		if ring1Shuffle[i] then plotTypes[pidx(ring1Shuffle[i][1], ring1Shuffle[i][2], params.iW)] = PlotTypes.PLOT_MOUNTAIN; end
	end
	for _, t in ipairs(ring1) do
		local pt = plotTypes[pidx(t[1], t[2], params.iW)];
		if pt ~= PlotTypes.PLOT_MOUNTAIN then plotTypes[pidx(t[1], t[2], params.iW)] = PlotTypes.PLOT_OCEAN; end
	end

	if not _island_placed then _island_placed = {}; end
	_island_placed.crescent = true;
	return true;
end
