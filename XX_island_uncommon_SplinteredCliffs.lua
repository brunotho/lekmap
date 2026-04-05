include("X_IslandHelpers");

local CONFIG = {
	RIDGE_LEN_MIN = 4,
	RIDGE_LEN_MAX = 7,
	RIDGE_TURN_PCT = 46,
	RIDGE_DOUBLE_TURN_PCT = 15,
	RIDGE_SKIP_STEP_PCT = 11,
	RIDGE_WIGGLE_PCT = 20,
	RIDGE_WIDTH_MIN = 1,
	RIDGE_WIDTH_MAX = 3,
	PAD1_PCT = 84,
	PAD2_PCT = 46,
	PAD_GAP_PCT = 14,
	FOOTHOLD_GAP_PCT = 11,
	SPRAY_BRANCH_MIN = 2,
	SPRAY_BRANCH_MAX = 4,
	SPRAY_BRANCH_LEN_MIN = 1,
	SPRAY_BRANCH_LEN_MAX = 3,
	SPRAY_STAY_DIR_PCT = 58,
	FOOTHOLD_COUNT_MIN = 3,
	FOOTHOLD_COUNT_MAX = 7,
	FOOTHOLD_ATTACH_PCT = 72,
	OVAL_SEMI_MAJOR = 8,
	OVAL_SEMI_MINOR = 5,
	MOUNTAIN_PCT_MIN = 20,
	MOUNTAIN_PCT_MAX = 35,
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

local function rotDir(d, delta)
	return ((d - 1 + delta) % 6 + 6) % 6 + 1;
end

local function addTile(allSet, allTiles, x, y)
	local k = kxy(x, y);
	if not allSet[k] then
		allSet[k] = true;
		allTiles[#allTiles + 1] = { x, y };
	end
end

local function dirTowardSpray(baseDir)
	local r = Map.Rand(100, "");
	if r < CONFIG.SPRAY_STAY_DIR_PCT then return baseDir; end
	if r < CONFIG.SPRAY_STAY_DIR_PCT + 18 then return rotDir(baseDir, -1); end
	if r < CONFIG.SPRAY_STAY_DIR_PCT + 36 then return rotDir(baseDir, 1); end
	return rotDir(baseDir, Map.Rand(2, "") == 0 and 2 or -2);
end

local function ridgeWidthNow()
	return CONFIG.RIDGE_WIDTH_MIN + Map.Rand(CONFIG.RIDGE_WIDTH_MAX - CONFIG.RIDGE_WIDTH_MIN + 1, "scW");
end

function DrawSplinteredCliffsIsland(plotTypes, allTiles, coreSet, ridgeSet, iW)
	local count = #allTiles;
	local mtnPct = CONFIG.MOUNTAIN_PCT_MIN + Map.Rand(CONFIG.MOUNTAIN_PCT_MAX - CONFIG.MOUNTAIN_PCT_MIN + 1, "");
	local targetMtn = math.max(1, math.floor(count * mtnPct / 100 + 0.5));
	local mountainSet = {};
	local mountainCount = 0;

	for _, t in ipairs(allTiles) do
		local k = kxy(t[1], t[2]);
		if coreSet[k] then
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
	local ei = 1;
	while mountainCount < targetMtn and ei <= #extra do
		local t = extra[ei];
		local k = kxy(t[1], t[2]);
		if ridgeSet[k] then
			mountainSet[k] = true;
			mountainCount = mountainCount + 1;
		end
		ei = ei + 1;
	end

	for _, t in ipairs(allTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		if mountainSet[kxy(x, y)] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			local h = 36 + Map.Rand(32, "");
			plotTypes[idx] = (Map.Rand(100, "") < h) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
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
		return (ex * ex + ey * ey) <= 1.04;
	end

	local allSet, allTiles = {}, {};
	local ridgeSet = {};
	local coreSet = {};

	local ridgeDir = Map.Rand(6, "") + 1;
	local sprayDir = rotDir(ridgeDir, 2 + Map.Rand(2, ""));
	local x, y = cx, cy;
	addTile(allSet, allTiles, x, y);
	ridgeSet[kxy(x, y)] = true;
	coreSet[kxy(x, y)] = true;

	local ridgeLen = CONFIG.RIDGE_LEN_MIN + Map.Rand(CONFIG.RIDGE_LEN_MAX - CONFIG.RIDGE_LEN_MIN + 1, "");
	for _ = 1, ridgeLen - 1 do
		if Map.Rand(100, "") < CONFIG.RIDGE_SKIP_STEP_PCT then
		else
			if Map.Rand(100, "") < CONFIG.RIDGE_TURN_PCT then
				local delta = (Map.Rand(2, "") == 0) and -1 or 1;
				ridgeDir = rotDir(ridgeDir, delta);
				if Map.Rand(100, "") < CONFIG.RIDGE_DOUBLE_TURN_PCT then
					ridgeDir = rotDir(ridgeDir, delta);
				end
			elseif Map.Rand(100, "") < CONFIG.RIDGE_WIGGLE_PCT then
				ridgeDir = rotDir(ridgeDir, Map.Rand(2, "") == 0 and 1 or -1);
			end
			local nx, ny = GetHexNeighbor(x, y, ridgeDir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx < 0 or nx >= params.iW or ny < 0 or ny >= params.iH then break; end
			x, y = nx, ny;
			addTile(allSet, allTiles, x, y);
			ridgeSet[kxy(x, y)] = true;
			coreSet[kxy(x, y)] = true;

			local wband = ridgeWidthNow();
			local left = rotDir(ridgeDir, 2);
			local right = rotDir(ridgeDir, -2);
			local lx, ly = x, y;
			for s = 1, math.floor(wband / 2) do
				lx, ly = GetHexNeighbor(lx, ly, left, params.iW, params.iH, params.wrapX, params.wrapY);
				if lx >= 0 and lx < params.iW and ly >= 0 and ly < params.iH and inOval(lx, ly) then
					addTile(allSet, allTiles, lx, ly);
					ridgeSet[kxy(lx, ly)] = true;
					coreSet[kxy(lx, ly)] = true;
				end
			end
			local rx, ry = x, y;
			for s = 1, math.floor((wband - 1) / 2) do
				rx, ry = GetHexNeighbor(rx, ry, right, params.iW, params.iH, params.wrapX, params.wrapY);
				if rx >= 0 and rx < params.iW and ry >= 0 and ry < params.iH and inOval(rx, ry) then
					addTile(allSet, allTiles, rx, ry);
					ridgeSet[kxy(rx, ry)] = true;
					coreSet[kxy(rx, ry)] = true;
				end
			end
		end
	end

	local ridgeTiles = 0;
	for k in pairs(ridgeSet) do
		ridgeTiles = ridgeTiles + 1;
	end
	if ridgeTiles < 4 then return false; end

	local function padLayer(padPct, isCoreNeighbor)
		local toAdd = {};
		for _, t in ipairs(allTiles) do
			local k = kxy(t[1], t[2]);
			local wantCore = isCoreNeighbor and coreSet[k] or (not isCoreNeighbor and not coreSet[k]);
			if wantCore then
				for d = 1, 6 do
					local nx, ny = GetHexNeighbor(t[1], t[2], d, params.iW, params.iH, params.wrapX, params.wrapY);
					if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and inOval(nx, ny) then
						local nk = kxy(nx, ny);
						if not allSet[nk] and Map.Rand(100, "") < padPct then
							toAdd[#toAdd + 1] = { nx, ny };
						end
					end
				end
			end
		end
		for _, row in ipairs(toAdd) do
			if Map.Rand(100, "") < CONFIG.PAD_GAP_PCT then
			else
				addTile(allSet, allTiles, row[1], row[2]);
			end
		end
	end

	padLayer(CONFIG.PAD1_PCT, true);
	padLayer(CONFIG.PAD2_PCT, false);

	local branchCount = CONFIG.SPRAY_BRANCH_MIN + Map.Rand(CONFIG.SPRAY_BRANCH_MAX - CONFIG.SPRAY_BRANCH_MIN + 1, "");
	for _ = 1, branchCount do
		local seed = allTiles[1 + Map.Rand(#allTiles, "")];
		local bx, by = seed[1], seed[2];
		local bdir = dirTowardSpray(sprayDir);
		local blen = CONFIG.SPRAY_BRANCH_LEN_MIN + Map.Rand(CONFIG.SPRAY_BRANCH_LEN_MAX - CONFIG.SPRAY_BRANCH_LEN_MIN + 1, "");
		for _s = 1, blen do
			local nx, ny = GetHexNeighbor(bx, by, bdir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx < 0 or nx >= params.iW or ny < 0 or ny >= params.iH then break; end
			bx, by = nx, ny;
			if inOval(bx, by) and Map.Rand(100, "") < 74 then addTile(allSet, allTiles, bx, by); end
			if Map.Rand(100, "") < 42 then
				local near = rotDir(bdir, Map.Rand(2, "") == 0 and 2 or -2);
				local sx, sy = GetHexNeighbor(bx, by, near, params.iW, params.iH, params.wrapX, params.wrapY);
				if sx >= 0 and sx < params.iW and sy >= 0 and sy < params.iH and Map.Rand(100, "") < 36 then
					if inOval(sx, sy) then addTile(allSet, allTiles, sx, sy); end
				end
			end
			bdir = dirTowardSpray(sprayDir);
		end
	end

	local footholdCount = CONFIG.FOOTHOLD_COUNT_MIN + Map.Rand(CONFIG.FOOTHOLD_COUNT_MAX - CONFIG.FOOTHOLD_COUNT_MIN + 1, "");
	for _ = 1, footholdCount do
		local seed = allTiles[1 + Map.Rand(#allTiles, "")];
		local fdir = (Map.Rand(100, "") < CONFIG.FOOTHOLD_ATTACH_PCT) and dirTowardSpray(sprayDir) or (Map.Rand(6, "") + 1);
		local fx, fy = GetHexNeighbor(seed[1], seed[2], fdir, params.iW, params.iH, params.wrapX, params.wrapY);
		if fx >= 0 and fx < params.iW and fy >= 0 and fy < params.iH and Map.Rand(100, "") < 88 then
			if Map.Rand(100, "") < CONFIG.FOOTHOLD_GAP_PCT then
			else
				if inOval(fx, fy) then addTile(allSet, allTiles, fx, fy); end
			end
		end
	end

	if #allTiles < 10 then return false; end
	if not footprintClear(plotTypes, allTiles, params.iW, params.iH) then return false; end

	DrawSplinteredCliffsIsland(plotTypes, allTiles, coreSet, ridgeSet, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.splinteredCliffs = true;
	return true;
end
