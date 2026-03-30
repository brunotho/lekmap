-- Linear mountain ridge with land on one flank, a water slot, then more land and optional satellites.

include("X_IslandHelpers");

local CONFIG = {
	RIDGE_LEN_MIN = 3, RIDGE_LEN_RANGE = 3,
	RIDGE_TURN_PCT = 30,
	RIDGE_STRAIGHT_FORCE_AT = 5,
	RIDGE_BRANCH_LEN_MIN = 2, RIDGE_BRANCH_LEN_RANGE = 2,
	RIDGE_RIFT_PCT = 70,
	LAND_SIDE_PCT_MIN = 50, LAND_SIDE_PCT_MAX = 85,
	WATER_GAP = 1,
	FAR_LAND_MIN = 3, FAR_LAND_MAX = 5,
	SATELLITE_PCT = 35,
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

	local ridgeLen = CONFIG.RIDGE_LEN_MIN + Map.Rand(CONFIG.RIDGE_LEN_RANGE, "");
	local dir = Map.Rand(6, "") + 1;
	local px, py = cx, cy;
	local ridgeSet = {};
	local lastMoveDir = nil;
	local straightRunTiles = 1;
	local straightCap = CONFIG.RIDGE_STRAIGHT_FORCE_AT or 5;

	local function turnDirFrom(fromD)
		return ((fromD + (Map.Rand(2, "") == 0 and -1 or 1) + 5) % 6) + 1;
	end

	ridgeSet[px .. "," .. py] = true;
	for step = 2, ridgeLen do
		if lastMoveDir and dir == lastMoveDir and straightRunTiles >= straightCap then
			if Map.Rand(2, "") == 0 then
				dir = turnDirFrom(lastMoveDir);
			else
				local bDir = turnDirFrom(lastMoveDir);
				local bLen = (CONFIG.RIDGE_BRANCH_LEN_MIN or 2) + Map.Rand(CONFIG.RIDGE_BRANCH_LEN_RANGE or 2, "");
				local bx, by = px, py;
				for _b = 1, bLen do
					bx, by = GetHexNeighbor(bx, by, bDir, iW, iH, wrapX, wrapY);
					if bx < 0 or bx >= iW or by < 0 or by >= iH then
						break;
					end
					local bk = bx .. "," .. by;
					if not ridgeSet[bk] then
						ridgeSet[bk] = true;
					end
				end
				dir = turnDirFrom(lastMoveDir);
			end
		elseif step == 4 and ridgeLen > 3 then
			dir = turnDirFrom(dir);
		elseif Map.Rand(100, "") < CONFIG.RIDGE_TURN_PCT then
			dir = turnDirFrom(dir);
		end

		local moveDir = dir;
		px, py = GetHexNeighbor(px, py, moveDir, iW, iH, wrapX, wrapY);
		if px < 0 or px >= iW or py < 0 or py >= iH then
			break;
		end
		ridgeSet[px .. "," .. py] = true;

		if lastMoveDir == nil then
			lastMoveDir = moveDir;
			straightRunTiles = 2;
		elseif moveDir == lastMoveDir then
			straightRunTiles = straightRunTiles + 1;
		else
			lastMoveDir = moveDir;
			straightRunTiles = 2;
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
