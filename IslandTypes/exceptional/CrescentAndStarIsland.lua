------------------------------------------------------------------------------
--	CrescentAndStarIsland.lua (recreated from transcript)
--	Crescent 13 tiles in C shape. Bay 5 water tiles. Star: 1 mountain in bay.
--	50-60% hills on crescent. 20% tip mountain.
------------------------------------------------------------------------------
include("IslandHelpers");

local CRESCENT_STAR_TEMPLATE = {
	{0,2},{1,2},{2,2},{3,2},
	{-1,1},{0,1},{1,1},{2,1},{3,1},{4,1},
	{-1,0},{0,0},{1,0},{2,0},{3,0},{4,0},
	{-1,-1},{0,-1},{1,-1},{2,-1},{3,-1},{4,-1},
	{0,-2},{1,-2},{2,-2},{3,-2},
};
local BAY_TILES = {{1,0},{2,0},{3,0},{1,1},{2,1}};
local CRESCENT_TILES = {};
for _, t in ipairs(CRESCENT_STAR_TEMPLATE) do
	local inBay = false;
	for _, b in ipairs(BAY_TILES) do
		if t[1] == b[1] and t[2] == b[2] then inBay = true; break; end
	end
	if not inBay then CRESCENT_TILES[#CRESCENT_TILES + 1] = t; end
end
local TIP_TILES = {{-1,1},{-1,0},{-1,-1},{4,1},{4,0},{4,-1}};

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

local function rotateHex60(dx, dy, steps)
	for _ = 1, steps do
		local q, r = dx, dy - math.floor((dx - (dx % 2)) / 2);
		dx = q + r;
		dy = -q + math.floor((dx - (dx % 2)) / 2);
	end
	return dx, dy;
end

function TryPlaceCrescentAndStarIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.crescentAndStar then return false; end
	local pullBack = params.pullBack or 3;
	local effMin = params.effMin or 3;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local rot = Map.Rand(6, "");
	local starTile = BAY_TILES[Map.Rand(#BAY_TILES, "") + 1];
	local landTiles = {};
	for _, t in ipairs(CRESCENT_TILES) do
		local dx, dy = rotateHex60(t[1], t[2], rot);
		local gx = WrapCoord(cx + dx, params.iW, params.wrapX);
		local gy = WrapCoord(cy + dy, params.iH, params.wrapY);
		if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH then
			landTiles[#landTiles + 1] = {gx, gy, t[1], t[2]};
		end
	end

	local starDx, starDy = rotateHex60(starTile[1], starTile[2], rot);
	local starGx = WrapCoord(cx + starDx, params.iW, params.wrapX);
	local starGy = WrapCoord(cy + starDy, params.iH, params.wrapY);
	landTiles[#landTiles + 1] = {starGx, starGy, starTile[1], starTile[2], "star"};

	if #landTiles < 12 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawCrescentAndStarIsland(plotTypes, landTiles, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.crescentAndStar = true;
	return true;
end

function DrawCrescentAndStarIsland(plotTypes, landTiles, iW)
	local tipSet = {};
	for _, t in ipairs(TIP_TILES) do tipSet[t[1] .. "," .. t[2]] = true; end
	local hillsPct = 50 + Map.Rand(11, "");
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if t[5] == "star" then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			local key = t[3] .. "," .. t[4];
			local isTip = tipSet[key];
			local mt = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
			if mt == PlotTypes.PLOT_LAND and isTip and Map.Rand(100, "") < 20 then
				mt = PlotTypes.PLOT_MOUNTAIN;
			end
			plotTypes[idx] = mt;
		end
	end
end
