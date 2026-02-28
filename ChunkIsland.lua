------------------------------------------------------------------------------
--	ChunkIsland.lua
--	6-9 tiles, scattered disk (noisy rings). Hills 50-60%, mountains by size.
------------------------------------------------------------------------------
include("IslandHelpers");

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

function TryPlaceChunkIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 1;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local radius = 2;
	local landTiles = GetScatteredDiskLandTiles(cx, cy, radius, params.iW, params.iH, params.wrapX, params.wrapY);
	if #landTiles < 6 or #landTiles > 10 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawScatteredDisk(plotTypes, landTiles, params.iW, 50 + Map.Rand(11, ""));
	return true;
end
