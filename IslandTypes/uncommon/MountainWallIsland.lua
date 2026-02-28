------------------------------------------------------------------------------
--	MountainWallIsland.lua
--	Ridge 3-6 tiles, land depth = ridge length ±1.
--	Gaps: len 3 none; len 4 50% one gap; len 5-6 → 45% none, 50% one, 5% two (never at ends).
--	Ridge: mountains; adjacent 85% hills; 2nd tile 70%; 3rd 50%; 4th 35%; 5th 25%.
--	Ridge perpendicular to mainland.
------------------------------------------------------------------------------
include("IslandHelpers");

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

function TryPlaceMountainWallIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local ridgeLen = 3 + Map.Rand(4, "");
	local depth = ridgeLen + Map.Rand(3, "") - 1;
	if depth < 1 then depth = 1; end

	local numGaps = 0;
	if ridgeLen == 3 then numGaps = 0;
	elseif ridgeLen == 4 then
		if Map.Rand(100, "") < 50 then numGaps = 1; end
	else
		local r = Map.Rand(100, "");
		if r < 45 then numGaps = 0;
		elseif r < 95 then numGaps = 1;
		else numGaps = 2; end
	end

	local dir = Map.Rand(6, "") + 1;
	local perpDir = ((dir + 2) % 6) + 1;

	local landTiles = {};
	local ridgeTiles = {};
	local x, y = cx, cy;

	for i = 1, ridgeLen do
		if numGaps == 0 or (i > 1 and i < ridgeLen and Map.Rand(100, "") >= (100 / (ridgeLen - 2))) then
			ridgeTiles[#ridgeTiles + 1] = {x, y};
			landTiles[#landTiles + 1] = {x, y, "ridge"};
		end
		local nx, ny = GetHexNeighbor(x, y, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx < 0 or nx >= params.iW or ny < 0 or ny >= params.iH then break; end
		x, y = nx, ny;
	end

	local ridgeSet = {};
	for _, t in ipairs(ridgeTiles) do ridgeSet[t[1] .. "," .. t[2]] = true; end

	for _, rt in ipairs(ridgeTiles) do
		local rx, ry = rt[1], rt[2];
		for d = 1, depth do
			local nx, ny = GetHexNeighbor(rx, ry, perpDir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and not ridgeSet[nx .. "," .. ny] then
				landTiles[#landTiles + 1] = {nx, ny, d};
				rx, ry = nx, ny;
			else break; end
		end
	end

	if #landTiles < 5 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawMountainWallIsland(plotTypes, landTiles, ridgeTiles, params.iW);
	return true;
end

function DrawMountainWallIsland(plotTypes, landTiles, ridgeTiles, iW)
	local ridgeSet = {};
	for _, t in ipairs(ridgeTiles) do ridgeSet[t[1] .. "," .. t[2]] = true; end
	local hillChance = {85, 70, 50, 35, 25};
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if ridgeSet[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			local d = t[3] or 1;
			local pct = hillChance[d] or 25;
			plotTypes[idx] = (Map.Rand(100, "") < pct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
