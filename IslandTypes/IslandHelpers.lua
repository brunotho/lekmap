------------------------------------------------------------------------------
--	IslandHelpers.lua
--	Shared hex utilities used by island types.
------------------------------------------------------------------------------

firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
firstRingYIsOdd  = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};

function GetHexRing(y)
	return (y % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
end

function WrapCoord(v, size, doWrap)
	if not doWrap then return v; end
	v = v % size;
	if v < 0 then v = v + size; end
	return v;
end

function GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY)
	local adj = (y % 2 ~= 0) and firstRingYIsOdd[dir] or firstRingYIsEven[dir];
	local nx = x + adj[1];
	local ny = y + adj[2];
	nx = WrapCoord(nx, iW, wrapX);
	ny = WrapCoord(ny, iH, wrapY);
	return nx, ny;
end

function GetHexNeighbors(x, y)
	local adj = (y % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
	local out = {};
	for dir = 1, 6 do
		out[#out + 1] = {x + adj[dir][1], y + adj[dir][2]};
	end
	return out;
end

function IsHexAdjacent(ax, ay, bx, by)
	local adj = (ay % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
	local dx, dy = bx - ax, by - ay;
	for d = 1, 6 do
		if adj[d][1] == dx and adj[d][2] == dy then return true; end
	end
	return false;
end

function GetHexDisk(cx, cy, radius, iW, iH, wrapX, wrapY)
	local out = {};
	local gx = WrapCoord(cx, iW, wrapX);
	local gy = WrapCoord(cy, iH, wrapY);
	if gx >= 0 and gx < iW and gy >= 0 and gy < iH then
		out[#out + 1] = {gx, gy};
	end
	for r = 1, radius do
		local currentX = cx - r;
		local currentY = cy;
		for dir = 1, 6 do
			for step = 1, r do
				local adj = (currentY % 2 ~= 0) and firstRingYIsOdd[dir] or firstRingYIsEven[dir];
				currentX = currentX + adj[1];
				currentY = currentY + adj[2];
				gx = WrapCoord(currentX, iW, wrapX);
				gy = WrapCoord(currentY, iH, wrapY);
				if gx >= 0 and gx < iW and gy >= 0 and gy < iH then
					out[#out + 1] = {gx, gy};
				end
			end
		end
	end
	return out;
end

function ApplyBasicIslandTerrain(plotTypes, landTiles, iW)
	local n = #landTiles;
	if n == 0 then return; end
	local hillsPct = 50 + Map.Rand(11, "");
	local hillTiles = {};
	local flatTiles = {};
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if Map.Rand(100, "") < hillsPct then
			plotTypes[idx] = PlotTypes.PLOT_HILLS;
			hillTiles[#hillTiles + 1] = idx;
		else
			plotTypes[idx] = PlotTypes.PLOT_LAND;
			flatTiles[#flatTiles + 1] = idx;
		end
	end
	local numMountains = 0;
	if n <= 6 then
		if Map.Rand(100, "") < 2 then numMountains = 1;
		elseif Map.Rand(100, "") < 1 then numMountains = 2; end
	else
		if Map.Rand(100, "") < 5 then numMountains = 1;
		elseif Map.Rand(100, "") < 2 then numMountains = 2; end
	end
	local candidates = {};
	for _, idx in ipairs(hillTiles) do candidates[#candidates + 1] = idx; end
	if #candidates == 0 then
		for _, idx in ipairs(flatTiles) do candidates[#candidates + 1] = idx; end
	end
	for i = 1, math.min(numMountains, #candidates) do
		local r = Map.Rand(#candidates, "") + 1;
		plotTypes[candidates[r]] = PlotTypes.PLOT_MOUNTAIN;
		table.remove(candidates, r);
	end
end
