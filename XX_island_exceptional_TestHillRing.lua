------------------------------------------------------------------------------
--	TestHillRing.lua
--	Mountain center, r1 = water ring, r2+r3 = splintered land. Random gap placement.
------------------------------------------------------------------------------
include("X_IslandHelpers");

local CONFIG = {
	DISK_RADIUS_MIN = 2, DISK_RADIUS_RANGE = 3,  -- radius 2-4
	WATER_RING_RADIUS = 1,
	HILLS_PCT = 80,
	NUM_SEGMENTS_MIN = 3, NUM_SEGMENTS_RANGE = 2,
	NUM_GAPS_MIN = 1, NUM_GAPS_RANGE = 4,  -- 1-4 gaps (1 + Rand(4))
	RIM_MOUNTAIN_PCT = 12,  -- segment tiles adjacent to water: % chance mountain
	RIM_HILLS_PCT = 70,     -- rim non-mountain: % hills
};

function TryPlaceTestHillRing(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 0;
	local effMin = params.effMin or 0;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local diskRadius = CONFIG.DISK_RADIUS_MIN + Map.Rand(CONFIG.DISK_RADIUS_RANGE, "");
	local disk1 = GetHexDisk(cx, cy, CONFIG.WATER_RING_RADIUS, params.iW, params.iH, params.wrapX, params.wrapY);
	local diskOuter = GetHexDisk(cx, cy, diskRadius, params.iW, params.iH, params.wrapX, params.wrapY);
	local disk1Set = {};
	for _, t in ipairs(disk1) do disk1Set[t[1] .. "," .. t[2]] = true; end

	plotTypes[cy * params.iW + cx] = PlotTypes.PLOT_MOUNTAIN;
	for _, t in ipairs(disk1) do
		if t[1] ~= cx or t[2] ~= cy then
			plotTypes[t[2] * params.iW + t[1]] = PlotTypes.PLOT_OCEAN;
		end
	end

	local ring23 = {};
	for _, t in ipairs(diskOuter) do
		if not disk1Set[t[1] .. "," .. t[2]] then
			ring23[#ring23 + 1] = t;
		end
	end

	local numGaps = math.min(CONFIG.NUM_GAPS_MIN + Map.Rand(CONFIG.NUM_GAPS_RANGE, ""), #ring23 - 1);
	local gapIndices = {};
	for i = 1, numGaps do
		local k;
		repeat
			k = 1 + Map.Rand(#ring23, "");
		until not gapIndices[k];
		gapIndices[k] = true;
	end

	local waterSet = {};
	for _, t in ipairs(disk1) do waterSet[t[1] .. "," .. t[2]] = true; end
	for i = 1, #ring23 do
		if gapIndices[i] then
			local t = ring23[i];
			waterSet[t[1] .. "," .. t[2]] = true;
		end
	end

	for i = 1, #ring23 do
		local t = ring23[i];
		local x, y = t[1], t[2];
		if gapIndices[i] then
			plotTypes[y * params.iW + x] = PlotTypes.PLOT_OCEAN;
		else
			local adjWater = false;
			for d = 1, 6 do
				local nx, ny = GetHexNeighbor(x, y, d, params.iW, params.iH, params.wrapX, params.wrapY);
				if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and waterSet[nx .. "," .. ny] then
					adjWater = true;
					break;
				end
			end
			local mt;
			if adjWater and Map.Rand(100, "") < CONFIG.RIM_MOUNTAIN_PCT then
				mt = PlotTypes.PLOT_MOUNTAIN;
			else
				local hillsPct = adjWater and CONFIG.RIM_HILLS_PCT or CONFIG.HILLS_PCT;
				mt = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
			end
			plotTypes[y * params.iW + x] = mt;
		end
	end
	return true;
end
