------------------------------------------------------------------------------
--	CrescentIsland.lua
--	Half-moon crescent: 7-9 spine, width 2 at center (rarely 3), tapering to 1 at tips.
--	Outer edge hills (2-4), inner flat, 30-40% hills total. 6 orientations, bias toward open ocean.
------------------------------------------------------------------------------

local CRESCENT_TEMPLATES = {
	{
		{-2, 1, "outer"}, {-1, 2, "outer"}, {-2, 0, "outer"}, {-1, 1, "outer"},
		{-1, 0, "outer"}, {-1, -1, "outer"}, {-1, -2, "tip"},
		{0, 2, "inner"}, {0, 1, "inner"}, {0, 0, "inner"}, {0, -1, "inner"},
	},
	{
		{-2, 2, "outer"}, {-2, 1, "outer"}, {-1, 2, "outer"}, {-2, 0, "outer"},
		{-1, 1, "outer"}, {-1, 0, "outer"}, {-1, -1, "outer"}, {-1, -2, "tip"},
		{0, 2, "inner"}, {0, 1, "inner"}, {0, 0, "inner"}, {0, -1, "inner"},
	},
	{
		{-2, 2, "outer"}, {-2, 1, "outer"}, {-1, 2, "outer"}, {-2, 0, "outer"},
		{-1, 1, "outer"}, {-1, 0, "outer"}, {-2, -1, "outer"}, {-1, -1, "outer"}, {-1, -2, "tip"},
		{0, 2, "inner"}, {0, 1, "inner"}, {0, 0, "inner"}, {0, -1, "inner"},
	},
};

local function rotateHex60(dx, dy, steps)
	for _ = 1, steps do
		local q = dx;
		local r = dy - math.floor((dx - (dx % 2)) / 2);
		dx = q + r;
		dy = -q + math.floor((dx - (dx % 2)) / 2);
	end
	return dx, dy;
end

local function wrapCoord(v, size, doWrap)
	if not doWrap then return v; end
	v = v % size;
	if v < 0 then v = v + size; end
	return v;
end

local function pickRotationTowardOpenOcean(centerX, centerY, landX, landY)
	if not landX or not landY then return Map.Rand(6, ""); end
	local awayDx = centerX - landX;
	local awayDy = centerY - landY;
	local bestDir = 0;
	local bestDot = -999;
	for dir = 0, 5 do
		local vx, vy = rotateHex60(-1, 0, dir);
		local dot = awayDx * vx + awayDy * vy;
		if dot > bestDot then bestDot = dot; bestDir = dir; end
	end
	if Map.Rand(100, "") < 70 then
		return bestDir;
	end
	return Map.Rand(6, "");
end

function TryPlaceCrescentIsland(plotTypes, centerX, centerY, islLandInRing, params)
	if _island_placed and _island_placed.crescent then return false; end
	local pullBack = params.pullBack or 2;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 4;
	local effRadius = islLandInRing - pullBack;
	if effRadius <= effMin or effRadius >= effMax then return false; end
	DrawCrescentIsland(plotTypes, centerX, centerY, params.iW, params.iH, params.wrapX, params.wrapY, params.landX, params.landY);
	if not _island_placed then _island_placed = {}; end
	_island_placed.crescent = true;
	return true;
end

function DrawCrescentIsland(plotTypes, centerX, centerY, iW, iH, wrapX, wrapY, landX, landY)
	local templateIdx = Map.Rand(3, "") + 1;
	local template = CRESCENT_TEMPLATES[templateIdx];
	local rot = pickRotationTowardOpenOcean(centerX, centerY, landX, landY);

	local outerTiles = {};
	local innerTiles = {};
	local tipTiles = {};
	for _, t in ipairs(template) do
		local dx, dy = rotateHex60(t[1], t[2], rot);
		local gx = wrapCoord(centerX + dx, iW, wrapX);
		local gy = wrapCoord(centerY + dy, iH, wrapY);
		if gx >= 0 and gx < iW and gy >= 0 and gy < iH then
			local zone = t[3];
			if zone == "outer" then
				outerTiles[#outerTiles + 1] = {gx, gy};
			elseif zone == "inner" then
				innerTiles[#innerTiles + 1] = {gx, gy};
			else
				tipTiles[#tipTiles + 1] = {gx, gy};
			end
		end
	end

	local targetHillsPct = 30 + Map.Rand(11, "");
	local totalTiles = #outerTiles + #innerTiles + #tipTiles;
	local targetHills = math.max(1, math.floor(totalTiles * targetHillsPct / 100));

	local hillsOuter = math.min(#outerTiles, math.max(2, targetHills - Map.Rand(2, "")));
	local hillsCenter = math.min(2, math.max(0, targetHills - hillsOuter));
	local shuffle = function(t)
		for i = #t, 2, -1 do
			local j = Map.Rand(i, "") + 1;
			t[i], t[j] = t[j], t[i];
		end
	end

	shuffle(outerTiles);
	shuffle(innerTiles);
	local hillsSet = {};
	for i = 1, hillsOuter do
		if outerTiles[i] then
			hillsSet[outerTiles[i][1] .. "," .. outerTiles[i][2]] = true;
		end
	end
	for i = 1, hillsCenter do
		if innerTiles[i] then
			hillsSet[innerTiles[i][1] .. "," .. innerTiles[i][2]] = true;
		end
	end

	for _, t in ipairs(template) do
		local dx, dy = rotateHex60(t[1], t[2], rot);
		local gx = wrapCoord(centerX + dx, iW, wrapX);
		local gy = wrapCoord(centerY + dy, iH, wrapY);
		if gx >= 0 and gx < iW and gy >= 0 and gy < iH then
			local idx = gy * iW + gx + 1;
			if hillsSet[gx .. "," .. gy] then
				plotTypes[idx] = PlotTypes.PLOT_HILLS;
			else
				plotTypes[idx] = PlotTypes.PLOT_LAND;
			end
		end
	end
end
