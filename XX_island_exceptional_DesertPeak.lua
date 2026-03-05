------------------------------------------------------------------------------
--	DesertPeakIsland.lua (Sinai)
--	Layout: Center (mountain) + 6 hills ring1 + 6 hills ring2 (flat 2N, mountain 2S, hills 2E/2SW/2W/2NW).
------------------------------------------------------------------------------
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

function TryPlaceDesertPeakIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.desertPeak then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end
	local sx = WrapCoord(centerX, params.iW, params.wrapX);
	local sy = WrapCoord(centerY, params.iH, params.wrapY);
	local margin = 4;
	if not params.wrapY and (sy < margin or sy >= params.iH - margin) then return false; end
	if not params.wrapX and (sx < margin or sx >= params.iW - margin) then return false; end

	local landTiles = {{sx, sy}};
	for d = 1, 6 do
		local nx, ny = GetHexNeighbor(sx, sy, d, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
			landTiles[#landTiles + 1] = {nx, ny};
		end
	end
	-- Spec: flat 2 north, mountain 2 south. Ring2: add 4 more tiles (2E, 2SW, 2W, 2NW). No xOff for diagonals.
	-- N/S tiles need empirical xOff; offset may depend on row parity (hex layout differs odd/even).
	local northDir = (sy % 2 == 0) and 1 or 6;
	local southDir = (sy % 2 == 0) and 3 or 4;
	local function xOffForRow(row) return (row % 2 == 0) and -2 or -1; end
	local function addRing2(dir, useOffset)
		local p1x, p1y = GetHexNeighbor(sx, sy, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if p1x < 0 or p1x >= params.iW or p1y < 0 or p1y >= params.iH then return; end
		local p2x, p2y = GetHexNeighbor(p1x, p1y, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if p2x < 0 or p2x >= params.iW or p2y < 0 or p2y >= params.iH then return; end
		local ax = useOffset and WrapCoord(p2x + xOffForRow(p2y), params.iW, params.wrapX) or p2x;
		if ax >= 0 and ax < params.iW then landTiles[#landTiles + 1] = {ax, p2y}; end
	end
	addRing2(northDir, true);
	addRing2(southDir, true);
	for d = 2, 6 do if d ~= northDir and d ~= southDir then addRing2(d, false); end end

	if #landTiles < 9 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawDesertPeakIsland(plotTypes, sx, sy, landTiles, params.iW, params.iH, params.wrapX, params.wrapY);
	_desert_peak_sinai_plot = plotIdx1(sx, sy, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.desertPeak = true;
	return true;
end

function DrawDesertPeakIsland(plotTypes, sinaiX, sinaiY, landTiles, iW, iH, wrapX, wrapY)
	local northDir = (sinaiY % 2 == 0) and 1 or 6;
	local southDir = (sinaiY % 2 == 0) and 3 or 4;
	-- Spec: flat 2 north, mountain 2 south. Same xOffForRow as TryPlace (row-parity dependent).
	local flatTile, mtnTile = nil, nil;
	local function xOffForRow(row) return (row % 2 == 0) and -2 or -1; end
	local n1x, n1y = GetHexNeighbor(sinaiX, sinaiY, northDir, iW, iH, wrapX, wrapY);
	if n1x >= 0 and n1x < iW and n1y >= 0 and n1y < iH then
		local n2x, n2y = GetHexNeighbor(n1x, n1y, northDir, iW, iH, wrapX, wrapY);
		if n2x >= 0 and n2x < iW and n2y >= 0 and n2y < iH then
			flatTile = {WrapCoord(n2x + xOffForRow(n2y), iW, wrapX), n2y};
		end
	end
	local s1x, s1y = GetHexNeighbor(sinaiX, sinaiY, southDir, iW, iH, wrapX, wrapY);
	if s1x >= 0 and s1x < iW and s1y >= 0 and s1y < iH then
		local s2x, s2y = GetHexNeighbor(s1x, s1y, southDir, iW, iH, wrapX, wrapY);
		if s2x >= 0 and s2x < iW and s2y >= 0 and s2y < iH then
			mtnTile = {WrapCoord(s2x + xOffForRow(s2y), iW, wrapX), s2y};
		end
	end
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if x == sinaiX and y == sinaiY then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif flatTile and x == flatTile[1] and y == flatTile[2] then
			plotTypes[idx] = PlotTypes.PLOT_LAND;
		elseif mtnTile and x == mtnTile[1] and y == mtnTile[2] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			plotTypes[idx] = PlotTypes.PLOT_HILLS;
		end
	end
end
