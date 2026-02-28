------------------------------------------------------------------------------
--	PolarMerge.lua
--	Two variants (mutually exclusive):
--	1. Pangaea Embrace (active): Two arms from pangea ends toward map edge
--	2. Arctic Merge (commented out): Single V-shaped landmass from edge
------------------------------------------------------------------------------
include("IslandHelpers");

local EMBRACE_ODDS = 100;

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[y * iW + x];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

------------------------------------------------------------------------------
-- PANGAEA EMBRACE
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
	-- wrapY maps are not supported (arms need clear N and S edges).
	if wrapY then return false; end

	-- Pick whether the arms grow from the south edge (y=0) or north edge (y=iH-1).
	-- The pangea body sits on the opposite side of the map.
	local southEdge = (Map.Rand(2, "") == 0);
	local edgeY = southEdge and 0 or (iH - 1);

	-- Scan inward from the chosen edge (up to 25 rows) to locate the pangea.
	-- Returns: extent.west/east = leftmost/rightmost pangea column found near the edge.
	--          extent.maxDistFromEdge = how many rows in from the edge the pangea starts.
	local extent = findPangeaExtentAtEdge(plotTypes, iW, iH, southEdge, 25);

	-- Need the pangea to span at least 15 columns near the edge, otherwise there
	-- is no room for two arms with a gap between them.
	local span = extent.east - extent.west;
	if span < 15 then return false; end

	-- westAnchor/eastAnchor: the outermost pangea columns near the edge.
	-- Arms root here — one growing inward from each side of the pangea's mouth.
	local westAnchor = extent.west;
	local eastAnchor = extent.east;

	-- Each arm is 4-7 columns wide (E-W), randomised independently.
	local armLenW = 4 + Map.Rand(4, "");
	local armLenE = 4 + Map.Rand(4, "");

	-- Check that a meaningful open-sea gap remains between the two arms.
	-- seaMinX/seaMaxX are the inner edges of the west and east arms respectively.
	local seaMinX = westAnchor + armLenW;
	local seaMaxX = eastAnchor - armLenE;
	if seaMaxX <= seaMinX + 5 then return false; end

	-- armDepth: target N-S length of each arm, just enough to bridge the gap
	-- from the map edge to where the pangea was detected (+1 to ensure contact).
	-- armWidthW/E: per-arm depth cap, slightly randomised above armDepth.
	local armDepth = extent.maxDistFromEdge + 1;
	local armWidthW = math.max(3, armDepth + Map.Rand(3, ""));
	local armWidthE = math.max(3, armDepth + Map.Rand(3, ""));

	-- -------------------------------------------------------------------------
	-- PHASE 1: Paint arm land tiles.
	-- Walk each arm column from the map edge inward, adding ocean tiles as arm
	-- land until the column either hits existing pangea land or reaches armWidth.
	-- While painting, track the outermost x per y-row for each arm — these form
	-- the mountain ridge in Phase 2 without needing ocean-neighbor detection.
	-- -------------------------------------------------------------------------
	-- landTiles stores {x, y, isMtn} where isMtn=true for ridge tiles.
	local landTiles = {};
	local landTilesSet = {};
	local RIDGE_MTN_ODDS = 90;

	-- curveAmp/curveFreq control how much the arm bends E-W as it goes deeper.
	-- The sine offset grows from 0 at the map edge and peaks partway to the pangea.
	local curveAmp = 2 + Map.Rand(2, "");
	local curveFreq = 0.4 + Map.Rand(3, "") * 0.1;

	-- Adds tile to landTiles. isRidge=true marks it as a mountain ridge candidate.
	-- Terrain classification is stored directly in the tile record (no string keys).
	local function addTile(x, y, isRidge)
		local key = x .. "," .. y;
		if not landTilesSet[key] then
			local isMtn = isRidge and (Map.Rand(100, "") < RIDGE_MTN_ODDS);
			landTiles[#landTiles + 1] = {x, y, isMtn};
			landTilesSet[key] = true;
		end
	end

	-- West arm: columns start at westAnchor and step eastward (+1).
	-- w=0 is always the outermost (leftmost) column → ridge candidates.
	-- curveOffset bends each column inward (toward gap) as depth increases.
	for w = 0, armLenW - 1 do
		local baseX = westAnchor + w;
		local widthNoise = Map.Rand(3, "") - 1;
		local widthHere = math.max(armDepth, armWidthW + widthNoise);
		for d = 0, widthHere - 1 do
			local y = southEdge and d or (edgeY - d);
			local xOffset = math.floor(curveAmp * math.sin(d * curveFreq));
			local x = baseX + xOffset;
			if wrapX then x = ((x % iW) + iW) % iW; end
			if x < 0 or x >= iW or y < 0 or y >= iH then break; end
			if isLand(plotTypes, x, y, iW, iH) then break; end
			addTile(x, y, w == 0);
		end
	end

	-- East arm: columns start at eastAnchor and step westward (-1).
	-- w=0 is always the outermost (rightmost) column → ridge candidates.
	-- curveOffset bends each column inward (toward gap) as depth increases.
	for w = 0, armLenE - 1 do
		local baseX = eastAnchor - w;
		local widthNoise = Map.Rand(3, "") - 1;
		local widthHere = math.max(armDepth, armWidthE + widthNoise);
		for d = 0, widthHere - 1 do
			local y = southEdge and d or (edgeY - d);
			local xOffset = -math.floor(curveAmp * math.sin(d * curveFreq));
			local x = baseX + xOffset;
			if wrapX then x = ((x % iW) + iW) % iW; end
			if x < 0 or x >= iW or y < 0 or y >= iH then break; end
			if isLand(plotTypes, x, y, iW, iH) then break; end
			addTile(x, y, w == 0);
		end
	end

	-- -------------------------------------------------------------------------
	-- PHASE 2: Terrain placement.
	-- -------------------------------------------------------------------------

	-- Write final plot types for all arm tiles.
	-- Ridge tiles (isMtn=true) → MOUNTAIN.
	-- All other tiles → HILLS or LAND (flat for now, gradient can be added later).
	for _, t in ipairs(landTiles) do
		local x, y, isMtn = t[1], t[2], t[3];
		local idx = y * iW + x;
		if isMtn then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 40) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
	return true;
end

--[==[
------------------------------------------------------------------------------
-- ARCTIC MERGE (disabled)
------------------------------------------------------------------------------
local HILLS_ADJ = 75;
local TUNDRA_LAT = 0.85;

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
--]==]

------------------------------------------------------------------------------
-- ENTRY POINT
------------------------------------------------------------------------------
function TryPlacePolarMerge(plotTypes, opts)
	if _island_placed and _island_placed.polarmerge then return false; end
	local iW, iH = opts.iW, opts.iH;
	local wrapX = opts.wrapX or true;
	local wrapY = opts.wrapY or false;
	if wrapY then return false; end

	if Map.Rand(100, "") < EMBRACE_ODDS then
		if drawPangaeaEmbrace(plotTypes, iW, iH, wrapX, wrapY) then
			if not _island_placed then _island_placed = {}; end
			_island_placed.polarmerge = true;
			return true;
		end
	end
	return false;
end
