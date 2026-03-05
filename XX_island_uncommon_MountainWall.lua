------------------------------------------------------------------------------
--	MountainWallIsland.lua
--
--	Layout: Curved mountain ridge (3-6 tiles), land behind. Longer ridges: less depth.
--	Ridge 5-6: mandatory 1-2 tile gap (hill/flat) inside ridge. Shorter: 65% chance gap.
------------------------------------------------------------------------------
include("X_IslandHelpers");

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

local function rotDir(d, delta)
	return ((d - 1 + delta) % 6 + 6) % 6 + 1;
end

function TryPlaceMountainWallIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 0;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local perpDir = Map.Rand(6, "") + 1;
	local ridgeDir = rotDir(perpDir, Map.Rand(2, "") == 0 and 2 or -2);

	local ridgeLen = 3 + Map.Rand(4, "");
	local depth = (ridgeLen >= 5) and 1 or (1 + Map.Rand(2, ""));

	local numGaps = 0;
	if ridgeLen >= 5 then
		numGaps = 1 + Map.Rand(2, "");
	elseif ridgeLen >= 3 and Map.Rand(100, "") < 65 then
		numGaps = 1;
	end
	local isGap = {};
	if numGaps > 0 then
		local pool = {};
		for p = 2, ridgeLen - 1 do pool[#pool + 1] = p; end
		for g = 1, math.min(numGaps, #pool) do
			local pick = 1 + Map.Rand(#pool, "");
			isGap[pool[pick]] = true;
			pool[pick] = pool[#pool];
			pool[#pool] = nil;
		end
	end

	local ridgeTiles = {};
	local landTiles = {};
	local used = {};

	local function add(x, y, distFromRidge)
		if x < 0 or x >= params.iW or y < 0 or y >= params.iH then return; end
		local key = x .. "," .. y;
		if used[key] then return; end
		used[key] = true;
		landTiles[#landTiles + 1] = {x, y, distFromRidge};
	end

	-- Curved ridge: bend every 1-2 steps
	local x, y = cx, cy;
	local curRidgeDir = ridgeDir;
	local bendFreq = 1 + Map.Rand(2, "");
	local nextBend = bendFreq;

	for i = 1, ridgeLen do
		add(x, y, 0);
		if not isGap[i] then
			ridgeTiles[#ridgeTiles + 1] = {x, y};
		end
		for d = 1, depth do
			local px, py = x, y;
			for _ = 1, d do
				px, py = GetHexNeighbor(px, py, perpDir, params.iW, params.iH, params.wrapX, params.wrapY);
				if px < 0 or px >= params.iW or py < 0 or py >= params.iH then break; end
			end
			if px >= 0 and px < params.iW and py >= 0 and py < params.iH then
				add(px, py, d);
			end
		end
		nextBend = nextBend - 1;
		if nextBend <= 0 then
			curRidgeDir = rotDir(curRidgeDir, Map.Rand(2, "") == 0 and 1 or -1);
			nextBend = bendFreq;
		end
		local nx, ny = GetHexNeighbor(x, y, curRidgeDir, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx < 0 or nx >= params.iW or ny < 0 or ny >= params.iH then break; end
		x, y = nx, ny;
	end

	if #landTiles < 5 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	local ridgeSet = {};
	for _, t in ipairs(ridgeTiles) do ridgeSet[t[1] .. "," .. t[2]] = true; end

	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * params.iW + x;
		local dist = t[3] or 0;
		if ridgeSet[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			local basePct = (dist == 1) and (70 + Map.Rand(21, ""))
				or (dist == 2) and (55 + Map.Rand(21, ""))
				or (dist == 3) and (40 + Map.Rand(21, ""))
				or (25 + Map.Rand(21, ""));
			local mt = (Map.Rand(100, "") < basePct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
			if mt == PlotTypes.PLOT_HILLS and dist <= 2 and Map.Rand(100, "") < 5 then
				mt = PlotTypes.PLOT_MOUNTAIN;
			end
			plotTypes[idx] = mt;
		end
	end
	return true;
end
