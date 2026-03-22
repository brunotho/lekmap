-- Diamond stack of land with the wonder peak embedded, extra peaks on tips, small satellite islets.

include("X_IslandHelpers");

local function plotIdx1(x, y, iW) return y * iW + x + 1; end

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

local function wrapCoord(v, size, doWrap)
	if not doWrap then return v; end
	v = v % size;
	if v < 0 then v = v + size; end
	return v;
end

local DIAMOND_OFFSETS = {
	{0, 3},
	{-1, 2}, {0, 2},
	{-1, 1}, {0, 1}, {1, 1},
	{-2, 0}, {-1, 0}, {0, 0}, {1, 0},
	{-1, -1}, {0, -1}, {1, -1},
	{-1, -2}, {0, -2},
	{0, -3},
};

local function rotDir(d, delta)
	return ((d - 1 + delta) % 6 + 6) % 6 + 1;
end

local function oppDir(d) return ((d - 1 + 3) % 6) + 1; end
local function DrawSinaiSatellites(plotTypes, cx, cy, rot, diamondSet, iW, iH, wrapX, wrapY)
	local axisDir = rotDir(1, rot);
	local perpDirs = { rotDir(2, rot), rotDir(5, rot) };
	local numSats = 1 + Map.Rand(2, "");
	for _ = 1, numSats do
		local perpDir = perpDirs[Map.Rand(2, "") + 1];
		local steps = 2 + Map.Rand(2, "");
		local x, y = cx, cy;
		for _ = 1, steps do
			x, y = GetHexNeighbor(x, y, perpDir, iW, iH, wrapX, wrapY);
			if x < 0 or x >= iW or y < 0 or y >= iH then break; end
		end
		if x >= 0 and x < iW and y >= 0 and y < iH and not diamondSet[x .. "," .. y] then
			local satTiles = {};
			local idx = y * iW + x + 1;
			if plotTypes[idx] == PlotTypes.PLOT_OCEAN then
				satTiles[#satTiles + 1] = {x, y};
			end
			if #satTiles > 0 then
				local ax, ay = GetHexNeighbor(x, y, axisDir, iW, iH, wrapX, wrapY);
				if ax >= 0 and ax < iW and ay >= 0 and ay < iH and not diamondSet[ax .. "," .. ay] and plotTypes[ay * iW + ax + 1] == PlotTypes.PLOT_OCEAN then
					satTiles[#satTiles + 1] = {ax, ay};
				end
				if #satTiles < 2 then
					local ox, oy = GetHexNeighbor(x, y, oppDir(axisDir), iW, iH, wrapX, wrapY);
					if ox >= 0 and ox < iW and oy >= 0 and oy < iH and not diamondSet[ox .. "," .. oy] and plotTypes[oy * iW + ox + 1] == PlotTypes.PLOT_OCEAN then
						satTiles[#satTiles + 1] = {ox, oy};
					end
				elseif Map.Rand(2, "") == 0 then
					local ox, oy = GetHexNeighbor(x, y, oppDir(axisDir), iW, iH, wrapX, wrapY);
					if ox >= 0 and ox < iW and oy >= 0 and oy < iH and not diamondSet[ox .. "," .. oy] and plotTypes[oy * iW + ox + 1] == PlotTypes.PLOT_OCEAN then
						satTiles[#satTiles + 1] = {ox, oy};
					end
				end
			end
			if #satTiles >= 2 then
				for _, t in ipairs(satTiles) do
					local tx, ty = t[1], t[2];
					plotTypes[ty * iW + tx + 1] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
				end
			end
		end
	end
end

function TryPlaceSinaiIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.sinaiIsland then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end
	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	local margin = 4;
	if not params.wrapY and (cy < margin or cy >= params.iH - margin) then return false; end
	if not params.wrapX and (cx < margin or cx >= params.iW - margin) then return false; end

	local rot = Map.Rand(6, "");
	local landTiles = {};
	for _, off in ipairs(DIAMOND_OFFSETS) do
		local dx, dy = RotateOffset60(off[1], off[2], rot);
		local gx = wrapCoord(cx + dx, params.iW, params.wrapX);
		local gy = wrapCoord(cy + dy, params.iH, params.wrapY);
		if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH then
			landTiles[#landTiles + 1] = {gx, gy};
		end
	end
	if #landTiles < 14 then return false; end
	local outerRingIdx = {};
	for _, idx in ipairs({1, 2, 3, 14, 15, 16}) do
		if idx <= #landTiles then outerRingIdx[#outerRingIdx + 1] = idx; end
	end
	local numToRemove = math.min(1 + Map.Rand(2, ""), #outerRingIdx);
	local toRemove = {};
	for _ = 1, numToRemove do
		local pick = 1 + Map.Rand(#outerRingIdx, "");
		toRemove[#toRemove + 1] = outerRingIdx[pick];
		table.remove(outerRingIdx, pick);
	end
	table.sort(toRemove, function(a, b) return a > b; end);
	for _, idx in ipairs(toRemove) do
		table.remove(landTiles, idx);
	end
	if #landTiles < 12 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	local diamondSet = {};
	for _, t in ipairs(landTiles) do diamondSet[t[1] .. "," .. t[2]] = true; end

	DrawSinaiIsland(plotTypes, cx, cy, landTiles, rot, params.iW, params.iH, params.wrapX, params.wrapY);
	DrawSinaiSatellites(plotTypes, cx, cy, rot, diamondSet, params.iW, params.iH, params.wrapX, params.wrapY);
	_sinai_island_plot = plotIdx1(cx, cy, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.sinaiIsland = true;
	return true;
end

function DrawSinaiIsland(plotTypes, cx, cy, landTiles, rot, iW, iH, wrapX, wrapY)
	local dx, dy = rotateHex60(0, 1, rot);
	local sinaiX = wrapCoord(cx + dx, iW, wrapX);
	local sinaiY = wrapCoord(cy + dy, iH, wrapY);

	local tip1Dx, tip1Dy = rotateHex60(0, 3, rot);
	local tip2Dx, tip2Dy = rotateHex60(0, -3, rot);
	local tip1X = wrapCoord(cx + tip1Dx, iW, wrapX);
	local tip1Y = wrapCoord(cy + tip1Dy, iH, wrapY);
	local tip2X = wrapCoord(cx + tip2Dx, iW, wrapX);
	local tip2Y = wrapCoord(cy + tip2Dy, iH, wrapY);

	local outerMtnSet = {};
	do
		local candidates = {};
		local function addCandidate(wx, wy)
			for _, t in ipairs(landTiles) do
				if t[1] == wx and t[2] == wy then
					candidates[#candidates + 1] = { wx, wy };
					break;
				end
			end
		end
		addCandidate(tip1X, tip1Y);
		addCandidate(tip2X, tip2Y);
		local leftDx, leftDy = rotateHex60(-2, 0, rot);
		local leftX = wrapCoord(cx + leftDx, iW, wrapX);
		local leftY = wrapCoord(cy + leftDy, iH, wrapY);
		addCandidate(leftX, leftY);
		local rightDx, rightDy = rotateHex60(1, 0, rot);
		local rightX = wrapCoord(cx + rightDx, iW, wrapX);
		local rightY = wrapCoord(cy + rightDy, iH, wrapY);
		addCandidate(rightX, rightY);
		local toPick = math.min(3, #candidates);
		while toPick > 0 and #candidates > 0 do
			local idx = 1 + Map.Rand(#candidates, "");
			local wx, wy = candidates[idx][1], candidates[idx][2];
			outerMtnSet[wx .. "," .. wy] = true;
			table.remove(candidates, idx);
			toPick = toPick - 1;
		end
	end

	local adjToSinai = {};
	for d = 1, 6 do
		local nx, ny = GetHexNeighbor(sinaiX, sinaiY, d, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			adjToSinai[nx .. "," .. ny] = true;
		end
	end

	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if x == sinaiX and y == sinaiY then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif outerMtnSet[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif adjToSinai[x .. "," .. y] then
			plotTypes[idx] = PlotTypes.PLOT_HILLS;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 40) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
