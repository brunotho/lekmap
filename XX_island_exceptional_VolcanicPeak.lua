------------------------------------------------------------------------------
--	VolcanicPeakIsland.lua
--	Center mountain, 6-tile caldera lake, land ring 3-5 segments with 1-2 tile gaps.
--	12-18 land tiles. 50-60% hills. Hills near caldera, flat on outer edge.
------------------------------------------------------------------------------
include("X_IslandHelpers");

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

function TryPlaceVolcanicPeakIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.volcanicPeak then return false; end
	local pullBack = params.pullBack or 3;
	local effMin = params.effMin or 3;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local ring = GetHexDisk(cx, cy, 2, params.iW, params.iH, params.wrapX, params.wrapY);
	local centerTiles = GetHexDisk(cx, cy, 1, params.iW, params.iH, params.wrapX, params.wrapY);
	local calderaTiles = {};
	for _, t in ipairs(centerTiles) do
		if t[1] ~= cx or t[2] ~= cy then
			calderaTiles[#calderaTiles + 1] = t;
		end
	end

	local numSegments = 3 + Map.Rand(3, "");
	local numGaps = 1 + Map.Rand(2, "");
	local landTiles = {};
	landTiles[#landTiles + 1] = {cx, cy};

	local step = math.floor(#ring / (numSegments + numGaps));
	local idx = 1;
	for seg = 1, numSegments + numGaps do
		local segLen = step;
		if seg == numSegments + numGaps then segLen = #ring - idx + 1; end
		local isGap = (seg > numSegments);
		for i = 1, segLen do
			if idx <= #ring then
				local t = ring[idx];
				if not isGap then
					landTiles[#landTiles + 1] = {t[1], t[2]};
				end
				idx = idx + 1;
			end
		end
	end

	if #landTiles < 12 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawVolcanicPeakIsland(plotTypes, landTiles, calderaTiles, cx, cy, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.volcanicPeak = true;
	return true;
end

function DrawVolcanicPeakIsland(plotTypes, landTiles, calderaTiles, cx, cy, iW)
	local centerIdx = cy * iW + cx;
	plotTypes[centerIdx] = PlotTypes.PLOT_MOUNTAIN;
	for _, t in ipairs(calderaTiles) do
		plotTypes[t[2] * iW + t[1]] = PlotTypes.PLOT_OCEAN;
	end
	local hillsPct = 50 + Map.Rand(11, "");
	for i, t in ipairs(landTiles) do
		if t[1] == cx and t[2] == cy then
		else
			local idx = t[2] * iW + t[1];
			local dist = math.abs(t[1] - cx) + math.abs(t[2] - cy);
			local pct = (dist <= 2) and (50 + Map.Rand(11, "")) or (30 + Map.Rand(11, ""));
			plotTypes[idx] = (Map.Rand(100, "") < pct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
