------------------------------------------------------------------------------
--	WaterdropIsland.lua
--	Teardrop: bulb 3-4 tiles, body taper, tail 2-3 tiles (1 wide). Total 6-9.
--	Bulb 50-60% hills, body mix, tail flat. Lake on bulb 20% (1-2 tiles).
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

local function growCompactBlob(cx, cy, size, iW, iH, wrapX, wrapY)
	local landTiles = {{cx, cy}};
	local frontier = {{cx, cy}};
	local seen = {}; seen[cy * iW + cx] = true;

	while #landTiles < size and #frontier > 0 do
		local r = Map.Rand(#frontier, "") + 1;
		local fx, fy = frontier[r][1], frontier[r][2];
		table.remove(frontier, r);
		for _, n in ipairs(GetHexNeighbors(fx, fy)) do
			local gx = WrapCoord(n[1], iW, wrapX);
			local gy = WrapCoord(n[2], iH, wrapY);
			if gx >= 0 and gx < iW and gy >= 0 and gy < iH and not seen[gy * iW + gx] then
				local adjCount = 0;
				for _, t in ipairs(landTiles) do
					if IsHexAdjacent(t[1], t[2], gx, gy) then adjCount = adjCount + 1; end
				end
				if adjCount > 0 then
					landTiles[#landTiles + 1] = {gx, gy};
					frontier[#frontier + 1] = {gx, gy};
					seen[gy * iW + gx] = true;
					if #landTiles >= size then break; end
				end
			end
		end
	end
	return landTiles;
end

function TryPlaceWaterdropIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local bulbSize = 3 + Map.Rand(2, "");
	local bulbTiles = growCompactBlob(cx, cy, bulbSize, params.iW, params.iH, params.wrapX, params.wrapY);
	if #bulbTiles < 3 then return false; end

	local bulbSet = {};
	for _, t in ipairs(bulbTiles) do bulbSet[t[1] .. "," .. t[2]] = true; end

	local edgeTiles = {};
	for _, t in ipairs(bulbTiles) do
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(t[1], t[2], dir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and not bulbSet[nx .. "," .. ny] then
				edgeTiles[#edgeTiles + 1] = {nx, ny, t[1], t[2]};
			end
		end
	end
	if #edgeTiles == 0 then return false; end

	local tailStart = edgeTiles[Map.Rand(#edgeTiles, "") + 1];
	local tx, ty = tailStart[1], tailStart[2];
	local fromX, fromY = tailStart[3], tailStart[4];
	local landTiles = {};
	for _, t in ipairs(bulbTiles) do landTiles[#landTiles + 1] = {t[1], t[2]}; end
	landTiles[#landTiles + 1] = {tx, ty};

	local dir = 1;
	for d = 1, 6 do
		local nx, ny = GetHexNeighbor(fromX, fromY, d, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx == tx and ny == ty then dir = d; break; end
	end

	local bodyLen = 1 + Map.Rand(2, "");
	local tailLen = 2 + Map.Rand(2, "");
	for _ = 1, bodyLen - 1 do
		local nx, ny = GetHexNeighbor(tx, ty, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and not bulbSet[nx .. "," .. ny] then
			local dup = false;
			for _, t in ipairs(landTiles) do if t[1] == nx and t[2] == ny then dup = true; break; end end
			if not dup then
				landTiles[#landTiles + 1] = {nx, ny};
				tx, ty = nx, ny;
			else break; end
		else break; end
	end

	for _ = 1, tailLen - 1 do
		local nx, ny = GetHexNeighbor(tx, ty, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
			local dup = false;
			for _, t in ipairs(landTiles) do if t[1] == nx and t[2] == ny then dup = true; break; end end
			if not dup then
				landTiles[#landTiles + 1] = {nx, ny};
				tx, ty = nx, ny;
			else break; end
		else break; end
	end

	if #landTiles < 6 or #landTiles > 9 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawWaterdropIsland(plotTypes, landTiles, bulbTiles, params.iW, params.iH, params.wrapX, params.wrapY);
	return true;
end

function DrawWaterdropIsland(plotTypes, landTiles, bulbTiles, iW, iH, wrapX, wrapY)
	wrapY = wrapY or false;
	local bulbSet = {};
	for _, t in ipairs(bulbTiles) do bulbSet[t[1] .. "," .. t[2]] = true; end

	local landSet = {};
	for _, t in ipairs(landTiles) do landSet[t[1] .. "," .. t[2]] = true; end

	local lakeTiles = {};
	if #bulbTiles >= 4 and Map.Rand(100, "") < 20 then
		for _, t in ipairs(bulbTiles) do
			local interior = true;
			for dir = 1, 6 do
				local nx, ny = GetHexNeighbor(t[1], t[2], dir, iW, iH, wrapX, wrapY);
				if nx < 0 or nx >= iW or ny < 0 or ny >= iH or not landSet[nx .. "," .. ny] then
					interior = false;
					break;
				end
			end
			if interior then lakeTiles[#lakeTiles + 1] = t; end
		end
		if #lakeTiles > 0 then
			local numLake = math.min(1 + Map.Rand(2, ""), #lakeTiles);
			for i = 1, numLake do
				local r = Map.Rand(#lakeTiles, "") + 1;
				local lt = lakeTiles[r];
				plotTypes[lt[2] * iW + lt[1]] = PlotTypes.PLOT_OCEAN;
				table.remove(lakeTiles, r);
			end
		end
	end

	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		if plotTypes[idx] ~= PlotTypes.PLOT_OCEAN then
			local key = x .. "," .. y;
			if bulbSet[key] then
				plotTypes[idx] = (Map.Rand(100, "") < (50 + Map.Rand(11, ""))) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
			else
				local pos = 0;
				for i, lt in ipairs(landTiles) do if lt[1] == x and lt[2] == y then pos = i; break; end end
				if pos <= #bulbTiles + 2 then
					plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
				else
					plotTypes[idx] = (Map.Rand(100, "") < 30) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
				end
			end
		end
	end
end
