-- Drafts and places pangaea-fractal islands on plotTypes.
print("### PangaeaIslands: loading ###");
include("X_IslandHelpers");
include("XX_island_common_Dot");
include("XX_island_common_Pebble");
include("XX_island_common_Strip");
include("XX_island_common_SplinteredCliffsTiny");
include("XX_island_uncommon_WaterRift");
include("XX_island_uncommon_Chunk");
include("XX_island_uncommon_Lollipop");
include("XX_island_uncommon_Barbell");
include("XX_island_uncommon_Wishbone");
include("XX_island_uncommon_Snake");
include("XX_island_uncommon_SplinteredMountains");
include("XX_island_uncommon_SplinteredCliffs");
include("XX_island_uncommon_TwinBay");
include("XX_island_uncommon_MountainWall");
include("XX_island_uncommon_RidgePeak");
include("XX_island_uncommon_LakeRidge");
include("XX_island_uncommon_ClusterOfTiny");
include("XX_island_rare_PolarMerge");
include("XX_island_rare_Horn");
include("XX_island_rare_ShatteredRing");
include("XX_island_rare_SteppingStone");
include("XX_island_rare_JunglePeak");
include("XX_island_rare_SinaiIsland");
include("XX_island_rare_Crescent");
include("XX_island_rare_SolomonsMinesIsland");
include("XX_island_rare_VolcanicRing");
include("XX_island_rare_GeothermalIsland");
include("XX_island_rare_WrapSoftLandbridge");
-- include("XX_island_rare_FjordPeninsula");
-- include("XX_island_rare_BrokenHeart");
-- include("XX_island_rare_EdgeOfWorld");
-- include("XX_island_rare_EllipseArchipelago");
-- include("XX_island_rare_RiverDelta");

-- Island placement knobs:
-- islLandInRing = nearest-land ring from candidate ocean seed.
-- effRadius = islLandInRing - pullBack
-- placement passes when effMin <= effRadius <= effMax
-- Equivalent ring bounds:
--   (pullBack + effMin) <= islLandInRing <= (pullBack + effMax)
-- lower pullBack/eff* -> generally closer to mainland.
local CommonIslands = {
	{ type = "dot",                  odds = 5, pullBack = 1, effMin = 0, effMax = 0, budget = 0.10 },
	{ type = "pebble",               odds = 2, pullBack = 1, effMin = 0, effMax = 0, budget = 0.38 },
	{ type = "strip",                odds = 2, pullBack = 1, effMin = 0, effMax = 1, budget = 0.42 },
	{ type = "splinteredCliffsTiny", odds = 3, pullBack = 1, effMin = 0, effMax = 2, budget = 0.23 },
};

local UncommonIslands = {
	{ type = "mountainWall",        odds = 2, pullBack = 0, effMin = 0, effMax = 4, budget = 0.60 },
	{ type = "ridgePeak",           odds = 3, pullBack = 0, effMin = 0, effMax = 3, budget = 1.31 },
	{ type = "splinteredCliffs",    odds = 2, pullBack = 0, effMin = 2, effMax = 5, budget = 0.72, fragile = true },
	{ type = "chunk",               odds = 1, pullBack = 1, effMin = 2, effMax = 5, budget = 0.66 },
	{ type = "barbell",             odds = 4, pullBack = 1, effMin = 0, effMax = 5, budget = 0.67 },
	{ type = "snake",               odds = 3, pullBack = 1, effMin = 1, effMax = 4, budget = 1.13 },
	{ type = "lollipop",            odds = 2, pullBack = 2, effMin = 1, effMax = 4, budget = 1.02 },
	{ type = "wishbone",            odds = 5, pullBack = 1, effMin = 1, effMax = 3, budget = 0.75 },
	{ type = "twinBay",             odds = 1, pullBack = 1, effMin = 1, effMax = 3, budget = 1.08 },
	{ type = "shatteredRing",       odds = 3, pullBack = 1, effMin = 2, effMax = 5, budget = 1.67 },
	{ type = "clusterOfTiny",      	odds = 5, pullBack = 1, effMin = 0, effMax = 3, budget = 0.5, fragile = true },
	{ type = "waterRift",           odds = 2, pullBack = 0, effMin = 4, effMax = 5, budget = 1.17 },
};

local RareIslands = {
	{ type = "polarMerge",         	odds = 6, pullBack = 3, effMin = 3, effMax = 5, budget = 2.5 },
	{ type = "steppingStone",      	odds = 1, pullBack = 2, effMin = 2, effMax = 4, budget = 0.9 },
	{ type = "crescent",           	odds = 1, pullBack = 2, effMin = 2, effMax = 4, budget = 1.62 },
	{ type = "volcanicRing",       	odds = 1, pullBack = 1, effMin = 2, effMax = 5, budget = 1.85 },
	{ type = "solomonsMinesIsland", odds = 1, pullBack = 2, effMin = 2, effMax = 5, budget = 1.67 },
	{ type = "sinaiIsland",        	odds = 1, pullBack = 2, effMin = 2, effMax = 5, budget = 1.5 },
	{ type = "geothermalIsland",  	odds = 2, pullBack = 2, effMin = 2, effMax = 5, budget = 1.2 },
	{ type = "wrapSoftLandbridge",  odds = 2, pullBack = 2, effMin = 2, effMax = 5, budget = 0.55 },
	{ type = "junglePeak",         	odds = 2, pullBack = 3, effMin = 2, effMax = 5, budget = 1.65 },
	{ type = "lakeRidge",          	odds = 2, pullBack = 0, effMin = 0, effMax = 0, budget = 0 },
	-- { type = "fjordPeninsula",     odds = 1, pullBack = 4, effMin = 4, effMax = 6, budget = 0.65 },
	-- { type = "BrokenHeart",        odds = 1, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	-- { type = "EdgeOfWorld",        odds = 1, pullBack = 0, effMin = 0, effMax = 7, budget = 1 },
	-- { type = "EllipseArchipelago", odds = 1, pullBack = 0, effMin = 0, effMax = 7, budget = 2 },
	-- { type = "riverDelta",         odds = 1, pullBack = 0, effMin = 0, effMax = 0, budget = 1.04 },
};

local IslandTypePlace = {
	dot = TryPlaceDotIsland,
	pebble = TryPlacePebbleIsland,
	strip = TryPlaceStripIsland,
	splinteredCliffsTiny = TryPlaceSplinteredCliffsTinyIsland,
	waterRift = TryPlaceWaterRift,
	chunk = TryPlaceChunkIsland,
	lollipop = TryPlaceLollipopIsland,
	barbell = TryPlaceBarbellIsland,
	wishbone = TryPlaceWishboneIsland,
	snake = TryPlaceSnakeIsland,
	splinteredMountains = TryPlaceSplinteredMountainsIsland,
	splinteredCliffs = TryPlaceSplinteredCliffsIsland,
	twinBay = TryPlaceTwinBayIslands,
	mountainWall = TryPlaceMountainWallIsland,
	ridgePeak = TryPlaceRidgePeak,
	horn = TryPlaceHornIsland,
	shatteredRing = TryPlaceShatteredRingIsland,
	steppingStone = TryPlaceSteppingStoneIsland,
	clusterOfTiny = TryPlaceClusterOfTinyIslands,
	junglePeak = TryPlaceJunglePeakIsland,
	sinaiIsland = TryPlaceSinaiIsland,
	crescent = TryPlaceCrescentIsland,
	solomonsMinesIsland = TryPlaceSolomonsMinesIsland,
	volcanicRing = TryPlaceVolcanicRing,
	geothermalIsland = TryPlaceGeothermalIsland,
	wrapSoftLandbridge = TryPlaceWrapSoftLandbridge,
	-- fjordPeninsula = TryPlaceFjordPeninsulaIsland,
	-- BrokenHeart = TryPlaceBrokenHeartIsland,
	-- EdgeOfWorld = TryPlaceEdgeOfWorldIsland,
	-- EllipseArchipelago = TryPlaceEllipseArchipelagoIsland,
	-- riverDelta = TryPlaceRiverDeltaIsland,
};

local AllIslandTypeTables = {
	{ tier = "common", pool = CommonIslands },
	{ tier = "uncommon", pool = UncommonIslands },
	{ tier = "rare", pool = RareIslands },
};

local PANGAEA_ISLAND_TOTAL_BUDGET = 9;
local PANGAEA_COMMON_FILL_MAX_PASSES = 10000;
local PANGAEA_ISLAND_BUDGET_RETRY = true;
local PANGAEA_ISLAND_MAX_TRIES_PER_BUDGET = 80;
local PANGAEA_ISLAND_BUDGET_FLOOR = 5;
local PANGAEA_SHORE_SMALL_ISLAND_ATTEMPTS = 600;
local PANGAEA_COMMON_SMALL_ISLAND_TRIES_TIGHT = 500;
local PANGAEA_COMMON_SMALL_ISLAND_TRIES_LOOSE = 350;
local PANGAEA_COMMON_FILL_IDLE_BREAK = 800;

local function GetOptEntry(islandType)
	for _, t in ipairs(AllIslandTypeTables) do
		for _, e in ipairs(t.pool) do
			if e.type == islandType then e.tier = t.tier; return e; end
		end
	end
	return nil;
end

local function GetBudget(islandType)
	local e = GetOptEntry(islandType);
	return e and e.budget or 1;
end

local function IsMaxOne(islandType)
	local e = GetOptEntry(islandType);
	return e ~= nil and (e.tier == "rare");
end

local function GetPlaceParams(islandType)
	local e = GetOptEntry(islandType);
	if e and e.pullBack then
		local effMin = e.effMin or ((1 + Map.Rand(3, "")) - e.pullBack - 1);
		return { pullBack = e.pullBack, effMin = effMin, effMax = e.effMax };
	end
	return { pullBack = 1, effMin = 1, effMax = 6 };
end

local function TryPlaceIsland(plotTypes, x, y, islLandInRing, opts, forceType)
	local islandType = forceType or "dot";
	if not IslandTypePlace[islandType] then return false, islandType; end
	local params = GetPlaceParams(islandType);
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

local function DraftOneFromTier(pool, excludeSet)
	local totalWeight = 0;
	for _, e in ipairs(pool) do
		if not (IsMaxOne(e.type) and excludeSet[e.type]) then
			totalWeight = totalWeight + e.odds;
		end
	end
	if totalWeight == 0 then return nil; end
	local roll = Map.Rand(totalWeight, "");
	local cumulative = 0;
	for _, e in ipairs(pool) do
		if not (IsMaxOne(e.type) and excludeSet[e.type]) then
			cumulative = cumulative + e.odds;
			if roll < cumulative then return e.type; end
		end
	end
	return nil;
end

local NAMED_PRIORITY = {
	polarMerge = 1,
	wrapSoftLandbridge = 3,
};
local TIER_BASE_PRIORITY = {
	rare        = 5,
	uncommon    = 6,
	common      = 8,
};

local function GetDraftPriority(islandType)
	if NAMED_PRIORITY[islandType] then return NAMED_PRIORITY[islandType]; end
	local e = GetOptEntry(islandType);
	if not e then return 99; end
	if e.fragile then return 7; end
	return TIER_BASE_PRIORITY[e.tier] or 99;
end

function GeneratePangaeaIslands(self, genOpts)
	genOpts = genOpts or {};
	local budgetRetry = genOpts.budgetRetry;
	if budgetRetry == nil then budgetRetry = PANGAEA_ISLAND_BUDGET_RETRY; end
	local maxTriesPerBudget = genOpts.maxTriesPerBudget or PANGAEA_ISLAND_MAX_TRIES_PER_BUDGET;
	local budgetFloor = genOpts.budgetFloor or PANGAEA_ISLAND_BUDGET_FLOOR;

	local function dbg2(msg) print(msg); end
	dbg2("### GeneratePangaeaIslands: start [" .. os.date("%H:%M:%S") .. "] ###");
	local iW, iH = Map.GetGridSize();
	local n = iW * iH;
	local snapshot = {};
	for i = 1, n do
		snapshot[i] = self.plotTypes[i];
	end

	local pangeaTiles = {};
	for i = 0, (iW * iH) - 1 do
		local t = snapshot[i + 1];
		if t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN then
			pangeaTiles[i + 1] = true;
		end
	end

	local wrapX = Map:IsWrapX();
	local wrapY = false;
	local odd = firstRingYIsOdd;
	local even = firstRingYIsEven;

	local opts = {
		iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY,
		landX = 0, landY = 0
	};

	local function resetIslandGlobals()
		_island_placed = {};
		_sri_pada_island_plot = nil;
		_solomons_island_mines_plot = nil;
		_solomons_island_nw_type = nil;
		_krakatoa_island_plot = nil;
		_sinai_island_plot = nil;
		_geothermal_island_plot = nil;
		_geothermal_island_nw_type = nil;
		_geothermal_is_krakatoa = nil;
		_geothermal_snow_plot_indices = nil;
		_geothermal_forest_ring_indices = nil;
	end

	local function restorePlotTypes()
		for i = 1, n do
			self.plotTypes[i] = snapshot[i];
		end
	end

	local function runOnce(TOTAL_BUDGET)
		restorePlotTypes();
		resetIslandGlobals();

	local excludeSet = {};
	local drafted = {};
	local draftEstimate = 0;

	local function draftAdd(t)
		if t then
			drafted[#drafted + 1] = t;
			if IsMaxOne(t) then excludeSet[t] = true; end
		end
	end

	local numRare = 1 + Map.Rand(4, "");
	local numUncommon = 1 + Map.Rand(6, "");

	for _ = 1, numRare do
		for _try = 1, 50 do
			local pick = DraftOneFromTier(RareIslands, excludeSet);
			if not pick then break; end
			local b = GetBudget(pick);
			if draftEstimate + b <= TOTAL_BUDGET then
				draftAdd(pick);
				draftEstimate = draftEstimate + b;
				break;
			end
		end
	end
	for _ = 1, numUncommon do
		for _try = 1, 50 do
			local pick = DraftOneFromTier(UncommonIslands, excludeSet);
			if not pick then break; end
			local b = GetBudget(pick);
			if draftEstimate + b <= TOTAL_BUDGET then
				draftAdd(pick);
				draftEstimate = draftEstimate + b;
				break;
			end
		end
	end

	table.sort(drafted, function(a, b)
		return GetDraftPriority(a) < GetDraftPriority(b);
	end);

	local islandsPlaced = 0;
	local function tryOneSpot(forceType, attempt, overrideSpot)
		local x, y;
		if overrideSpot and type(overrideSpot) == "table" and #overrideSpot >= 2 then
			x, y = overrideSpot[1], overrideSpot[2];
		else
			x = Map.Rand(iW, "");
			y = nil;
		end
		if y == nil then
			if forceType == "junglePeak" then
				if attempt and attempt >= 25 then
					y = 3 + Map.Rand((iH - 6), "");
				else
					local bandHeight = 6 + Map.Rand(5, "");
					local centerY = math.floor(iH / 2);
					local jungleMin = math.max(2, centerY - math.floor(bandHeight / 2));
					local jungleMax = math.min(iH - 3, jungleMin + bandHeight - 1);
					y = jungleMin + Map.Rand(math.max(1, jungleMax - jungleMin + 1), "");
				end
			elseif forceType == "solomonsMinesIsland" then
				if attempt and attempt >= 60 then
					y = 3 + Map.Rand((iH - 6), "");
				else
					local bandHeight = 5 + Map.Rand(4, "");
					if Map.Rand(2, "") == 0 then
						local dMin = math.max(2, math.floor(0.22 * iH));
						local dMax = math.min(iH - 3, math.floor(0.34 * iH));
						if dMax >= dMin then
							local c0 = dMin + Map.Rand(math.max(1, dMax - dMin + 1), "");
							local lo = math.max(2, c0 - math.floor(bandHeight / 2));
							local hi = math.min(iH - 3, lo + bandHeight - 1);
							y = lo + Map.Rand(math.max(1, hi - lo + 1), "");
						else
							y = 3 + Map.Rand((iH - 6), "");
						end
					else
						local dMin = math.max(2, math.floor(0.66 * iH));
						local dMax = math.min(iH - 3, math.floor(0.78 * iH));
						if dMax >= dMin then
							local c0 = dMin + Map.Rand(math.max(1, dMax - dMin + 1), "");
							local lo = math.max(2, c0 - math.floor(bandHeight / 2));
							local hi = math.min(iH - 3, lo + bandHeight - 1);
							y = lo + Map.Rand(math.max(1, hi - lo + 1), "");
						else
							y = 3 + Map.Rand((iH - 6), "");
						end
					end
				end
			elseif forceType == "geothermalIsland" then
				if attempt and attempt >= 25 then
					y = 3 + Map.Rand((iH - 6), "");
				else
					if iH > 8 then
						if Map.Rand(2, "") == 0 then
							y = 3 + Map.Rand(2, "");
						else
							y = (iH - 4) + Map.Rand(2, "");
						end
					else
						y = 3 + Map.Rand(math.max(1, iH - 6), "");
					end
				end
			elseif forceType == "sinaiIsland" then
				if attempt and attempt >= 50 then
					y = 3 + Map.Rand((iH - 6), "");
				else
					local northMin = math.max(2, math.floor(0.22 * iH));
					local northMax = math.min(iH - 3, math.floor(0.36 * iH));
					local southMin = math.max(2, math.floor(0.64 * iH));
					local southMax = math.min(iH - 3, math.floor(0.78 * iH));
					if Map.Rand(2, "") == 0 and northMax >= northMin then
						y = northMin + Map.Rand(math.max(1, northMax - northMin + 1), "");
					elseif southMax >= southMin then
						y = southMin + Map.Rand(math.max(1, southMax - southMin + 1), "");
					else
						y = northMin + Map.Rand(math.max(1, northMax - northMin + 1), "");
					end
				end
			else
				y = 3 + Map.Rand((iH - 6), "");
			end
		end
		if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
		local plotIndex = y * iW + x + 1;
		if self.plotTypes[plotIndex] ~= PlotTypes.PLOT_OCEAN then return false; end
		local islLandInRing, landX, landY, landPlot = 0, 0, 0, 0;
		local spotOpts = { iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY, landX = 0, landY = 0 };
		if attempt then spotOpts.attempt = attempt; end
		for ripple_radius = 1, 6 do
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
					local scanPlotIndex = realY * iW + realX + 1;
					if self.plotTypes[scanPlotIndex] ~= PlotTypes.PLOT_OCEAN then
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
		if islLandInRing == 0 or self.plotTypes[landPlot] == PlotTypes.PLOT_OCEAN then return false; end
		if not pangeaTiles[landPlot] then return false; end
		if forceType == "clusterOfTiny" and islLandInRing > 0 and attempt ~= nil and attempt < 50 then
			if islLandInRing >= 5 then return false; end
			if islLandInRing >= 4 and Map.Rand(100, "") < 78 then return false; end
			if islLandInRing == 3 and Map.Rand(100, "") < 35 then return false; end
		end
		spotOpts.landX = landX;
		spotOpts.landY = landY;
		spotOpts.nearPangea = pangeaTiles[landPlot];  -- landPlot is 1-based
		return TryPlaceIsland(self.plotTypes, x, y, islLandInRing, spotOpts, forceType);
	end

	local spentBudget = 0;
	local function placeAndCount(islandType, attemptsCap)
		local placed = false;
		local attempts = 0;
		local cap = attemptsCap or 180;
		while not placed and attempts < cap do
			placed = tryOneSpot(islandType, attempts);
			attempts = attempts + 1;
		end
		if placed then
			spentBudget = spentBudget + GetBudget(islandType);
			islandsPlaced = islandsPlaced + 1;
		end
		return placed;
	end

	local shoreDots = 12 + Map.Rand(5, "");
	local shorePebbles = 1 + Map.Rand(4, "");
	for _ = 1, shoreDots do placeAndCount("dot", PANGAEA_SHORE_SMALL_ISLAND_ATTEMPTS); end
	for _ = 1, shorePebbles do placeAndCount("pebble", PANGAEA_SHORE_SMALL_ISLAND_ATTEMPTS); end

	dbg2("### GeneratePangaeaIslands: placing drafted islands ###");

	for _, islandType in ipairs(drafted) do
		dbg2("### placing: " .. tostring(islandType) .. " ###");
		if islandType == "polarMerge" then
			if TryPlacePolarMerge(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			end
		--[[ elseif islandType == "fjordPeninsula" then
			local placedFjord = false;
			for _fj = 1, 45 do
				if TryPlaceFjordPeninsulaIsland(self.plotTypes, opts) then
					placedFjord = true;
					break;
				end
			end
			if placedFjord then
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			end
		]]
		elseif islandType == "steppingStone" then
			if TryPlaceSteppingStoneIsland(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			end
		elseif islandType == "wrapSoftLandbridge" then
			local placedBridge = false;
			for _wb = 1, 28 do
				if TryPlaceWrapSoftLandbridge(self.plotTypes, opts) then
					placedBridge = true;
					break;
				end
			end
			if placedBridge then
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			end
		elseif islandType == "mainlandRidge" then
			if TryPlaceMainlandRidge(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			end
		elseif islandType == "lakeRidge" then
			if TryPlaceLakeRidge(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			end
		elseif IslandTypePlace[islandType] then
			local maxAttempts = 180;
			if islandType == "solomonsMinesIsland" then
				maxAttempts = 300;
			end
			placeAndCount(islandType, maxAttempts);
		end
	end

	dbg2("### GeneratePangaeaIslands: drafted done, filling commons (until spent >= " .. TOTAL_BUDGET .. ", est at draft was " .. draftEstimate .. ") ###");
	local commonPass = 0;
	local idleCommonPasses = 0;
	while spentBudget + 0.004 < TOTAL_BUDGET and commonPass < PANGAEA_COMMON_FILL_MAX_PASSES do
		commonPass = commonPass + 1;
		if commonPass == 1 or commonPass % 200 == 0 then
			dbg2("### common fill pass " .. commonPass .. ", spent " .. spentBudget .. "/" .. TOTAL_BUDGET .. " ###");
		end
		local remaining = TOTAL_BUDGET - spentBudget;
		local islandType;
		if remaining <= 0.15 then
			islandType = "dot";
		elseif remaining <= 0.45 then
			islandType = (Map.Rand(2, "") == 0) and "dot" or "pebble";
		elseif remaining <= 0.95 and Map.Rand(100, "") < 55 then
			islandType = (Map.Rand(2, "") == 0) and "pebble" or "splinteredCliffsTiny";
		else
			islandType = DraftOneFromTier(CommonIslands, {});
		end
		if islandType then
			local placed = false;
			local tries = (remaining <= 0.55) and PANGAEA_COMMON_SMALL_ISLAND_TRIES_TIGHT or PANGAEA_COMMON_SMALL_ISLAND_TRIES_LOOSE;
			for i = 1, tries do
				placed = tryOneSpot(islandType, nil, nil);
				if placed then break; end
			end
			if placed then
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
				idleCommonPasses = 0;
			else
				idleCommonPasses = idleCommonPasses + 1;
				if idleCommonPasses >= PANGAEA_COMMON_FILL_IDLE_BREAK then
					dbg2("### common fill stall break at " .. spentBudget .. "/" .. TOTAL_BUDGET .. " ###");
					break;
				end
			end
		end
	end

		return islandsPlaced, spentBudget;
	end

	if not budgetRetry then
		local ip, sp = runOnce(PANGAEA_ISLAND_TOTAL_BUDGET);
		dbg2("### GeneratePangaeaIslands: islands placed = " .. tostring(ip) .. " spent " .. string.format("%.2f", sp) .. "/" .. PANGAEA_ISLAND_TOTAL_BUDGET .. " ###");
		return ip, true;
	end

	local b = PANGAEA_ISLAND_TOTAL_BUDGET;
	local budgetSlack = 0.06;
	while b >= budgetFloor do
		for _t = 1, maxTriesPerBudget do
			local ip, sp = runOnce(b);
			if sp + budgetSlack >= b then
				dbg2("### GeneratePangaeaIslands: islands placed = " .. tostring(ip) .. ", budget target " .. b .. " met ###");
				return ip, true;
			end
		end
		dbg2("### GeneratePangaeaIslands: budget " .. b .. " not met in " .. maxTriesPerBudget .. " attempts, lowering target ###");
		b = b - 1;
	end

	restorePlotTypes();
	resetIslandGlobals();
	dbg2("### GeneratePangaeaIslands: budget retry exhausted, islands cleared ###");
	return 0, false;
end
