include("X_IslandHelpers");

local CONFIG = {
	RIDGE_LEN_MIN = 8, RIDGE_LEN_MAX = 12,
	RIDGE_TURN_PCT = 18,
	RIDGE_WIDEN_PCT = 30,
	SPRAY_BRANCH_MIN = 4, SPRAY_BRANCH_MAX = 7,
	SPRAY_BRANCH_LEN_MIN = 2, SPRAY_BRANCH_LEN_MAX = 5,
	SPRAY_STAY_DIR_PCT = 68,
	FOOTHOLD_COUNT_MIN = 8, FOOTHOLD_COUNT_MAX = 14,
	FOOTHOLD_ATTACH_PCT = 78,
	OVAL_SEMI_MAJOR = 7, OVAL_SEMI_MINOR = 4,
	MOUNTAIN_PCT_MIN = 45, MOUNTAIN_PCT_MAX = 70,
};

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

local function kxy(x, y) return x .. "," .. y; end

local function addTile(set, list, x, y)
	local k = kxy(x, y);
	if not set[k] then
		set[k] = true;
		list[#list + 1] = { x, y };
	end
end

local function dirToward(baseDir)
	local r = Map.Rand(100, "");
	if r < CONFIG.SPRAY_STAY_DIR_PCT then return baseDir; end
	if r < CONFIG.SPRAY_STAY_DIR_PCT + 16 then return ((baseDir + 4) % 6) + 1; end
	if r < CONFIG.SPRAY_STAY_DIR_PCT + 32 then return ((baseDir) % 6) + 1; end
	return ((baseDir + 2) % 6) + 1;
end

function TryPlaceSplinteredCliffsIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.splinteredCliffs then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end
	local ovalOrient = Map.Rand(2, "");

	local function inOval(tx, ty)
		local dx = tx - cx;
		local dy = ty - cy;
		if params.wrapX and math.abs(dx) > params.iW / 2 then
			dx = dx - (dx > 0 and params.iW or -params.iW);
		end
		local ex, ey;
		if ovalOrient == 0 then
			ex = dx / CONFIG.OVAL_SEMI_MAJOR;
			ey = dy / CONFIG.OVAL_SEMI_MINOR;
		else
			ex = dy / CONFIG.OVAL_SEMI_MAJOR;
			ey = dx / CONFIG.OVAL_SEMI_MINOR;
		end
		return (ex * ex + ey * ey) <= 1.0;
	end

	local allSet, allTiles = {}, {};
	local ridgeSet = {};

	local ridgeDir = Map.Rand(6, "") + 1;
	local sprayDir = ((ridgeDir + 2 + Map.Rand(3, "")) % 6) + 1;
	local x, y = cx, cy;
	addTile(allSet, allTiles, x, y);
	ridgeSet[kxy(x, y)] = true;
	local ridgeLen = CONFIG.RIDGE_LEN_MIN + Map.Rand(CONFIG.RIDGE_LEN_MAX - CONFIG.RIDGE_LEN_MIN + 1, "");
	for _ = 1, ridgeLen - 1 do
		if Map.Rand(100, "") < CONFIG.RIDGE_TURN_PCT then
			local delta = (Map.Rand(2, "") == 0) and -1 or 1;
			ridgeDir = ((ridgeDir + delta + 5) % 6) + 1;
		end
		local nx, ny = GetHexNeighbor(x, y, ridgeDir, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx < 0 or nx >= params.iW or ny < 0 or ny >= params.iH then break; end
		x, y = nx, ny;
		addTile(allSet, allTiles, x, y);
		ridgeSet[kxy(x, y)] = true;
		if Map.Rand(100, "") < CONFIG.RIDGE_WIDEN_PCT then
			local side = (Map.Rand(2, "") == 0) and ((ridgeDir + 4) % 6) + 1 or ((ridgeDir) % 6) + 1;
			local sx, sy = GetHexNeighbor(x, y, side, params.iW, params.iH, params.wrapX, params.wrapY);
			if sx >= 0 and sx < params.iW and sy >= 0 and sy < params.iH then
				addTile(allSet, allTiles, sx, sy);
				ridgeSet[kxy(sx, sy)] = true;
			end
		end
	end

	local ridgeList = {};
	for _, t in ipairs(allTiles) do
		if ridgeSet[kxy(t[1], t[2])] then ridgeList[#ridgeList + 1] = t; end
	end
	if #ridgeList < 6 then return false; end

	local branchCount = CONFIG.SPRAY_BRANCH_MIN + Map.Rand(CONFIG.SPRAY_BRANCH_MAX - CONFIG.SPRAY_BRANCH_MIN + 1, "");
	for _ = 1, branchCount do
		local seed = ridgeList[1 + Map.Rand(#ridgeList, "")];
		local bx, by = seed[1], seed[2];
		local bdir = dirToward(sprayDir);
		local blen = CONFIG.SPRAY_BRANCH_LEN_MIN + Map.Rand(CONFIG.SPRAY_BRANCH_LEN_MAX - CONFIG.SPRAY_BRANCH_LEN_MIN + 1, "");
		for _s = 1, blen do
			local nx, ny = GetHexNeighbor(bx, by, bdir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx < 0 or nx >= params.iW or ny < 0 or ny >= params.iH then break; end
			bx, by = nx, ny;
			if inOval(bx, by) then addTile(allSet, allTiles, bx, by); end
			if Map.Rand(100, "") < 60 then
				local near = (Map.Rand(2, "") == 0) and ((bdir + 4) % 6) + 1 or ((bdir) % 6) + 1;
				local sx, sy = GetHexNeighbor(bx, by, near, params.iW, params.iH, params.wrapX, params.wrapY);
				if sx >= 0 and sx < params.iW and sy >= 0 and sy < params.iH and Map.Rand(100, "") < 34 then
					if inOval(sx, sy) then addTile(allSet, allTiles, sx, sy); end
				end
			end
			bdir = dirToward(sprayDir);
		end
	end

	local footholdCount = CONFIG.FOOTHOLD_COUNT_MIN + Map.Rand(CONFIG.FOOTHOLD_COUNT_MAX - CONFIG.FOOTHOLD_COUNT_MIN + 1, "");
	for _ = 1, footholdCount do
		local seed = allTiles[1 + Map.Rand(#allTiles, "")];
		local fdir = (Map.Rand(100, "") < CONFIG.FOOTHOLD_ATTACH_PCT) and dirToward(sprayDir) or (Map.Rand(6, "") + 1);
		local fx, fy = GetHexNeighbor(seed[1], seed[2], fdir, params.iW, params.iH, params.wrapX, params.wrapY);
		if fx >= 0 and fx < params.iW and fy >= 0 and fy < params.iH then
			if inOval(fx, fy) then addTile(allSet, allTiles, fx, fy); end
		end
	end

	if #allTiles < 14 then return false; end
	if not footprintClear(plotTypes, allTiles, params.iW, params.iH) then return false; end

	DrawSplinteredCliffsIsland(plotTypes, allTiles, ridgeSet, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.splinteredCliffs = true;
	return true;
end

function DrawSplinteredCliffsIsland(plotTypes, allTiles, ridgeSet, iW)
	local count = #allTiles;
	local mtnPct = CONFIG.MOUNTAIN_PCT_MIN + Map.Rand(CONFIG.MOUNTAIN_PCT_MAX - CONFIG.MOUNTAIN_PCT_MIN + 1, "");
	local targetMtn = math.max(1, math.floor(count * mtnPct / 100 + 0.5));
	local mountainSet = {};
	local mountainCount = 0;

	for _, t in ipairs(allTiles) do
		local k = kxy(t[1], t[2]);
		if ridgeSet[k] then
			mountainSet[k] = true;
			mountainCount = mountainCount + 1;
		end
	end

	local extra = {};
	for _, t in ipairs(allTiles) do
		local k = kxy(t[1], t[2]);
		if not mountainSet[k] then extra[#extra + 1] = t; end
	end
	for i = #extra, 2, -1 do
		local j = 1 + Map.Rand(i, "");
		extra[i], extra[j] = extra[j], extra[i];
	end
	local i = 1;
	while mountainCount < targetMtn and i <= #extra do
		local t = extra[i];
		local k = kxy(t[1], t[2]);
		mountainSet[k] = true;
		mountainCount = mountainCount + 1;
		i = i + 1;
	end

	for _, t in ipairs(allTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		if mountainSet[kxy(x, y)] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 62) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
