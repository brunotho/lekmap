------------------------------------------------------------------------------
--	DesertPeakIsland.lua (recreated from transcript)
--	Sinai: center mountain, diamond-shaped ring 2 tiles thick.
--	60-70% hills inner, 70-80% flat outer. 30% chance 2-3 adjacent islands (1-2 tiles each).
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

local DIAMOND_OFFSETS = {
	{0, 0}, {1, 0}, {-1, 0}, {0, 1}, {0, -1}, {1, 1}, {-1, -1}, {1, -1}, {-1, 1},
	{2, 0}, {-2, 0}, {0, 2}, {0, -2}, {2, 1}, {-2, -1}, {2, -1}, {-2, 1}, {1, 2}, {-1, -2}, {1, -2}, {-1, 2},
};

function TryPlaceDesertPeakIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.desertPeak then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local landTiles = {};
	for _, off in ipairs(DIAMOND_OFFSETS) do
		local gx = WrapCoord(cx + off[1], params.iW, params.wrapX);
		local gy = WrapCoord(cy + off[2], params.iH, params.wrapY);
		if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH then
			local dist = math.abs(off[1]) + math.abs(off[2]);
			landTiles[#landTiles + 1] = {gx, gy, (dist <= 1) and "inner" or "outer"};
		end
	end

	if Map.Rand(100, "") < 30 then
		local numExtra = 2 + Map.Rand(2, "");
		for i = 1, numExtra do
			local dir = Map.Rand(6, "") + 1;
			local gx, gy = GetHexNeighbor(cx, cy, dir, params.iW, params.iH, params.wrapX, params.wrapY);
			for _ = 1, 2 do
				gx, gy = GetHexNeighbor(gx, gy, dir, params.iW, params.iH, params.wrapX, params.wrapY);
			end
			if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH then
				landTiles[#landTiles + 1] = {gx, gy, "satellite"};
			end
		end
	end

	if #landTiles < 5 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawDesertPeakIsland(plotTypes, landTiles, cx, cy, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.desertPeak = true;
	return true;
end

function DrawDesertPeakIsland(plotTypes, landTiles, cx, cy, iW)
	plotTypes[cy * iW + cx + 1] = PlotTypes.PLOT_MOUNTAIN;
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		if x == cx and y == cy then
		else
			local idx = y * iW + x + 1;
			local zone = t[3] or "outer";
			local pct = (zone == "inner") and (60 + Map.Rand(11, "")) or (20 + Map.Rand(11, ""));
			plotTypes[idx] = (Map.Rand(100, "") < pct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
