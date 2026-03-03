------------------------------------------------------------------------------
--	SteppingStoneIsland.lua
--	Stepping stone from mainland: coast - 1 water - stepping stone (1, rarely 2) - 1 water - blob (4-8).
--	Closest mainland tile set to mountain for consistent stepping stone terrain.
--	Optional 20%: 1 water (rarely 2) - far island (1-3).
------------------------------------------------------------------------------

local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
local firstRingYIsOdd  = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};

local function getNeighbor(x, y, dir, iW, iH, wrapX, wrapY)
	local adj = (y % 2 ~= 0) and firstRingYIsOdd[dir] or firstRingYIsEven[dir];
	local nx = x + adj[1];
	local ny = y + adj[2];
	if wrapX then nx = nx % iW; if nx < 0 then nx = nx + iW; end end
	if wrapY then ny = ny % iH; if ny < 0 then ny = ny + iH; end end
	if not wrapX and (nx < 0 or nx >= iW) then return nil, nil; end
	if not wrapY and (ny < 0 or ny >= iH) then return nil, nil; end
	return nx, ny;
end

local function isWater(plotTypes, x, y, iW)
	if x < 0 or x >= iW or y < 0 then return false; end
	local idx = y * iW + x;
	return plotTypes[idx] == PlotTypes.PLOT_OCEAN;
end

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local idx = y * iW + x;
	local t = plotTypes[idx];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function floodFillMainland(plotTypes, iW, iH, wrapX, wrapY)
	local visited = {};
	local bestSize, bestStart = 0, nil;
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local idx = y * iW + x;
			local t = plotTypes[idx];
			if (t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN) and not visited[idx] then
				local stack = {{x, y}};
				local size = 0;
				visited[idx] = true;
				while #stack > 0 do
					local cx, cy = stack[#stack][1], stack[#stack][2];
					stack[#stack] = nil;
					size = size + 1;
					for dir = 1, 6 do
						local adj = (cy % 2 ~= 0) and firstRingYIsOdd[dir] or firstRingYIsEven[dir];
						local nx, ny = cx + adj[1], cy + adj[2];
						if wrapX then nx = nx % iW; if nx < 0 then nx = nx + iW; end end
						if wrapY then ny = ny % iH; if ny < 0 then ny = ny + iH; end end
						if (wrapX or (nx >= 0 and nx < iW)) and (wrapY or (ny >= 0 and ny < iH)) then
							local nidx = ny * iW + nx;
							local nt = plotTypes[nidx];
							if (nt == PlotTypes.PLOT_LAND or nt == PlotTypes.PLOT_HILLS or nt == PlotTypes.PLOT_MOUNTAIN) and not visited[nidx] then
								visited[nidx] = true;
								stack[#stack + 1] = {nx, ny};
							end
						end
					end
				end
				if size > bestSize then bestSize = size; bestStart = {x, y}; end
			end
		end
	end
	return bestStart, bestSize;
end

local function collectMainlandAndCoasts(plotTypes, startX, startY, iW, iH, wrapX, wrapY)
	local mainland = {};
	local coasts = {};
	local stack = {{startX, startY}};
	local seen = {};
	seen[startY * iW + startX] = true;
	while #stack > 0 do
		local cx, cy = stack[#stack][1], stack[#stack][2];
		stack[#stack] = nil;
		mainland[#mainland + 1] = {cx, cy};
		local hasOcean = false;
		for dir = 1, 6 do
			local nx, ny = getNeighbor(cx, cy, dir, iW, iH, wrapX, wrapY);
			if nx and ny >= 0 and ny < iH then
				local nidx = ny * iW + nx;
				local nt = plotTypes[nidx];
				if nt == PlotTypes.PLOT_OCEAN then hasOcean = true;
				elseif (nt == PlotTypes.PLOT_LAND or nt == PlotTypes.PLOT_HILLS or nt == PlotTypes.PLOT_MOUNTAIN) and not seen[nidx] then
					seen[nidx] = true;
					stack[#stack + 1] = {nx, ny};
				end
			end
		end
		if hasOcean then coasts[#coasts + 1] = {cx, cy}; end
	end
	return mainland, coasts;
end

local function wrapCoord(v, size, doWrap)
	if not doWrap then return v; end
	v = v % size;
	if v < 0 then v = v + size; end
	return v;
end

local function drawBlob(plotTypes, centerX, centerY, numTiles, iW, iH, wrapX, wrapY, steppingStoneMountain, closestBlobTile)
	local odd, even = firstRingYIsOdd, firstRingYIsEven;
	local landvarDefault = 15;
	local mountainChance = steppingStoneMountain and 20 or 5;
	local hillsPct = 40 + Map.Rand(11, "");
	local startingPlot = centerY * iW + centerX;
	local tiles = {{centerX, centerY}};
	local nextX, nextY, plot_adjustments;
	for ripple_radius = 1, 2 do
		local currentX = centerX - ripple_radius;
		local currentY = centerY;
		for direction_index = 1, 6 do
			for plot_to_handle = 1, ripple_radius do
				if currentY / 2 > math.floor(currentY / 2) then
					plot_adjustments = odd[direction_index];
				else
					plot_adjustments = even[direction_index];
				end
				nextX = currentX + plot_adjustments[1];
				nextY = currentY + plot_adjustments[2];
				local realX = wrapCoord(nextX, iW, wrapX);
				local realY = wrapCoord(nextY, iH, wrapY);
				if realX >= 0 and realX < iW and realY >= 0 and realY < iH then
					local islThresh = Map.Rand(45, "") + landvarDefault;
					if Map.Rand(100, "") <= islThresh then
						tiles[#tiles + 1] = {realX, realY};
						landvarDefault = landvarDefault + 4;
					end
					currentX, currentY = nextX, nextY;
				end
			end
		end
	end
	while #tiles > numTiles do
		local r = (#tiles > 1) and (Map.Rand(#tiles - 1, "") + 2) or 1;
		tiles[r] = tiles[#tiles];
		tiles[#tiles] = nil;
	end
	for _, t in ipairs(tiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		local isClosest = (x == closestBlobTile[1] and y == closestBlobTile[2]);
		local mt = PlotTypes.PLOT_LAND;
		if isClosest and Map.Rand(100, "") < mountainChance then
			mt = PlotTypes.PLOT_MOUNTAIN;
		elseif Map.Rand(100, "") < hillsPct then
			mt = PlotTypes.PLOT_HILLS;
		end
		plotTypes[idx] = mt;
	end
end

function TryPlaceSteppingStoneIsland(plotTypes, opts)
	if _island_placed and _island_placed.steppingStone then return false; end
	local iW = opts.iW;
	local iH = opts.iH;
	local wrapX = opts.wrapX;
	local wrapY = opts.wrapY or false;

	local start, size = floodFillMainland(plotTypes, iW, iH, wrapX, wrapY);
	if not start or size < 10 then return false; end
	local _, coasts = collectMainlandAndCoasts(plotTypes, start[1], start[2], iW, iH, wrapX, wrapY);
	if #coasts == 0 then return false; end

	local candidates = {};
	for _, c in ipairs(coasts) do
		local cx, cy = c[1], c[2];
		for dir = 1, 6 do
			local nx1, ny1 = getNeighbor(cx, cy, dir, iW, iH, wrapX, wrapY);
			if nx1 and ny1 >= 0 and ny1 < iH and isWater(plotTypes, nx1, ny1, iW) then
				local nx2, ny2 = getNeighbor(nx1, ny1, dir, iW, iH, wrapX, wrapY);
				if nx2 and ny2 >= 0 and ny2 < iH and isWater(plotTypes, nx2, ny2, iW) then
					local nx3, ny3 = getNeighbor(nx2, ny2, dir, iW, iH, wrapX, wrapY);
					if nx3 and ny3 >= 0 and ny3 < iH and isWater(plotTypes, nx3, ny3, iW) then
						local nx4, ny4 = getNeighbor(nx3, ny3, dir, iW, iH, wrapX, wrapY);
						if nx4 and ny4 >= 0 and ny4 < iH and isWater(plotTypes, nx4, ny4, iW) then
							candidates[#candidates + 1] = {coastX = cx, coastY = cy, dir = dir, stepX = nx2, stepY = ny2, blobX = nx4, blobY = ny4};
						end
					end
				end
			end
		end
	end
	if #candidates == 0 then return false; end

	local c = candidates[Map.Rand(#candidates, "") + 1];
	local coastX, coastY = c.coastX, c.coastY;
	local stepX, stepY = c.stepX, c.stepY;
	local blobX, blobY = c.blobX, c.blobY;

	plotTypes[coastY * iW + coastX] = PlotTypes.PLOT_MOUNTAIN;
	local stepType = PlotTypes.PLOT_MOUNTAIN;

	local stepSize = (Map.Rand(100, "") < 15) and 2 or 1;
	plotTypes[stepY * iW + stepX] = stepType;
	if stepSize == 2 then
		local oppDir = ((c.dir + 2) % 6) + 1;
		local otherDirs = {};
		for d = 1, 6 do
			if d ~= c.dir and d ~= oppDir then otherDirs[#otherDirs + 1] = d; end
		end
		local pickDir = otherDirs[Map.Rand(#otherDirs, "") + 1];
		local adj = (stepY % 2 ~= 0) and firstRingYIsOdd[pickDir] or firstRingYIsEven[pickDir];
		local sx2 = wrapCoord(stepX + adj[1], iW, wrapX);
		local sy2 = wrapCoord(stepY + adj[2], iH, wrapY);
		if sx2 >= 0 and sx2 < iW and sy2 >= 0 and sy2 < iH and plotTypes[sy2 * iW + sx2] == PlotTypes.PLOT_OCEAN then
			plotTypes[sy2 * iW + sx2] = stepType;
		end
	end

	local blobSize = 4 + Map.Rand(5, "");
	local steppingStoneMountain = (stepType == PlotTypes.PLOT_MOUNTAIN);
	drawBlob(plotTypes, blobX, blobY, blobSize, iW, iH, wrapX, wrapY, steppingStoneMountain, {blobX, blobY});

	if Map.Rand(100, "") < 20 then
		local gapDist = (Map.Rand(100, "") < 15) and 2 or 1;
		local farX, farY = blobX, blobY;
		while farX and isLand(plotTypes, farX, farY, iW, iH) do
			farX, farY = getNeighbor(farX, farY, c.dir, iW, iH, wrapX, wrapY);
			if not farX or farY < 0 or farY >= iH then farX = nil; break; end
		end
		for _ = 1, gapDist do
			if not farX then break; end
			farX, farY = getNeighbor(farX, farY, c.dir, iW, iH, wrapX, wrapY);
			if not farX or farY < 0 or farY >= iH or not isWater(plotTypes, farX, farY, iW) then farX = nil; break; end
		end
		if farX and farY >= 0 and farY < iH and isWater(plotTypes, farX, farY, iW) then
			local farSize = 1 + Map.Rand(3, "");
			plotTypes[farY * iW + farX] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
			for _ = 1, farSize - 1 do
				local pickDir = Map.Rand(6, "") + 1;
				local adj = (farY % 2 ~= 0) and firstRingYIsOdd[pickDir] or firstRingYIsEven[pickDir];
				local fx = wrapCoord(farX + adj[1], iW, wrapX);
				local fy = wrapCoord(farY + adj[2], iH, wrapY);
				if fx >= 0 and fx < iW and fy >= 0 and fy < iH and plotTypes[fy * iW + fx] == PlotTypes.PLOT_OCEAN then
					plotTypes[fy * iW + fx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
					farX, farY = fx, fy;
				end
			end
		end
	end

	if not _island_placed then _island_placed = {}; end
	_island_placed.steppingStone = true;
	return true;
end
