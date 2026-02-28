------------------------------------------------------------------------------
--	ShatteredRingIsland.lua (recreated from transcript)
--	Central island 6-10 tiles, ring 5-8 islands (1-3 tiles each) across 8 sectors.
--	Ring radius 6-9 from center. center 80% mountain / 20% hill; ring 50% hills.
------------------------------------------------------------------------------
include("IslandHelpers");

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[y * iW + x + 1];
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
	local seen = {}; seen[cy * iW + cx + 1] = true;

	while #landTiles < size and #frontier > 0 do
		local r = Map.Rand(#frontier, "") + 1;
		local fx, fy = frontier[r][1], frontier[r][2];
		table.remove(frontier, r);
		for _, n in ipairs(GetHexNeighbors(fx, fy)) do
			local gx = WrapCoord(n[1], iW, wrapX);
			local gy = WrapCoord(n[2], iH, wrapY);
			if gx >= 0 and gx < iW and gy >= 0 and gy < iH and not seen[gy * iW + gx + 1] then
				for _, t in ipairs(landTiles) do
					if IsHexAdjacent(t[1], t[2], gx, gy) then
						landTiles[#landTiles + 1] = {gx, gy};
						frontier[#frontier + 1] = {gx, gy};
						seen[gy * iW + gx + 1] = true;
						break;
					end
				end
			end
		end
	end
	return landTiles;
end

local function growSmallIsland(seedX, seedY, targetSize, iW, iH, wrapX, wrapY, occupied)
	local tiles = {{seedX, seedY}};
	local frontier = {{seedX, seedY}};
	local seen = {}; seen[seedY * iW + seedX + 1] = true;

	while #tiles < targetSize and #frontier > 0 do
		local r = Map.Rand(#frontier, "") + 1;
		local fx, fy = frontier[r][1], frontier[r][2];
		table.remove(frontier, r);
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(fx, fy, dir, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local idx = ny * iW + nx + 1;
				if not seen[idx] and not occupied[nx .. "," .. ny] then
					for _, t in ipairs(tiles) do
						if IsHexAdjacent(t[1], t[2], nx, ny) then
							tiles[#tiles + 1] = {nx, ny};
							frontier[#frontier + 1] = {nx, ny};
							seen[idx] = true;
							break;
						end
					end
				end
			end
		end
	end
	return tiles;
end

function TryPlaceShatteredRingIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.shatteredRing then return false; end
	local pullBack = params.pullBack or 4;
	local effMin = params.effMin or 4;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local centerSize = 6 + Map.Rand(5, "");
	local centerTiles = growCompactBlob(cx, cy, centerSize, params.iW, params.iH, params.wrapX, params.wrapY);
	if #centerTiles < 6 then return false; end

	local occupied = {};
	for _, t in ipairs(centerTiles) do occupied[t[1] .. "," .. t[2]] = true; end

	local ringRadius = 6 + Map.Rand(4, "");
	local numIslands = 5 + Map.Rand(4, "");
	local numSectors = 8;
	local allTiles = {};
	for _, t in ipairs(centerTiles) do allTiles[#allTiles + 1] = {t[1], t[2]}; end

	for i = 1, numIslands do
		local base = (i - 1) * (2 * math.pi / numIslands) + (Map.Rand(100, "") / 100 - 0.5) * 0.5;
		local dx = math.floor(ringRadius * math.cos(base) + 0.5);
		local dy = math.floor(ringRadius * math.sin(base) + 0.5);
		local gx = WrapCoord(cx + dx, params.iW, params.wrapX);
		local gy = WrapCoord(cy + dy, params.iH, params.wrapY);
		if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH and not occupied[gx .. "," .. gy] then
			local distSq = dx * dx + dy * dy;
			if distSq >= 9 then
				local islSize = 1 + Map.Rand(3, "");
				local tiles = growSmallIsland(gx, gy, islSize, params.iW, params.iH, params.wrapX, params.wrapY, occupied);
				for _, t in ipairs(tiles) do
					allTiles[#allTiles + 1] = {t[1], t[2]};
					occupied[t[1] .. "," .. t[2]] = true;
				end
			end
		end
	end

	if #allTiles < 10 then return false; end
	if not footprintClear(plotTypes, allTiles, params.iW, params.iH) then return false; end

	DrawShatteredRingIsland(plotTypes, allTiles, centerTiles, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.shatteredRing = true;
	return true;
end

function DrawShatteredRingIsland(plotTypes, landTiles, centerTiles, iW)
	local centerSet = {};
	for _, t in ipairs(centerTiles) do centerSet[t[1] .. "," .. t[2]] = true; end

	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if centerSet[x .. "," .. y] then
			plotTypes[idx] = (Map.Rand(100, "") < 80) and PlotTypes.PLOT_MOUNTAIN or PlotTypes.PLOT_HILLS;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
