------------------------------------------------------------------------------
--	StripIsland.lua
--	4-6 tiles, linear chain. Terrain odds in CONFIG.
------------------------------------------------------------------------------
include("X_IslandHelpers");

local CONFIG = {
	HILLS_PCT_MIN = 50, HILLS_PCT_RANGE = 11,
	MTN_CHANCE_SMALL = 2, MTN_CHANCE_LARGE = 5,
	SIZE_THRESHOLD = 6,
	TURN_PCT = 40,
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

function TryPlaceStripIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 1;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local size = 4 + Map.Rand(3, "");
	local landTiles = {{cx, cy}};
	local dir = Map.Rand(6, "") + 1;
	local x, y = cx, cy;
	local used = {}; used[cx .. "," .. cy] = true;

	for _ = 1, size - 1 do
		if #landTiles == 4 then
			dir = ((dir + Map.Rand(2, "") - 1) % 6) + 1;
		elseif Map.Rand(100, "") < CONFIG.TURN_PCT then
			dir = ((dir + Map.Rand(2, "") - 1) % 6) + 1;
		end
		local nx, ny = GetHexNeighbor(x, y, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and not used[nx .. "," .. ny] then
			landTiles[#landTiles + 1] = {nx, ny};
			used[nx .. "," .. ny] = true;
			x, y = nx, ny;
		else
			break;
		end
	end

	if #landTiles < 4 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawStripIsland(plotTypes, landTiles, params.iW);
	return true;
end

function DrawStripIsland(plotTypes, landTiles, iW)
	local hillsPct = CONFIG.HILLS_PCT_MIN + Map.Rand(CONFIG.HILLS_PCT_RANGE, "");
	local n = #landTiles;
	local mtnChance = (n <= CONFIG.SIZE_THRESHOLD) and CONFIG.MTN_CHANCE_SMALL or CONFIG.MTN_CHANCE_LARGE;
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		local mt = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		if mt == PlotTypes.PLOT_LAND and Map.Rand(100, "") < mtnChance then
			mt = PlotTypes.PLOT_MOUNTAIN;
		end
		plotTypes[idx] = mt;
	end
end
