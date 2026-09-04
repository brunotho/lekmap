------------------------------------------------------------------------------
-- Lekmap_Islands_EquatorRing.lua — pangaea-draft policy for equator ring.
-- Coastal bonus (4a) + inland-sea spray (RoundInlandSeas) stay separate.
-- pangaeaDraft=false until coastal-bonus tuning done; then enable + retune.
------------------------------------------------------------------------------

function LekIslands_GetEquatorRingPolicy()
	return {
		id = "equator_ring",
		channels = {
			pangaeaDraft = false, -- TEMP: re-enable after coastal-bonus A/B
			coastalBonus = true,
			inlandSeaSpray = true,
		},
		-- Smaller water budget when draft turns on (polar basins only).
		totalBudget = 4,
		dotStripEarlyBudget = 1,
		budgetRetry = false,
		relaxBudgetTier = false,
		maxRunOnceNominal = 2,
		maxTriesPerBudget = 40,
		budgetFloor = 2,
		site = {
			basins = "polar",
			-- denyTags consulted later when engine filters by LekIslandTypeTags
		},
		denyTags = {
			"wrap_landbridge",
			"needs_ew_ocean_gap",
			"needs_polar_merge",
		},
		-- Allowlist-shaped menus (odds 0 = disabled but listed for retune).
		common = {
			{ type = "dot",                  odds = 5, pullBack = 1, effMin = 0, effMax = 0, budget = 0.09 },
			{ type = "pebble",               odds = 2, pullBack = 1, effMin = 0, effMax = 0, budget = 0.35 },
			{ type = "strip",                odds = 2, pullBack = 1, effMin = 0, effMax = 1, budget = 0.39 },
			{ type = "splinteredCliffsTiny", odds = 3, pullBack = 1, effMin = 0, effMax = 1, budget = 0.21 },
		},
		uncommon = {
			{ type = "mountainWall",     odds = 2, pullBack = 0, effMin = 0, effMax = 1, budget = 0.56 },
			{ type = "ridgePeak",        odds = 3, pullBack = 0, effMin = 0, effMax = 1, budget = 1.21 },
			{ type = "splinteredCliffs", odds = 2, pullBack = 0, effMin = 1, effMax = 2, budget = 0.66, fragile = true },
			{ type = "chunk",            odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 0.61 },
			{ type = "barbell",          odds = 3, pullBack = 1, effMin = 0, effMax = 2, budget = 0.62 },
			{ type = "snake",            odds = 3, pullBack = 1, effMin = 0, effMax = 2, budget = 1.04 },
			{ type = "lollipop",         odds = 2, pullBack = 1, effMin = 0, effMax = 2, budget = 0.94 },
			{ type = "wishbone",         odds = 4, pullBack = 1, effMin = 0, effMax = 1, budget = 0.69 },
			{ type = "twinBay",          odds = 1, pullBack = 1, effMin = 0, effMax = 1, budget = 1.00 },
			{ type = "shatteredRing",    odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.54 },
			{ type = "clusterOfTiny",    odds = 4, pullBack = 1, effMin = 0, effMax = 2, budget = 0.46, fragile = true },
		},
		rare = {
			-- Denied for ring geometry / wrap (odds 0):
			{ type = "polarMerge",          odds = 0, pullBack = 3, effMin = 3, effMax = 5, budget = 2.5 },
			{ type = "wrapSoftLandbridge",  odds = 0, pullBack = 2, effMin = 2, effMax = 5, budget = 2.5 },
			{ type = "steppingStone",       odds = 0, pullBack = 2, effMin = 2, effMax = 4, budget = 0.9 },
			{ type = "crescent",            odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.50 },
			{ type = "volcanicRing",        odds = 1, pullBack = 1, effMin = 1, effMax = 2, budget = 1.71 },
			{ type = "solomonsMinesIsland", odds = 0, pullBack = 1, effMin = 0, effMax = 2, budget = 1.54 },
			{ type = "sinaiIsland",         odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.39 },
			{ type = "geothermalIsland",    odds = 1, pullBack = 2, effMin = 2, effMax = 4, budget = 1.2 },
			{ type = "junglePeak",          odds = 1, pullBack = 1, effMin = 2, effMax = 3, budget = 1.52 },
			{ type = "lakeRidge",           odds = 0, pullBack = 0, effMin = 0, effMax = 0, budget = 0 },
		},
		dotStripEarly = {
			{ type = "dot", odds = 5, budget = 0.09 },
			{ type = "strip", odds = 2, budget = 0.39 },
		},
		specialPhaseTypes = {
			geothermalIsland = true,
		},
		namedPriority = {},
		tierBasePriority = {
			rare = 5,
			uncommon = 6,
			common = 8,
		},
	};
end
