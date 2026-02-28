------------------------------------------------------------------------------
--	BrokenHeartIsland.lua (recreated from transcript)
--	7 rows × 6 wide. Variant A: 3-tile lake scar. B: rift to ocean. C: full break, two islands.
--	50% hills, 50% flat. 6 rotations.
------------------------------------------------------------------------------
include("IslandHelpers");

local HEART_TEMPLATE = {
	{0,0},{1,0},{2,0},{3,0},
	{-1,1},{0,1},{1,1},{2,1},{3,1},{4,1},
	{-1,2},{0,2},{1,2},{2,2},{3,2},{4,2},
	{0,3},{1,3},{2,3},{3,3},
	{0,4},{1,4},{2,4},{3,4},
	{1,5},{2,5},
};

local SCAR_A = {{1,2},{2,2},{1,3}};
local RIFT_B = {{1,2},{2,2},{1,3},{2,3}};
local BREAK_C = {{1,2},{2,2},{1,3},{2,3},{0,2},{3,2}};

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

function TryPlaceBrokenHeartIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.brokenHeart then return false; end
	local pullBack = params.pullBack or 3;
	local effMin = params.effMin or 3;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local variant = Map.Rand(3, "") + 1;
	local scar = (variant == 1) and SCAR_A or ((variant == 2) and RIFT_B or BREAK_C);
	local scarSet = {};
	for _, t in ipairs(scar) do scarSet[t[1] .. "," .. t[2]] = true; end

	local rot = Map.Rand(6, "");
	local landTiles = {};
	for _, t in ipairs(HEART_TEMPLATE) do
		if not scarSet[t[1] .. "," .. t[2]] then
			local dx, dy = rotateHex60(t[1], t[2], rot);
			local gx = WrapCoord(cx + dx, params.iW, params.wrapX);
			local gy = WrapCoord(cy + dy, params.iH, params.wrapY);
			if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH then
				landTiles[#landTiles + 1] = {gx, gy};
			end
		end
	end

	if #landTiles < 10 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawBrokenHeartIsland(plotTypes, landTiles, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.brokenHeart = true;
	return true;
end

function DrawBrokenHeartIsland(plotTypes, landTiles, iW)
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end
end
