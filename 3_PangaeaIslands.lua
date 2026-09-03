-- Drafts and places pangaea-fractal islands on plotTypes.
if LekMapgenPrint then
	LekMapgenPrint("### PangaeaIslands: loading ###");
elseif _lek_mapgen_logs == true then
	print("### PangaeaIslands: loading ###");
end
include("X_IslandHelpers");
include("XX_island_common_Dot");
include("XX_island_common_Pebble");
include("XX_island_common_Strip");
include("XX_island_common_SplinteredCliffsTiny");
-- include("XX_island_uncommon_WaterRift");
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
-- include("XX_island_rare_PangaeaBow");
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
-- Acceptable nearest-pangea ring: pullBack+effMin .. pullBack+effMax (see tryOneSpot).
-- Budget guide: ~12 land tiles (mountains count ~0.5) ~= 1 island budget for generic shapes.
-- Special placers (polarMerge, steppingStone, wrapSoftLandbridge, geothermal, lakeRidge) keep bespoke tuning.
local CommonIslands = {
	{ type = "dot",                  odds = 5, pullBack = 1, effMin = 0, effMax = 0, budget = 0.09 },
	{ type = "pebble",               odds = 2, pullBack = 1, effMin = 0, effMax = 0, budget = 0.35 },
	{ type = "strip",                odds = 2, pullBack = 1, effMin = 0, effMax = 1, budget = 0.39 },
	{ type = "splinteredCliffsTiny", odds = 3, pullBack = 1, effMin = 0, effMax = 1, budget = 0.21 },
};

local UncommonIslands = {
	{ type = "mountainWall",        odds = 2, pullBack = 0, effMin = 0, effMax = 1, budget = 0.56 },
	{ type = "ridgePeak",           odds = 3, pullBack = 0, effMin = 0, effMax = 1, budget = 1.21 },
	{ type = "splinteredCliffs",    odds = 2, pullBack = 0, effMin = 1, effMax = 2, budget = 0.66, fragile = true },
	{ type = "chunk",               odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 0.61 },
	{ type = "barbell",             odds = 4, pullBack = 1, effMin = 0, effMax = 2, budget = 0.62 },
	{ type = "snake",               odds = 4, pullBack = 1, effMin = 0, effMax = 2, budget = 1.04 },
	{ type = "lollipop",            odds = 2, pullBack = 1, effMin = 0, effMax = 2, budget = 0.94 },
	{ type = "wishbone",            odds = 5, pullBack = 1, effMin = 0, effMax = 1, budget = 0.69 },
	{ type = "twinBay",             odds = 1, pullBack = 1, effMin = 0, effMax = 1, budget = 1.00 },
	{ type = "shatteredRing",       odds = 2, pullBack = 1, effMin = 0, effMax = 2, budget = 1.54 },
	{ type = "clusterOfTiny",      	odds = 5, pullBack = 1, effMin = 0, effMax = 2, budget = 0.46, fragile = true },
	-- { type = "waterRift",           odds = 2, pullBack = 1, effMin = 5, effMax = 6, budget = 0.88 },
};

local RareIslands = {
	{ type = "polarMerge",         	odds = 7, pullBack = 3, effMin = 3, effMax = 5, budget = 2.5 },
	{ type = "steppingStone",      	odds = 1, pullBack = 2, effMin = 2, effMax = 4, budget = 0.9 },
	{ type = "crescent",           	odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.50 },
	{ type = "volcanicRing",       	odds = 1, pullBack = 1, effMin = 1, effMax = 2, budget = 1.71 },
	{ type = "solomonsMinesIsland", odds = 0, pullBack = 1, effMin = 0, effMax = 2, budget = 1.54 },
	{ type = "sinaiIsland",        	odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.39 },
	{ type = "geothermalIsland",  	odds = 2, pullBack = 2, effMin = 2, effMax = 5, budget = 1.2 },
	{ type = "wrapSoftLandbridge",  odds = 2, pullBack = 2, effMin = 2, effMax = 5, budget = 2.5 },
	{ type = "junglePeak",         	odds = 2, pullBack = 1, effMin = 2, effMax = 3, budget = 1.52 },
	{ type = "lakeRidge",          	odds = 0, pullBack = 0, effMin = 0, effMax = 0, budget = 0 },
	-- { type = "pangaeaBow",         	odds = 9999, pullBack = 1, effMin = 0, effMax = 2, budget = 1.35 },
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
	-- waterRift = TryPlaceWaterRift,
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
	-- pangaeaBow = TryPlacePangaeaBowIsland,
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

local PANGAEA_ISLAND_TOTAL_BUDGET = 8;
-- After specials: soft-spend up to this much on dot/strip only, before remaining draft + common fill.
local PANGAEA_ISLAND_DOT_STRIP_EARLY_BUDGET = 2;
local DotStripEarlyPool = {
	{ type = "dot", odds = 5, budget = 0.09 },
	{ type = "strip", odds = 2, budget = 0.39 },
};
local IslandSpecialPhaseTypes = {
	polarMerge = true,
	steppingStone = true,
	wrapSoftLandbridge = true,
	lakeRidge = true,
	geothermalIsland = true,
};
local PANGAEA_COMMON_FILL_MAX_PASSES = 10000;
local PANGAEA_ISLAND_BUDGET_RETRY = true;
-- If false: only try nominal budget (e.g. 9), then fail so PangaeaFractalWorld outer regen runs (no lowering target).
local PANGAEA_ISLAND_RELAX_BUDGET_TIER = false;
-- Max full runOnce() attempts at nominal budget before outer fractal redraw. Logs show easy maps usually pass on
-- cumulativeRunOnceCalls=1; this is ceil(1 * 1.5) with headroom (loop budget, not wall clock).
local PANGAEA_ISLAND_MAX_RUNONCE_NOMINAL = 2;
local PANGAEA_ISLAND_MAX_TRIES_PER_BUDGET = 80;
local PANGAEA_ISLAND_BUDGET_FLOOR = 5;
local PANGAEA_SHORE_SMALL_ISLAND_ATTEMPTS = 600;
local PANGAEA_COMMON_SMALL_ISLAND_TRIES_TIGHT = 500;
local PANGAEA_COMMON_SMALL_ISLAND_TRIES_LOOSE = 350;
local PANGAEA_COMMON_FILL_IDLE_BREAK = 400;
-- os.clock() limits; nil/<=0 disables. Safety rail inside one runOnce (common fill / shore).
local PANGAEA_RUNONCE_MAX_CLOCK = 75;
-- nil: rely on PANGAEA_ISLAND_MAX_RUNONCE_NOMINAL + outer regen (no tier time budget).
local PANGAEA_BUDGET_TIER_MAX_CLOCK = nil;
-- Optional: after N misses at one tier, if best spent+slack < b*frac, skip remaining tries (set N to enable).
local PANGAEA_BUDGET_FAST_FAIL_TRIES = nil;
local PANGAEA_BUDGET_FAST_FAIL_SPENT_FRAC = 0.68;

local function LekIslandProbeLog(msg, minVerb)
	minVerb = minVerb or 2;
	if LekMapgenChannelEnabled then
		if not LekMapgenChannelEnabled("islands") then
			return;
		end
	elseif LekMapgenLogsEnabled and not LekMapgenLogsEnabled() then
		return;
	end
	if _lek_mapgen_world_is_small == true and minVerb < 3 then
		minVerb = 3;
	end
	if LekMapgenLogAtLeast and not LekMapgenLogAtLeast(minVerb) then
		return;
	end
	print(msg);
	pcall(function()
		if LekMapgenDiagLogAppend then
			LekMapgenDiagLogAppend({ msg });
		end
	end);
end

local function LekIslandBudgetFillPct(spent, target)
	if not target or type(target) ~= "number" or target <= 0 then
		return 0;
	end
	return 100 * spent / target;
end

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
	wrapSoftLandbridge = 2,
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
	local relaxBudgetTier = genOpts.relaxBudgetTier;
	if relaxBudgetTier == nil then relaxBudgetTier = PANGAEA_ISLAND_RELAX_BUDGET_TIER; end
	local maxRunOnceNominal = genOpts.maxRunOnceNominal;
	if maxRunOnceNominal == nil then maxRunOnceNominal = PANGAEA_ISLAND_MAX_RUNONCE_NOMINAL; end
	local laIsland = _lek_map_layout_attempt or 0;
	local outerIsland = tonumber(_lek_pangaea_outer_attempt) or 0;
	local tIslandGen0 = (os and os.clock) and os.clock() or 0;
	local islandRunBudget = 0;
	local islandRunTry = 0;
	local tallyRunOnceAborts = 0;
	local globalBestSpent = 0;
	local tierClockStopCount = 0;
	local fastFailStopCount = 0;
	local nominalBudget = PANGAEA_ISLAND_TOTAL_BUDGET;

	local function dbg2(msg)
		if LekMapgenPrint then
			LekMapgenPrint(msg);
		elseif LekMapgenLogsEnabled and LekMapgenLogsEnabled() then
			print(msg);
		end
	end
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
	do
		local t1 = (os and os.clock) and os.clock() or 0;
		LekIslandProbeLog("### LekIslandProbe layoutAttempt=" .. tostring(laIsland)
			.. " phase=snapshot_pangeaMask dt=" .. tostring(t1 - tIslandGen0), 2);
	end

	local opts = {
		iW = iW, iH = iH, wrapX = wrapX, wrapY = wrapY,
		landX = 0, landY = 0,
		lakeRidgeCenterX = math.floor(iW / 2),
		lakeRidgeCenterY = math.floor(iH / 2),
		lakeRidgeMaxHexFromCenter = 10,
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
		local tR0 = (os and os.clock) and os.clock() or 0;
		local runOnceDeadline = nil;
		if PANGAEA_RUNONCE_MAX_CLOCK and type(PANGAEA_RUNONCE_MAX_CLOCK) == "number" and PANGAEA_RUNONCE_MAX_CLOCK > 0 and os and os.clock then
			runOnceDeadline = os.clock() + PANGAEA_RUNONCE_MAX_CLOCK;
		end
		local runOnceAbortReason = nil;
		local function runOnceMarkAbort(reason)
			if runOnceAbortReason == nil then
				runOnceAbortReason = reason;
			end
		end
		local function runOnceClockExpired()
			if runOnceDeadline and os and os.clock and os.clock() > runOnceDeadline then
				runOnceMarkAbort("runOnce_clock_cap");
				return true;
			end
			return false;
		end
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
	local draftedSpecials = {};
	local draftedRest = {};
	for _, islandType in ipairs(drafted) do
		if IslandSpecialPhaseTypes[islandType] then
			draftedSpecials[#draftedSpecials + 1] = islandType;
		else
			draftedRest[#draftedRest + 1] = islandType;
		end
	end
	local tAfterDraft = (os and os.clock) and os.clock() or 0;

	local islandsPlaced = 0;
	local rollIslandSequence = {};
	local rollIslandCounts = {};
	local lastTryOceanSeedX, lastTryOceanSeedY;
	local lastTryLandX, lastTryLandY;
	local lastPaintBefore = nil;
	local tileOwnerByIndex = {};

	local function islandTilesLogEnabled()
		if LekMapgenChannelEnabled then
			return LekMapgenChannelEnabled("islands_tiles");
		end
		return LekMapgenLogsEnabled and LekMapgenLogsEnabled();
	end

	local function emitIslandLogLine(msg)
		if LekMapgenPrintAndDiagFile then
			LekMapgenPrintAndDiagFile(msg);
		else
			print(msg);
			pcall(function()
				if LekMapgenDiagLogAppend then
					LekMapgenDiagLogAppend(msg);
				end
			end);
		end
	end

	local function isIslandLandPlotType(t)
		return t == PlotTypes.PLOT_LAND or t == PlotTypes.PLOT_HILLS or t == PlotTypes.PLOT_MOUNTAIN;
	end

	local function islandPlotTypeTag(t)
		if t == PlotTypes.PLOT_MOUNTAIN then
			return "mtn";
		elseif t == PlotTypes.PLOT_HILLS then
			return "hills";
		elseif t == PlotTypes.PLOT_LAND then
			return "land";
		end
		return "other";
	end

	local function captureIslandLandState()
		local s = {};
		for i = 1, n do
			local t = self.plotTypes[i];
			if isIslandLandPlotType(t) then
				s[i] = t;
			end
		end
		return s;
	end

	local function markIslandPaintBefore()
		if islandTilesLogEnabled() then
			lastPaintBefore = captureIslandLandState();
		else
			lastPaintBefore = nil;
		end
	end

	local function logIslandPaintedTiles(islandType, seq)
		if not lastPaintBefore or not islandTilesLogEnabled() then
			lastPaintBefore = nil;
			return;
		end
		local before = lastPaintBefore;
		lastPaintBefore = nil;
		local added = {};
		for i = 1, n do
			local t = self.plotTypes[i];
			if isIslandLandPlotType(t) and before[i] == nil then
				local i0 = i - 1;
				local x = i0 % iW;
				local y = math.floor(i0 / iW);
				added[#added + 1] = { x = x, y = y, t = t, i = i };
			end
		end
		table.sort(added, function(a, b)
			if a.y ~= b.y then
				return a.y < b.y;
			end
			return a.x < b.x;
		end);
		local minX, maxX, minY, maxY = nil, nil, nil, nil;
		for _, row in ipairs(added) do
			local prev = tileOwnerByIndex[row.i];
			tileOwnerByIndex[row.i] = islandType;
			if minX == nil or row.x < minX then minX = row.x; end
			if maxX == nil or row.x > maxX then maxX = row.x; end
			if minY == nil or row.y < minY then minY = row.y; end
			if maxY == nil or row.y > maxY then maxY = row.y; end
			local prevPart = "";
			if prev ~= nil then
				prevPart = " overwrite=" .. tostring(prev);
			end
			emitIslandLogLine("### LekIslandTile runId=" .. tostring(_lek_run_id or "na")
				.. " layoutAttempt=" .. tostring(laIsland)
				.. " outerAttempt=" .. tostring(outerIsland)
				.. " budgetTry=" .. tostring(islandRunTry)
				.. " seq=" .. tostring(seq)
				.. " type=" .. tostring(islandType)
				.. " xy=" .. tostring(row.x) .. "," .. tostring(row.y)
				.. " plot=" .. islandPlotTypeTag(row.t)
				.. prevPart);
		end
		emitIslandLogLine("### LekIslandFootprint runId=" .. tostring(_lek_run_id or "na")
			.. " layoutAttempt=" .. tostring(laIsland)
			.. " outerAttempt=" .. tostring(outerIsland)
			.. " budgetTry=" .. tostring(islandRunTry)
			.. " seq=" .. tostring(seq)
			.. " type=" .. tostring(islandType)
			.. " nLand=" .. tostring(#added)
			.. " bbox=" .. tostring(minX or "na") .. "," .. tostring(minY or "na")
			.. "-" .. tostring(maxX or "na") .. "," .. tostring(maxY or "na"));
	end

	-- Fired only when a placer returns true (budget retries may wipe later; match final LekIslandRollSummary).
	local function recordIslandPlaced(islandType, atX, atY, nearLandX, nearLandY)
		rollIslandSequence[#rollIslandSequence + 1] = islandType;
		rollIslandCounts[islandType] = (rollIslandCounts[islandType] or 0) + 1;
		local seq = #rollIslandSequence;
		local atPart = " at=na";
		if atX ~= nil and atY ~= nil then
			atPart = " at=" .. tostring(atX) .. "," .. tostring(atY);
		end
		local nearPart = "";
		if nearLandX ~= nil and nearLandY ~= nil then
			nearPart = " nearLand=" .. tostring(nearLandX) .. "," .. tostring(nearLandY);
		end
		emitIslandLogLine("### LekIslandPlaced runId=" .. tostring(_lek_run_id or "na")
			.. " layoutAttempt=" .. tostring(laIsland)
			.. " outerAttempt=" .. tostring(outerIsland)
			.. " budgetTry=" .. tostring(islandRunTry)
			.. " seq=" .. tostring(seq)
			.. " type=" .. tostring(islandType)
			.. atPart
			.. nearPart);
		logIslandPaintedTiles(islandType, seq);
	end
	local function logRollIslandSummary(spent, target)
		local keys = {};
		for k in pairs(rollIslandCounts) do
			keys[#keys + 1] = k;
		end
		table.sort(keys);
		local countParts = {};
		for _, k in ipairs(keys) do
			countParts[#countParts + 1] = tostring(k) .. "=" .. tostring(rollIslandCounts[k]);
		end
		local summary = "### LekIslandRollSummary runId=" .. tostring(_lek_run_id or "na")
			.. " layoutAttempt=" .. tostring(laIsland)
			.. " outerAttempt=" .. tostring(outerIsland)
			.. " budgetTry=" .. tostring(islandRunTry)
			.. " budgetTarget=" .. tostring(target)
			.. " spent=" .. string.format("%.3f", spent or 0)
			.. " placedN=" .. tostring(#rollIslandSequence)
			.. " order=" .. table.concat(rollIslandSequence, ",")
			.. " countsByType=" .. table.concat(countParts, ";");
		emitIslandLogLine(summary);
	end
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
		lastTryOceanSeedX, lastTryOceanSeedY = x, y;
		lastTryLandX, lastTryLandY = landX, landY;
		return TryPlaceIsland(self.plotTypes, x, y, islLandInRing, spotOpts, forceType);
	end

	local spentBudget = 0;
	local function placeAndCount(islandType, attemptsCap)
		local placed = false;
		local attempts = 0;
		local cap = attemptsCap or 180;
		while not placed and attempts < cap do
			if runOnceClockExpired() then
				break;
			end
			markIslandPaintBefore();
			placed = tryOneSpot(islandType, attempts);
			attempts = attempts + 1;
		end
		if placed then
			recordIslandPlaced(islandType, lastTryOceanSeedX, lastTryOceanSeedY, lastTryLandX, lastTryLandY);
			spentBudget = spentBudget + GetBudget(islandType);
			islandsPlaced = islandsPlaced + 1;
		else
			lastPaintBefore = nil;
		end
		return placed;
	end

	dbg2("### GeneratePangaeaIslands: placing special-phase drafted islands ###");

	local function placeDraftedOne(islandType)
		if runOnceClockExpired() then
			return;
		end
		dbg2("### placing: " .. tostring(islandType) .. " ###");
		if islandType == "polarMerge" then
			markIslandPaintBefore();
			local ok, px, py = TryPlacePolarMerge(self.plotTypes, opts);
			if ok then
				recordIslandPlaced("polarMerge", px, py);
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			else
				lastPaintBefore = nil;
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
			markIslandPaintBefore();
			local ok, px, py = TryPlaceSteppingStoneIsland(self.plotTypes, opts);
			if ok then
				recordIslandPlaced("steppingStone", px, py);
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			else
				lastPaintBefore = nil;
			end
		elseif islandType == "wrapSoftLandbridge" then
			local placedBridge = false;
			local bx, by = nil, nil;
			for _wb = 1, 28 do
				if runOnceClockExpired() then
					break;
				end
				markIslandPaintBefore();
				local ok, px, py = TryPlaceWrapSoftLandbridge(self.plotTypes, opts);
				if ok then
					placedBridge = true;
					bx, by = px, py;
					break;
				else
					lastPaintBefore = nil;
				end
			end
			if placedBridge then
				recordIslandPlaced("wrapSoftLandbridge", bx, by);
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			end
		elseif islandType == "mainlandRidge" then
			markIslandPaintBefore();
			local ok, px, py = TryPlaceMainlandRidge(self.plotTypes, opts);
			if ok then
				recordIslandPlaced("mainlandRidge", px, py);
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			else
				lastPaintBefore = nil;
			end
		elseif islandType == "lakeRidge" then
			markIslandPaintBefore();
			local ok, px, py = TryPlaceLakeRidge(self.plotTypes, opts);
			if ok then
				recordIslandPlaced("lakeRidge", px, py);
				spentBudget = spentBudget + GetBudget(islandType);
				islandsPlaced = islandsPlaced + 1;
			else
				lastPaintBefore = nil;
			end
		elseif IslandTypePlace[islandType] then
			local maxAttempts = 180;
			if islandType == "solomonsMinesIsland" then
				maxAttempts = 300;
			end
			placeAndCount(islandType, maxAttempts);
		end
	end

	for _, islandType in ipairs(draftedSpecials) do
		placeDraftedOne(islandType);
	end

	dbg2("### GeneratePangaeaIslands: early dot/strip after specials (target budget "
		.. tostring(PANGAEA_ISLAND_DOT_STRIP_EARLY_BUDGET or 2) .. ") ###");
	local earlyTarget = PANGAEA_ISLAND_DOT_STRIP_EARLY_BUDGET or 2;
	local earlySpent = 0;
	while earlySpent + 0.001 < earlyTarget
		and spentBudget + 0.004 < TOTAL_BUDGET do
		if runOnceClockExpired() then
			break;
		end
		local remainingEarly = earlyTarget - earlySpent;
		local islandType;
		if remainingEarly < 0.39 then
			islandType = "dot";
		else
			islandType = DraftOneFromTier(DotStripEarlyPool, {});
		end
		if not islandType then
			break;
		end
		local placed = false;
		for i = 1, PANGAEA_COMMON_SMALL_ISLAND_TRIES_LOOSE do
			if (i % 40 == 0) and runOnceClockExpired() then
				break;
			end
			markIslandPaintBefore();
			placed = tryOneSpot(islandType, nil, nil);
			if placed then
				break;
			else
				lastPaintBefore = nil;
			end
		end
		if placed then
			recordIslandPlaced(islandType, lastTryOceanSeedX, lastTryOceanSeedY, lastTryLandX, lastTryLandY);
			local b = GetBudget(islandType);
			earlySpent = earlySpent + b;
			spentBudget = spentBudget + b;
			islandsPlaced = islandsPlaced + 1;
		else
			break;
		end
	end

	dbg2("### GeneratePangaeaIslands: placing remaining drafted islands ###");
	for _, islandType in ipairs(draftedRest) do
		placeDraftedOne(islandType);
	end

	local tAfterDraftedPlaced = (os and os.clock) and os.clock() or 0;

	dbg2("### GeneratePangaeaIslands: drafted done, filling commons (until spent >= " .. TOTAL_BUDGET .. ", est at draft was " .. draftEstimate .. ") ###");
	local commonPass = 0;
	local idleCommonPasses = 0;
	while spentBudget + 0.004 < TOTAL_BUDGET and commonPass < PANGAEA_COMMON_FILL_MAX_PASSES do
		if runOnceClockExpired() then
			break;
		end
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
				if (i % 40 == 0) and runOnceClockExpired() then
					break;
				end
				markIslandPaintBefore();
				placed = tryOneSpot(islandType, nil, nil);
				if placed then
					break;
				else
					lastPaintBefore = nil;
				end
			end
			if placed then
				recordIslandPlaced(islandType, lastTryOceanSeedX, lastTryOceanSeedY, lastTryLandX, lastTryLandY);
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
	local tAfterCommonFill = (os and os.clock) and os.clock() or 0;
		local runTotal = tAfterCommonFill - tR0;
		LekIslandProbeLog("### LekIslandProbe layoutAttempt=" .. tostring(laIsland)
			.. " runOnce budgetTarget=" .. tostring(TOTAL_BUDGET)
			.. " retryTry=" .. tostring(islandRunTry) .. "/" .. tostring(maxTriesPerBudget)
			.. " draft_dt=" .. tostring(tAfterDraft - tR0)
			.. " shore_dt=0"
			.. " draftedPlace_dt=" .. tostring(tAfterDraftedPlaced - tAfterDraft)
			..(" commonFill_dt=" .. tostring(tAfterCommonFill - tAfterDraftedPlaced))
			.. " commonPasses=" .. tostring(commonPass)
			.. " islandsPlaced=" .. tostring(islandsPlaced)
			.. " spentBudget=" .. string.format("%.3f", spentBudget)
			.. " runOnce_total_dt=" .. tostring(runTotal)
			.. " abort=" .. tostring(runOnceAbortReason or "none"), 3);
		local fillPct = LekIslandBudgetFillPct(spentBudget, TOTAL_BUDGET);
		local shortfall = math.max(0, TOTAL_BUDGET - spentBudget);
		LekIslandProbeLog("### LekIslandProbe runOnce_summary layoutAttempt=" .. tostring(laIsland)
			.. " target=" .. tostring(TOTAL_BUDGET)
			.. " spent=" .. string.format("%.3f", spentBudget)
			.. " fillPct=" .. string.format("%.1f", fillPct)
			.. " shortfall=" .. string.format("%.3f", shortfall)
			.. " islandsPlaced=" .. tostring(islandsPlaced)
			.. " dt=" .. string.format("%.2f", runTotal)
			.. " commonPasses=" .. tostring(commonPass)
			.. " abort=" .. tostring(runOnceAbortReason or "none"), 2);
		if runOnceAbortReason then
			tallyRunOnceAborts = tallyRunOnceAborts + 1;
		end

		logRollIslandSummary(spentBudget, TOTAL_BUDGET);

		return islandsPlaced, spentBudget;
	end

	if not budgetRetry then
		islandRunBudget = PANGAEA_ISLAND_TOTAL_BUDGET;
		islandRunTry = 1;
		local ip, sp = runOnce(PANGAEA_ISLAND_TOTAL_BUDGET);
		dbg2("### GeneratePangaeaIslands: islands placed = " .. tostring(ip) .. " spent " .. string.format("%.2f", sp) .. "/" .. PANGAEA_ISLAND_TOTAL_BUDGET .. " ###");
		do
			local tEnd = (os and os.clock) and os.clock() or 0;
			LekIslandProbeLog("### LekIslandProbe layoutAttempt=" .. tostring(laIsland)
				.. " exit=no_budget_retry ok=1 generatePangaeaIslands_total_dt=" .. tostring(tEnd - tIslandGen0), 1);
			LekIslandProbeLog("### LekIslandProbe budgetOutcome layoutAttempt=" .. tostring(laIsland)
				.. " path=no_budget_retry islandsPlaced=" .. tostring(ip)
				.. " spent=" .. string.format("%.3f", sp)
				.. " nominalTarget=" .. tostring(nominalBudget)
				.. " fillPctOfNominal=" .. string.format("%.1f", LekIslandBudgetFillPct(sp, nominalBudget))
				.. " runOnceAbortsThisGen=" .. tostring(tallyRunOnceAborts), 2);
			LekIslandProbeLog("### LekIslandProbe innerSuccessProfile layoutAttempt=" .. tostring(laIsland)
				.. " outer=" .. tostring(outerIsland)
				.. " acceptedTier=" .. tostring(nominalBudget)
				.. " winningTry=1"
				.. " cumulativeRunOnceCalls=1"
				.. " tierDropsBeforeOk=0"
				.. " relaxBudgetTier=n/a_path"
				.. " note=single_runOnce_no_budget_retry", 2);
		end
		return ip, true;
	end

	local b = PANGAEA_ISLAND_TOTAL_BUDGET;
	local budgetSlack = 0.06;
	local cumulativeRunOnce = 0;
	local nominalRunOnceCount = 0;
	local island_nominal_tier_abort_no_relax = false;
	while b >= budgetFloor do
		islandRunBudget = b;
		local tierClock0 = (os and os.clock) and os.clock() or 0;
		local bestSpentTry = 0;
		local nominalTierLoopExit = nil;
		for _t = 1, maxTriesPerBudget do
			islandRunTry = _t;
			if b == nominalBudget and type(maxRunOnceNominal) == "number" and maxRunOnceNominal > 0
				and nominalRunOnceCount >= maxRunOnceNominal then
				nominalTierLoopExit = "nominal_runOnce_cap";
				LekIslandProbeLog("### LekIslandProbe budgetTierCap budget=" .. tostring(b)
					.. " reason=nominal_runOnce_cap triesUsed=" .. tostring(_t - 1)
					.. " cap=" .. tostring(maxRunOnceNominal), 2);
				break;
			end
			cumulativeRunOnce = cumulativeRunOnce + 1;
			if b == nominalBudget then
				nominalRunOnceCount = nominalRunOnceCount + 1;
			end
			local tTry0 = (os and os.clock) and os.clock() or 0;
			local ip, sp = runOnce(b);
			local tryDt = (os and os.clock) and (os.clock() - tTry0) or 0;
			if sp > bestSpentTry then
				bestSpentTry = sp;
			end
			if sp + budgetSlack >= b then
				dbg2("### GeneratePangaeaIslands: islands placed = " .. tostring(ip) .. ", budget target " .. b .. " met ###");
				do
					local tEnd = (os and os.clock) and os.clock() or 0;
					LekIslandProbeLog("### LekIslandProbe layoutAttempt=" .. tostring(laIsland)
						.. " exit=budget_met budgetFinal=" .. tostring(b)
						.. " spentFinal=" .. string.format("%.3f", sp)
						.. " islandsPlaced=" .. tostring(ip)
						.. " generatePangaeaIslands_total_dt=" .. tostring(tEnd - tIslandGen0), 1);
					LekIslandProbeLog("### LekIslandProbe budgetOutcome layoutAttempt=" .. tostring(laIsland)
						.. " path=budget_retry_success acceptedTier=" .. tostring(b)
						.. " islandsPlaced=" .. tostring(ip)
						.. " spent=" .. string.format("%.3f", sp)
						.. " fillPctOfAcceptedTier=" .. string.format("%.1f", LekIslandBudgetFillPct(sp, b))
						.. " nominalTarget=" .. tostring(nominalBudget)
						.. " fillPctOfNominal=" .. string.format("%.1f", LekIslandBudgetFillPct(sp, nominalBudget))
						.. " tiersBelowNominal=" .. tostring(math.max(0, nominalBudget - b))
						.. " runOnceAbortsThisGen=" .. tostring(tallyRunOnceAborts)
						.. " tierClockStops=" .. tostring(tierClockStopCount)
						.. " fastFailStops=" .. tostring(fastFailStopCount), 2);
					LekIslandProbeLog("### LekIslandProbe innerSuccessProfile layoutAttempt=" .. tostring(laIsland)
						.. " outer=" .. tostring(outerIsland)
						.. " acceptedTier=" .. tostring(b)
						.. " winningTry=" .. tostring(_t)
						.. " cumulativeRunOnceCalls=" .. tostring(cumulativeRunOnce)
						.. " tierDropsBeforeOk=" .. tostring(math.max(0, nominalBudget - b))
						.. " nominalRunOnceCallsSession=" .. tostring(nominalRunOnceCount)
						.. " relaxBudgetTier=" .. (relaxBudgetTier and "1" or "0"), 2);
				end
				return ip, true;
			end
			if sp > globalBestSpent then
				globalBestSpent = sp;
			end
			LekIslandProbeLog("### LekIslandProbe budgetMiss budget=" .. tostring(b)
				.. " try=" .. tostring(_t) .. "/" .. tostring(maxTriesPerBudget)
				.. " spent=" .. string.format("%.3f", sp)
				.. " fillPctOfTier=" .. string.format("%.1f", LekIslandBudgetFillPct(sp, b))
				.. " try_dt=" .. string.format("%.2f", tryDt)
				.. " bestSoFar=" .. string.format("%.3f", bestSpentTry)
				.. " gapToTier=" .. string.format("%.3f", math.max(0, b - budgetSlack - sp)), 2);
			if PANGAEA_BUDGET_TIER_MAX_CLOCK and type(PANGAEA_BUDGET_TIER_MAX_CLOCK) == "number" and PANGAEA_BUDGET_TIER_MAX_CLOCK > 0 and os and os.clock then
				if (os.clock() - tierClock0) > PANGAEA_BUDGET_TIER_MAX_CLOCK then
					nominalTierLoopExit = "tier_clock_cap";
					tierClockStopCount = tierClockStopCount + 1;
					LekIslandProbeLog("### LekIslandProbe budgetTierCap budget=" .. tostring(b)
						.. " reason=tier_clock_cap triesUsed=" .. tostring(_t)
						.. " tier_dt=" .. string.format("%.2f", os.clock() - tierClock0)
						.. " bestSpent=" .. string.format("%.3f", bestSpentTry)
						.. " tierFillPct=" .. string.format("%.1f", LekIslandBudgetFillPct(bestSpentTry, b)), 2);
					break;
				end
			end
			if PANGAEA_BUDGET_FAST_FAIL_TRIES and type(PANGAEA_BUDGET_FAST_FAIL_TRIES) == "number" and PANGAEA_BUDGET_FAST_FAIL_TRIES > 0
				and type(PANGAEA_BUDGET_FAST_FAIL_SPENT_FRAC) == "number" and PANGAEA_BUDGET_FAST_FAIL_SPENT_FRAC > 0
				and _t >= PANGAEA_BUDGET_FAST_FAIL_TRIES then
				if bestSpentTry + budgetSlack < b * PANGAEA_BUDGET_FAST_FAIL_SPENT_FRAC then
					nominalTierLoopExit = "fast_fail_hopeless";
					fastFailStopCount = fastFailStopCount + 1;
					LekIslandProbeLog("### LekIslandProbe budgetTierCap budget=" .. tostring(b)
						.. " reason=fast_fail_hopeless bestSpent=" .. string.format("%.3f", bestSpentTry)
						.. " tierFillPct=" .. string.format("%.1f", LekIslandBudgetFillPct(bestSpentTry, b))
						.. " gate=b*" .. tostring(PANGAEA_BUDGET_FAST_FAIL_SPENT_FRAC)
						.. " triesUsed=" .. tostring(_t), 2);
					break;
				end
			end
		end
		if nominalTierLoopExit == nil and b == nominalBudget and islandRunTry >= maxTriesPerBudget then
			nominalTierLoopExit = "max_tries_per_budget";
		end
		if relaxBudgetTier == false and b == nominalBudget then
			island_nominal_tier_abort_no_relax = true;
			LekIslandProbeLog("### LekIslandProbe innerFailProfile layoutAttempt=" .. tostring(laIsland)
				.. " outer=" .. tostring(outerIsland)
				.. " reason=" .. tostring(nominalTierLoopExit or "nominal_tier_exhausted_skip_relax")
				.. " lastBudget=" .. tostring(b)
				.. " cumulativeRunOnceCalls=" .. tostring(cumulativeRunOnce)
				.. " nominalRunOnceCalls=" .. tostring(nominalRunOnceCount)
				.. " tierClockStops=" .. tostring(tierClockStopCount)
				.. " note=next_step_Pangaea_outer_regen", 2);
			break;
		end
		LekIslandProbeLog("### LekIslandProbe tierDrop layoutAttempt=" .. tostring(laIsland)
			.. " fromBudget=" .. tostring(b)
			.. " tierBestSpent=" .. string.format("%.3f", bestSpentTry)
			.. " tierFillPct=" .. string.format("%.1f", LekIslandBudgetFillPct(bestSpentTry, b))
			.. " nominalTarget=" .. tostring(nominalBudget)
			.. " globalBestSpentSoFar=" .. string.format("%.3f", globalBestSpent), 2);
		dbg2("### GeneratePangaeaIslands: budget " .. b .. " incomplete after tier attempts/caps; lowering target ###");
		b = b - 1;
	end

	restorePlotTypes();
	resetIslandGlobals();
	dbg2("### GeneratePangaeaIslands: budget retry exhausted, islands cleared ###");
	do
		local tEnd = (os and os.clock) and os.clock() or 0;
		LekIslandProbeLog("### LekIslandProbe layoutAttempt=" .. tostring(laIsland)
			.. " exit=budget_retry_exhausted ok=0 generatePangaeaIslands_total_dt=" .. tostring(tEnd - tIslandGen0)
			.. " globalBestSpent=" .. string.format("%.3f", globalBestSpent)
			.. " bestFillPctOfNominal=" .. string.format("%.1f", LekIslandBudgetFillPct(globalBestSpent, nominalBudget))
			.. " runOnceAborts=" .. tostring(tallyRunOnceAborts)
			.. " tierClockStops=" .. tostring(tierClockStopCount)
			.. " fastFailStops=" .. tostring(fastFailStopCount), 1);
		LekIslandProbeLog("### LekIslandProbe budgetOutcome layoutAttempt=" .. tostring(laIsland)
			.. " path=budget_retry_exhausted islandsPlaced=0 spent=0.000"
			.. " nominalTarget=" .. tostring(nominalBudget)
			.. " globalBestSpentSeen=" .. string.format("%.3f", globalBestSpent)
			.. " bestFillPctOfNominal=" .. string.format("%.1f", LekIslandBudgetFillPct(globalBestSpent, nominalBudget))
			.. " runOnceAborts=" .. tostring(tallyRunOnceAborts)
			.. " tierClockStops=" .. tostring(tierClockStopCount)
			.. " fastFailStops=" .. tostring(fastFailStopCount), 2);
		if not island_nominal_tier_abort_no_relax then
			LekIslandProbeLog("### LekIslandProbe innerFailProfile layoutAttempt=" .. tostring(laIsland)
				.. " outer=" .. tostring(outerIsland)
				.. " reason=budget_retry_exhausted_all_tiers"
				.. " cumulativeRunOnceCalls=" .. tostring(cumulativeRunOnce)
				.. " globalBestSpent=" .. string.format("%.3f", globalBestSpent)
				.. " relaxBudgetTier=" .. (relaxBudgetTier and "1" or "0"), 2);
		end
	end
	return 0, false;
end
