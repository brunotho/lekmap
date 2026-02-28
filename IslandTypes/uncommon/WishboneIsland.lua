------------------------------------------------------------------------------
--	WishboneIsland.lua
--	Y-shape: a short handle/stem below a fork, two arms spreading ~120° apart.
--	10-14 tiles. Stem 2-3 tiles, two arms 3-5 tiles each, 1 tile wide.
--	Stem/fork: hills 70%, 1-2 mountains. Arms: hills 50%, no mountains.
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

	-- stemDir: direction the handle grows away from the fork.
	-- arm1Dir/arm2Dir: each 1 hex step away from the opposite of stemDir,
	-- giving ~120° spread between the two arms.
	local stemDir    = Map.Rand(6, "") + 1;
	local oppIdx     = (stemDir - 1 + 3) % 6;
	local arm1Dir    = oppIdx % 6 + 1;
	local arm2Dir    = (oppIdx + 2) % 6 + 1;

	local stemLen = 2 + Map.Rand(2, "");   -- 2-3 tiles
	local armLen  = 3 + Map.Rand(3, "");   -- 3-5 tiles

	local landTiles = {};
	local used = {};
	local baseCount = 0;

	local function addTile(x, y, isBase)
		local key = x .. "," .. y;
		if not used[key] and x >= 0 and x < params.iW and y >= 0 and y < params.iH then
			landTiles[#landTiles + 1] = {x, y};
			used[key] = true;
			if isBase then baseCount = baseCount + 1; end
			return true;
		end
		return false;
	end

	-- Fork point (center).
	addTile(cx, cy, true);

	-- Stem: grows from fork in stemDir.
	local tx, ty = cx, cy;
	for _ = 1, stemLen do
		local nx, ny = GetHexNeighbor(tx, ty, stemDir, params.iW, params.iH, params.wrapX, params.wrapY);
		if not addTile(nx, ny, true) then break; end
		tx, ty = nx, ny;
	end

	-- Arm 1: grows from fork in arm1Dir.
	local a1x, a1y = cx, cy;
	for _ = 1, armLen do
		local nx, ny = GetHexNeighbor(a1x, a1y, arm1Dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if not addTile(nx, ny, false) then break; end
		a1x, a1y = nx, ny;
	end

	-- Arm 2: grows from fork in arm2Dir.
	local a2x, a2y = cx, cy;
	for _ = 1, armLen do
		local nx, ny = GetHexNeighbor(a2x, a2y, arm2Dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if not addTile(nx, ny, false) then break; end
		a2x, a2y = nx, ny;
	end

	if #landTiles < 10 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawWishboneIsland(plotTypes, landTiles, baseCount, params.iW);
	return true;
end

function DrawWishboneIsland(plotTypes, landTiles, baseCount, iW)
	for i, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		if i <= baseCount then
			plotTypes[idx] = (Map.Rand(100, "") < 70) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 50) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
	-- 1-2 mountains in the stem/fork region.
	local numMountains = 1 + Map.Rand(2, "");
	local candidates = {};
	for i = 1, baseCount do
		candidates[#candidates + 1] = landTiles[i];
	end
	for _ = 1, math.min(numMountains, #candidates) do
		local r = Map.Rand(#candidates, "") + 1;
		local t = candidates[r];
		plotTypes[t[2] * iW + t[1] + 1] = PlotTypes.PLOT_MOUNTAIN;
		table.remove(candidates, r);
	end
end
