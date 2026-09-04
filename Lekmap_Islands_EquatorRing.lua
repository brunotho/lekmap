------------------------------------------------------------------------------
-- Lekmap_Islands_EquatorRing.lua — pangaea-draft policy for equator ring.
-- Coastal bonus (4a) + inland-sea spray (RoundInlandSeas) stay separate.
--
-- v1: shoreSineChain in rare menu; polar basins; no EW-gap / wrap / polarMerge.
-- Budget ~half of Fractal Pangaea (less usable ocean).
------------------------------------------------------------------------------

function LekIslands_GetEquatorRingPolicy()
	return {
		id = "equator_ring",
		channels = {
			pangaeaDraft = true,
			coastalBonus = true,
			inlandSeaSpray = true,
		},
		totalBudget = 5,
		dotStripEarlyBudget = 1,
		budgetRetry = false,
		relaxBudgetTier = false,
		maxRunOnceNominal = 2,
		maxTriesPerBudget = 40,
		budgetFloor = 2,
		site = {
			basins = "polar",
		},
		denyTags = {
			"wrap_landbridge",
			"needs_ew_ocean_gap",
			"needs_polar_merge",
		},
		common = {
			{ type = "dot",                  odds = 6, pullBack = 1, effMin = 0, effMax = 0, budget = 0.09 },
			{ type = "pebble",               odds = 3, pullBack = 1, effMin = 0, effMax = 0, budget = 0.35 },
			{ type = "strip",                odds = 3, pullBack = 1, effMin = 0, effMax = 1, budget = 0.39 },
			{ type = "splinteredCliffsTiny", odds = 3, pullBack = 1, effMin = 0, effMax = 1, budget = 0.21 },
		},
		uncommon = {
			{ type = "snake",               odds = 5, pullBack = 1, effMin = 0, effMax = 2, budget = 1.04 },
			{ type = "barbell",             odds = 4, pullBack = 1, effMin = 0, effMax = 2, budget = 0.62 },
			{ type = "wishbone",            odds = 4, pullBack = 1, effMin = 0, effMax = 1, budget = 0.69 },
			{ type = "lollipop",            odds = 2, pullBack = 1, effMin = 0, effMax = 2, budget = 0.94 },
			{ type = "chunk",               odds = 2, pullBack = 1, effMin = 0, effMax = 2, budget = 0.61 },
			{ type = "clusterOfTiny",       odds = 5, pullBack = 1, effMin = 0, effMax = 2, budget = 0.46, fragile = true },
			{ type = "splinteredCliffs",    odds = 2, pullBack = 0, effMin = 1, effMax = 2, budget = 0.66, fragile = true },
			{ type = "mountainWall",        odds = 1, pullBack = 0, effMin = 0, effMax = 1, budget = 0.56 },
			{ type = "ridgePeak",           odds = 2, pullBack = 0, effMin = 0, effMax = 1, budget = 1.21 },
			{ type = "twinBay",             odds = 1, pullBack = 1, effMin = 0, effMax = 1, budget = 1.00 },
			{ type = "shatteredRing",       odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.54 },
		},
		rare = {
			-- ~8–16+ land across 3–5 islets → between crescent (1.50) and volcanicRing (1.71)
			{ type = "shoreSineChain",     odds = 5, pullBack = 1, effMin = 0, effMax = 5, budget = 1.55 },
			{ type = "crescent",            odds = 2, pullBack = 1, effMin = 0, effMax = 2, budget = 1.50 },
			{ type = "volcanicRing",        odds = 1, pullBack = 1, effMin = 1, effMax = 2, budget = 1.71 },
			{ type = "junglePeak",          odds = 2, pullBack = 1, effMin = 2, effMax = 3, budget = 1.52 },
			{ type = "sinaiIsland",         odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.39 },
			{ type = "geothermalIsland",    odds = 1, pullBack = 2, effMin = 2, effMax = 4, budget = 1.2 },
			-- Inland paint only (no new land) — budget 0; rare specialty like crescent
			{ type = "lakeRidge",           odds = 2, pullBack = 0, effMin = 0, effMax = 0, budget = 0 },
			-- denied: polarMerge, wrapSoftLandbridge, steppingStone, EdgeOfWorld, fjordPeninsula
		},
		dotStripEarly = {
			{ type = "dot", odds = 5, budget = 0.09 },
			{ type = "strip", odds = 2, budget = 0.39 },
		},
		specialPhaseTypes = {
			shoreSineChain = true,
			geothermalIsland = true,
			lakeRidge = true,
		},
		namedPriority = {
			shoreSineChain = 1,
			lakeRidge = 2,
		},
		tierBasePriority = {
			rare = 5,
			uncommon = 6,
			common = 8,
		},
	};
end
