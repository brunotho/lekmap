------------------------------------------------------------------------------
--	SplinteredCliffsIsland.lua
--	Mostly visual: scattered mountains, individual peaks alone in water,
--	occasionally small adjacent mountain clusters. Land tiles extremely rare.
------------------------------------------------------------------------------
include("X_IslandHelpers");

local CONFIG = {
	RADIUS = 5,
	SEMI_MAJOR = 6, SEMI_MINOR = 4,  -- oval: elongated in one axis
	MIN_PEAK_DIST = 2,
	NUM_PEAKS_MIN = 12,
	NUM_PEAKS_MAX = 22,
	CLUSTER_CHANCE_PCT = 16,   -- reduced for less clumping
	CLUSTER_2ND_PCT = 35,
	LAND_TILE_PCT = 3,
};

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[y * iW + x];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function manhattanDist(ax, ay, bx, by, iW, wrapX)
	local dx = math.abs(bx - ax);
	if wrapX and dx > iW / 2 then dx = iW - dx; end
	return dx + math.abs(by - ay);
end

local function footprintClear(plotTypes, tiles, iW, iH)
	for _, t in ipairs(tiles) do
		if isLand(plotTypes, t[1], t[2], iW, iH) then return false; end
	end
	return true;
end

function TryPlaceSplinteredCliffsIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.splinteredCliffs then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local disk = GetHexDisk(cx, cy, math.max(CONFIG.SEMI_MAJOR, CONFIG.SEMI_MINOR), params.iW, params.iH, params.wrapX, params.wrapY);
	local orient = Map.Rand(2, "");
	local semiA = CONFIG.SEMI_MAJOR;
	local semiB = CONFIG.SEMI_MINOR;
	local oval = {};
	for _, t in ipairs(disk) do
		local dx = t[1] - cx;
		local dy = t[2] - cy;
		if params.wrapX and math.abs(dx) > params.iW / 2 then
			dx = dx - (dx > 0 and params.iW or -params.iW);
		end
		local ex, ey = (orient == 0) and (dx / semiA) or (dy / semiA), (orient == 0) and (dy / semiB) or (dx / semiB);
		if ex * ex + ey * ey <= 1 then
			oval[#oval + 1] = t;
		end
	end
	local shuffled = {};
	for i = 1, #oval do shuffled[i] = oval[i]; end
	for i = #shuffled, 2, -1 do
		local j = Map.Rand(i, "") + 1;
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i];
	end

	local centers = {};
	for _, t in ipairs(shuffled) do
		local x, y = t[1], t[2];
		local ok = true;
		for _, c in ipairs(centers) do
			if manhattanDist(x, y, c[1], c[2], params.iW, params.wrapX) < CONFIG.MIN_PEAK_DIST then
				ok = false;
				break;
			end
		end
		if ok then
			centers[#centers + 1] = {x, y};
			if #centers >= CONFIG.NUM_PEAKS_MAX then break; end
		end
	end

	if #centers < CONFIG.NUM_PEAKS_MIN then return false; end

	local landTiles = {};
	local used = {};

	for _, c in ipairs(centers) do
		local x, y = c[1], c[2];
		local key = y * params.iW + x;
		if not used[key] then
			landTiles[#landTiles + 1] = {x, y, "mountain"};
			used[key] = true;

			if Map.Rand(100, "") < CONFIG.CLUSTER_CHANCE_PCT then
				local adjTbl = (y % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
				local candidates = {};
				for d = 1, 6 do
					local nx = x + adjTbl[d][1];
					local ny = y + adjTbl[d][2];
					nx = WrapCoord(nx, params.iW, params.wrapX);
					ny = WrapCoord(ny, params.iH, params.wrapY);
					if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
						local nkey = ny * params.iW + nx;
						if not used[nkey] then
							candidates[#candidates + 1] = {nx, ny, nkey};
						end
					end
				end
				if #candidates > 0 then
					local pick = Map.Rand(#candidates, "") + 1;
					local nx, ny, nkey = candidates[pick][1], candidates[pick][2], candidates[pick][3];
					landTiles[#landTiles + 1] = {nx, ny, "mountain"};
					used[nkey] = true;

					if Map.Rand(100, "") < CONFIG.CLUSTER_2ND_PCT then
						local adjTbl2 = (ny % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
						for d = 1, 6 do
							local nnx = nx + adjTbl2[d][1];
							local nny = ny + adjTbl2[d][2];
							nnx = WrapCoord(nnx, params.iW, params.wrapX);
							nny = WrapCoord(nny, params.iH, params.wrapY);
							if nnx >= 0 and nnx < params.iW and nny >= 0 and nny < params.iH then
								local nnkey = nny * params.iW + nnx;
								if not used[nnkey] then
									landTiles[#landTiles + 1] = {nnx, nny, "mountain"};
									used[nnkey] = true;
									break;
								end
							end
						end
					end
				end
			end
		end
	end

	for _, m in ipairs(landTiles) do
		if m[3] == "mountain" and Map.Rand(100, "") < CONFIG.LAND_TILE_PCT then
			local x, y = m[1], m[2];
			local adjTbl = (y % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
			for d = 1, 6 do
				local nx = x + adjTbl[d][1];
				local ny = y + adjTbl[d][2];
				nx = WrapCoord(nx, params.iW, params.wrapX);
				ny = WrapCoord(ny, params.iH, params.wrapY);
				if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
					local nkey = ny * params.iW + nx;
					if not used[nkey] then
						landTiles[#landTiles + 1] = {nx, ny, (Map.Rand(100, "") < 50) and "hill" or "land"};
						used[nkey] = true;
						break;
					end
				end
			end
		end
	end

	if #landTiles < 8 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawSplinteredCliffsIsland(plotTypes, landTiles, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.splinteredCliffs = true;
	return true;
end

function DrawSplinteredCliffsIsland(plotTypes, landTiles, iW)
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		if t[3] == "mountain" then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif t[3] == "hill" then
			plotTypes[idx] = PlotTypes.PLOT_HILLS;
		else
			plotTypes[idx] = PlotTypes.PLOT_LAND;
		end
	end
end
