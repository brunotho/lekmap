------------------------------------------------------------------------------
--	BlobIsland.lua (recreated from transcript)
--	7-10 tiles, organic irregular mass. Hills 50-60%, mountains by size.
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

local function growCompactBlob(cx, cy, size, iW, iH, wrapX, wrapY)
	local landTiles = {{cx, cy}};
	local frontier = {{cx, cy}};
	local seen = {}; seen[cy * iW + cx + 1] = true;

	while #landTiles < size and #frontier > 0 do
		local r = Map.Rand(#frontier, "") + 1;
		local fx, fy = frontier[r][1], frontier[r][2];
		table.remove(frontier, r);
		for _, n in ipairs(GetHexNeighbors(fx, fy)) do
			local gx = WrapCoord(n[1], iW, wrapX);
			local gy = WrapCoord(n[2], iH, wrapY);
			if gx >= 0 and gx < iW and gy >= 0 and gy < iH and not seen[gy * iW + gx + 1] then
				for _, t in ipairs(landTiles) do
					if IsHexAdjacent(t[1], t[2], gx, gy) then
						landTiles[#landTiles + 1] = {gx, gy};
						frontier[#frontier + 1] = {gx, gy};
						seen[gy * iW + gx + 1] = true;
						break;
					end
				end
			end
		end
	end
	return landTiles;
end

function TryPlaceBlobIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 1;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 6;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local size = 7 + Map.Rand(4, "");
	local landTiles = growCompactBlob(cx, cy, size, params.iW, params.iH, params.wrapX, params.wrapY);
	if #landTiles < 7 then return false; end
	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	DrawBlobIsland(plotTypes, landTiles, params.iW);
	return true;
end

function DrawBlobIsland(plotTypes, landTiles, iW)
	local hillsPct = 50 + Map.Rand(11, "");
	local n = #landTiles;
	local mtnChance = (n <= 6) and 2 or 5;
	for _, t in ipairs(landTiles) do
		local x, y = t[1], t[2];
		local idx = y * iW + x + 1;
		local mt = (Map.Rand(100, "") < hillsPct) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
		if mt == PlotTypes.PLOT_LAND and Map.Rand(100, "") < mtnChance then
			mt = PlotTypes.PLOT_MOUNTAIN;
		end
		plotTypes[idx] = mt;
	end
end
