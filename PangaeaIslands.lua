------------------------------------------------------------------------------
--	PangaeaIslands.lua
--	Island layer for Pangaea Fractal. Dot, Chunk, PolarMerge.
------------------------------------------------------------------------------
print("### PangaeaIslands: loading ###");
include("IslandHelpers");
include("DotIsland");
include("ChunkIsland");
include("PolarMerge");
include("PebbleIsland");
include("LollipopIsland");
include("WaterdropIsland");
include("BrokenHeartIsland");
-- include("VolcanicPeakIsland");
include("CommaIsland");
include("SplitIsland");
include("BlobIsland");
include("CoastalHornIsland");
-- odds: probability this type is selected when its tier slot is being filled (0-100).
-- budget: cost deducted from total island budget when placed.
-- pullBack: minimum ring distance from nearest land before placing.
-- effMin/effMax: acceptable ring distance range for placement.
-- fragile: placed late in the placement order - only followed by small common islands
-- tier: determines maxOne behavior (exceptional/rare = maxOne via IsMaxOne helper).

local CommonIslands = {
	{ type = "dot",    tier = "common", odds = 100, pullBack = 1,             effMax = 6, budget = 0.4 },
	{ type = "pebble", tier = "common", odds = 100, pullBack = 1, effMin = 3, effMax = 6, budget = 1   },
};

local UncommonIslands = {
	{ type = "chunk",     tier = "uncommon", odds = 100, pullBack = 1, effMin = 3, effMax = 6, budget = 1 },
	{ type = "lollipop",  tier = "uncommon", odds = 100, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "waterdrop", tier = "uncommon", odds = 100, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "comma",     tier = "uncommon", odds = 100, pullBack = 0, effMin = 0, effMax = 6, budget = 1 },
	{ type = "split",     tier = "uncommon", odds = 100, pullBack = 1, effMin = 1, effMax = 6, budget = 1 },
	{ type = "blob",      tier = "uncommon", odds = 100, pullBack = 1, effMin = 1, effMax = 6, budget = 1 },
};

local RareIslands = {
	{ type = "polarmerge",         tier = "rare", odds = 99, pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "coastalHorn",        tier = "rare", odds = 1,  pullBack = 1, effMin = 1, effMax = 6, budget = 1 },
	{ type = "ShatteredRing",      tier = "rare", odds = 1,  pullBack = 4, effMin = 4, effMax = 6, budget = 1 },
	{ type = "EdgeOfWorld",        tier = "rare", odds = 1,  pullBack = 4, effMin = 4, effMax = 6, budget = 1 },
	{ type = "FjordPeninsula",     tier = "rare", odds = 1,  pullBack = 4, effMin = 4, effMax = 6, budget = 1 },
	{ type = "EllipseArchipelago", tier = "rare", odds = 1,  pullBack = 4, effMin = 5, effMax = 6, budget = 1 },
	{ type = "SteppingStone",      tier = "rare", odds = 1,  pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "Crescent",           tier = "rare", odds = 1,  pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
};

local ExceptionalIslands = {
	-- { type = "volcanicPeak",    tier = "exceptional", odds = 9900, pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "junglePeak",      tier = "exceptional", odds = 1,    pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "desertPeak",      tier = "exceptional", odds = 1,    pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "CrescentAndStar", tier = "exceptional", odds = 1,    pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
	{ type = "BrokenHeart",     tier = "exceptional", odds = 9900, pullBack = 2, effMin = 2, effMax = 5, budget = 1 },
	{ type = "curledDragon",    tier = "exceptional", odds = 1,    pullBack = 3, effMin = 3, effMax = 5, budget = 1 },
};

-- Active (implemented) island types.
-- Types in the tier tables not listed here are defined but not yet active.
local IslandTypePlace = {
	dot          = TryPlaceDotIsland,
	chunk        = TryPlaceChunkIsland,
	coastalHorn  = TryPlaceCoastalHornIsland,
	pebble       = TryPlacePebbleIsland,
	lollipop     = TryPlaceLollipopIsland,
	waterdrop    = TryPlaceWaterdropIsland,
	-- volcanicPeak = TryPlaceVolcanicPeakIsland,
	BrokenHeart  = TryPlaceBrokenHeartIsland,
	comma        = TryPlaceCommaIsland,
	split        = TryPlaceSplitIsland,
	blob         = TryPlaceBlobIsland,
};

-- Unified lookup across all tier tables.
local AllIslandTypeTables = {
	CommonIslands,
	UncommonIslands,
	RareIslands,
	ExceptionalIslands,
};

local function GetOptEntry(islandType)
	for _, tbl in ipairs(AllIslandTypeTables) do
		for _, e in ipairs(tbl) do
			if e.type == islandType then return e; end
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
	-- fjordpeninsula = 2,   (reserved)
	-- steppingstone  = 3,   (reserved)
};
local TIER_BASE_PRIORITY = {
	exceptional = 4,
	rare        = 5,
	uncommon    = 6,
	common      = 8,
};
-- fragile types slot at 7, between uncommon and common.

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

	local numExceptional = 1;    -- 1..2
	local numRare        = 1;    -- 1..4
	local numUncommon    = 6;    -- 0..6

	for i = 1, numExceptional do
		draftAdd(DraftOneFromTier(ExceptionalIslands, excludeSet));
	end
	for i = 1, numRare do
		draftAdd(DraftOneFromTier(RareIslands, excludeSet));
	end
	for i = 1, numUncommon do
		draftAdd(DraftOneFromTier(UncommonIslands, excludeSet));
	end
	-- Common islands are not pre-drafted; they fill remaining budget during placement.

	-- -------------------------------------------------------------------------
	-- SORT PHASE
	-- Priority order: named specials → exceptional → rare → uncommon →
	--                 fragile → common.
	-- -------------------------------------------------------------------------
	table.sort(drafted, function(a, b)
		return GetDraftPriority(a) < GetDraftPriority(b);
	end);

	-- -------------------------------------------------------------------------
	-- PLACEMENT PHASE
	-- Iterate sorted draft. polarmerge uses its own placement path; all others
	-- use spot-finding with up to 10 attempts per drafted slot.
	-- -------------------------------------------------------------------------
	local function tryOneSpot(forceType, attempt)
		local x = Map.Rand(iW, "");
		local y = 3 + Map.Rand((iH - 6), "");
		local plotIndex = y * iW + x;
		if self.plotTypes[plotIndex] ~= PlotTypes.PLOT_OCEAN then return false; end
		local islLandInRing, landX, landY, landPlot = 0, 0, 0, 0;
		local spotOpts = { iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY, landX = 0, landY = 0 };
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
		return TryPlaceIsland(self.plotTypes, x, y, islLandInRing, spotOpts, forceType);
	end

	local spentBudget = 0;
	dbg2("### GeneratePangaeaIslands: placing drafted islands ###");

	-- DIAG: skip BrokenHeart only - if works, BrokenHeart is the culprit
	for _, islandType in ipairs(drafted) do
		dbg2("### placing: " .. tostring(islandType) .. " ###");
		if islandType == "BrokenHeart" then
			dbg2("### skipping BrokenHeart (crash test) ###");
		elseif not IslandTypePlace[islandType] and islandType ~= "polarmerge" then
		elseif islandType == "polarmerge" then
			if TryPlacePolarMerge(self.plotTypes, opts) then
				spentBudget = spentBudget + GetBudget(islandType);
			end
		elseif islandType == "coastalHorn" then
			if TryPlaceCoastalHornIsland(self.plotTypes, opts) then
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
	while spentBudget < TOTAL_BUDGET and escapeCommon > 0 do
		local islandType = DraftOneFromTier(CommonIslands, {});
		if islandType then
			local placed = tryOneSpot(islandType);
			if placed then
				spentBudget = spentBudget + GetBudget(islandType);
			end
		end
		escapeCommon = escapeCommon - 1;
	end

	return false;
end
