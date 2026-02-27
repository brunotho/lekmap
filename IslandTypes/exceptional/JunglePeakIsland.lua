------------------------------------------------------------------------------
--	JunglePeakIsland.lua (recreated from transcript)
--	Sri Pada: center mountain, land ring 1-3 thick. 2-3 rings. 20% chance 1 water gap.
--	40-50% hills near center, 50-60% flat on outer. Exports _jungle_peak_island_tiles.
------------------------------------------------------------------------------
include("IslandTypes/IslandHelpers");

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[y * iW + x + 1];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function footprintClear(plotTypes, tiles, iW, iH)
	for _, t in ipairs(tiles) do
		if isLand(plotTypes, t[1], t[2], iW, iH) then return false; end
	end
	return true;
end

function TryPlaceJunglePeakIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.junglePeak then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local numRings = 2 + Map.Rand(2, "");
	local ringThick = 1 + Map.Rand(3, "");
	local hasGap = (Map.Rand(100, "") < 20);

	local landTiles = {};
	for r = 1, numRings do
		local disk = GetHexDisk(cx, cy, r, params.iW, params.iH, params.wrapX, params.wrapY);
		for i, t in ipairs(disk) do
			if hasGap and r == numRings and i <= 2 then
			else
				landTiles[#landTiles + 1] = {t[1], t[2], r};
			end
		end
	end

	if #landTiles < 10 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawJunglePeakIsland(plotTypes, landTiles, cx, cy, params.iW);
	_jungle_peak_island_tiles = landTiles;
	if not _island_placed then _island_placed = {}; end
	_island_placed.junglePeak = true;
	return true;
end

function DrawJunglePeakIsland(plotTypes, landTiles, cx, cy, iW)
	local centerIdx = cy * iW + cx + 1;
	plotTypes[centerIdx] = PlotTypes.PLOT_MOUNTAIN;
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		local ring = t[3] or 1;
		local pct = (ring <= 2) and (40 + Map.Rand(11, "")) or (30 + Map.Rand(21, ""));
		plotTypes[idx] = (Map.Rand(100, "") < pct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end
end
