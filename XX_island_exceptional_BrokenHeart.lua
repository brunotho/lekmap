print("### BrokenHeartIsland: loading ###");
------------------------------------------------------------------------------
--	BrokenHeartIsland.lua
--	26 tiles. Point at south (low y), two bumps with V-notch gap at north (high y).
--	No rotation, no scar variants — stable baseline shape.
--	50% hills, 50% flat.
------------------------------------------------------------------------------
include("X_IslandHelpers");

-- Point at y=0 (south/bottom), widens 1→2→3→4→5→6, then two bumps with 1-hex gap at y=6 (north/top).
-- All rows centered on screen x=2.0 accounting for odd-row +0.5 visual offset.
-- Row widths: 1, 2, 3, 4, 5, 6, (2 + gap-1 + 2) = 25 tiles total.
HEART_TEMPLATE = {
	{1,0},                                          -- tip        (1)
	{1,1},{2,1},                                    -- y=1        (2)
	{0,2},{1,2},{2,2},                              -- y=2        (3)
	{0,3},{1,3},{2,3},{3,3},                        -- y=3        (4)
	{-1,4},{0,4},{1,4},{2,4},{3,4},                 -- y=4        (5)
	{-1,5},{0,5},{1,5},{2,5},{3,5},{4,5},           -- y=5        (6)
	{-1,6},{0,6},        {2,6},{3,6},               -- bumps      (2 + gap@x=1 + 2)
};

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

function TryPlaceBrokenHeartIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.brokenHeart then return false; end
	local pullBack = params.pullBack or 1;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	-- Stable template: tip at (cx+2,cy), widens north, bumps with 1-hex gap at top.
	-- Odd absolute rows (cy+dy) get dx=-1 to cancel hex offset for visual centering.
	local canonical = {
		{2,0},{1,1},{2,1},{1,2},{2,2},{3,2},{0,3},{1,3},{2,3},{3,3},
		{0,4},{1,4},{2,4},{3,4},{4,4},{-1,5},{0,5},{1,5},{2,5},{3,5},{4,5},
		{0,6},{1,6},{3,6},{4,6},
	};
	local landTiles = {};
	for _, t in ipairs(canonical) do
		local absY = cy + t[2];
		local dx = (absY % 2 == 1) and -1 or 0;
		local gx = WrapCoord(cx + t[1] + dx, params.iW, params.wrapX);
		local gy = absY;
		if gy >= 0 and gy < params.iH then
			landTiles[#landTiles + 1] = {gx, gy};
		end
	end

	if #landTiles < 18 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawBrokenHeartIsland(plotTypes, landTiles, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.brokenHeart = true;
	return true;
end

function DrawBrokenHeartIsland(plotTypes, landTiles, iW)
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end
end

function ForcePlaceBrokenHeartIsland(plotTypes, cx, cy, iW, iH)
	local template = {
		{2,0},
		{1,1},{2,1},
		{1,2},{2,2},{3,2},
		{0,3},{1,3},{2,3},{3,3},
		{0,4},{1,4},{2,4},{3,4},{4,4},
		{-1,5},{0,5},{1,5},{2,5},{3,5},{4,5},
		{0,6},{1,6},{3,6},{4,6},
	};
	local landTiles = {};
	for _, t in ipairs(template) do
		local gx = (cx + t[1] + iW) % iW;
		local gy = cy + t[2];
		if gy >= 0 and gy < iH then
			landTiles[#landTiles + 1] = {gx, gy};
		end
	end
	for _, t in ipairs(landTiles) do
		local idx = t[2] * iW + t[1];
		plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end
	if not _island_placed then _island_placed = {}; end
	_island_placed.brokenHeart = true;
end
