------------------------------------------------------------------------------
--	SplinteredMountainsIsland.lua
--	Lots of isolated tiny mountain islands, occasional hills adjacent, rare land blobs.
--	No scattered disk - explicit placement with min spacing for isolation.
------------------------------------------------------------------------------
include("X_IslandHelpers");

local CONFIG = {
	RADIUS = 4,
	MIN_ISLAND_DIST = 2,
	NUM_ISLANDS_MIN = 10,
	NUM_ISLANDS_MAX = 16,
	HILL_ADJACENT_PCT = 12,
	BLOB_SIZE_MIN = 2,
	BLOB_SIZE_MAX = 3,
	BLOB_CHANCE_PCT = 5,
	TWO_TILE_PCT = 12,
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

local function distToCenter(nx, ny, cx, cy, iW, wrapX)
	return manhattanDist(nx, ny, cx, cy, iW, wrapX);
end

local function footprintClear(plotTypes, tiles, iW, iH)
	for _, t in ipairs(tiles) do
		if isLand(plotTypes, t[1], t[2], iW, iH) then return false; end
	end
	return true;
end

function TryPlaceSplinteredMountainsIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.splinteredMountains then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 5;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local disk = GetHexDisk(cx, cy, CONFIG.RADIUS, params.iW, params.iH, params.wrapX, params.wrapY);
	local shuffled = {};
	for i = 1, #disk do shuffled[i] = disk[i]; end
	for i = #shuffled, 2, -1 do
		local j = Map.Rand(i, "") + 1;
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i];
	end

	local centers = {};
	for _, t in ipairs(shuffled) do
		local x, y = t[1], t[2];
		local ok = true;
		for _, c in ipairs(centers) do
			if manhattanDist(x, y, c[1], c[2], params.iW, params.wrapX) < CONFIG.MIN_ISLAND_DIST then
				ok = false;
				break;
			end
		end
		if ok then
			centers[#centers + 1] = {x, y};
			if #centers >= CONFIG.NUM_ISLANDS_MAX then break; end
		end
	end

	if #centers < CONFIG.NUM_ISLANDS_MIN then return false; end

	local landTiles = {};
	local mountainTiles = {};
	local used = {};
	local blobCenterIdx = (Map.Rand(100, "") < CONFIG.BLOB_CHANCE_PCT) and (1 + Map.Rand(#centers, "")) or nil;

	for i, c in ipairs(centers) do
		local x, y = c[1], c[2];
		local key = y * params.iW + x;
		if not used[key] then
			local isBlob = (blobCenterIdx == i);

			if isBlob then
				local blobSize = CONFIG.BLOB_SIZE_MIN + Map.Rand(CONFIG.BLOB_SIZE_MAX - CONFIG.BLOB_SIZE_MIN + 1, "");
				local blob = {{x, y, "land"}};
				used[key] = true;
				local frontier = {{x, y}};
				for _ = 2, blobSize do
					if #frontier == 0 then break; end
					local idx = Map.Rand(#frontier, "") + 1;
					local fx, fy = frontier[idx][1], frontier[idx][2];
					table.remove(frontier, idx);
					local adj = (fy % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
					for d = 1, 6 do
						local nx = fx + adj[d][1];
						local ny = fy + adj[d][2];
						nx = WrapCoord(nx, params.iW, params.wrapX);
						ny = WrapCoord(ny, params.iH, params.wrapY);
						if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
							local nkey = ny * params.iW + nx;
							if not used[nkey] then
								local isHill = (Map.Rand(100, "") < 60);
								blob[#blob + 1] = {nx, ny, isHill and "hill" or "land"};
								frontier[#frontier + 1] = {nx, ny};
								used[nkey] = true;
								break;
							end
						end
					end
				end
				for _, b in ipairs(blob) do landTiles[#landTiles + 1] = b; end
			else
				local r = Map.Rand(100, "");
				if r < (100 - CONFIG.TWO_TILE_PCT) then
					landTiles[#landTiles + 1] = {x, y, "mountain"};
					mountainTiles[#mountainTiles + 1] = {x, y};
					used[key] = true;
				else
					landTiles[#landTiles + 1] = {x, y, "mountain"};
					mountainTiles[#mountainTiles + 1] = {x, y};
					used[key] = true;
					local adj = (y % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
					local candidates = {};
					for d = 1, 6 do
						local nx = x + adj[d][1];
						local ny = y + adj[d][2];
						nx = WrapCoord(nx, params.iW, params.wrapX);
						ny = WrapCoord(ny, params.iH, params.wrapY);
						if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
							local nkey = ny * params.iW + nx;
							if not used[nkey] then
								local dist = distToCenter(nx, ny, cx, cy, params.iW, params.wrapX);
								candidates[#candidates + 1] = {nx, ny, nkey, dist};
							end
						end
					end
					if #candidates > 0 then
						table.sort(candidates, function(a, b) return a[4] < b[4]; end);
						local pick = (Map.Rand(100, "") < 70) and 1 or (1 + Map.Rand(math.min(2, #candidates), ""));
						local nx, ny, nkey = candidates[pick][1], candidates[pick][2], candidates[pick][3];
						local isHill = (Map.Rand(100, "") < 50);
						landTiles[#landTiles + 1] = {nx, ny, isHill and "hill" or "mountain"};
						if not isHill then mountainTiles[#mountainTiles + 1] = {nx, ny}; end
						used[nkey] = true;
					end
				end
			end
		end
	end

	for _, m in ipairs(mountainTiles) do
		if Map.Rand(100, "") < CONFIG.HILL_ADJACENT_PCT then
			local x, y = m[1], m[2];
			local adj = (y % 2 ~= 0) and firstRingYIsOdd or firstRingYIsEven;
			local candidates = {};
			for d = 1, 6 do
				local nx = x + adj[d][1];
				local ny = y + adj[d][2];
				nx = WrapCoord(nx, params.iW, params.wrapX);
				ny = WrapCoord(ny, params.iH, params.wrapY);
				if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
					local nkey = ny * params.iW + nx;
					if not used[nkey] then
						local dist = distToCenter(nx, ny, cx, cy, params.iW, params.wrapX);
						candidates[#candidates + 1] = {nx, ny, nkey, dist};
					end
				end
			end
			if #candidates > 0 then
				table.sort(candidates, function(a, b) return a[4] < b[4]; end);
				local pick = (Map.Rand(100, "") < 75) and 1 or (1 + Map.Rand(math.min(2, #candidates), ""));
				local nx, ny, nkey = candidates[pick][1], candidates[pick][2], candidates[pick][3];
				landTiles[#landTiles + 1] = {nx, ny, "hill"};
				used[nkey] = true;
			end
		end
	end

	if #landTiles < 8 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawSplinteredMountainsIsland(plotTypes, landTiles, params.iW);
	if not _island_placed then _island_placed = {}; end
	_island_placed.splinteredMountains = true;
	return true;
end

function DrawSplinteredMountainsIsland(plotTypes, landTiles, iW)
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		if t[3] == "mountain" then
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		elseif t[3] == "hill" then
			plotTypes[idx] = PlotTypes.PLOT_HILLS;
		else
			plotTypes[idx] = (Map.Rand(100, "") < 40) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		end
	end
end
