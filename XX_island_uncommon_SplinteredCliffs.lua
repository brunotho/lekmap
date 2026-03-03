------------------------------------------------------------------------------
--	SplinteredCliffsIsland.lua (recreated from transcript)
--	Variant A (60%): 3-5 mountains, 0-1 land, tight cluster.
--	Variant B (20%): 3-6 mountains, 2-4 land, 1 per mountain island max.
--	Variant C (20%): 5-7 mountains, 6-12 land, 2 islands get 2-5 hills each.
--	Adjacent to mountains: 85% hills. 2 tiles from: 65%. 3+: flat.
------------------------------------------------------------------------------
include("X_IslandHelpers");

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

local function distFromMountains(tile, mountainTiles, iW, iH, wrapX, wrapY)
	local minD = 999;
	for _, m in ipairs(mountainTiles) do
		if IsHexAdjacent(tile[1], tile[2], m[1], m[2]) then return 1; end
	end
	for _, m in ipairs(mountainTiles) do
		for dir = 1, 6 do
			local nx, ny = GetHexNeighbor(m[1], m[2], dir, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH and IsHexAdjacent(tile[1], tile[2], nx, ny) then
				return 2;
			end
		end
	end
	return 3;
end

function TryPlaceSplinteredCliffsIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local variant = Map.Rand(100, "");
	local numMountains, numLand;
	if variant < 60 then
		numMountains = 3 + Map.Rand(3, "");
		numLand = Map.Rand(2, "");
	elseif variant < 80 then
		numMountains = 3 + Map.Rand(4, "");
		numLand = 2 + Map.Rand(3, "");
	else
		numMountains = 5 + Map.Rand(3, "");
		numLand = 6 + Map.Rand(7, "");
	end

	local disk = GetHexDisk(cx, cy, 2, params.iW, params.iH, params.wrapX, params.wrapY);
	if #disk < numMountains + numLand then return false; end

	local landTiles = {};
	local mountainTiles = {};
	for i = 1, numMountains do
		if #disk > 0 then
			local r = Map.Rand(#disk, "") + 1;
			local t = disk[r];
			landTiles[#landTiles + 1] = {t[1], t[2], "mountain"};
			mountainTiles[#mountainTiles + 1] = {t[1], t[2]};
			table.remove(disk, r);
		end
	end
	for i = 1, numLand do
		if #disk > 0 then
			local r = Map.Rand(#disk, "") + 1;
			local t = disk[r];
			landTiles[#landTiles + 1] = {t[1], t[2], "land"};
			table.remove(disk, r);
		end
	end

	if #landTiles < 3 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawSplinteredCliffsIsland(plotTypes, landTiles, mountainTiles, params.iW, params.iH, params.wrapX, params.wrapY);
	return true;
end

function DrawSplinteredCliffsIsland(plotTypes, landTiles, mountainTiles, iW, iH, wrapX, wrapY)
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		if t[3] == "mountain" then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		else
			local d = distFromMountains({x, y}, mountainTiles, iW, iH, wrapX, wrapY);
			local pct = (d == 1) and 85 or ((d == 2) and 65 or 0);
			plotTypes[idx] = (Map.Rand(100, "") < pct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
