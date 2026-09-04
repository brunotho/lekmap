-- Shore-parallel sine island chain: EW along polar coast, sin wobble, then gap-cut
-- into several islets. Scale inspired by polarMerge arm+gap look (not the EW embrace).
-- Target: span ~8–16 cols, several islets of ~2–6 tiles each.

include("X_IslandHelpers");

local CONFIG = {
	-- Spine length (half on each side of seed): total cols = 2*halfLen+1 → ~11..19
	HALF_LEN_MIN = 5,
	HALF_LEN_RANGE = 5, -- 5..9
	AMP_MIN = 1,
	AMP_RANGE = 2,
	FREQ_SOFT = 0.22,
	FREQ_SOFT_STEP = 0.03,
	FREQ_WILD = 0.36,
	FREQ_WILD_STEP = 0.04,
	SOFT_FREQ_PCT = 55,
	-- After continuous spine: cut water gaps → islets
	ISLET_LEN_MIN = 2,
	ISLET_LEN_RANGE = 5, -- 2..6 spine tiles per islet
	GAP_LEN_MIN = 1,
	GAP_LEN_RANGE = 2, -- 1..2 ocean between islets
	MIN_ISLETS = 3,
	MAX_ISLETS = 5,
	THICKEN_PCT = 55, -- fatter islets (2–6 tiles)
	THICKEN_SECOND_PCT = 22,
	HILLS_PCT = 55,
	MTN_PCT = 8,
	MIN_LAND_TILES = 8,
	MIN_SPAN = 8,
	OCEAN_OFFSET_MIN = 2,
	OCEAN_OFFSET_RANGE = 2, -- 2..3 off shore — more room than hugging the jagged coast
};

local function pidx(x, y, iW)
	return y * iW + x + 1;
end

local function isLand(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	local t = plotTypes[pidx(x, y, iW)];
	return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
end

local function isWater(plotTypes, x, y, iW, iH)
	if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
	return plotTypes[pidx(x, y, iW)] == PlotTypes.PLOT_OCEAN;
end

local function keyXY(x, y)
	return x .. "," .. y;
end

function TryPlaceShoreSineChainIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.shoreSineChain then return false; end

	local pullBack = params.pullBack or 1;
	local effMin = params.effMin;
	if effMin == nil then effMin = 0; end
	local effMax = params.effMax;
	if effMax == nil then effMax = 5; end
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local iW, iH = params.iW, params.iH;
	local wrapX = params.wrapX;
	local wrapY = params.wrapY;
	local cx = WrapCoord(centerX, iW, wrapX);
	local cy = centerY;
	if wrapY then cy = WrapCoord(cy, iH, wrapY); end
	if cx < 0 or cx >= iW or cy < 0 or cy >= iH then return false; end
	if not isWater(plotTypes, cx, cy, iW, iH) then return false; end

	local landY = params.landY;
	local landDirY;
	if type(landY) == "number" then
		landDirY = (landY >= cy) and 1 or -1;
	else
		local midY = math.floor(iH / 2);
		landDirY = (cy >= midY) and -1 or 1;
	end
	local away = -landDirY;

	local baseY = cy;
	if type(landY) == "number" then
		local off = CONFIG.OCEAN_OFFSET_MIN + Map.Rand(CONFIG.OCEAN_OFFSET_RANGE, "sineChainOff");
		baseY = landY + away * off;
		if baseY < 2 or baseY >= iH - 2 or not isWater(plotTypes, cx, baseY, iW, iH) then
			baseY = cy;
		end
	end
	-- Prefer a bit more polar room when seed is already ocean-ward of shore.
	if type(landY) == "number" and math.abs(cy - landY) >= 2 then
		baseY = cy;
	end

	local halfLen = CONFIG.HALF_LEN_MIN + Map.Rand(CONFIG.HALF_LEN_RANGE, "sineChainLen");
	local amp = CONFIG.AMP_MIN + Map.Rand(CONFIG.AMP_RANGE, "sineChainAmp");
	local soft = Map.Rand(100, "") < CONFIG.SOFT_FREQ_PCT;
	local freq = soft
		and (CONFIG.FREQ_SOFT + Map.Rand(3, "") * CONFIG.FREQ_SOFT_STEP)
		or (CONFIG.FREQ_WILD + Map.Rand(3, "") * CONFIG.FREQ_WILD_STEP);
	local phase = Map.Rand(628, "") / 100;

	-- 1) Continuous sine corridor (no gaps yet). Skip only impassable columns.
	local spine = {}; -- ordered by t
	local spineSet = {};
	local minX, maxX = nil, nil;
	for t = -halfLen, halfLen do
		local x = WrapCoord(cx + t, iW, wrapX);
		local y = baseY + math.floor(amp * math.sin(t * freq + phase) + 0.0001) * away;
		local placed = false;
		for nudge = 0, 2 do
			local ty = y + away * nudge;
			if ty >= 1 and ty < iH - 1 and isWater(plotTypes, x, ty, iW, iH) then
				local k = keyXY(x, ty);
				if not spineSet[k] then
					spineSet[k] = true;
					spine[#spine + 1] = { x, ty, t };
					if minX == nil or x < minX then minX = x; end
					if maxX == nil or x > maxX then maxX = x; end
					placed = true;
				end
				break;
			end
		end
		-- keep going even if one column fails (jagged bite); gaps later handle rhythm
		if not placed then
			spine[#spine + 1] = { nil, nil, t, hole = true };
		end
	end

	-- Collapse to only real spine tiles in order (holes become natural gap candidates).
	local solid = {};
	for _, s in ipairs(spine) do
		if not s.hole and s[1] ~= nil then
			solid[#solid + 1] = { s[1], s[2] };
		end
	end
	if #solid < CONFIG.MIN_LAND_TILES then return false; end

	-- Span: prefer linear extent; on wrap use count of solid cols as proxy.
	local span = #solid;
	if minX ~= nil and maxX ~= nil and maxX >= minX then
		span = math.max(span, maxX - minX + 1);
	end
	if span < CONFIG.MIN_SPAN then return false; end

	-- 2) Paint islet / gap pattern along solid spine (polarMerge-style cuts).
	local keep = {};
	local isletCount = 0;
	local i = 1;
	local wantIslet = true;
	while i <= #solid do
		if wantIslet then
			if isletCount >= CONFIG.MAX_ISLETS then
				break;
			end
			local len = CONFIG.ISLET_LEN_MIN + Map.Rand(CONFIG.ISLET_LEN_RANGE, "");
			local n = 0;
			while n < len and i <= #solid do
				keep[#keep + 1] = solid[i];
				i = i + 1;
				n = n + 1;
			end
			if n >= CONFIG.ISLET_LEN_MIN then
				isletCount = isletCount + 1;
			end
			wantIslet = false;
		else
			local glen = CONFIG.GAP_LEN_MIN + Map.Rand(CONFIG.GAP_LEN_RANGE, "");
			i = i + glen;
			wantIslet = true;
		end
	end
	if isletCount < CONFIG.MIN_ISLETS then return false; end
	if #keep < CONFIG.MIN_LAND_TILES then return false; end

	-- 3) Thicken into 2–6 tile islets.
	local landTiles = {};
	local landSet = {};
	for _, t in ipairs(keep) do
		local k = keyXY(t[1], t[2]);
		if not landSet[k] then
			landSet[k] = true;
			landTiles[#landTiles + 1] = { t[1], t[2] };
		end
	end
	for _, t in ipairs(keep) do
		if Map.Rand(100, "") < CONFIG.THICKEN_PCT then
			local candidates = {
				{ t[1], t[2] + away },
				{ WrapCoord(t[1] + 1, iW, wrapX), t[2] },
				{ WrapCoord(t[1] - 1, iW, wrapX), t[2] },
				{ t[1], t[2] - away }, -- mild shoreward only if still ocean
			};
			local added = 0;
			for _, c in ipairs(candidates) do
				local x, y = c[1], c[2];
				if y >= 1 and y < iH - 1 and isWater(plotTypes, x, y, iW, iH) then
					local k = keyXY(x, y);
					if not landSet[k] then
						landSet[k] = true;
						landTiles[#landTiles + 1] = { x, y };
						added = added + 1;
						if added >= 1 and Map.Rand(100, "") >= CONFIG.THICKEN_SECOND_PCT then
							break;
						end
						if added >= 2 then break; end
					end
				end
			end
		end
	end

	for _, t in ipairs(landTiles) do
		if not isWater(plotTypes, t[1], t[2], iW, iH) then return false; end
	end
	if #landTiles < CONFIG.MIN_LAND_TILES then return false; end

	-- Reject if we somehow collapsed to one tiny blob (bbox too small).
	local bx0, bx1, by0, by1 = landTiles[1][1], landTiles[1][1], landTiles[1][2], landTiles[1][2];
	for _, t in ipairs(landTiles) do
		if t[1] < bx0 then bx0 = t[1]; end
		if t[1] > bx1 then bx1 = t[1]; end
		if t[2] < by0 then by0 = t[2]; end
		if t[2] > by1 then by1 = t[2]; end
	end
	local bboxW = bx1 - bx0 + 1;
	if bboxW < CONFIG.MIN_SPAN and #landTiles < 12 then
		-- wrap-friendly: if many tiles but bbox small, still OK if isletCount ok
		if isletCount < CONFIG.MIN_ISLETS then return false; end
	elseif bboxW < CONFIG.MIN_SPAN then
		return false;
	end

	for _, t in ipairs(landTiles) do
		local r = Map.Rand(100, "");
		local pt;
		if r < CONFIG.MTN_PCT then
			pt = PlotTypes.PLOT_MOUNTAIN;
		elseif r < CONFIG.MTN_PCT + CONFIG.HILLS_PCT then
			pt = PlotTypes.PLOT_HILLS;
		else
			pt = PlotTypes.PLOT_LAND;
		end
		plotTypes[pidx(t[1], t[2], iW)] = pt;
	end

	if not _island_placed then _island_placed = {}; end
	_island_placed.shoreSineChain = true;
	return true;
end
