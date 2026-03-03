------------------------------------------------------------------------------
--	WishboneIsland.lua
--	Y-shape: short stem below a fork, two arms spreading ~120° apart.
--	10-16 tiles. Stem 2-3 tiles, arms 3-5 tiles each. Arms gently curved
--	outward (biased away from each other); arms never touch.
--	Stem/fork: hills 70%, 1-2 mountains. Arms: hills 50%, no mountains.
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

local function rotDir(d, delta)
	return ((d - 1 + delta) % 6 + 6) % 6 + 1;
end

-- Grows a gently curved arm of up to armLen steps from (sx,sy) in baseDir.
-- bendBias: +1 or -1; the preferred bend direction (outward, weighted 70/30).
-- Grown tiles are immediately marked in `used` and returned as a list.
local function growArm(sx, sy, baseDir, armLen, bendBias, used, params)
	local tiles = {};
	local x, y  = sx, sy;
	local dir   = baseDir;
	local doBend   = Map.Rand(10, "") < 7;
	local bendAt   = 1 + Map.Rand(math.max(1, armLen - 1), "");
	local bendSide = (Map.Rand(10, "") < 7) and bendBias or -bendBias;
	for i = 1, armLen do
		if doBend and i == bendAt then
			dir = rotDir(dir, bendSide);
		end
		local nx, ny = GetHexNeighbor(x, y, dir, params.iW, params.iH, params.wrapX, params.wrapY);
		if nx < 0 or nx >= params.iW or ny < 0 or ny >= params.iH then break; end
		local key = nx .. "," .. ny;
		if used[key] then break; end
		tiles[#tiles + 1] = {nx, ny};
		used[key] = true;
		x, y = nx, ny;
	end
	return tiles;
end

-- Returns true if the bodies of arm1 and arm2 touch (are adjacent), ignoring
-- each arm's first tile since those are naturally adjacent at the fork.
local function armsTouch(arm1, arm2, params)
	local arm2Set = {};
	for _, t in ipairs(arm2) do
		arm2Set[t[1] .. "," .. t[2]] = true;
	end
	for i = 2, #arm1 do
		local t = arm1[i];
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(t[1], t[2], d, params.iW, params.iH, params.wrapX, params.wrapY);
			if arm2Set[nx .. "," .. ny] then return true; end
		end
	end
	local arm1Set = {};
	for _, t in ipairs(arm1) do
		arm1Set[t[1] .. "," .. t[2]] = true;
	end
	for i = 2, #arm2 do
		local t = arm2[i];
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(t[1], t[2], d, params.iW, params.iH, params.wrapX, params.wrapY);
			if arm1Set[nx .. "," .. ny] then return true; end
		end
	end
	return false;
end

function TryPlaceWishboneIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack  = params.pullBack or 2;
	local effMin    = params.effMin   or 2;
	local effMax    = params.effMax   or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local stemDir = Map.Rand(6, "") + 1;
	local oppIdx  = (stemDir - 1 + 3) % 6;
	-- arm1 and arm2 are 2 hex directions apart (~120°), both roughly opposite the stem.
	local arm1Dir = oppIdx % 6 + 1;
	local arm2Dir = (oppIdx + 2) % 6 + 1;

	local stemLen = 2 + Map.Rand(2, "");  -- 2-3
	local armLen  = 3 + Map.Rand(3, "");  -- 3-5

	local landTiles = {};
	local used      = {};
	local baseCount = 0;

	local function addBase(x, y)
		local key = x .. "," .. y;
		if not used[key] and x >= 0 and x < params.iW and y >= 0 and y < params.iH then
			landTiles[#landTiles + 1] = {x, y};
			used[key] = true;
			baseCount  = baseCount + 1;
			return true;
		end
		return false;
	end

	-- Fork point.
	addBase(cx, cy);

	-- Stem: slight optional curve (50%).
	local tx, ty     = cx, cy;
	local stemCurDir = stemDir;
	local sDoBend    = Map.Rand(2, "") == 0;
	local sBendAt    = 1 + Map.Rand(math.max(1, stemLen - 1), "");
	local sBendSide  = (Map.Rand(2, "") == 0) and 1 or -1;
	for i = 1, stemLen do
		if sDoBend and i == sBendAt then
			stemCurDir = rotDir(stemCurDir, sBendSide);
		end
		local nx, ny = GetHexNeighbor(tx, ty, stemCurDir, params.iW, params.iH, params.wrapX, params.wrapY);
		if not addBase(nx, ny) then break; end
		tx, ty = nx, ny;
	end

	-- Arms: arm2 is +2 dirs from arm1.
	-- arm1 bends outward = away from arm2 = -1 direction.
	-- arm2 bends outward = away from arm1 = +1 direction.
	local arm1Tiles = growArm(cx, cy, arm1Dir, armLen, -1, used, params);
	local arm2Tiles = growArm(cx, cy, arm2Dir, armLen,  1, used, params);

	if armsTouch(arm1Tiles, arm2Tiles, params) then return false; end

	for _, t in ipairs(arm1Tiles) do landTiles[#landTiles + 1] = t; end
	for _, t in ipairs(arm2Tiles) do landTiles[#landTiles + 1] = t; end

	if #landTiles < 10 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawWishboneIsland(plotTypes, landTiles, baseCount, params.iW);
	return true;
end

function DrawWishboneIsland(plotTypes, landTiles, baseCount, iW)
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx   = y * iW + x;
		plotTypes[idx] = (Map.Rand(100, "") < 70) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end
end
