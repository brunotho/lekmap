------------------------------------------------------------------------------
-- Lekmap_Islands_Compact.lua — pangaea-draft policy for classic compact blob.
-- Coastal bonus + inland-sea spray are NOT owned here.
------------------------------------------------------------------------------

function LekIslands_GetCompactPolicy()
	return {
		id = "compact",
		channels = {
			pangaeaDraft = true,
			-- coastalBonus / inlandSeaSpray: other modules; listed for docs only
			coastalBonus = true,
			inlandSeaSpray = true,
		},
		totalBudget = 8,
		dotStripEarlyBudget = 2,
		budgetRetry = true,
		relaxBudgetTier = false,
		maxRunOnceNominal = 2,
		maxTriesPerBudget = 80,
		budgetFloor = 5,
		site = { basins = "any_ocean" },
		common = {
			{ type = "dot",                  odds = 5, pullBack = 1, effMin = 0, effMax = 0, budget = 0.09 },
			{ type = "pebble",               odds = 2, pullBack = 1, effMin = 0, effMax = 0, budget = 0.35 },
			{ type = "strip",                odds = 2, pullBack = 1, effMin = 0, effMax = 1, budget = 0.39 },
			{ type = "splinteredCliffsTiny", odds = 3, pullBack = 1, effMin = 0, effMax = 1, budget = 0.21 },
		},
		uncommon = {
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
			{ type = "clusterOfTiny",       odds = 5, pullBack = 1, effMin = 0, effMax = 2, budget = 0.46, fragile = true },
		},
		rare = {
			{ type = "polarMerge",          odds = 7, pullBack = 3, effMin = 3, effMax = 5, budget = 2.5 },
			{ type = "steppingStone",       odds = 1, pullBack = 2, effMin = 2, effMax = 4, budget = 0.9 },
			{ type = "crescent",            odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.50 },
			{ type = "volcanicRing",        odds = 1, pullBack = 1, effMin = 1, effMax = 2, budget = 1.71 },
			{ type = "solomonsMinesIsland", odds = 0, pullBack = 1, effMin = 0, effMax = 2, budget = 1.54 },
			{ type = "sinaiIsland",         odds = 1, pullBack = 1, effMin = 0, effMax = 2, budget = 1.39 },
			{ type = "geothermalIsland",    odds = 2, pullBack = 2, effMin = 2, effMax = 5, budget = 1.2 },
			{ type = "wrapSoftLandbridge",  odds = 2, pullBack = 2, effMin = 2, effMax = 5, budget = 2.5 },
			{ type = "junglePeak",          odds = 2, pullBack = 1, effMin = 2, effMax = 3, budget = 1.52 },
			{ type = "lakeRidge",           odds = 0, pullBack = 0, effMin = 0, effMax = 0, budget = 0 },
		},
		dotStripEarly = {
			{ type = "dot", odds = 5, budget = 0.09 },
			{ type = "strip", odds = 2, budget = 0.39 },
		},
		specialPhaseTypes = {
			polarMerge = true,
			steppingStone = true,
			wrapSoftLandbridge = true,
			lakeRidge = true,
			geothermalIsland = true,
		},
		namedPriority = {
			polarMerge = 1,
			wrapSoftLandbridge = 2,
		},
		tierBasePriority = {
			rare = 5,
			uncommon = 6,
			common = 8,
		},
	};
end
