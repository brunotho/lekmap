-- Four or five sharp peaks in a small radius, occasionally a hill instead of a peak.

include("X_IslandHelpers");

local CONFIG = {
	RADIUS = 3,
	OVAL_SEMI_MAJOR = 3,
	OVAL_SEMI_MINOR = 2,
	NUM_PEAKS_MIN = 4,
	NUM_PEAKS_MAX = 5,
	HILL_INSTEAD_PCT = 20,
};

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

function TryPlaceSplinteredCliffsTinyIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 0;
	local effMin = params.effMin or 2;
	local effMax = params.effMax or 4;
	local effRadius = islLandInRing - pullBack;
	if effRadius < effMin or effRadius > effMax then return false; end

	local cx = WrapCoord(centerX, params.iW, params.wrapX);
	local cy = WrapCoord(centerY, params.iH, params.wrapY);
	if cx < 0 or cx >= params.iW or cy < 0 or cy >= params.iH then return false; end

	local orient = Map.Rand(2, "");
	local disk = GetHexDisk(cx, cy, CONFIG.RADIUS, params.iW, params.iH, params.wrapX, params.wrapY);
	local oval = {};
	for _, t in ipairs(disk) do
		local dx = t[1] - cx;
		local dy = t[2] - cy;
		if params.wrapX and math.abs(dx) > params.iW / 2 then
			dx = dx - (dx > 0 and params.iW or -params.iW);
		end
		local ex, ey;
		if orient == 0 then
			ex = dx / CONFIG.OVAL_SEMI_MAJOR;
			ey = dy / CONFIG.OVAL_SEMI_MINOR;
		else
			ex = dy / CONFIG.OVAL_SEMI_MAJOR;
			ey = dx / CONFIG.OVAL_SEMI_MINOR;
		end
		if ex * ex + ey * ey <= 1 then
			oval[#oval + 1] = t;
		end
	end
	if #oval < CONFIG.NUM_PEAKS_MIN then return false; end
	local shuffled = {};
	for i = 1, #oval do shuffled[i] = oval[i]; end
	for i = #shuffled, 2, -1 do
		local j = Map.Rand(i, "") + 1;
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i];
	end

	local numPeaks = CONFIG.NUM_PEAKS_MIN + Map.Rand(CONFIG.NUM_PEAKS_MAX - CONFIG.NUM_PEAKS_MIN + 1, "");
	local landTiles = {};
	for i = 1, math.min(numPeaks, #shuffled) do
		local t = shuffled[i];
		local plotType = (Map.Rand(100, "") < CONFIG.HILL_INSTEAD_PCT) and "hill" or "mountain";
		landTiles[#landTiles + 1] = {t[1], t[2], plotType};
	end

	if not footprintClear(plotTypes, landTiles, params.iW, params.iH) then return false; end

	for _, m in ipairs(landTiles) do
		local idx = m[2] * params.iW + m[1];
		plotTypes[idx] = (m[3] == "mountain") and PlotTypes.PLOT_MOUNTAIN or PlotTypes.PLOT_HILLS;
	end
	return true;
end
