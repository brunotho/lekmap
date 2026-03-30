include("X_IslandHelpers");

local function pidx(x, y, iW)
	return y * iW + x + 1;
end

local function isOcean(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	return plotTypes[pidx(x, y, iW)] == PlotTypes.PLOT_OCEAN;
end

local function randStdNormal()
	local u = (Map.Rand(999998, "") + 1) / 1000000;
	local v = (Map.Rand(999998, "") + 1) / 1000000;
	return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
end

local function pickCenterRow(iH)
	local lo = 12;
	local hi = 42;
	if hi > iH - 3 then hi = math.max(lo, iH - 3); end
	if lo > hi then lo = math.max(2, math.floor(iH / 2)); hi = lo; end
	local c = 26 + randStdNormal() * 5;
	c = math.floor(c + 0.5);
	if c < lo then c = lo; end
	if c > hi then c = hi; end
	c = math.max(2, math.min(iH - 3, c));
	return c;
end

local function keyXY(x, y)
	return tostring(x) .. "," .. tostring(y);
end

function TryPlaceWrapSoftLandbridge(plotTypes, opts)
	if not opts.wrapX then
		return false;
	end
	local iW, iH = opts.iW, opts.iH;
	local wrapX = true;
	local wrapY = opts.wrapY == true;

	local vSpan = 3 + Map.Rand(2, "");
	local yMid = pickCenterRow(iH);
	local yLo = yMid - Map.Rand(vSpan + 2, "") + 1;
	if yLo < 2 then yLo = 2; end
	if yLo + vSpan > iH - 3 then
		yLo = math.max(2, iH - 3 - vSpan);
	end

	local seen = {};

	local function tryMark(x, y, keepP)
		if Map.Rand(100, "") >= keepP then
			return;
		end
		x = math.max(0, math.min(iW - 1, x));
		if y < 0 or y >= iH then
			return;
		end
		local k = keyXY(x, y);
		if seen[k] then
			return;
		end
		seen[k] = true;
	end

	local function walkFromLeft()
		local n = 6 + Map.Rand(5, "");
		for _w = 1, n do
			local x, y = 0, yLo + Map.Rand(vSpan + 4, "") - 2;
			if y < 0 then y = 0; end
			if y >= iH then y = iH - 1; end
			local maxPen = 5 + Map.Rand(math.max(1, math.floor(iW * 0.3)), "");
			local steps = 22 + Map.Rand(45, "");
			for _s = 1, steps do
				if x >= maxPen and Map.Rand(100, "") > 28 then
					break;
				end
				tryMark(x, y, 62 + Map.Rand(25, ""));
				local r = Map.Rand(100, "");
				if r < 40 then
					x = x + 1;
					y = y + Map.Rand(3, "") - 1;
				elseif r < 76 then
					x = x + 1;
				elseif r < 90 then
					y = y + Map.Rand(5, "") - 2;
				else
					local nx, ny = GetHexNeighbor(x, y, 1 + Map.Rand(6, ""), iW, iH, wrapX, wrapY);
					if nx > x then
						x, y = nx, ny;
					elseif nx == x then
						x, y = nx, ny;
					else
						x = x + 1;
						y = y + Map.Rand(3, "") - 1;
					end
				end
				if x < 0 then x = 0; end
				if x >= iW then break; end
				if y < 0 then y = 0; end
				if y >= iH then y = iH - 1; end
			end
		end
	end

	local function walkFromRight()
		local n = 6 + Map.Rand(5, "");
		for _w = 1, n do
			local x, y = iW - 1, yLo + Map.Rand(vSpan + 4, "") - 2;
			if y < 0 then y = 0; end
			if y >= iH then y = iH - 1; end
			local maxPen = 5 + Map.Rand(math.max(1, math.floor(iW * 0.3)), "");
			local steps = 22 + Map.Rand(45, "");
			for _s = 1, steps do
				if (iW - 1 - x) >= maxPen and Map.Rand(100, "") > 28 then
					break;
				end
				tryMark(x, y, 62 + Map.Rand(25, ""));
				local r = Map.Rand(100, "");
				if r < 40 then
					x = x - 1;
					y = y + Map.Rand(3, "") - 1;
				elseif r < 76 then
					x = x - 1;
				elseif r < 90 then
					y = y + Map.Rand(5, "") - 2;
				else
					local nx, ny = GetHexNeighbor(x, y, 1 + Map.Rand(6, ""), iW, iH, wrapX, wrapY);
					if nx < x then
						x, y = nx, ny;
					elseif nx == x then
						x, y = nx, ny;
					else
						x = x - 1;
						y = y + Map.Rand(3, "") - 1;
					end
				end
				if x < 0 then break; end
				if x >= iW then x = iW - 1; end
				if y < 0 then y = 0; end
				if y >= iH then y = iH - 1; end
			end
		end
	end

	walkFromLeft();
	walkFromRight();

	local seeds = {};
	for k, _ in pairs(seen) do
		seeds[#seeds + 1] = k;
	end
	local thickenIters = 16 + Map.Rand(28, "");
	for _t = 1, thickenIters do
		if #seeds == 0 then
			break;
		end
		local sk = seeds[1 + Map.Rand(#seeds, "")];
		local sx, sy = sk:match("^([^,]+),([^,]+)$");
		sx, sy = tonumber(sx), tonumber(sy);
		if sx == nil then
			break;
		end
		local d = 1 + Map.Rand(6, "");
		local nx, ny = GetHexNeighbor(sx, sy, d, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			local nk = keyXY(nx, ny);
			if not seen[nk] and Map.Rand(100, "") < 52 then
				seen[nk] = true;
				seeds[#seeds + 1] = nk;
			end
		end
	end

	local tiles = {};
	for k, _ in pairs(seen) do
		local sx, sy = k:match("^([^,]+),([^,]+)$");
		sx, sy = tonumber(sx), tonumber(sy);
		if sx ~= nil then
			tiles[#tiles + 1] = { sx, sy };
		end
	end

	local kept = {};
	for _, t in ipairs(tiles) do
		if Map.Rand(100, "") >= 14 then
			kept[#kept + 1] = t;
		end
	end
	tiles = kept;

	if #tiles < 8 then
		return false;
	end

	for _, t in ipairs(tiles) do
		if not isOcean(plotTypes, t[1], t[2], iW, iH) then
			return false;
		end
	end

	for _, t in ipairs(tiles) do
		local idx = pidx(t[1], t[2], iW);
		plotTypes[idx] = Map.Rand(100, "") < 70 and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end

	return true;
end
