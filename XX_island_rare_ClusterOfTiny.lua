-- Several tiny one-to-four-tile islands laid out in a loose ellipse, each patch separated by water.

include("X_IslandHelpers");

local ELLIPSE_RX = 4;
local ELLIPSE_RY = 6;
local MAX_SEGMENTS = 7;

local function collectEllipsePositions(clusterRadius)
	local rx = clusterRadius;
	local ry = math.ceil(clusterRadius * ELLIPSE_RY / ELLIPSE_RX);
	local out = {};
	for dy = -ry, ry do
		for dx = -rx, rx do
			local v = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry);
			if v <= 1 then
				out[#out + 1] = {dx, dy};
			end
		end
	end
	return out;
end

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

function TryPlaceClusterOfTinyIslands(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 1;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 4;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local clusterRadius = 2;
	if params.radiusVariance then
		local r = Map.Rand(100, "");
		if r < 15 then clusterRadius = 1;
		elseif r < 90 then clusterRadius = 2;
		else clusterRadius = 3; end
	end

	local positions = collectEllipsePositions(clusterRadius);
	if #positions < 3 then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local segments = {};
	for _, p in ipairs(positions) do
		local gx = WrapCoord(cx + p[1], params.iW, params.wrapX);
		local gy = WrapCoord(cy + p[2], params.iH, params.wrapY);
		if gx >= 0 and gx < params.iW and gy >= 0 and gy < params.iH then
			segments[#segments + 1] = {gx, gy};
		end
	end

	local num1 = 3 + Map.Rand(4, "");
	local has2 = (Map.Rand(100, "") < 50);
	local has3 = (Map.Rand(100, "") < 5);
	local has4 = (Map.Rand(100, "") < 1);

	for i = 1, num1 do
		if #segments < MAX_SEGMENTS and i <= #segments then
			segments[i] = {segments[i][1], segments[i][2], 1};
		end
	end
	if has2 and #segments > num1 then
		segments[num1 + 1] = {segments[num1 + 1][1], segments[num1 + 1][2], 2};
	end
	if has3 and #segments > num1 + 1 then
		segments[num1 + 2] = {segments[num1 + 2][1], segments[num1 + 2][2], 3};
	end
	if has4 and #segments > num1 + 2 then
		segments[num1 + 3] = {segments[num1 + 3][1], segments[num1 + 3][2], 4};
	end

	if #segments > MAX_SEGMENTS then
		for i = 1, #segments - 1 do
			local j = i + Map.Rand(#segments - i, "");
			segments[i], segments[j] = segments[j], segments[i];
		end
		while #segments > MAX_SEGMENTS do segments[#segments] = nil; end
	end

	local allTiles = {};
	for _, seg in ipairs(segments) do
		local x, y = seg[1], seg[2];
		local size = seg[3] or 1;
		allTiles[#allTiles + 1] = {x, y};
		if size >= 2 then
			local dir = Map.Rand(6, "") + 1;
			local nx, ny = GetHexNeighbor(x, y, dir, params.iW, params.iH, params.wrapX, params.wrapY);
			if nx >= 0 and nx < params.iW and ny >= 0 and ny < params.iH then
				allTiles[#allTiles + 1] = {nx, ny};
			end
		end
	end

	if #allTiles < 3 then return false; end
	if not footprintClear(plotTypes, allTiles, params.iW, params.iH) then return false; end

	DrawClusterOfTinyIslands(plotTypes, allTiles, params.iW);
	return true;
end

function DrawClusterOfTinyIslands(plotTypes, landTiles, iW)
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x;
		local r = Map.Rand(100, "");
		if r < 30 then
			plotTypes[idx] = PlotTypes.PLOT_LAND;
		elseif r < 95 then
			plotTypes[idx] = PlotTypes.PLOT_HILLS;
		else
			plotTypes[idx] = PlotTypes.PLOT_MOUNTAIN;
		end
	end
end
