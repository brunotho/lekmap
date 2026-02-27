------------------------------------------------------------------------------
--	ArcticMergingLandmass.lua
--	Landmass from north/south map edge merging with pangea. Starts painting 2-3
--	tiles from edge. V-shaped splintered mountain ridges, 70% water path east-west.
--	Inland sea at tundra latitude (4-12 tiles). Budget 2.5-3.
--	Placement: must touch edge, ripple inward until mainland contact.
------------------------------------------------------------------------------
include("IslandTypes/IslandHelpers");

local HILLS_ADJ = 75;
local TUNDRA_LAT = 0.85;

local function getTundraLatitudeY(iH, southEdge)
	local offset = math.floor((iH / 2) * (1 - TUNDRA_LAT));
	if southEdge then
		return offset;
	end
	return iH - 1 - offset;
end

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[y * iW + x + 1];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function isWater(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	return plotTypes[y * iW + x + 1] == PlotTypes.PLOT_OCEAN;
end

local function rippleToLand(plotTypes, startX, startY, iW, iH, wrapX, southEdge)
	local visited = {};
	local queue = {{startX, startY}};
	visited[startX .. "," .. startY] = true;
	local dist = 0;
	local maxDist = 15;
	while #queue > 0 and dist < maxDist do
		local next = {};
		for _, p in ipairs(queue) do
			local x, y = p[1], p[2];
			if isLand(plotTypes, x, y, iW, iH) then
				return dist, x, y;
			end
			for dir = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, false);
				if ny >= 0 and ny < iH then
					local inward = southEdge and (ny > y) or (ny < y);
					if inward then
						local key = nx .. "," .. ny;
						if not visited[key] then
							visited[key] = true;
							next[#next + 1] = {nx, ny};
						end
					end
				end
			end
		end
		queue = next;
		dist = dist + 1;
	end
	return nil, nil, nil;
end

local function findValidXForPangea(plotTypes, iW, iH, southEdge, maxScan)
	local validX = {};
	local dy = southEdge and 1 or -1;
	local edgeY = southEdge and 0 or (iH - 1);
	for x = 0, iW - 1 do
		for d = 1, math.min(maxScan, 12) do
			local y = southEdge and d or (edgeY - d);
			if y >= 0 and y < iH and isLand(plotTypes, x, y, iW, iH) then
				validX[#validX + 1] = x;
				break;
			end
		end
	end
	return validX;
end

function TryPlaceArcticMergingLandmass(plotTypes, opts)
	if _island_placed and _island_placed.arcticMerging then return false; end
	if Map.Rand(100, "") >= 35 then return false; end
	local iW, iH = opts.iW, opts.iH;
	local wrapX = opts.wrapX or true;
	local wrapY = opts.wrapY or false;
	if wrapY then return false; end

	local southEdge = (Map.Rand(2, "") == 0);
	local edgeY = southEdge and 0 or (iH - 1);
	local validX = findValidXForPangea(plotTypes, iW, iH, southEdge, 12);
	if #validX < 5 then return false; end

	local centerX = validX[4 + Map.Rand(math.max(1, #validX - 8), "")];
	local contactDist, _, _ = rippleToLand(plotTypes, centerX, edgeY, iW, iH, wrapX, southEdge);
	if not contactDist or contactDist < 4 then return false; end

	local startOffset = 2 + Map.Rand(2, "");
	local hasWaterPath = (Map.Rand(100, "") < 70);
	local numRidges = (Map.Rand(2, "") == 0) and 1 or 2;

	DrawArcticMergingLandmass(plotTypes, centerX, edgeY, southEdge, contactDist, startOffset, hasWaterPath, numRidges, iW, iH, wrapX, wrapY);
	if not _island_placed then _island_placed = {}; end
	_island_placed.arcticMerging = true;
	return true;
end

function DrawArcticMergingLandmass(plotTypes, centerX, edgeY, southEdge, contactDist, startOffset, hasWaterPath, numRidges, iW, iH, wrapX, wrapY)
	local dy = southEdge and 1 or -1;
	local inlandSeaY = getTundraLatitudeY(iH, southEdge);
	local startY = southEdge and startOffset or (edgeY - startOffset);
	local endY = southEdge and math.min(contactDist + 2, iH - 1) or math.max(0, edgeY - contactDist - 2);

	local width = 8 + Map.Rand(5, "");
	local landTiles = {};
	local ridgeTiles = {};
	local waterPathTiles = {};
	local seaTiles = {};

	local splinterChance = 25;
	local ridge1Gaps = {};
	local ridge2Gaps = {};

	for row = 0, math.abs(endY - startY) do
		local rowY = southEdge and (startY + row) or (startY - row);
		if rowY < 0 or rowY >= iH then break; end
		local half = math.floor(width / 2);
		for dx = -half, half do
			local x = centerX + dx;
			if wrapX then x = ((x % iW) + iW) % iW; end
			if x >= 0 and x < iW then
				landTiles[#landTiles + 1] = {x, rowY};
			end
		end
	end

	local landSet = {};
	for _, t in ipairs(landTiles) do
		landSet[t[1] .. "," .. t[2]] = true;
	end

	for row = 0, math.abs(endY - startY) do
		local rowY = southEdge and (startY + row) or (startY - row);
		if rowY < 0 or rowY >= iH then break; end
		local half = math.floor(width / 2);
		local vSpread = math.floor(half * 0.15 * (row + 1));
		local ridge1X = centerX - math.floor(half * 0.35) - vSpread;
		local ridge2X = centerX + math.floor(half * 0.35) + vSpread;
		if Map.Rand(100, "") < splinterChance then ridge1Gaps[row] = true; end
		if Map.Rand(100, "") < splinterChance then ridge2Gaps[row] = true; end
		if not ridge1Gaps[row] then
			local rx = wrapX and (((ridge1X % iW) + iW) % iW) or ridge1X;
			if rx >= 0 and rx < iW and landSet[rx .. "," .. rowY] then
				ridgeTiles[#ridgeTiles + 1] = {rx, rowY};
			end
		end
		if numRidges >= 2 and not ridge2Gaps[row] then
			local rx = wrapX and (((ridge2X % iW) + iW) % iW) or ridge2X;
			if rx >= 0 and rx < iW and landSet[rx .. "," .. rowY] then
				ridgeTiles[#ridgeTiles + 1] = {rx, rowY};
			end
		end
		if hasWaterPath then
			local pathX = wrapX and (((centerX % iW) + iW) % iW) or centerX;
			if pathX >= 0 and pathX < iW and landSet[pathX .. "," .. rowY] then
				waterPathTiles[#waterPathTiles + 1] = {pathX, rowY};
			end
		end
	end

	local seaSize = 4 + Map.Rand(9, "");
	local seaRadius = math.max(1, math.floor(math.sqrt(seaSize / 3.14)));
	local seaCenterX = centerX;
	local yLo, yHi = math.min(startY, endY), math.max(startY, endY);
	local seaCenterY = math.max(yLo + 1, math.min(inlandSeaY, yHi - 1));
	if wrapX then seaCenterX = (((seaCenterX % iW) + iW) % iW); end

	for dy2 = -seaRadius, seaRadius do
		for dx2 = -seaRadius, seaRadius do
			if dx2 * dx2 + dy2 * dy2 <= seaRadius * seaRadius then
				local sx = seaCenterX + dx2;
				if wrapX then sx = (((sx % iW) + iW) % iW); end
				local sy = seaCenterY + dy2;
				if sx >= 0 and sx < iW and sy >= 0 and sy < iH and sy >= startY and (southEdge and sy <= endY or not southEdge and sy >= endY) then
					seaTiles[#seaTiles + 1] = {sx, sy};
				end
			end
		end
	end

	local landSet2 = {};
	for _, t in ipairs(landTiles) do
		landSet2[t[1] .. "," .. t[2]] = true;
	end
	local waterPathSet = {};
	for _, t in ipairs(waterPathTiles) do
		waterPathSet[t[1] .. "," .. t[2]] = true;
	end
	local seaSet = {};
	for _, t in ipairs(seaTiles) do
		seaSet[t[1] .. "," .. t[2]] = true;
		landSet2[t[1] .. "," .. t[2]] = nil;
	end

	local ridgeSet = {};
	for _, t in ipairs(ridgeTiles) do
		ridgeSet[t[1] .. "," .. t[2]] = true;
	end

	local mountainPicks = {};
	for i = 1, #ridgeTiles do mountainPicks[i] = i; end
	for i = #mountainPicks, 2, -1 do
		local j = Map.Rand(i, "") + 1;
		mountainPicks[i], mountainPicks[j] = mountainPicks[j], mountainPicks[i];
	end
	local numMountains = math.min(#ridgeTiles, 2 + Map.Rand(math.max(1, #ridgeTiles), ""));
	for i = 1, numMountains do
		local t = ridgeTiles[mountainPicks[i]];
		ridgeSet[t[1] .. "," .. t[2]] = "mountain";
	end

	local islandInSea = {};
	if seaSize >= 10 and Map.Rand(100, "") < 50 then
		local cx, cy = seaCenterX, seaCenterY;
		local candidates = {};
		for _, t in ipairs(seaTiles) do
			local x, y = t[1], t[2];
			local adjWater = 0;
			for dir = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
				if seaSet[nx .. "," .. ny] then adjWater = adjWater + 1; end
			end
			if adjWater >= 4 then
				candidates[#candidates + 1] = t;
			end
		end
		if #candidates > 0 then
			local pick = candidates[Map.Rand(#candidates, "") + 1];
			islandInSea[pick[1] .. "," .. pick[2]] = true;
		end
	end

	local function adjToMountain(x, y)
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
			if ridgeSet[nx .. "," .. ny] == "mountain" then return true; end
		end
		return false;
	end

	if Map.Rand(100, "") < 25 then
		local looseCount = 1 + Map.Rand(3, "");
		for _ = 1, looseCount do
			local lx = centerX + (Map.Rand(5, "") - 2);
			if wrapX then lx = (((lx % iW) + iW) % iW); end
			local ly = southEdge and Map.Rand(2, "") or (edgeY - Map.Rand(2, ""));
			if lx >= 0 and lx < iW and ly >= 0 and ly < iH then
				landTiles[#landTiles + 1] = {lx, ly};
				landSet2[lx .. "," .. ly] = true;
			end
		end
	end

	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if seaSet[x .. "," .. y] and not islandInSea[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_OCEAN;
		elseif waterPathSet[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_OCEAN;
		elseif islandInSea[x .. "," .. y] then
			plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		elseif ridgeSet[x .. "," .. y] == "mountain" then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif adjToMountain(x, y) then
			plotTypes[idx] = (Map.Rand(100, "") < HILLS_ADJ) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
