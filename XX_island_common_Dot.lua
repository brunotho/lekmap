-- One or two adjacent ocean tiles turned into a tiny island (hills/flat, rare mountain).

include("X_IslandHelpers");

local CONFIG = {
	HILLS_PCT_MIN = 50, HILLS_PCT_RANGE = 11,
	MTN_CHANCE_1_TILE = 2, MTN_CHANCE_2_TILE = 1,
	MTN_CHANCE_1_LARGE = 5, MTN_CHANCE_2_LARGE = 2,
	SIZE_THRESHOLD = 6,
};

function TryPlaceDotIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if params.nearPangea == false then return false; end
	local pullBack = params.pullBack or 1;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end
	DrawDotIsland(plotTypes, centerX, centerY, params.iW, params.iH, params.wrapX, params.wrapY);
	return true;
end

function DrawDotIsland(plotTypes, centerX, centerY, iW, iH, wrapX, wrapY)
	wrapY = wrapY or false;
	local size = 1 + Map.Rand(2, "");
	local landTiles = {};
	local cx = WrapCoord(centerX, iW, wrapX);
	local cy = WrapCoord(centerY, iH, wrapY);
	if cx >= 0 and cx < iW and cy >= 0 and cy < iH then
		landTiles[#landTiles + 1] = {cx, cy};
	end
	if size == 2 then
		local dir = Map.Rand(6, "") + 1;
		local nx, ny = GetHexNeighbor(cx, cy, dir, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			landTiles[#landTiles + 1] = {nx, ny};
		end
	end
	local hillsPct = CONFIG.HILLS_PCT_MIN + Map.Rand(CONFIG.HILLS_PCT_RANGE, "");
	local mtn1 = (#landTiles <= CONFIG.SIZE_THRESHOLD) and CONFIG.MTN_CHANCE_1_TILE or CONFIG.MTN_CHANCE_1_LARGE;
	local mtn2 = (#landTiles <= CONFIG.SIZE_THRESHOLD) and CONFIG.MTN_CHANCE_2_TILE or CONFIG.MTN_CHANCE_2_LARGE;
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		local mt = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		if mt == PlotTypes.PLOT_LAND and #landTiles == 1 and Map.Rand(100, "") < mtn1 then
			mt = PlotTypes.PLOT_MOUNTAIN;
		elseif mt == PlotTypes.PLOT_LAND and #landTiles == 2 and Map.Rand(100, "") < mtn2 then
			mt = PlotTypes.PLOT_MOUNTAIN;
		end
		plotTypes[idx] = mt;
	end
end
