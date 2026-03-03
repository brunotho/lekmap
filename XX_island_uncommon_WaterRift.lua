------------------------------------------------------------------------------
--	WaterRift.lua
--	3-radius disk, curved/splintered water rift. Inner (r1-2): hills/land. Outer (r3): land/ocean.
------------------------------------------------------------------------------
include("X_IslandHelpers");

local CONFIG = {
	DISK_RADIUS = 3,
	INNER_HILLS_PCT = 70,
	OUTER_LAND_PCT_INNER = 65, OUTER_LAND_PCT_OUTER = 35,  -- gradient: inner r3 vs outer r3
	OUTER_TILE_APPEAR_PCT = 82,
	RIFT_TURN_LEFT_PCT = 30, RIFT_TURN_RIGHT_PCT = 15, RIFT_DOUBLE_TURN_PCT = 12,  -- less zigzag, natural inlet
	RIFT_STEPS_MIN = 5, RIFT_STEPS_RANGE = 3,
	BRANCH_COUNT_MIN = 0, BRANCH_COUNT_RANGE = 2,  -- 0-2 branches, fewer
	BRANCH_STEPS_MIN = 1, BRANCH_STEPS_RANGE = 1,
	BRANCH_DIR_CHANGE_PCT = 25,
};

function TryPlaceWaterRift(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 0;
	local effMin = params.effMin or 0;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local disk = GetHexDisk(cx, cy, CONFIG.DISK_RADIUS, params.iW, params.iH, params.wrapX, params.wrapY);
	local diskSet = {};
	for _, t in ipairs(disk) do diskSet[t[1] .. "," .. t[2]] = true; end

	-- Curved/splintered cut: walk from center in two opposite directions, meandering with more noise
	local riftDir = Map.Rand(6, "") + 1;
	local oppDir = ((riftDir + 2) % 6) + 1;
	local riftSet = {};
	riftSet[cx .. "," .. cy] = true;

	local function walkRift(startX, startY, baseDir, steps)
		local px, py = startX, startY;
		local dir = baseDir;
		for _ = 1, steps do
			px, py = GetHexNeighbor(px, py, dir, params.iW, params.iH, params.wrapX, params.wrapY);
			if px >= 0 and px < params.iW and py >= 0 and py < params.iH and diskSet[px .. "," .. py] then
				riftSet[px .. "," .. py] = true;
				-- More noise: 50% turn left, 30% straight, 20% turn right; occasional double-turn
				local r = Map.Rand(100, "");
				if r < CONFIG.RIFT_TURN_LEFT_PCT then dir = ((dir - 2) % 6) + 1;
				elseif r >= (100 - CONFIG.RIFT_TURN_RIGHT_PCT) then dir = ((dir + 2) % 6) + 1; end
				if Map.Rand(100, "") < CONFIG.RIFT_DOUBLE_TURN_PCT then dir = ((dir + (Map.Rand(2, "") == 0 and -2 or 2)) % 6) + 1; end
			else break; end
		end
	end
	walkRift(cx, cy, riftDir, CONFIG.RIFT_STEPS_MIN + Map.Rand(CONFIG.RIFT_STEPS_RANGE, ""));
	walkRift(cx, cy, oppDir, CONFIG.RIFT_STEPS_MIN + Map.Rand(CONFIG.RIFT_STEPS_RANGE, ""));

	for _ = 1, CONFIG.BRANCH_COUNT_MIN + Map.Rand(CONFIG.BRANCH_COUNT_RANGE, "") do
		local branchDir = Map.Rand(6, "") + 1;
		local bx, by = cx, cy;
		for step = 1, CONFIG.BRANCH_STEPS_MIN + Map.Rand(CONFIG.BRANCH_STEPS_RANGE, "") do
			bx, by = GetHexNeighbor(bx, by, branchDir, params.iW, params.iH, params.wrapX, params.wrapY);
			if bx >= 0 and bx < params.iW and by >= 0 and by < params.iH and diskSet[bx .. "," .. by] then
				riftSet[bx .. "," .. by] = true;
				if Map.Rand(100, "") < CONFIG.BRANCH_DIR_CHANGE_PCT then branchDir = ((branchDir + (Map.Rand(2, "") == 0 and -1 or 1)) % 6) + 1; end
			else break; end
		end
	end

	local disk2 = GetHexDisk(cx, cy, CONFIG.DISK_RADIUS - 1, params.iW, params.iH, params.wrapX, params.wrapY);
	local disk2Set = {};
	for _, t in ipairs(disk2) do disk2Set[t[1] .. "," .. t[2]] = true; end

	for _, t in ipairs(disk) do
		local x, y = t[1], t[2];
		if riftSet[x .. "," .. y] then
			plotTypes[y * params.iW + x] = PlotTypes.PLOT_OCEAN;
		elseif disk2Set[x .. "," .. y] then
			plotTypes[y * params.iW + x] = (Map.Rand(100, "") < CONFIG.INNER_HILLS_PCT) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		else
			local adjInner = false;
			for d = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, d, params.iW, params.iH, params.wrapX, params.wrapY);
				if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and disk2Set[nx .. "," .. ny] then
					adjInner = true;
					break;
				end
			end
			local landPct = adjInner and CONFIG.OUTER_LAND_PCT_INNER or CONFIG.OUTER_LAND_PCT_OUTER;
			local roll = Map.Rand(100, "");
			plotTypes[y * params.iW + x] = (roll < CONFIG.OUTER_TILE_APPEAR_PCT and Map.Rand(100, "") < landPct) and PlotTypes.PLOT_LAND or PlotTypes.PLOT_OCEAN;
		end
	end
	return true;
end
