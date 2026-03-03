------------------------------------------------------------------------------
--	SShapeIsland.lua
--	Soft S-curve, 10-16 tiles. First curve 3-5, transition 1-2, second curve 3-5.
--	94% plain, 3% head (one end widens + 1 mountain), 3% mountain cluster (2-4 in middle).
--	Placement: pullBack 4, effMin 4, effMax 6. Footprint check to avoid overlap.
------------------------------------------------------------------------------
include("X_IslandHelpers");

local HILLS_MIN = 40;
local HILLS_MAX = 75;

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

local function buildSSpine(cx, cy, iW, iH, wrapX, wrapY)
	local seg1 = 3 + Map.Rand(3, "");
	local trans = 1 + Map.Rand(2, "");
	local seg2 = 3 + Map.Rand(3, "");
	local dir = Map.Rand(6, "") + 1;
	local turn1 = (Map.Rand(2, "") == 0) and -1 or 1;
	local turn2 = -turn1;

	local spine = {{cx, cy}};
	local x, y = cx, cy;

	for _ = 1, seg1 - 1 do
		dir = ((dir + turn1 + 5) % 6) + 1;
		local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			spine[#spine + 1] = {nx, ny};
			x, y = nx, ny;
		else break; end
	end

	for _ = 1, trans do
		local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			spine[#spine + 1] = {nx, ny};
			x, y = nx, ny;
		else break; end
	end

	for _ = 1, seg2 - 1 do
		dir = ((dir + turn2 + 5) % 6) + 1;
		local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			spine[#spine + 1] = {nx, ny};
			x, y = nx, ny;
		else break; end
	end

	return spine;
end

local function addWidth(landTiles, iW, iH, wrapX, wrapY)
	local spineSet = {};
	for _, t in ipairs(landTiles) do spineSet[t[1] .. "," .. t[2]] = true; end
	local added = {};
	for i, t in ipairs(landTiles) do
		if Map.Rand(100, "") < 55 then
			for dir = 1, 6 do
				local nx, ny = GetHexNeighbor(t[1], t[2], dir, iW, iH, wrapX, wrapY);
				if nx >= 0 and nx < iW and ny >= 0 and ny < iH and not spineSet[nx .. "," .. ny] and not added[nx .. "," .. ny] then
					landTiles[#landTiles + 1] = {nx, ny};
					added[nx .. "," .. ny] = true;
					spineSet[nx .. "," .. ny] = true;
					break;
				end
			end
		end
	end
end

function TryPlaceSShapeIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 4;
	local effMin = params.effMin or 4;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local spine = buildSSpine(centerX, centerY, params.iW, params.iH, params.wrapX, params.wrapY);
	if #spine < 6 then return false; end

	local landTiles = {};
	for _, t in ipairs(spine) do landTiles[#landTiles + 1] = {t[1], t[2]}; end
	addWidth(landTiles, params.iW, params.iH, params.wrapX, params.wrapY);

	local target = 10 + Map.Rand(7, "");
	while #landTiles < target and #landTiles < 16 do
		local r = Map.Rand(#landTiles, "") + 1;
		local tx, ty = landTiles[r][1], landTiles[r][2];
		local found = false;
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(tx, ty, dir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
				local dup = false;
				for _, t in ipairs(landTiles) do if t[1] == nx and t[2] == ny then dup = true; break; end end
				if not dup then
					landTiles[#landTiles + 1] = {nx, ny};
					found = true;
					break;
				end
			end
		end
		if not found then break; end
	end

	if #landTiles < 10 or #landTiles > 16 then return false; end

	local variant = Map.Rand(100, "");
	local hasHead = (variant < 3);
	local hasMountainCluster = (variant >= 3 and variant < 6);

	if hasHead then
		local endIdx = (Map.Rand(2, "") == 0) and 1 or #landTiles;
		local headTile = landTiles[endIdx];
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(headTile[1], headTile[2], dir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
				local dup = false;
				for _, t in ipairs(landTiles) do if t[1] == nx and t[2] == ny then dup = true; break; end end
				if not dup then landTiles[#landTiles + 1] = {nx, ny}; break; end
			end
		end
	end

	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawSShapeIsland(plotTypes, landTiles, hasHead, hasMountainCluster, params.iW, params.iH, params.wrapX, params.wrapY);
	return true;
end

function DrawSShapeIsland(plotTypes, landTiles, hasHead, hasMountainCluster, iW, iH, wrapX, wrapY)
	wrapY = wrapY or false;
	local mountainTiles = {};
	if hasHead then
		local endIdx = (#landTiles >= 2) and ((Map.Rand(2, "") == 0) and 1 or #landTiles) or 1;
		mountainTiles[#mountainTiles + 1] = landTiles[endIdx];
	elseif hasMountainCluster then
		local mid = math.floor(#landTiles / 2);
		local clusterSize = 2 + Map.Rand(3, "");
		for i = math.max(1, mid - 1), math.min(#landTiles, mid + 2) do
			if #mountainTiles < clusterSize then
				mountainTiles[#mountainTiles + 1] = landTiles[i];
			end
		end
	end

	local mountainSet = {};
	for _, t in ipairs(mountainTiles) do
		mountainSet[t[1] .. "," .. t[2]] = true;
	end

	local hillsPct = HILLS_MIN + Map.Rand(HILLS_MAX - HILLS_MIN + 1, "");
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		if mountainSet[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			plotTypes[idx] = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
