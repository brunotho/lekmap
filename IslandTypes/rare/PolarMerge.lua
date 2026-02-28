------------------------------------------------------------------------------
--	PolarMerge.lua
--	Two variants (mutually exclusive):
--	1. Pangaea Embrace: Two arms from pangea ends, inland sea between
--	2. Arctic Merge: Single V-shaped landmass from edge
------------------------------------------------------------------------------
include("IslandHelpers");

local EMBRACE_ODDS = 100;
local ARCTIC_MERGE_ODDS = 0;

local HILLS_ADJ = 75;
local TUNDRA_LAT = 0.85;

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[y * iW + x + 1];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function isWater(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	return plotTypes[y * iW + x + 1] == PlotTypes.PLOT_OCEAN;
end

local function getTundraLatitudeY(iH, southEdge)
	local offset = math.floor((iH / 2) * (1 - TUNDRA_LAT));
	if southEdge then return offset; end
	return iH - 1 - offset;
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
			if isLand(plotTypes, x, y, iW, iH) then return dist, x, y; end
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

------------------------------------------------------------------------------
-- PANGEA EMBRACE
------------------------------------------------------------------------------
local function findPangeaExtentAtEdge(plotTypes, iW, iH, southEdge, scanDepth)
	local extent = { west = iW, east = -1, maxDistFromEdge = 0 };
	local edgeY = southEdge and 0 or (iH - 1);
	for x = 0, iW - 1 do
		for d = 0, scanDepth do
			local y = southEdge and d or (edgeY - d);
			if y >= 0 and y < iH and isLand(plotTypes, x, y, iW, iH) then
				if x < extent.west then extent.west = x; end
				if x > extent.east then extent.east = x; end
				if d > extent.maxDistFromEdge then extent.maxDistFromEdge = d; end
				break;
			end
		end
	end
	return extent;
end

local function drawPangaeaEmbrace(plotTypes, iW, iH, wrapX, wrapY)
	if wrapY then return false; end
	local southEdge = (Map.Rand(2, "") == 0);
	local edgeY = southEdge and 0 or (iH - 1);
	local extent = findPangeaExtentAtEdge(plotTypes, iW, iH, southEdge, 25);
	local span = extent.east - extent.west;
	if span < 15 then return false; end

	local westAnchor = extent.west;
	local eastAnchor = extent.east;
	local armLenW = 4 + Map.Rand(4, "");
	local armLenE = 4 + Map.Rand(4, "");

	local seaMinX = westAnchor + armLenW;
	local seaMaxX = eastAnchor - armLenE;
	if seaMaxX <= seaMinX + 5 then return false; end

	local armDepth = extent.maxDistFromEdge + 1;
	local armWidthW = math.max(3, armDepth + Map.Rand(3, ""));
	local armWidthE = math.max(3, armDepth + Map.Rand(3, ""));

	local landTiles = {};
	local armWestSet = {};
	local armEastSet = {};

	local function addArmTile(x, y, armSet)
		if wrapX then x = ((x % iW) + iW) % iW; end
		if x >= 0 and x < iW and y >= 0 and y < iH then
			landTiles[#landTiles + 1] = {x, y};
			armSet[x .. "," .. y] = true;
		end
	end

	local curveAmp = 2 + Map.Rand(2, "");
	local curveFreq = 0.4 + Map.Rand(3, "") * 0.1;
	for w = 0, armLenW - 1 do
		local baseX = westAnchor + w;
		local widthNoise = Map.Rand(3, "") - 1;
		local widthHere = math.max(armDepth, armWidthW + widthNoise);
		for d = 0, widthHere - 1 do
			local y = southEdge and d or (edgeY - d);
			local xOffset = math.floor(curveAmp * math.sin(d * curveFreq));
			local x = baseX + xOffset;
			addArmTile(x, y, armWestSet);
		end
	end
	for w = 0, armLenE - 1 do
		local baseX = eastAnchor - w;
		local widthNoise = Map.Rand(3, "") - 1;
		local widthHere = math.max(armDepth, armWidthE + widthNoise);
		for d = 0, widthHere - 1 do
			local y = southEdge and d or (edgeY - d);
			local xOffset = -math.floor(curveAmp * math.sin(d * curveFreq));
			local x = baseX + xOffset;
			addArmTile(x, y, armEastSet);
		end
	end

	-- Build ridges: for each y row, westernmost tile in west arm, easternmost in east arm.
	local westMinXbyY = {};
	local eastMaxXbyY = {};
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local key = x .. "," .. y;
		if armWestSet[key] then
			if westMinXbyY[y] == nil or x < westMinXbyY[y] then westMinXbyY[y] = x; end
		end
		if armEastSet[key] then
			if eastMaxXbyY[y] == nil or x > eastMaxXbyY[y] then eastMaxXbyY[y] = x; end
		end
	end

	local RIDGE_MTN_ODDS = 90;
	local mtnWest = {};
	local mtnEast = {};
	for y, x in pairs(westMinXbyY) do
		if Map.Rand(100, "") < RIDGE_MTN_ODDS then mtnWest[x .. "," .. y] = true; end
	end
	for y, x in pairs(eastMaxXbyY) do
		if Map.Rand(100, "") < RIDGE_MTN_ODDS then mtnEast[x .. "," .. y] = true; end
	end

	local function distToMountain(ridgeSet, x, y)
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
			if ridgeSet[nx .. "," .. ny] then return 1; end
		end
		for d2 = 1, 2 do
			for dir = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
				for d3 = 1, d2 do
					local nnx, nny = GetHexNeighbor(nx, ny, dir, iW, iH, wrapX, wrapY);
					if ridgeSet[nnx .. "," .. nny] then return d2 + 1; end
				end
			end
		end
		return 4;
	end

	local ridgeSet = {};
	for k in pairs(mtnWest) do ridgeSet[k] = true; end
	for k in pairs(mtnEast) do ridgeSet[k] = true; end

	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if mtnWest[x .. "," .. y] or mtnEast[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			local d = distToMountain(ridgeSet, x, y);
			local hillsPct = (d == 1) and 80 or (d == 2) and 65 or (d == 3) and 50 or 50;
			plotTypes[idx] = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
	return true;
end

------------------------------------------------------------------------------
-- ARCTIC MERGE (30%) - original variant
------------------------------------------------------------------------------
local function drawArcticMerge(plotTypes, centerX, edgeY, southEdge, contactDist, startOffset, hasWaterPath, numRidges, iW, iH, wrapX, wrapY)
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
			if x >= 0 and x < iW then landTiles[#landTiles + 1] = {x, rowY}; end
		end
	end

	local landSet = {};
	for _, t in ipairs(landTiles) do landSet[t[1] .. "," .. t[2]] = true; end

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
			if rx >= 0 and rx < iW and landSet[rx .. "," .. rowY] then ridgeTiles[#ridgeTiles + 1] = {rx, rowY}; end
		end
		if numRidges >= 2 and not ridge2Gaps[row] then
			local rx = wrapX and (((ridge2X % iW) + iW) % iW) or ridge2X;
			if rx >= 0 and rx < iW and landSet[rx .. "," .. rowY] then ridgeTiles[#ridgeTiles + 1] = {rx, rowY}; end
		end
		if hasWaterPath then
			local pathX = wrapX and (((centerX % iW) + iW) % iW) or centerX;
			if pathX >= 0 and pathX < iW and landSet[pathX .. "," .. rowY] then waterPathTiles[#waterPathTiles + 1] = {pathX, rowY}; end
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
	for _, t in ipairs(landTiles) do landSet2[t[1] .. "," .. t[2]] = true; end
	local waterPathSet = {};
	for _, t in ipairs(waterPathTiles) do waterPathSet[t[1] .. "," .. t[2]] = true; end
	local seaSet = {};
	for _, t in ipairs(seaTiles) do
		seaSet[t[1] .. "," .. t[2]] = true;
		landSet2[t[1] .. "," .. t[2]] = nil;
	end

	local ridgeSet = {};
	for _, t in ipairs(ridgeTiles) do ridgeSet[t[1] .. "," .. t[2]] = true; end

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
		local candidates = {};
		for _, t in ipairs(seaTiles) do
			local x, y = t[1], t[2];
			local adjWater = 0;
			for dir = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
				if seaSet[nx .. "," .. ny] then adjWater = adjWater + 1; end
			end
			if adjWater >= 4 then candidates[#candidates + 1] = t; end
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
		for _ = 1, 1 + Map.Rand(3, "") do
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

------------------------------------------------------------------------------
-- ENTRY POINT
------------------------------------------------------------------------------
function TryPlacePolarMerge(plotTypes, opts)
	if _island_placed and _island_placed.polarmerge then return false; end
	local iW, iH = opts.iW, opts.iH;
	local wrapX = opts.wrapX or true;
	local wrapY = opts.wrapY or false;
	if wrapY then return false; end

	local useEmbrace = (Map.Rand(100, "") < EMBRACE_ODDS);

	if useEmbrace then
		if drawPangaeaEmbrace(plotTypes, iW, iH, wrapX, wrapY) then
			if not _island_placed then _island_placed = {}; end
			_island_placed.polarmerge = true;
			return true;
		end
	end

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

	drawArcticMerge(plotTypes, centerX, edgeY, southEdge, contactDist, startOffset, hasWaterPath, numRidges, iW, iH, wrapX, wrapY);
	if not _island_placed then _island_placed = {}; end
	_island_placed.polarmerge = true;
	return true;
end
