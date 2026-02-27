------------------------------------------------------------------------------
--	PangaeaIslands.lua
--	Dot islands only. Sibling to main Pangaea script.
------------------------------------------------------------------------------
include("IslandTypes/IslandHelpers");
include("IslandTypes/common/DotIsland");

local IslandTypeOdds = {
	{ type = "dot", tier = "common", pullBack = 1, effMax = 6, budget = 1 },
};

local IslandTypePlace = {
	dot = TryPlaceDotIsland,
};

local function GetBudget(islandType)
	for _, e in ipairs(IslandTypeOdds) do
		if e.type == islandType then return e.budget or 1; end
	end
	return 1;
end

local function GetPlaceParams(islandType, minIslandSize, maxIslandSize)
	for _, e in ipairs(IslandTypeOdds) do
		if e.type == islandType and e.pullBack then
			local effMin = e.effMin or ((1 + Map.Rand(3, "")) - e.pullBack - 1);
			local effMax = e.effMax;
			return { pullBack = e.pullBack, effMin = effMin, effMax = effMax };
		end
	end
	return { pullBack = 1, effMin = 1, effMax = 6 };
end

local function TryPlaceIsland(plotTypes, x, y, islLandInRing, opts, forceType)
	local islandType = forceType or "dot";
	local params = GetPlaceParams(islandType, opts.minIslandSize, opts.maxIslandSize);
	params.iW = opts.iW;
	params.iH = opts.iH;
	params.wrapX = opts.wrapX;
	params.wrapY = opts.wrapY;
	params.landX = opts.landX;
	params.landY = opts.landY;
	if opts.attempt then params.attempt = opts.attempt; end
	local placed = IslandTypePlace[islandType](plotTypes, x, y, islLandInRing, params);
	return placed, islandType;
end

------------------------------------------------------------------------------
function GeneratePangaeaIslands(self)
	local WorldSizeTypes = {};
	for row in GameInfo.Worlds() do
		WorldSizeTypes[row.Type] = row.ID;
	end
	local sizekey = Map.GetWorldSize();

	local islandQty = {
		[WorldSizeTypes.WORLDSIZE_DUEL]     = 5,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 16,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 24,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 32,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 52,
		[WorldSizeTypes.WORLDSIZE_HUGE]     = 77
	};

	local iW, iH = Map.GetGridSize();
	local wrapX = Map:IsWrapX();
	local wrapY = false;
	local odd = firstRingYIsOdd;
	local even = firstRingYIsEven;
	local minIslandSize = 1;
	local maxIslandSize = 5;
	local escapeRedo = 500;
	local redoMap = false;

	local islandSetting = Map.GetCustomOption(15);
	local totalIslands;
	if islandSetting < 26 then
		totalIslands = Map.GetCustomOption(15) - 1;
	elseif islandSetting == 26 then
		totalIslands = Map.Rand(5, "") + 6;
	elseif islandSetting == 27 then
		totalIslands = Map.Rand(5, "") + 8;
	else
		totalIslands = Map.Rand(5, "") + 10;
	end
	maxIslandSize = 3;

	local consumedBudget = 0;
	local BUDGET_TOLERANCE = 0.4;

	local opts = {
		minIslandSize = minIslandSize, maxIslandSize = maxIslandSize,
		iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY,
		landX = 0, landY = 0
	};

	local function tryOneSpot(attempt)
		local x = Map.Rand(iW, "");
		local y = 3 + Map.Rand((iH - 6), "");
		local plotIndex = y * iW + x;
		if self.plotTypes[plotIndex] ~= PlotTypes.PLOT_OCEAN then return false; end
		local islLandInRing, landX, landY, landPlot = 0, 0, 0, 0;
		local spotOpts = { minIslandSize = minIslandSize, maxIslandSize = maxIslandSize, iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY, landX = 0, landY = 0 };
		if attempt then spotOpts.attempt = attempt; end
		for ripple_radius = 1, 5 do
			local currentX = x - ripple_radius;
			local currentY = y;
			for direction_index = 1, 6 do
				for plot_to_handle = 1, ripple_radius do
					local plot_adjustments;
					if currentY / 2 > math.floor(currentY / 2) then
						plot_adjustments = odd[direction_index];
					else
						plot_adjustments = even[direction_index];
					end
					local nextX = currentX + plot_adjustments[1];
					local nextY = currentY + plot_adjustments[2];
					if wrapX == false and (nextX < 0 or nextX >= iW) then
					elseif wrapY == false and (nextY < 0 or nextY >= iH) then
					else
						local realX = nextX;
						local realY = nextY;
						if wrapX then realX = realX % iW; end
						if wrapY then realY = realY % iH; end
						local scanPlotIndex = realY * iW + realX;
						if self.plotTypes[scanPlotIndex] == PlotTypes.PLOT_LAND then
							islLandInRing = ripple_radius;
							landPlot = scanPlotIndex;
							landX = realX;
							landY = realY;
							break;
						end
						currentX, currentY = nextX, nextY;
					end
				end
				if islLandInRing ~= 0 then break; end
			end
			if islLandInRing ~= 0 then break; end
		end
		if islLandInRing == 0 or self.plotTypes[landPlot] ~= PlotTypes.PLOT_LAND then return false; end
		spotOpts.landX = landX;
		spotOpts.landY = landY;
		return TryPlaceIsland(self.plotTypes, x, y, islLandInRing, spotOpts, "dot");
	end

	while math.max(0, totalIslands - consumedBudget) > BUDGET_TOLERANCE and escapeRedo > 0 do
		local placed, islandType = tryOneSpot();
		if placed then
			consumedBudget = consumedBudget + GetBudget(islandType);
		end
		escapeRedo = escapeRedo - 1;
	end

	if escapeRedo == 0 then
		redoMap = true;
	end
	return redoMap;
end
