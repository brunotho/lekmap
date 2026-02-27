------------------------------------------------------------------------------
--	IsthmusIsland.lua (recreated - simplified placeholder)
--	Original: 1 in 5 maps, bridge 4-7 wide E-W, splice/side arm/crescent variants.
--	Placement: valid ocean gap (5+ ocean rows N/S of pangaea). Max 1 per map.
--	TODO: Expand with full bridge, splice, side arm, splinter logic when integrating.
------------------------------------------------------------------------------
include("IslandTypes/IslandHelpers");

function TryPlaceIsthmusIsland(plotTypes, opts)
	if _island_placed and _island_placed.isthmus then return false; end
	if Map.Rand(5, "") ~= 0 then return false; end

	local iW, iH = opts.iW, opts.iH;
	local wrapX = opts.wrapX or false;
	local wrapY = opts.wrapY or false;

	local edgeY = 0;
	if Map.Rand(2, "") == 0 then edgeY = iH - 1; end

	local centerX = math.floor(iW / 2) + Map.Rand(5, "") - 2;
	centerX = WrapCoord(centerX, iW, wrapX);
	if centerX < 2 or centerX >= iW - 2 then return false; end

	local bridgeWidth = 4 + Map.Rand(4, "");
	local halfW = math.floor(bridgeWidth / 2);
	local landTiles = {};
	for dx = -halfW, halfW do
		for dy = -1, 1 do
			local gx = WrapCoord(centerX + dx, iW, wrapX);
			local gy = edgeY + dy;
			if gy >= 0 and gy < iH then
				landTiles[#landTiles + 1] = {gx, gy};
			end
		end
	end

	if #landTiles < 6 then return false; end

	for _, t in ipairs(landTiles) do
		local idx = t[2] * iW + t[1] + 1;
		plotTypes[idx] = (Map.Rand(100, "") < 55) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
	end

	if not _island_placed then _island_placed = {}; end
	_island_placed.isthmus = true;
	return true;
end
