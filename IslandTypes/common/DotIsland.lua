------------------------------------------------------------------------------
--	DotIsland.lua (collected from transcript)
--	1-2 tiles. Hills 50-60%, mountains: size<=6 → 2% for 1, 1% for 2; size>=7 → 5% for 1, 2% for 2.
------------------------------------------------------------------------------
include("IslandTypes/IslandHelpers");

function TryPlaceDotIsland(plotTypes, centerX, centerY, islLandInRing, params)
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
	local hillsPct = 50 + Map.Rand(11, "");
	local mtnChance1 = 2;
	local mtnChance2 = 1;
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		local mt = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		if mt == PlotTypes.PLOT_LAND and #landTiles == 1 and Map.Rand(100, "") < mtnChance1 then
			mt = PlotTypes.PLOT_MOUNTAIN;
		elseif mt == PlotTypes.PLOT_LAND and #landTiles == 2 and Map.Rand(100, "") < mtnChance2 then
			mt = PlotTypes.PLOT_MOUNTAIN;
		end
		plotTypes[idx] = mt;
	end
end
