------------------------------------------------------------------------------
--	CurledDragonIsland.lua (recreated from transcript)
--	S-curve dragon: 8 rows × 6 wide, ~25 tiles. 6 mountains + horn on snout.
--	Lake eye → El Dorado tile. 85% hills next to mountains.
------------------------------------------------------------------------------
include("IslandHelpers");

local DRAGON_TEMPLATE = {
	{2,0},{3,0},{4,0},
	{1,1},{2,1},{3,1},{4,1},{5,1},
	{0,2},{1,2},{2,2},{3,2},{4,2},{5,2},
	{0,3},{1,3},{2,3},{3,3},{4,3},
	{1,4},{2,4},{3,4},{4,4},{5,4},
	{2,5},{3,5},{4,5},
	{3,6},{4,6},
	{4,7},
};
local MOUNTAIN_TILES = {{2,0},{4,0},{1,1},{3,2},{2,4},{4,5}};
local HORN_TILE = {4,7};
local EYE_TILE = {2,2};

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

local function isAdjacentToMountain(tx, ty, mountainCoords, rot)
	for _, m in ipairs(mountainCoords) do
		local mx, my = rotateHex60(m[1], m[2], rot);
		local dx = math.abs(tx - mx);
		local dy = math.abs(ty - my);
		if (dx == 1 and dy == 0) or (dx == 0 and dy == 1) or (dx == 1 and dy == 1) then
			return true;
		end
	end
	return false;
end

function TryPlaceCurledDragonIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.curledDragon then return false; end
	local pullBack = params.pullBack or 3;
	local effMin = params.effMin or 3;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local rot = Map.Rand(6, "");
	local landTiles = {};
	for _, t in ipairs(DRAGON_TEMPLATE) do
		local dx, dy = rotateHex60(t[1], t[2], rot);
		local gx = WrapCoord(cx + dx, params.iW, params.wrapX);
		local gy = WrapCoord(cy + dy, params.iH, params.wrapY);
		if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH then
			landTiles[#landTiles + 1] = {gx, gy, t[1], t[2]};
		end
	end

	if #landTiles < 15 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawCurledDragonIsland(plotTypes, landTiles, rot, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.curledDragon = true;
	return true;
end

function DrawCurledDragonIsland(plotTypes, landTiles, rot, iW)
	local mountainSet = {};
	for _, m in ipairs(MOUNTAIN_TILES) do
		mountainSet[m[1] .. "," .. m[2]] = true;
	end
	mountainSet[HORN_TILE[1] .. "," .. HORN_TILE[2]] = true;

	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		local tx, ty = t[3], t[4];
		local key = tx .. "," .. ty;
		if mountainSet[key] then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif tx == EYE_TILE[1] and ty == EYE_TILE[2] then
			plotTypes[idx] = PlotTypes.PLOT_OCEAN;
		else
			local adjMtn = false;
			for _, m in ipairs(MOUNTAIN_TILES) do
				local dmx = math.abs(tx - m[1]);
				local dmy = math.abs(ty - m[2]);
				if (dmx <= 1 and dmy <= 1 and (dmx + dmy) > 0) then adjMtn = true; break; end
			end
			plotTypes[idx] = (adjMtn and Map.Rand(100, "") < 85) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
