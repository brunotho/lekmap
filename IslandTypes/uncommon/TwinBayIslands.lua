------------------------------------------------------------------------------
--	TwinBayIslands.lua (recreated from transcript)
--	Two islands 5-8 tiles each, concave bays facing each other.
--	One tip extends into bay of the other. Gap 1-2 water tiles.
--	Hills 40-50% on outer edges, flat on bay-facing. No mountains.
------------------------------------------------------------------------------
include("IslandTypes/IslandHelpers");

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

function TryPlaceTwinBayIslands(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local gap = 1 + Map.Rand(2, "");
	local dir = Map.Rand(6, "") + 1;
	local isl1X, isl1Y = cx, cy;
	local isl2X, isl2Y = cx, cy;
	for _ = 1, gap + 1 do
		isl2X, isl2Y = GetHexNeighbor(isl2X, isl2Y, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if isl2X < 0 or isl2X >= params.iW or isl2Y < 0 or isl2Y >= params.iH then return false; end
	end

	local size1 = 5 + Map.Rand(4, "");
	local size2 = 5 + Map.Rand(4, "");
	local tiles1 = growCompactBlob(isl1X, isl1Y, size1, params.iW, params.iH, params.wrapX, params.wrapY);
	if #tiles1 < 5 then return false; end

	local occupied = {};
	for _, t in ipairs(tiles1) do occupied[t[1] .. "," .. t[2]] = true; end
	local tiles2 = growCompactBlob(isl2X, isl2Y, size2, params.iW, params.iH, params.wrapX, params.wrapY);
	for _, t in ipairs(tiles2) do
		if occupied[t[1] .. "," .. t[2]] then return false; end
	end

	local landTiles = {};
	for _, t in ipairs(tiles1) do landTiles[#landTiles + 1] = {t[1], t[2], 1}; end
	for _, t in ipairs(tiles2) do landTiles[#landTiles + 1] = {t[1], t[2], 2}; end

	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawTwinBayIslands(plotTypes, landTiles, tiles1, tiles2, params.iW);
	return true;
end

function DrawTwinBayIslands(plotTypes, landTiles, tiles1, tiles2, iW)
	local hillsPct = 40 + Map.Rand(11, "");
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		plotTypes[idx] = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end
end
