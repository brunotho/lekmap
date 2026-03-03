------------------------------------------------------------------------------
--	RidgePeak.lua
--	Mountain ridge island: center ridge, land on one side, water gap + far land on other.
------------------------------------------------------------------------------
include("X_IslandHelpers");

local CONFIG = {
	RIDGE_LEN_MIN = 3, RIDGE_LEN_RANGE = 3,  -- 3-5 tiles
	RIDGE_TURN_PCT = 30,
	RIDGE_RIFT_PCT = 70,  -- when ridge has 3+ tiles: % chance to add 1-2 water rifts (splinter)
	LAND_SIDE_PCT_MIN = 50, LAND_SIDE_PCT_MAX = 85,  -- % of mountain-adjacent tiles that are land
	WATER_GAP = 1,
	FAR_LAND_MIN = 3, FAR_LAND_MAX = 5,  -- land tiles on water side
	SATELLITE_PCT = 35,  -- % chance to add 1-2 satellite land tiles (1 water gap from main)
	SATELLITE_MIN = 1, SATELLITE_MAX = 2,
	HILLS_ADJ_PCT = 85, HILLS_2ND_PCT = 65, HILLS_3RD_PCT = 50,
};

function TryPlaceRidgePeak(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 0;
	local effMin = params.effMin or 0;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local iW, iH = params.iW, params.iH;
	local wrapX, wrapY = params.wrapX, params.wrapY;
	local cx = WrapCoord(centerX, iW, wrapX);
	local cy = WrapCoord(centerY, iH, wrapY);
	if cx < 0 or cx >= iW or cy < 0 or cy >= iH then return false; end

	-- 1. Ridge in center (3-5 tiles, roughly line)
	local ridgeLen = CONFIG.RIDGE_LEN_MIN + Map.Rand(CONFIG.RIDGE_LEN_RANGE, "");
	local dir = Map.Rand(6, "") + 1;
	local px, py = cx, cy;
	local ridgeSet = {};
	for step = 1, ridgeLen do
		ridgeSet[px .. "," .. py] = true;
		if step < ridgeLen then
			if step == 4 and ridgeLen > 3 then
				dir = ((dir + (Map.Rand(2, "") == 0 and -1 or 1) + 5) % 6) + 1;
			elseif Map.Rand(100, "") < CONFIG.RIDGE_TURN_PCT then
				dir = ((dir + (Map.Rand(2, "") == 0 and -1 or 1) + 5) % 6) + 1;
			end
			px, py = GetHexNeighbor(px, py, dir, iW, iH, wrapX, wrapY);
			if px < 0 or px >= iW or py < 0 or py >= iH then break; end
		end
	end

	local riftSet = {};
	local ridgeList = {};
	for k in pairs(ridgeSet) do ridgeList[#ridgeList + 1] = k; end
	if #ridgeList >= 3 and Map.Rand(100, "") < CONFIG.RIDGE_RIFT_PCT then
		local numRifts = 1 + Map.Rand(2, "");
		numRifts = math.min(numRifts, #ridgeList - 1);
		for _ = 1, numRifts do
			local i = 1 + Map.Rand(#ridgeList, "");
			riftSet[ridgeList[i]] = true;
		end
	end

	for key in pairs(ridgeSet) do
		local x, y = key:match("([^,]+),([^,]+)");
		x, y = tonumber(x), tonumber(y);
		plotTypes[y * iW + x] = riftSet[key] and PlotTypes.PLOT_OCEAN or PlotTypes.PLOT_MOUNTAIN;
	end

	-- 2. Land side: tiles adjacent to ridge, 40-80% land (rolled once per island)
	local landSidePct = CONFIG.LAND_SIDE_PCT_MIN + Map.Rand(CONFIG.LAND_SIDE_PCT_MAX - CONFIG.LAND_SIDE_PCT_MIN + 1, "");
	local landSideDir = dir;
	local waterSideDir = ((dir + 2) % 6) + 1;

	local adjToRidge = {};
	for key in pairs(ridgeSet) do
		local rx, ry = key:match("([^,]+),([^,]+)");
		rx, ry = tonumber(rx), tonumber(ry);
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(rx, ry, d, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local nk = nx .. "," .. ny;
				if not ridgeSet[nk] then adjToRidge[nk] = true; end
			end
		end
	end

	local landSet = {};
	for key in pairs(adjToRidge) do
		if Map.Rand(100, "") < landSidePct then
			landSet[key] = "land_side";
		end
	end

	-- 3. Water side: 1 tile water gap, then 2-4 land tiles
	local numFarLand = CONFIG.FAR_LAND_MIN + Map.Rand(CONFIG.FAR_LAND_MAX - CONFIG.FAR_LAND_MIN + 1, "");
	local gapTiles = {};
	for key in pairs(adjToRidge) do
		if not landSet[key] then
			gapTiles[key] = true;
		end
	end

	local farLandSet = {};
	local waterSideCandidates = {};
	for key in pairs(gapTiles) do
		local x, y = key:match("([^,]+),([^,]+)");
		x, y = tonumber(x), tonumber(y);
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(x, y, d, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local nk = nx .. "," .. ny;
				if not ridgeSet[nk] and not gapTiles[nk] and not landSet[nk] then
					waterSideCandidates[nk] = true;
				end
			end
		end
	end

	local farList = {};
	for k in pairs(waterSideCandidates) do farList[#farList + 1] = k; end
	for i = 1, math.min(numFarLand, #farList) do
		local j = i + Map.Rand(#farList - i + 1, "");
		if j < i then j = i; end
		farList[i], farList[j] = farList[j], farList[i];
		local nk = farList[i];
		if nk then farLandSet[nk] = true; end
	end

	for key in pairs(gapTiles) do
		local x, y = key:match("([^,]+),([^,]+)");
		x, y = tonumber(x), tonumber(y);
		plotTypes[y * iW + x] = PlotTypes.PLOT_OCEAN;
	end

	-- 4. Satellite islands: 1-2 land tiles with 1 water gap from main (occasionally)
	local allLandSet = {};
	for k in pairs(landSet) do allLandSet[k] = true; end
	for k in pairs(farLandSet) do allLandSet[k] = true; end

	if Map.Rand(100, "") < CONFIG.SATELLITE_PCT then
		local waterAdjToLand = {};
		for key in pairs(allLandSet) do
			local x, y = key:match("([^,]+),([^,]+)");
			x, y = tonumber(x), tonumber(y);
			for d = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, d, iW, iH, wrapX, wrapY);
				if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
					local nk = nx .. "," .. ny;
					if not allLandSet[nk] and not ridgeSet[nk] then
						waterAdjToLand[nk] = true;
					end
				end
			end
		end
		local satCandidates = {};
		for key in pairs(waterAdjToLand) do
			local x, y = key:match("([^,]+),([^,]+)");
			x, y = tonumber(x), tonumber(y);
			for d = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, d, iW, iH, wrapX, wrapY);
				if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
					local nk = nx .. "," .. ny;
					if not allLandSet[nk] and not ridgeSet[nk] and not waterAdjToLand[nk] then
						satCandidates[nk] = true;
					end
				end
			end
		end
		local satList = {};
		for k in pairs(satCandidates) do satList[#satList + 1] = k; end
		local numSat = CONFIG.SATELLITE_MIN + Map.Rand(CONFIG.SATELLITE_MAX - CONFIG.SATELLITE_MIN + 1, "");
		for i = 1, math.min(numSat, #satList) do
			local j = i + Map.Rand(#satList - i + 1, "");
			if j < i then j = i; end
			satList[i], satList[j] = satList[j], satList[i];
			allLandSet[satList[i]] = true;
		end
	end

	local distToRidge = {};
	local queue = {};
	for k in pairs(ridgeSet) do
		if not riftSet[k] then
			local x, y = k:match("([^,]+),([^,]+)");
			x, y = tonumber(x), tonumber(y);
			distToRidge[k] = 0;
			queue[#queue + 1] = {x, y};
		end
	end
	local q = 1;
	while q <= #queue do
		local x, y = queue[q][1], queue[q][2];
		local key = x .. "," .. y;
		local d = distToRidge[key] or 0;
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local nk = nx .. "," .. ny;
				if distToRidge[nk] == nil then
					distToRidge[nk] = d + 1;
					queue[#queue + 1] = {nx, ny};
				end
			end
		end
		q = q + 1;
	end

	for key in pairs(allLandSet) do
		local x, y = key:match("([^,]+),([^,]+)");
		x, y = tonumber(x), tonumber(y);
		local d = distToRidge[key];
		local hillsPct = CONFIG.HILLS_3RD_PCT;
		if d == 1 then hillsPct = CONFIG.HILLS_ADJ_PCT;
		elseif d == 2 then hillsPct = CONFIG.HILLS_2ND_PCT; end
		plotTypes[y * iW + x] = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end

	return true;
end
