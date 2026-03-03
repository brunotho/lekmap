------------------------------------------------------------------------------
--	NormalIslandLegacy.lua
--	Draws one "normal" island: center + rings of land/hills/ocean (noisy disk).
--	Called from Pangaea Fractal island loop with plotTypes, center, radius, map size, wrap.
------------------------------------------------------------------------------

local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
local firstRingYIsOdd  = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};

------------------------------------------------------------------------------
-- Try to place a normal island. Returns true if placed.
-- params: pullBack, effMin, effMax, iW, iH, wrapX, wrapY
------------------------------------------------------------------------------
function TryPlaceNormalIsland(plotTypes, centerX, centerY, islLandInRing, params)
	local pullBack = params.pullBack or 3;
	local effMin = params.effMin or 1;
	local effMax = params.effMax or 3;
	local effRadius = islLandInRing - pullBack;
	if effRadius <= effMin or effRadius >= effMax then return false; end
	DrawNormalIslandLegacy(plotTypes, centerX, centerY, effRadius, params.iW, params.iH, params.wrapX, params.wrapY);
	return true;
end

------------------------------------------------------------------------------
-- Draw one island at (centerX, centerY) with given radius (in rings).
-- plotTypes: 1-based table to mutate. radius: effective ring count (e.g. 2).
------------------------------------------------------------------------------
function DrawNormalIslandLegacy(plotTypes, centerX, centerY, radius, iW, iH, wrapX, wrapY)
	local odd = firstRingYIsOdd;
	local even = firstRingYIsEven;
	local startingPlot = centerY * iW + centerX + 1;

	local islThresh = 0;
	local landvarDefault = 10;
	local locationRnd = Map.Rand(100, "");
	local hill_thresh = 70;
	local inner_hill_thresh = 50;

	if locationRnd > inner_hill_thresh then
		plotTypes[startingPlot] = PlotTypes.PLOT_LAND;
	else
		plotTypes[startingPlot] = PlotTypes.PLOT_HILLS;
	end

	local nextX, nextY, plot_adjustments;
	for ripple_radius = 1, radius do
		local currentX = centerX - ripple_radius;
		local currentY = centerY;
		for direction_index = 1, 6 do
			for plot_to_handle = 1, ripple_radius do
				if currentY / 2 > math.floor(currentY / 2) then
					plot_adjustments = odd[direction_index];
				else
					plot_adjustments = even[direction_index];
				end
				nextX = currentX + plot_adjustments[1];
				nextY = currentY + plot_adjustments[2];
				if wrapX == false and (nextX < 0 or nextX >= iW) then
				elseif wrapY == false and (nextY < 0 or nextY >= iH) then
				else
					local realX = nextX;
					local realY = nextY;
					if wrapX then realX = realX % iW; end
					if wrapY then realY = realY % iH; end
					local plotIndex = realY * iW + realX + 1;

					local thisislandvar = Map.Rand(30, "") + landvarDefault;
					if _lek_islands_nerfed then
						if ripple_radius == 1 then
							islThresh = Map.Rand(50, "") + thisislandvar;
						elseif ripple_radius == 2 then
							islThresh = Map.Rand(45, "") + (thisislandvar / 1.25);
						elseif ripple_radius == 3 then
							islThresh = Map.Rand(37, "") + (thisislandvar / 1.5);
						else
							islThresh = Map.Rand(30, "") + (thisislandvar / 2);
						end
					else
						if ripple_radius == 1 then
							islThresh = Map.Rand(50, "") + thisislandvar;
						elseif ripple_radius == 2 then
							islThresh = Map.Rand(45, "") + (thisislandvar / 1.25);
						elseif ripple_radius == 3 then
							islThresh = Map.Rand(37, "") + (thisislandvar / 1.5);
						else
							islThresh = Map.Rand(30, "") + (thisislandvar / 2);
						end
					end

					local islRand = Map.Rand(100, "");
					local islHill = Map.Rand(100, "");
					if islRand > islThresh then
						plotTypes[plotIndex] = PlotTypes.PLOT_OCEAN;
						landvarDefault = landvarDefault + 5;
					else
						if islHill <= hill_thresh then
							plotTypes[plotIndex] = PlotTypes.PLOT_LAND;
						else
							plotTypes[plotIndex] = PlotTypes.PLOT_HILLS;
						end
					end
					currentX, currentY = nextX, nextY;
				end
			end
		end
	end
end
