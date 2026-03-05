------------------------------------------------------------------------------
--	PangaeaIslands.lua
--	Island layer for Pangaea Fractal. Dot, Chunk, PolarMerge.
------------------------------------------------------------------------------
print("### PangaeaIslands: loading ###");
include("X_IslandHelpers");
include("XX_island_common_Dot");
include("XX_island_common_Pebble");
include("XX_island_common_Strip");
include("XX_island_common_SplinteredCliffsTiny");
include("XX_island_uncommon_WaterRift");
include("XX_island_uncommon_Chunk");
include("XX_island_uncommon_Lollipop");
include("XX_island_uncommon_Waterdrop");
include("XX_island_uncommon_Barbell");
include("XX_island_uncommon_Wishbone");
include("XX_island_uncommon_SShape");
include("XX_island_uncommon_SplinteredMountains");
include("XX_island_uncommon_SplinteredCliffs");
include("XX_island_uncommon_TwinBay");
include("XX_island_uncommon_MountainWall");
include("XX_island_uncommon_RidgePeak");
include("XX_island_rare_PolarMerge");
include("XX_island_rare_CoastalHorn");
include("XX_island_rare_ShatteredRing");
include("XX_island_rare_EdgeOfWorld");
include("XX_island_rare_FjordPeninsula");
include("XX_island_rare_EllipseArchipelago");
include("XX_island_rare_SteppingStone");
include("XX_island_rare_Crescent");
include("XX_island_rare_ClusterOfTiny");
include("XX_island_exceptional_BrokenHeart");
include("XX_island_exceptional_VolcanicPeak");
include("XX_island_exceptional_JunglePeak");
include("XX_island_exceptional_DesertPeak");
include("XX_island_exceptional_CrescentAndStar");
include("XX_island_exceptional_CurledDragon");
include("XX_island_exceptional_VolcanicRing");
-- odds: probability this type is selected when its tier slot is being filled (0-100).
-- budget: cost deducted from total island budget when placed.
-- pullBack: minimum ring distance from nearest land before placing.
-- effMin/effMax: acceptable ring distance range for placement.
-- tier: determines maxOne behavior (exceptional/rare = maxOne via IsMaxOne helper).

local CommonIslands = {
	{ type = "dot",         			odds = 0,  pullBack = 0, effMin = 2, effMax = 2, budget = 0.1 },
	{ type = "mountainWall",   		odds = 0,  pullBack = 0, effMin = 1, effMax = 5, budget = 0.5 },
	{ type = "strip",       			odds = 0,  pullBack = 0, effMin = 2, effMax = 3, budget = 0.4 },
	{ type = "pebble",      			odds = 0,  pullBack = 0, effMin = 2, effMax = 3, budget = 0.4 },
	{ type = "splinteredCliffsTiny", 	odds = 0, pullBack = 0, effMin = 2, effMax = 4, budget = 0.3 },
};

local UncommonIslands = {
	{ type = "waterRift",       	odds = 0,  pullBack = 0, effMin = 6, effMax = 7, budget = 2.5 },
	{ type = "chunk",       			odds = 0,  pullBack = 1, effMin = 3, effMax = 6, budget = 0.8 },
	{ type = "barbell",         	odds = 0,  pullBack = 1, effMin = 1, effMax = 6, budget = 1 },
	{ type = "sShape",          	odds = 50, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "lollipop",        	odds = 0,  pullBack = 2, effMin = 2, effMax = 5, budget = 0.4 },
	{ type = "wishbone",        	odds = 0,  pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "waterdrop",       	odds = 0,  pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "splinteredMountains", odds = 0, pullBack = 0, effMin = 4, effMax = 7, budget = 1, fragile = true },
	{ type = "splinteredCliffs", 	odds = 0, pullBack = 0, effMin = 3, effMax = 6, budget = 0.8, fragile = true },
	{ type = "twinBay",         	odds = 0,  pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "ridgePeak",       	odds = 0,  pullBack = 0, effMin = 1, effMax = 7, budget = 1.5 },
};

local RareIslands = {
	{ type = "polarmerge",         odds = 99, pullBack = 3, effMin = 3, effMax = 5, budget = 4 },
	{ type = "coastalHorn",        odds = 0,  pullBack = 1, effMin = 1, effMax = 6, budget = 1 },
	{ type = "ShatteredRing",      odds = 0,  pullBack = 4, effMin = 4, effMax = 6, budget = 1 },
	{ type = "EdgeOfWorld",        odds = 0,  pullBack = 4, effMin = 4, effMax = 6, budget = 1 },
	{ type = "FjordPeninsula",     odds = 0,  pullBack = 4, effMin = 4, effMax = 6, budget = 1 },
	{ type = "EllipseArchipelago", odds = 0,  pullBack = 4, effMin = 5, effMax = 6, budget = 1 },
	{ type = "SteppingStone",      odds = 0,  pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "Crescent",           odds = 0,  pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "ClusterOfTiny",      odds = 0, pullBack = 4, effMin = 5, effMax = 6, budget = 1, fragile = true },
};

local ExceptionalIslands = {
	{ type = "BrokenHeart",     odds = 0, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "volcanicPeak",    odds = 0, pullBack = 3, effMin = 2, effMax = 6, budget = 1 },
	{ type = "junglePeak",      odds = 0, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "desertPeak",      odds = 80, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "CrescentAndStar", odds = 0, pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "curledDragon",    odds = 0, pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "volcanicRing", 	odds = 0, pullBack = 3, effMin = 3, effMax = 6, budget = 2 },
};

local IslandTypePlace = {
	dot = TryPlaceDotIsland,
	pebble = TryPlacePebbleIsland,
	strip = TryPlaceStripIsland,
	splinteredCliffsTiny = TryPlaceSplinteredCliffsTinyIsland,
	waterRift = TryPlaceWaterRift,
	chunk = TryPlaceChunkIsland,
	lollipop = TryPlaceLollipopIsland,
	waterdrop = TryPlaceWaterdropIsland,
	barbell = TryPlaceBarbellIsland,
	wishbone = TryPlaceWishboneIsland,
	sShape = TryPlaceSShapeIsland,
	splinteredMountains = TryPlaceSplinteredMountainsIsland,
	splinteredCliffs = TryPlaceSplinteredCliffsIsland,
	twinBay = TryPlaceTwinBayIslands,
	mountainWall = TryPlaceMountainWallIsland,
	ridgePeak = TryPlaceRidgePeak,
	coastalHorn = TryPlaceCoastalHornIsland,
	ShatteredRing = TryPlaceShatteredRingIsland,
	EdgeOfWorld = TryPlaceEdgeOfWorldIsland,
	FjordPeninsula = TryPlaceFjordPeninsulaIsland,
	EllipseArchipelago = TryPlaceEllipseArchipelagoIsland,
	SteppingStone = TryPlaceSteppingStoneIsland,
	Crescent = TryPlaceCrescentIsland,
	ClusterOfTiny = TryPlaceClusterOfTinyIslands,
	BrokenHeart = TryPlaceBrokenHeartIsland,
	volcanicPeak = TryPlaceVolcanicPeakIsland,
	junglePeak = TryPlaceJunglePeakIsland,
	desertPeak = TryPlaceDesertPeakIsland,
	CrescentAndStar = TryPlaceCrescentAndStarIsland,
	curledDragon = TryPlaceCurledDragonIsland,
	volcanicRing = TryPlaceVolcanicRing,
};

-- Unified lookup across all tier tables. Tier is inferred from the bucket.
local AllIslandTypeTables = {
	{ tier = "common", pool = CommonIslands },
	{ tier = "uncommon", pool = UncommonIslands },
	{ tier = "rare", pool = RareIslands },
	{ tier = "exceptional", pool = ExceptionalIslands },
};

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

-- Exceptional and rare types can only appear once in a draft (no redrafting).
-- Common and uncommon may be redrafted into multiple slots.
local function IsMaxOne(islandType)
	local e = GetOptEntry(islandType);
	return e ~= nil and (e.tier == "exceptional" or e.tier == "rare");
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

-- Draft one slot from a tier pool using weighted selection.
-- Each entry's odds value is its relative weight within the tier.
-- Excludes maxOne types already committed to the draft.
-- Returns the picked type name, or nil if pool is empty.
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

-- Priority constants for placement ordering. Lower = placed first.
local NAMED_PRIORITY = {
	polarmerge = 1,
	ridgePeak = 2,
};
local TIER_BASE_PRIORITY = {
	exceptional = 4,
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

------------------------------------------------------------------------------
function GeneratePangaeaIslands(self)
	local function dbg2(msg) print(msg); end
	dbg2("### GeneratePangaeaIslands: start [" .. os.date("%H:%M:%S") .. "] ###");
	_island_placed = {};
	local iW, iH = Map.GetGridSize();
	local wrapX = Map:IsWrapX();
	local wrapY = false;
	local odd = firstRingYIsOdd;
	local even = firstRingYIsEven;

	-- Tiles that were land before any islands placed (pangaea mainland). Used to bias dot/pebble/strip.
	-- plotTypes is 1-based (index = y*iW+x+1); we key pangeaTiles by same 1-based index for consistency.
	local pangeaTiles = {};
	for i = 0, (iW * iH) - 1 do
		local t = self.plotTypes[i + 1];
		if t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN then
			pangeaTiles[i + 1] = true;
		end
	end

	local TOTAL_BUDGET    = 12;
	local BUDGET_TOLERANCE = 0.2;

	local opts = {
		iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY,
		landX = 0, landY = 0
	};

	-- -------------------------------------------------------------------------
	-- DRAFT PHASE
	-- Each tier contributes a random count of slots. Common fills remaining budget.
	-- maxOne types (exceptional/rare) are committed to excludeSet after drafting.
	-- -------------------------------------------------------------------------
	local excludeSet = {};
	local drafted = {};

	local function draftAdd(t)
		if t then
			drafted[#drafted + 1] = t;
			if IsMaxOne(t) then excludeSet[t] = true; end
		end
	end

	local numExceptional = 1;
	local numRare        = 1;
	local numUncommon    = 6;

	for i = 1, numExceptional do
		draftAdd(DraftOneFromTier(ExceptionalIslands, excludeSet));
	end
	for i = 1, numRare do
		draftAdd(DraftOneFromTier(RareIslands, excludeSet));
	end
	for i = 1, numUncommon do
		draftAdd(DraftOneFromTier(UncommonIslands, excludeSet));
	end

	-- -------------------------------------------------------------------------
	-- SORT PHASE
	-- -------------------------------------------------------------------------
	table.sort(drafted, function(a, b)
		return GetDraftPriority(a) < GetDraftPriority(b);
	end);

	-- -------------------------------------------------------------------------
	-- PLACEMENT PHASE
	-- polarmerge and ridgePeak use opts-based placement; all others use spot-finding.
	-- -------------------------------------------------------------------------
	local function tryOneSpot(forceType, attempt)
		local x = Map.Rand(iW, "");
		local y;
		if forceType == "volcanicPeak" then
			if attempt and attempt >= 25 then
				y = 3 + Map.Rand((iH - 6), "");
			else
				local bandHeight = 6 + Map.Rand(5, "");
				local centerY = math.floor(iH / 2);
				local jungleMin = math.max(2, centerY - math.floor(bandHeight / 2));
				local jungleMax = math.min(iH - 3, jungleMin + bandHeight - 1);
				y = jungleMin + Map.Rand(math.max(1, jungleMax - jungleMin + 1), "");
			end
		elseif forceType == "desertPeak" then
			if attempt and attempt >= 25 then
				y = 3 + Map.Rand((iH - 6), "");
			else
				local northMin = math.max(2, math.floor(0.25 * iH));
				local northMax = math.min(iH - 3, math.floor(0.4 * iH));
				local southMin = math.max(2, math.floor(0.6 * iH));
				local southMax = math.min(iH - 3, math.floor(0.75 * iH));
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
		local plotIndex = y * iW + x + 1;
		if self.plotTypes[plotIndex] ~= PlotTypes.PLOT_OCEAN then return false; end
		local islLandInRing, landX, landY, landPlot = 0, 0, 0, 0;
		local spotOpts = { iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY, landX = 0, landY = 0 };
		if attempt then spotOpts.attempt = attempt; end
		for ripple_radius = 1, 7 do
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
		spotOpts.landX = landX;
		spotOpts.landY = landY;
		spotOpts.nearPangea = pangeaTiles[landPlot];  -- landPlot is 1-based
		return TryPlaceIsland(self.plotTypes, x, y, islLandInRing, spotOpts, forceType);
	end

	local spentBudget = 0;
	dbg2("### GeneratePangaeaIslands: placing drafted islands ###");

	for _, islandType in ipairs(drafted) do
		dbg2("### placing: " .. tostring(islandType) .. " ###");
		if not IslandTypePlace[islandType] and islandType ~= "polarmerge" then
		elseif islandType == "polarmerge" then
			if TryPlacePolarMerge(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
			end
		elseif islandType == "coastalHorn" then
			if TryPlaceCoastalHornIsland(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
			end
		elseif islandType == "FjordPeninsula" then
			if TryPlaceFjordPeninsulaIsland(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
			end
		elseif islandType == "SteppingStone" then
			if TryPlaceSteppingStoneIsland(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
			end
		else
			local placed = false;
			local attempts = 0;
			local maxAttempts = 50;
			while not placed and attempts < maxAttempts do
				placed = tryOneSpot(islandType, attempts);
				attempts = attempts + 1;
			end
			if placed then
				spentBudget = spentBudget + GetBudget(islandType);
			end
		end
	end

	dbg2("### GeneratePangaeaIslands: drafted done, filling commons ###");
	local escapeCommon = 500;
	local commonAttempts = 0;
	local consecutiveFails = 0;
	local CONSECUTIVE_FAIL_CAP = 80;
	while spentBudget < TOTAL_BUDGET and escapeCommon > 0 do
		commonAttempts = commonAttempts + 1;
		if commonAttempts == 1 or commonAttempts % 100 == 0 then
			dbg2("### common fill attempt " .. commonAttempts .. ", budget " .. spentBudget .. "/" .. TOTAL_BUDGET .. " ###");
		end
		local islandType = DraftOneFromTier(CommonIslands, {});
		if islandType then
			local placed = tryOneSpot(islandType);
			if placed then
				spentBudget = spentBudget + GetBudget(islandType);
				consecutiveFails = 0;
			else
				consecutiveFails = consecutiveFails + 1;
				if consecutiveFails >= CONSECUTIVE_FAIL_CAP then
					dbg2("### common fill: " .. consecutiveFails .. " consecutive fails, exiting early ###");
					break;
				end
			end
		end
		escapeCommon = escapeCommon - 1;
	end

	return false;
end
