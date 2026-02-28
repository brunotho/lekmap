------------------------------------------------------------------------------
--	WishboneIsland.lua (recreated from transcript)
--	10-14 tiles. Base 2-3 thick, two arms 3-5 tiles each, 1 tile wide.
--	Angle between arms 45-90°. Base: hills 70%, 1-2 mountains. Arms: hills 50%, no mountains.
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

function TryPlaceWishboneIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local baseThick = 2 + Map.Rand(2, "");
	local armLen = 3 + Map.Rand(3, "");
	local angleDeg = 45 + Map.Rand(46, "");
	local angleRad = angleDeg * math.pi / 180;

	local dir1 = Map.Rand(6, "") + 1;
	local dir2 = dir1 + math.floor(angleDeg / 60) + 1;
	if dir2 > 6 then dir2 = dir2 - 6; end

	local landTiles = {};
	local x, y = cx, cy;
	local used = {}; used[cx .. "," .. cy] = true;

	for _ = 1, baseThick do
		for i = -1, 1 do
			local d = ((dir1 + i + 5) % 6) + 1;
			local nx, ny = GetHexNeighbor(x, y, d, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and not used[nx .. "," .. ny] then
				landTiles[#landTiles + 1] = {nx, ny};
				used[nx .. "," .. ny] = true;
			end
		end
		local nx, ny = GetHexNeighbor(x, y, dir1, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
			x, y = nx, ny;
			if not used[x .. "," .. y] then
				landTiles[#landTiles + 1] = {x, y};
				used[x .. "," .. y] = true;
			end
		else break; end
	end

	local baseX, baseY = cx, cy;
	local arm1X, arm1Y = baseX, baseY;
	for _ = 1, armLen do
		local nx, ny = GetHexNeighbor(arm1X, arm1Y, dir1, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and not used[nx .. "," .. ny] then
			landTiles[#landTiles + 1] = {nx, ny};
			used[nx .. "," .. ny] = true;
			arm1X, arm1Y = nx, ny;
		else break; end
	end

	for _ = 1, armLen do
		local nx, ny = GetHexNeighbor(baseX, baseY, dir2, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH and not used[nx .. "," .. ny] then
			landTiles[#landTiles + 1] = {nx, ny};
			used[nx .. "," .. ny] = true;
			baseX, baseY = nx, ny;
		else break; end
	end

	if #landTiles < 10 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawWishboneIsland(plotTypes, landTiles, params.iW);
	return true;
end

function DrawWishboneIsland(plotTypes, landTiles, iW)
	local baseCount = math.min(8, #landTiles);
	for i, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if i <= baseCount then
			plotTypes[idx] = (Map.Rand(100, "") < 70) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
	local numMountains = 1 + Map.Rand(2, "");
	local candidates = {};
	for i = 1, math.min(baseCount, #landTiles) do
		candidates[#candidates + 1] = landTiles[i];
	end
	for i = 1, math.min(numMountains, #candidates) do
		local r = Map.Rand(#candidates, "") + 1;
		local t = candidates[r];
		plotTypes[t[2] * iW + t[1] + 1] = PlotTypes.PLOT_MOUNTAIN;
		table.remove(candidates, r);
	end
end
