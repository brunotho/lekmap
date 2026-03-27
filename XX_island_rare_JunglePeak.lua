-- Tropical volcano-style feature: central peak, caldera water, several small satellite islands around it.

include("X_IslandHelpers");

local function plotIdx1(x, y, iW) return y * iW + x + 1; end

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[y * iW + x];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function footprintClear(plotTypes, tiles, iW, iH)
	for _, t in ipairs(tiles) do
		if isLand(plotTypes, t[1], t[2], iW, iH) then return false; end
	end
	return true;
end

local function isAdjacentToTile(ax, ay, bx, by)
	local dx, dy = bx - ax, by - ay;
	local adj = (ay % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
	for d = 1, 6 do
		if adj[d][1] == dx and adj[d][2] == dy then return true; end
	end
	return false;
end

function TryPlaceJunglePeakIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.junglePeak then return false; end
	local pullBack = params.pullBack or 3;
	local effMin = params.effMin or 3;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local disk = GetHexDisk(cx, cy, 4, params.iW, params.iH, params.wrapX, params.wrapY);
	local calderaTiles = {};
	local ring2Tiles = {};
	local ring3Tiles = {};
	local ring1End = 7;
	local ring2End = 19;
	local ring3End = 37;
	for i = 2, ring1End do calderaTiles[#calderaTiles + 1] = disk[i]; end
	for i = ring1End + 1, ring2End do ring2Tiles[#ring2Tiles + 1] = disk[i]; end
	for i = ring2End + 1, ring3End do ring3Tiles[#ring3Tiles + 1] = disk[i]; end

	local numIslands = 3 + Map.Rand(2, "");
	numIslands = math.min(numIslands, 4);
	local r2Count, r3Count = #ring2Tiles, #ring3Tiles;
	local landTiles = {};
	local used = {};
	local allR2R3 = {};
	for _, t in ipairs(ring2Tiles) do allR2R3[#allR2R3 + 1] = {t[1], t[2], "r2"}; end
	for _, t in ipairs(ring3Tiles) do allR2R3[#allR2R3 + 1] = {t[1], t[2], "r3"}; end

	local function isAdjacentToIsland(tx, ty, island)
		for _, it in ipairs(island) do
			if isAdjacentToTile(tx, ty, it[1], it[2]) then return true; end
		end
		return false;
	end

	for isl = 1, numIslands do
		local loR2 = math.floor((isl - 1) * r2Count / numIslands) + 1;
		local hiR2 = math.floor(isl * r2Count / numIslands);
		local loR3 = math.floor((isl - 1) * r3Count / numIslands) + 1;
		local hiR3 = math.floor(isl * r3Count / numIslands);
		local r2Pick = loR2 + Map.Rand(math.max(1, hiR2 - loR2 + 1), "");
		local r2t = ring2Tiles[r2Pick];
		local r3Cand = {};
		for _, t in ipairs(ring3Tiles) do
			if isAdjacentToTile(t[1], t[2], r2t[1], r2t[2]) and not used[t[2] * params.iW + t[1]] then
				r3Cand[#r3Cand + 1] = t;
			end
		end
		if #r3Cand == 0 then
			for _, t in ipairs(ring3Tiles) do
				if isAdjacentToTile(t[1], t[2], r2t[1], r2t[2]) then
					r3Cand[#r3Cand + 1] = t;
					break;
				end
			end
		end
		if #r3Cand == 0 then r3Cand[#r3Cand + 1] = ring3Tiles[loR3]; end
		local r3Pick = r3Cand[1 + Map.Rand(#r3Cand, "")];
		local island = {{r2t[1], r2t[2], "r2"}, {r3Pick[1], r3Pick[2], "r3"}};
		used[r2t[2] * params.iW + r2t[1]] = true;
		used[r3Pick[2] * params.iW + r3Pick[1]] = true;

		local targetSize = 3 + Map.Rand(4, "");
		targetSize = math.min(targetSize, 6);
		while #island < targetSize do
			local adjCand = {};
			for _, t in ipairs(allR2R3) do
				local k = t[2] * params.iW + t[1];
				if not used[k] and isAdjacentToIsland(t[1], t[2], island) then
					adjCand[#adjCand + 1] = {t[1], t[2], t[3], k};
				end
			end
			if #adjCand == 0 then break; end
			local pick = adjCand[1 + Map.Rand(#adjCand, "")];
			island[#island + 1] = {pick[1], pick[2], pick[3]};
			used[pick[4]] = true;
		end
		for _, t in ipairs(island) do
			landTiles[#landTiles + 1] = {t[1], t[2], t[3]};
		end
	end

	local footprintTiles = {{cx, cy}};
	for _, t in ipairs(calderaTiles) do footprintTiles[#footprintTiles + 1] = t; end
	for _, t in ipairs(landTiles) do footprintTiles[#footprintTiles + 1] = {t[1], t[2]}; end
	if not footprintClear(plotTypes, footprintTiles, params.iW, params.iH) then return false; end

	DrawJunglePeakIsland(plotTypes, landTiles, calderaTiles, cx, cy, params.iW, params.iH);
	if Map.Rand(2, "") == 0 then
		_krakatoa_island_plot = plotIdx1(cx, cy, params.iW);
		_sri_pada_island_plot = nil;
	else
		local sx = WrapCoord(cx - 1, params.iW, params.wrapX);
		local sy = cy;
		_sri_pada_island_plot = plotIdx1(sx, sy, params.iW);
		_krakatoa_island_plot = nil;
	end
	if not _island_placed then _island_placed = {}; end
	_island_placed.junglePeak = true;
	return true;
end

function DrawJunglePeakIsland(plotTypes, landTiles, calderaTiles, cx, cy, iW, iH)
	plotTypes[cy * iW + cx] = PlotTypes.PLOT_MOUNTAIN;
	for _, t in ipairs(calderaTiles) do
		plotTypes[t[2] * iW + t[1]] = PlotTypes.PLOT_OCEAN;
	end
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		local adjCaldera = false;
		for _, c in ipairs(calderaTiles) do
			if isAdjacentToTile(x, y, c[1], c[2]) then adjCaldera = true; break; end
		end
		local plotType;
		if adjCaldera then
			plotType = (Map.Rand(100, "") < 6) and PlotTypes.PLOT_MOUNTAIN
				or ((Map.Rand(100, "") < (82 + Map.Rand(14, ""))) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND);
		else
			plotType = (Map.Rand(100, "") < (18 + Map.Rand(15, ""))) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
		plotTypes[idx] = plotType;
	end
end
