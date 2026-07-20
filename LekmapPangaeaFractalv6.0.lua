------------------------------------------------------------------------------
--	FILE:	 LekmapPangaeaFractalv6.0.lua (Modified Pangaea_Plus.lua)
--	AUTHOR:  Original Bob Thomas, Changes HellBlazer, lek10, EnormousApplePie, Cirra, Meota, t0mtezuma
--	PURPOSE: Global map script - Simulates a Pan-Earth Supercontinent, with
--           numerous tectonic island chains.
------------------------------------------------------------------------------
--	Copyright (c) 2011 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------


-- :2863 using Hax function if coastal
-- :9291 call to expand coastal plots

-- 1=progress milestones (tuple vs legacy, outcomes) | 2=+ ChooseLocations / feasibility | 3=tuple phases, pools, DFS detail
_lek_mapgen_log_verbosity = 1;
-- Small map: softer Pangaea/island tracing (outer loop + per-island spam). Tuple bench line (`LekBench6`): on for Global six pace (option 13 = 2), off for Legacy pace (13 = 1).
_lek_mapgen_world_is_small = false;

-- TEST ONLY: not used in normal maps. When true, PlaceResources ends with LekTestCopperOnAllWater (ocean/lake copper); engine may skip tiles.
_lek_test_copper_on_all_water = false;

-- RS5: after OG balance majors, place small iron+horse in r4-5 and r6-7 (iron flat-only; horse OG flat primary).
_lek_strat_extra_balance_smalls = true;
-- RS5: when true, skip biome ProcessResourceList / PlaceSmallQuantities / backfill for horse+iron.
-- Split from extras. false = globals on; volume via rs5_* freqs only (no post trim).
_lek_strat_skip_global_horse_iron = false;
-- RS5 oil/uranium balance recipe (in AddStrategicBalanceResources): band guarantees instead of OG 2×oil + 2×uran.
-- Oil: major r1-3, major/minor r4-5, major/minor r6-7. Uran: 50/50 major/minor r3-5 + qty1 r6-8.
-- Land oil globals off (majors + small_strat); CS minor oil kept. Uran majors/backfill spaced.
_lek_strat_ou_bands = true;
-- Per-tile horse/iron/oil/uran placement lines (`### LEK_STRAT_HIT`). On with strat testing.
_lek_strat_audit_log_each_hit = true;

-- Setup UI shows only two map script rows; code still uses legacy indices 1–19 via LekMapGetCustomOption.
-- Engine Map.GetCustomOption(1..2) are those rows, mapped by _lek_map_visible_ui_order to old 13, 17.
-- Start Quality (legacy index 5) is stubbed in _lek_map_hidden_option_defaults, not shown in Advanced Setup.
-- All other legacy indices return fixed defaults matching the former full menu DefaultValues.
_lek_map_visible_ui_order = { 13, 17 }
_lek_map_hidden_option_defaults = {
	[1] = 2, [2] = 2, [3] = 2, [4] = 2,
	[5] = 2,
	[6] = 2, [7] = 15, [8] = 2, [9] = 2, [10] = 2,
	[11] = 6, [12] = 6, [14] = 5, [15] = 1, [16] = 9,
	[18] = 2, [19] = 2,
}
_lek_map_visible_option_defaults = { [13] = 2, [17] = 1 }

function LekMapGetCustomOption(oldindex)
	for ui_slot = 1, #_lek_map_visible_ui_order do
		if _lek_map_visible_ui_order[ui_slot] == oldindex then
			if Map and Map.GetCustomOption then
				local v = Map.GetCustomOption(ui_slot)
				if type(v) == "number" and v >= 1 then
					return v
				end
			end
			return _lek_map_visible_option_defaults[oldindex]
		end
	end
	local h = _lek_map_hidden_option_defaults[oldindex]
	if h ~= nil then
		return h
	end
	return 1
end

include("4_HBMapGenerator");
include("2_HBFractalWorld");
include("6_HBFeatureGenerator");
include("5_HBTerrainGenerator");
include("IslandMaker");
include("MultilayeredFractal");
include("3_PangaeaIslands");
include("X_IslandHelpers");
print("### LekmapPangaeaFractal: includes done ###");

-- Option 13 "Geometric Balance": Legacy = HB only. Global six = one-map tuple: extra relax phases on the current landmask,
-- no HB layout regen from tuple/placement/lux gates (see _lek_global_six_one_map_placement_mode); fractal+Pangaea outer redraw unchanged.
-- For this mapscript's one-map focus, keep HB layout loop at one layout.
_lek_global_six_regen_max_layouts = 1;
_lek_fjord_distance_setting_fixed = 1;
_lek_fjord_length_setting_fixed = 1;
-- Pangaea inner loop: redraw fractal+Pangaea until land/islands pass (per single GeneratePlotTypes call). Tuple regen does NOT bump this counter.
_lek_pangaea_max_outer_failed = false;
-- Regen loop: GenerateMap() may re-run LekHB_GenerateMap_Core when code still requests layout regen (e.g. some non-Pangaea maps).
-- Pangaea global-six enables one-map mode so tuple/search does not burn layouts for tuple-fail or post-placement gates; outer fractal failure still uses regen.
_lek_enable_hb_generatemap_regen_loop = true;
_lek_map_layout_attempt = nil;
_lek_global_six_request_map_regen = false;

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "## Lekmap 6.0 -- Fractal Pangaea",
		Description = "A map script made for Lekmod based of HB's Mapscript v8.1. Pangaea - Fractal",
		IsAdvancedMap = false,
		IconIndex = 0,
		SortIndex = 2,
		SupportsMultiplayer = true,
	-- Two rows in Advanced Setup; Start Quality (legacy 5) stubbed — see _lek_map_hidden_option_defaults.
	CustomOptions = {
			{
				Name = "Starting Locations",
				Values = {
					"Legacy (fast)",
					"Geometric Balance (slow)",
				},
				DefaultValue = 2,
				SortPriority = -100,
			},
			{
				Name = "Coastal Spawns",
				Values = {
					"Coastal Civs Only",
					"Force 2 Coastals",
					"All Inland",
					"Pure Random",
				},
				DefaultValue = 1,
				SortPriority = -98,
			},
		},
	};
end
------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	_lek_mapgen_world_is_small = false;

	local LandSizeXDuel = 22 + (LekMapGetCustomOption(11) * 2);
	local LandSizeYDuel = 18 + (LekMapGetCustomOption(12) * 2);

	local LandSizeXTiny = 36 + (LekMapGetCustomOption(11) * 2);
	local LandSizeYTiny = 30 + (LekMapGetCustomOption(12) * 2);

	local LandSizeXSmall = 32 + (LekMapGetCustomOption(11) * 2);
	local LandSizeYSmall = 40 + (LekMapGetCustomOption(12) * 2);

	local LandSizeXStandard = 54 + (LekMapGetCustomOption(11) * 2);
	local LandSizeYStandard = 48 + (LekMapGetCustomOption(12) * 2);

	local LandSizeXLarge = 62 + (LekMapGetCustomOption(11) * 2);
	local LandSizeYLarge = 54 + (LekMapGetCustomOption(12) * 2);

	local LandSizeXHuge = 70 + (LekMapGetCustomOption(11) * 2);
	local LandSizeYHuge = 62 + (LekMapGetCustomOption(12) * 2);

	local worldsizes = {};

	worldsizes = {

		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {LandSizeXDuel, LandSizeYDuel}, -- 1020
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {LandSizeXTiny, LandSizeYTiny}, -- 2016
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {LandSizeXSmall, LandSizeYSmall}, -- 3016
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {LandSizeXStandard, LandSizeYStandard}, -- 3960
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {LandSizeXLarge, LandSizeYLarge}, -- 5032
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {LandSizeXHuge, LandSizeYHuge} -- 6068
		}
		
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	_lek_mapgen_world_is_small = (world ~= nil and worldSize == GameInfo.Worlds.WORLDSIZE_SMALL.ID);
	if (world ~= nil) then
		return {
			Width = grid_size[1],
			Height = grid_size[2],
			WrapX = true,
		}; 
	end

end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- START OF FRACTAL PANGAEA CREATION CODE
------------------------------------------------------------------------------
PangaeaFractalWorld = {};
------------------------------------------------------------------------------
function PangaeaFractalWorld.Create(fracXExp, fracYExp)
	local gridWidth, gridHeight = Map.GetGridSize();
	
	local data = {
		InitFractal = FractalWorld.InitFractal,
		ShiftPlotTypes = FractalWorld.ShiftPlotTypes,
		ShiftPlotTypesBy = FractalWorld.ShiftPlotTypesBy,
		DetermineXShift = FractalWorld.DetermineXShift,
		DetermineYShift = FractalWorld.DetermineYShift,
		GenerateCenterRift = FractalWorld.GenerateCenterRift,
		GeneratePlotTypes = PangaeaFractalWorld.GeneratePlotTypes,	-- Custom method
		
		iFlags = Map.GetFractalFlags(),
		
		fracXExp = fracXExp,
		fracYExp = fracYExp,
		
		iNumPlotsX = gridWidth,
		iNumPlotsY = gridHeight,
		plotTypes = table.fill(PlotTypes.PLOT_OCEAN, gridWidth * gridHeight)
	};
		
	return data;
end

------------------------------------------------------------------------------
-- Before PangaeaIslands: demote mountains with at least one OCEAN neighbor (main + inland-sea mask).
-- pctRoll: 0-100, fraction to demote (100 = all). Returns count demoted.
------------------------------------------------------------------------------
function LekDemoteMountainsTouchingOcean(plotTypes, iW, iH, wrapX, wrapY, pctRoll)
	if not GetHexNeighbor or not plotTypes or type(pctRoll) ~= "number" then
		return 0;
	end
	if pctRoll <= 0 then
		return 0;
	end
	local n = 0;
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local idx = y * iW + x + 1;
			if plotTypes[idx] == PlotTypes.PLOT_MOUNTAIN then
				local touches = false;
				for d = 1, 6 do
					local nx, ny = GetHexNeighbor(x, y, d, iW, iH, wrapX, wrapY or false);
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
						if plotTypes[ny * iW + nx + 1] == PlotTypes.PLOT_OCEAN then
							touches = true;
							break;
						end
					end
				end
				if touches and Map.Rand(100, "lek_demote_coast_mtn") < pctRoll then
					plotTypes[idx] = PlotTypes.PLOT_HILLS;
					n = n + 1;
				end
			end
		end
	end
	return n;
end

------------------------------------------------------------------------------
-- After majors are placed: demote only mountains that touch ocean, are PlotDistance 4 from a coastal
-- major start, and are still mountains on the live map. Replaces broad LekDemoteMountainsTouchingOcean(100).
------------------------------------------------------------------------------
function LekDemoteRing4CoastalMountainsNearCoastalMajors(start_plot_database)
	if not start_plot_database or not GetHexNeighbor then
		return 0;
	end
	local iW, iH = Map.GetGridSize();
	if not iW or not iH then
		return 0;
	end
	local wrapX = Map.IsWrapX and Map:IsWrapX() or false;
	local wrapY = Map.IsWrapY and Map:IsWrapY() or false;
	local function pd(x1, y1, x2, y2)
		if Map.PlotDistance then
			return Map.PlotDistance(x1, y1, x2, y2);
		end
		if PlotDistance then
			return PlotDistance(x1, y1, x2, y2);
		end
		return nil;
	end
	local starts = {};
	for loop = 1, start_plot_database.iNumCivs or 0 do
		local pid = start_plot_database.player_ID_list[loop];
		local pl = pid and Players[pid];
		if pl and pl:IsEverAlive() and not pl:IsMinorCiv() then
			local sp = pl:GetStartingPlot();
			if sp and sp:IsCoastalLand() then
				starts[#starts + 1] = { sp:GetX(), sp:GetY() };
			end
		end
	end
	if #starts == 0 then
		return 0;
	end
	local n = 0;
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlot(x, y);
			if plot and plot:GetPlotType() == PlotTypes.PLOT_MOUNTAIN then
				local touchesOcean = false;
				for d = 1, 6 do
					local nx, ny = GetHexNeighbor(x, y, d, iW, iH, wrapX, wrapY);
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
						local np = Map.GetPlot(nx, ny);
						if np and np:GetPlotType() == PlotTypes.PLOT_OCEAN then
							touchesOcean = true;
							break;
						end
					end
				end
				if touchesOcean then
					for si = 1, #starts do
						local st = starts[si];
						if pd(x, y, st[1], st[2]) == 4 then
							plot:SetPlotType(PlotTypes.PLOT_HILLS, false, true);
							n = n + 1;
							break;
						end
					end
				end
			end
		end
	end
	return n;
end

------------------------------------------------------------------------------
-- Round thin inland seas (Lua 5.1 compatible: no goto). Inland-sea islands are sprayed during this pass.
------------------------------------------------------------------------------
function RoundInlandSeas(self)
	if not GetHexNeighbor then return; end
	local iW, iH = self.iNumPlotsX, self.iNumPlotsY;
	local wrapX = Map.IsWrapX and Map:IsWrapX() or false;
	local wrapY = Map.IsWrapY and Map:IsWrapY() or false;
	local plotTypes = self.plotTypes;
	local function pidx(x, y) return y * iW + x + 1; end
	local function isOcean(x, y)
		if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
		return plotTypes[pidx(x, y)] == PlotTypes.PLOT_OCEAN;
	end
	local function isLand(x, y)
		if x < 0 or x >= iW or y < 0 or y >= iH then return false; end
		return plotTypes[pidx(x, y)] ~= PlotTypes.PLOT_OCEAN;
	end

	local openOcean = {};
	local queue = {};
	for x = 0, iW - 1 do
		for _, edgeY in ipairs({0, iH - 1}) do
			if isOcean(x, edgeY) then
				local k = edgeY * iW + x;
				if not openOcean[k] then openOcean[k] = true; queue[#queue + 1] = {x, edgeY}; end
			end
		end
	end
	local q = 1;
	while q <= #queue do
		local cx, cy = queue[q][1], queue[q][2];
		q = q + 1;
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(cx, cy, d, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH and isOcean(nx, ny) then
				local nk = ny * iW + nx;
				if not openOcean[nk] then openOcean[nk] = true; queue[#queue + 1] = {nx, ny}; end
			end
		end
	end

	-- Land distance to open ocean (hex steps). Used so inland-sea expansion only nibbles toward pangaea center.
	local distToOpenOcean = {};
	queue = {};
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local k = y * iW + x;
			if openOcean[k] then
				for d = 1, 6 do
					local nx, ny = GetHexNeighbor(x, y, d, iW, iH, wrapX, wrapY);
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH and isLand(nx, ny) then
						local nk = ny * iW + nx;
						if distToOpenOcean[nk] == nil then
							distToOpenOcean[nk] = 1;
							queue[#queue + 1] = {nx, ny};
						end
					end
				end
			end
		end
	end
	q = 1;
	while q <= #queue do
		local cx, cy = queue[q][1], queue[q][2];
		q = q + 1;
		local ck = cy * iW + cx;
		local cd = distToOpenOcean[ck];
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(cx, cy, d, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH and isLand(nx, ny) then
				local nk = ny * iW + nx;
				if distToOpenOcean[nk] == nil then
					distToOpenOcean[nk] = cd + 1;
					queue[#queue + 1] = {nx, ny};
				end
			end
		end
	end

	local inlandSet = {};
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			if isOcean(x, y) and not openOcean[y * iW + x] then
				inlandSet[y * iW + x] = {x, y};
			end
		end
	end
	if next(inlandSet) == nil then
		return;
	end

	local components = {};
	local used = {};
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local k = y * iW + x;
			if inlandSet[k] and not used[k] then
				local comp = {};
				queue = {{x, y}};
				used[k] = true;
				comp[k] = true;
				q = 1;
				while q <= #queue do
					local cx, cy = queue[q][1], queue[q][2];
					q = q + 1;
					for d = 1, 6 do
						local nx, ny = GetHexNeighbor(cx, cy, d, iW, iH, wrapX, wrapY);
						if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
							local nk = ny * iW + nx;
							if inlandSet[nk] and not used[nk] then
								used[nk] = true; comp[nk] = true; queue[#queue + 1] = {nx, ny};
							end
						end
					end
				end
				components[#components + 1] = comp;
			end
		end
	end

	-- Hex distance from every tile to nearest main-ocean water. Inland-sea water must stay at
	-- dist >= MIN_INLAND_TO_OPEN_WATER_DIST (6 => at least 5 land tiles between the water bodies).
	local MIN_INLAND_TO_OPEN_WATER_DIST = 6;
	local distFromOpenWater = {};
	queue = {};
	for k, _ in pairs(openOcean) do
		local ox = k % iW;
		local oy = math.floor(k / iW);
		distFromOpenWater[k] = 0;
		queue[#queue + 1] = {ox, oy};
	end
	q = 1;
	while q <= #queue do
		local cx, cy = queue[q][1], queue[q][2];
		q = q + 1;
		local cd = distFromOpenWater[cy * iW + cx];
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(cx, cy, d, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local nk = ny * iW + nx;
				if distFromOpenWater[nk] == nil then
					distFromOpenWater[nk] = cd + 1;
					queue[#queue + 1] = {nx, ny};
				end
			end
		end
	end

	-- Paint inland-sea ocean that is too close to main ocean back to land. Optional comp limits to one body.
	local function enforceInlandOpenOceanLandGap(comp)
		local filled = 0;
		local keys = {};
		if comp ~= nil then
			for k in pairs(comp) do
				keys[#keys + 1] = k;
			end
		else
			for k in pairs(inlandSet) do
				keys[#keys + 1] = k;
			end
		end
		for i = 1, #keys do
			local k = keys[i];
			local d = distFromOpenWater[k];
			if d ~= nil and d < MIN_INLAND_TO_OPEN_WATER_DIST then
				local tx = k % iW;
				local ty = math.floor(k / iW);
				if isOcean(tx, ty) and not openOcean[k] then
					plotTypes[pidx(tx, ty)] = PlotTypes.PLOT_LAND;
					inlandSet[k] = nil;
					if comp ~= nil then
						comp[k] = nil;
					end
					filled = filled + 1;
				end
			end
		end
		return filled;
	end

	-- Fix ridge-created seas that already sit too close, before thickening.
	enforceInlandOpenOceanLandGap(nil);

	-- Thicken inland seas: random ocean seeds, paint ring-1 land→ocean with noise (no touch to open ocean).
	local MIN_SIZE = 6;
	local MIN_DIST_FROM_OPEN_OCEAN = 6;
	local BLOB_PAINT_ITERS = 12;
	local BLOB_EDGE_PAINT_PCT = 76;
	for _, comp in ipairs(components) do
		local tiles = {};
		for k in pairs(comp) do
			if inlandSet[k] ~= nil then
				tiles[#tiles + 1] = inlandSet[k];
			end
		end
		if #tiles >= MIN_SIZE then
			for _blob = 1, BLOB_PAINT_ITERS do
				local oceanCells = {};
				for k in pairs(comp) do
					local tx = k % iW;
					local ty = math.floor(k / iW);
					if isOcean(tx, ty) then
						oceanCells[#oceanCells + 1] = {tx, ty};
					end
				end
				if #oceanCells == 0 then
					break;
				end
				local seed = oceanCells[1 + Map.Rand(#oceanCells, "inland_blob_center")];
				local sx, sy = seed[1], seed[2];
				for d = 1, 6 do
					local nx, ny = GetHexNeighbor(sx, sy, d, iW, iH, wrapX, wrapY);
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH and isLand(nx, ny) then
						if Map.Rand(100, "inland_blob_noise") < BLOB_EDGE_PAINT_PCT then
							local adjOpenOcean = false;
							for d2 = 1, 6 do
								local ax, ay = GetHexNeighbor(nx, ny, d2, iW, iH, wrapX, wrapY);
								if ax >= 0 and ax < iW and ay >= 0 and ay < iH and openOcean[ay * iW + ax] then
									adjOpenOcean = true;
									break;
								end
							end
							local nk = ny * iW + nx;
							local distO = distToOpenOcean[nk];
							local waterDist = distFromOpenWater[nk];
							-- Require known land-dist AND hex-dist-to-main-ocean water (>= 6 => 5 land tiles between).
							local farEnough = (distO ~= nil) and (distO >= MIN_DIST_FROM_OPEN_OCEAN)
								and (waterDist ~= nil) and (waterDist >= MIN_INLAND_TO_OPEN_WATER_DIST);
							if not adjOpenOcean and farEnough then
								plotTypes[pidx(nx, ny)] = PlotTypes.PLOT_OCEAN;
								comp[nk] = true;
								inlandSet[nk] = {nx, ny};
							end
						end
					end
				end
			end
			-- After thicken: fill any too-close inland water back to land (same step family).
			enforceInlandOpenOceanLandGap(comp);
			tiles = {};
			for k in pairs(comp) do
				local tx = k % iW;
				local ty = math.floor(k / iW);
				if isOcean(tx, ty) then
					tiles[#tiles + 1] = {tx, ty};
				end
			end
			if #tiles > 0 then
			local minX, maxX, minY, maxY = iW, -1, iH, -1;
			for _, t in ipairs(tiles) do
				local x, y = t[1], t[2];
				if x < minX then minX = x; end
				if x > maxX then maxX = x; end
				if y < minY then minY = y; end
				if y > maxY then maxY = y; end
			end
			local w, h = maxX - minX + 1, maxY - minY + 1;
			local aspectX = w / math.max(1, h);
			local aspectY = h / math.max(1, w);
			-- Distance to mainland shore only (land bordering this inland sea). So spray can fill around sprayed islands.
			local shoreSet = {};
			for _, t in ipairs(tiles) do
				local x, y = t[1], t[2];
				for dir = 1, 6 do
					local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH and isLand(nx, ny) then
						shoreSet[ny * iW + nx] = true;
					end
				end
			end
			local distToShore = {};
			queue = {};
			for _, t in ipairs(tiles) do
				local x, y = t[1], t[2];
				local k = y * iW + x;
				for dir = 1, 6 do
					local nx, ny = GetHexNeighbor(x, y, dir, iW, iH, wrapX, wrapY);
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH and shoreSet[ny * iW + nx] then
						distToShore[k] = 1;
						queue[#queue + 1] = {x, y};
						break;
					end
				end
			end
			q = 1;
			while q <= #queue do
				local cx, cy = queue[q][1], queue[q][2];
				q = q + 1;
				local ck = cy * iW + cx;
				local cd = distToShore[ck];
				for dir = 1, 6 do
					local nx, ny = GetHexNeighbor(cx, cy, dir, iW, iH, wrapX, wrapY);
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
						local nk = ny * iW + nx;
						if comp[nk] and distToShore[nk] == nil then
							distToShore[nk] = cd + 1;
							queue[#queue + 1] = {nx, ny};
						end
					end
				end
			end
			local function distFromShore(x, y)
				return distToShore[y * iW + x] or 99;
			end
			-- Spray inland islands: blob pass widens seas; allow slightly elongated bodies (was 2.2).
			local doSpray = (aspectX < 2.85 and aspectY < 2.85);
			if doSpray then
				local SPRAY_CHANCE = 100;  -- was 90; set to 100 to verify spray logic (eligible = all painted)
				local MIN_DIST = 2;       -- tiles 2+ from mainland shore eligible (islands don't block)
				for _, t in ipairs(tiles) do
					local x, y = t[1], t[2];
					if plotTypes[pidx(x, y)] == PlotTypes.PLOT_OCEAN and distFromShore(x, y) >= MIN_DIST then
						if Map.Rand(100, "inland_spray") < SPRAY_CHANCE then
							local r = Map.Rand(100, "");
							if r < 3 then plotTypes[pidx(x, y)] = PlotTypes.PLOT_MOUNTAIN;
							else plotTypes[pidx(x, y)] = (r < 53) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND; end
						end
					end
				end
				local function isSprayLand(px, py)
					if px < 0 or px >= iW or py < 0 or py >= iH then return false; end
					local pt = plotTypes[pidx(px, py)];
					return pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS or pt == PlotTypes.PLOT_MOUNTAIN;
				end
				for _ = 1, 3 do
					local grown = {};
					for _, t in ipairs(tiles) do
						local x, y = t[1], t[2];
						if plotTypes[pidx(x, y)] == PlotTypes.PLOT_OCEAN and distFromShore(x, y) >= MIN_DIST then
							local landNeighbors = 0;
							for d = 1, 6 do
								local nx, ny = GetHexNeighbor(x, y, d, iW, iH, wrapX, wrapY);
								if isSprayLand(nx, ny) then landNeighbors = landNeighbors + 1; end
							end
							if landNeighbors >= 1 and Map.Rand(100, "inland_blob") < 72 then
								grown[#grown + 1] = { x, y };
							end
						end
					end
					for _, t in ipairs(grown) do
						local r = Map.Rand(100, "");
						if r < 3 then plotTypes[pidx(t[1], t[2])] = PlotTypes.PLOT_MOUNTAIN;
						else plotTypes[pidx(t[1], t[2])] = (r < 53) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND; end
					end
				end
			end
			end -- #tiles > 0
		end
	end
	-- Small / unthickened seas + any leftover violations.
	enforceInlandOpenOceanLandGap(nil);
end

------------------------------------------------------------------------------
local function LekPangaeaProbeLog(msg, minVerb)
	minVerb = minVerb or 2;
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

-- Outer-loop reject: row land < thinMax with rows at y±2 both > thickMin (horizontal water sliver).
local function LekPangaeaWaterSliceReject(plotTypes, iW, iH, thinMax, thickMin)
	if not plotTypes or type(iW) ~= "number" or type(iH) ~= "number" or iH < 5 then
		return false;
	end
	thinMax = thinMax or 10;
	thickMin = thickMin or 18;
	local rowN = {};
	for y = 0, iH - 1 do
		local n = 0;
		for x = 0, iW - 1 do
			if plotTypes[y * iW + x + 1] ~= PlotTypes.PLOT_OCEAN then
				n = n + 1;
			end
		end
		rowN[y] = n;
	end
	for y = 2, iH - 3 do
		if rowN[y] < thinMax and rowN[y - 2] > thickMin and rowN[y + 2] > thickMin then
			LekPangaeaProbeLog("### LekPangaea waterSliceReject row=" .. tostring(y)
				.. " land=" .. tostring(rowN[y])
				.. " rowN_y-2=" .. tostring(rowN[y - 2])
				.. " rowN_y+2=" .. tostring(rowN[y + 2])
				.. " thinMax=" .. tostring(thinMax) .. " thickMin=" .. tostring(thickMin), 1);
			return true;
		end
	end
	return false;
end

function PangaeaFractalWorld:GeneratePlotTypes(args)
	if(args == nil) then args = {}; end
	_lek_pangaea_max_outer_failed = false;

	local allcomplete = false;
	local outerAttempts = 0;
	local MAX_OUTER = 50;

	while allcomplete == false do
		outerAttempts = outerAttempts + 1;
		_lek_pangaea_outer_attempt = outerAttempts;
		if not _lek_mapgen_world_is_small then
			print("### Pangaea attempt " .. outerAttempts .. "/" .. MAX_OUTER .. " ###");
		end
		if outerAttempts > MAX_OUTER then
			_lek_pangaea_max_outer_failed = true;
			print("########################################################################");
			print("[Lekmap] Pangaea failed: " .. tostring(MAX_OUTER) .. " redraws, land/islands check never passed.");
			print("Game will load with NO major starting plots — everyone dead on spawn (intentional fail).");
			print("########################################################################");
			LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe outcome=max_outer_no_starts outerAttempts=" .. tostring(outerAttempts), 1);
			break;
		end

		local tPass0 = (os and os.clock) and os.clock() or 0;
		local laProbe = _lek_map_layout_attempt or 0;

		local sea_level_low = 64;
		local sea_level_normal = 67;
		local sea_level_high = 70;
		local world_size_for_sea = Map.GetWorldSize();
		if world_size_for_sea == GameInfo.Worlds.WORLDSIZE_SMALL.ID then
			-- Small canvas (reduced X): lower water threshold to keep comparable pangaea mass.
			sea_level_low = 54;
			sea_level_normal = 57;
			sea_level_high = 60;
		end
		local world_age_old = 3;
		local world_age_normal = 4;
		local world_age_new = 5;
		--
		local extra_mountains = 6;
		local grain_amount = 0;
		local adjust_plates = 1.3;
		local shift_plot_types = true;
		local tectonic_islands = true;
		local hills_ridge_flags = self.iFlags;
		local peaks_ridge_flags = self.iFlags;
		local has_center_rift = true;
		local adjadj = 1.2;
		local xshift = 0;
		local yshift = 0;
		local yshiftamt = 0;
		local xshiftamt = 0;
		local xstart, xend = 0,0;
		local ystart, yend = 0,0;

		local sea_level = LekMapGetCustomOption(4)
		if sea_level == 4 then
			sea_level = 1 + Map.Rand(3, "Random Sea Level - Lua");
		end
		local world_age = LekMapGetCustomOption(1)
		if world_age == 5 then
			world_age = 1 + Map.Rand(3, "Random World Age - Lua");
		end

		-- Set Sea Level according to user selection.
		local water_percent = sea_level_normal;
		local fjorddistmodif = _lek_fjord_distance_setting_fixed;
		local fjordlengthmodif = _lek_fjord_length_setting_fixed;
		local fjordmodif = (fjorddistmodif - 1) * (fjordlengthmodif + 1);
		if sea_level == 1 then -- Low Sea Level
			water_percent = sea_level_low
		elseif sea_level == 3 then -- High Sea Level
			water_percent = sea_level_high
		else -- Normal Sea Level
		
		end
		water_percent = water_percent - math.floor(fjordmodif / 10);
		
		-- Set values for hills and mountains according to World Age chosen by user.
		local adjustment = world_age_normal;
		if world_age == 4 then -- No Moutains
			adjustment = world_age_old;
			adjust_plates = adjust_plates * 0.5;
		elseif world_age == 3 then -- 5 Billion Years
			adjustment = world_age_old;
			adjust_plates = adjust_plates * 0.5;
		elseif world_age == 1 then -- 3 Billion Years
			adjustment = world_age_new;
			adjust_plates = adjust_plates * 1;
		else -- 4 Billion Years
		end
		-- Apply adjustment to hills and peaks settings.
		local hillsBottom1 = 26 - (adjustment * adjadj);
		local hillsTop1 = 26 + (adjustment * adjadj);
		local hillsBottom2 = 72 - (adjustment * adjadj);
		local hillsTop2 = 72 + (adjustment * adjadj);
		local hillsClumps = 1 + (adjustment * adjadj);
		local hillsNearMountains = 91 - (adjustment * 2) - extra_mountains;
		local mountains = 95 - adjustment - extra_mountains;
	
		if world_age == 4 then
			mountains = 300 - adjustment - extra_mountains;
		end

		-- Hills and Mountains handled differently according to map size - Bob
		local WorldSizeTypes = {};
		for row in GameInfo.Worlds() do
			WorldSizeTypes[row.Type] = row.ID;
		end
		local sizekey = Map.GetWorldSize();
		-- Fractal Grains
		local sizevalues = {
			[WorldSizeTypes.WORLDSIZE_DUEL]     = 3,
			[WorldSizeTypes.WORLDSIZE_TINY]     = 3,
			[WorldSizeTypes.WORLDSIZE_SMALL]    = 3,
			[WorldSizeTypes.WORLDSIZE_STANDARD] = 3,
			[WorldSizeTypes.WORLDSIZE_LARGE]    = 3,
			[WorldSizeTypes.WORLDSIZE_HUGE]		= 3
		};
		local grain = sizevalues[sizekey] or 3;
		-- Tectonics Plate Counts
		local platevalues = {
			[WorldSizeTypes.WORLDSIZE_DUEL]		= 100,
			[WorldSizeTypes.WORLDSIZE_TINY]     = 100,
			[WorldSizeTypes.WORLDSIZE_SMALL]    = 100,
			[WorldSizeTypes.WORLDSIZE_STANDARD] = 100,
			[WorldSizeTypes.WORLDSIZE_LARGE]    = 100,
			[WorldSizeTypes.WORLDSIZE_HUGE]     = 100
		};
		local numPlates = platevalues[sizekey] or 5;
		-- Add in any plate count modifications passed in from the map script. - Bob
		numPlates = numPlates * adjust_plates;

		-- Generate continental fractal layer and examine the largest landmass. Reject
		-- the result until the largest landmass occupies 90% or more of the total land.
		local bMapOK = false;
		local middleAttempts = 0;
		local MAX_MIDDLE = 20;
		while bMapOK == false do
			middleAttempts = middleAttempts + 1;
			if middleAttempts > MAX_MIDDLE then
				print("[Pangaea] MAX_MIDDLE reached, accepting choke check");
				bMapOK = true;
			end
			local done = false;
			local iAttempts = 0;
			local MAX_INNER = 50;
			local iWaterThreshold, biggest_area, iNumTotalLandTiles, iNumBiggestAreaTiles, iBiggestID;
			while done == false do
				local grain_dice = Map.Rand(7, "Continental Grain roll - LUA Pangaea");
				if grain_dice < 4 then
					grain_dice = 1;
				else
					grain_dice = 2;
				end
				local rift_dice = Map.Rand(3, "Rift Grain roll - LUA Pangaea");
				if rift_dice < 1 then
					rift_dice = -1;
				end

				rift_dice = -1;
				grain_dice = 7;

				self.continentsFrac = nil;
				self:InitFractal{continent_grain = grain_dice, rift_grain = rift_dice};
				iWaterThreshold = self.continentsFrac:GetHeight(water_percent);
		
				iNumTotalLandTiles = 0;
				for x = 0, self.iNumPlotsX - 1 do
					for y = 0, self.iNumPlotsY - 1 do
						local i = y * self.iNumPlotsX + x + 1;
						local val = self.continentsFrac:GetHeight(x, y);
						if(val <= iWaterThreshold) then
							self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
						else
							self.plotTypes[i] = PlotTypes.PLOT_LAND;
							iNumTotalLandTiles = iNumTotalLandTiles + 1;
						end
					end
				end

				SetPlotTypes(self.plotTypes);
				Map.RecalculateAreas();
		
				biggest_area = Map.FindBiggestArea(false);
				iNumBiggestAreaTiles = biggest_area:GetNumTiles();
				-- Now test the biggest landmass to see if it is large enough.
				if iNumBiggestAreaTiles >= iNumTotalLandTiles * 1 then
					done = true;
					iBiggestID = biggest_area:GetID();
				end
				iAttempts = iAttempts + 1;
				if iAttempts >= MAX_INNER then
					done = true;
					iBiggestID = biggest_area:GetID();
					print("[Pangaea] MAX_INNER reached, accepting best landmass");
				end

				--[[--Printout for debug use only
				print("-"); print("--- Pangaea landmass generation, Attempt#", iAttempts, "---");
				print("- This attempt successful: ", done);
				print("- Total Land Plots in world:", iNumTotalLandTiles);
				print("- Land Plots belonging to biggest landmass:", iNumBiggestAreaTiles);
				print("- Percentage of land belonging to Pangaea: ", 100 * iNumBiggestAreaTiles / iNumTotalLandTiles);
				print("- Continent Grain for this attempt: ", grain_dice);
				print("- Rift Grain for this attempt: ", rift_dice);
				print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -");
				print(".");--]]
		
			end

			-- Generate fractals to govern hills and mountains
			self.hillsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
			self.mountainsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
			self.hillsFrac:BuildRidges(numPlates, hills_ridge_flags, 1, 2);
			self.mountainsFrac:BuildRidges((numPlates * 2) / 3, peaks_ridge_flags, 6, 1);
			-- Get height values
			local iHillsBottom1 = self.hillsFrac:GetHeight(hillsBottom1);
			local iHillsTop1 = self.hillsFrac:GetHeight(hillsTop1);
			local iHillsBottom2 = self.hillsFrac:GetHeight(hillsBottom2);
			local iHillsTop2 = self.hillsFrac:GetHeight(hillsTop2);
			local iHillsClumps = self.mountainsFrac:GetHeight(hillsClumps);
			local iHillsNearMountains = self.mountainsFrac:GetHeight(hillsNearMountains);
			local iMountainThreshold = self.mountainsFrac:GetHeight(mountains);
			local iPassThreshold = self.hillsFrac:GetHeight(hillsNearMountains);
			-- Get height values for tectonic islands
			local iMountain100 = self.mountainsFrac:GetHeight(100);
			local iMountain99 = self.mountainsFrac:GetHeight(99);
			local iMountain97 = self.mountainsFrac:GetHeight(97);
			local iMountain95 = self.mountainsFrac:GetHeight(95);

			-- Because we haven't yet shifted the plot types, we will not be able to take advantage 
			-- of having water and flatland plots already set. We still have to generate all data
			-- for hills and mountains, too, then shift everything, then set plots one more time.
			for x = 0, self.iNumPlotsX - 1 do
				for y = 0, self.iNumPlotsY - 1 do
		
					local i = y * self.iNumPlotsX + x + 1;
					local val = self.continentsFrac:GetHeight(x, y);
					local mountainVal = self.mountainsFrac:GetHeight(x, y);
					local hillVal = self.hillsFrac:GetHeight(x, y);
	
					if(val <= iWaterThreshold) then
						self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
				
						if tectonic_islands then -- Build islands in oceans along tectonic ridge lines - Brian
							if (mountainVal == iMountain100) then -- Isolated peak in the ocean
								self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
							elseif (mountainVal == iMountain99) then
								self.plotTypes[i] = PlotTypes.PLOT_HILLS;
							elseif (mountainVal == iMountain97) or (mountainVal == iMountain95) then
								self.plotTypes[i] = PlotTypes.PLOT_LAND;
							end
						end
					
					else
						if (mountainVal >= iMountainThreshold) then
							if (hillVal >= iPassThreshold) then -- Mountain Pass though the ridgeline - Brian
								self.plotTypes[i] = PlotTypes.PLOT_HILLS;
							else -- Mountain
								-- set some randomness to mountains next to each other
								local iIsMount = Map.Rand(100, "Mountain Spawn Chance");
								--print("-"); print("Mountain Spawn Chance: ", iIsMount);
								local iIsMountAdj = 48 - adjustment;
								if iIsMount >= iIsMountAdj then
									self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
								else
									-- set some randomness to hills or flat land next to the mountain
									local iIsHill = Map.Rand(100, "Hill Spawn Chance");
									--print("-"); print("Mountain Spawn Chance: ", iIsMount);
									local iIsHillAdj = 30 - adjustment;
									if iIsHill >= iIsHillAdj then
										self.plotTypes[i] = PlotTypes.PLOT_HILLS;
									else
										self.plotTypes[i] = PlotTypes.PLOT_LAND;
									end
								end
							end
						elseif (mountainVal >= iHillsNearMountains) then
							self.plotTypes[i] = PlotTypes.PLOT_HILLS; -- Foot hills - Bob
						else
							if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
								self.plotTypes[i] = PlotTypes.PLOT_HILLS;
							else
								self.plotTypes[i] = PlotTypes.PLOT_LAND;
							end
						end
					end
				end
			end

			self:ShiftPlotTypes();
	
			--#####################
		



			--check landmass
			local iW, iH = Map.GetGridSize();
			local bfland = false;
			local startcol = 0;
			local cont = 0;
			local bprev = false;
			local biggest = 0;
			local mainstart = 0;
			local mainend = 0;
			local cencol = 0;
			local colshift = 0;
			local landincol = 0;
			local chkstart = 0;
			local chkend = 0;
			local chokepoint = 16;
			local bXChkFail = false;
			local bYChkFail = false;
			local bLastLand = false;
			local contlandincol = 0;
			local xcen = 0;
			local ycen = 0;

			--check y choke points
			print("-----------------------------------");
			print("Checking Y Chokes");
			print("-----------------------------------");
			for x = 1, iW do
				bfland = false;
				landincol = 0;
		
				for y = 2, iH-2  do
					local i = iW * y + x + 1;
					--print("Plot Location = ", i);
					if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
						landincol = landincol + 1;
						bfland = true;
					end
				end
		
				if bfland == false then
					--print("No Land Found in Col: ", x);
					bprev = false;
					if cont > biggest then
						biggest = cont;
						mainstart = startcol;
						mainend = x-1;
					end
					cont = 0;
					startcol = 0;
				else
					--print("Land Found In Col: ", x, "Qty: ", landincol);
					if startcol == 0 then
						startcol = x;
					end
					bprev = true;
					cont = cont + 1;	
				end
			end
		
			xstart = mainstart;
			xend = mainend;

			chkstart = mainstart + 8;
			chkend = mainend -  8;

			local landincol_prev1 = chokepoint;
			local landincol_prev2 = chokepoint;

			for x = chkstart, chkend do
				landincol = 0;
				contlandincol = 0;
				for y = 2, iH-2  do
					local i = iW * y + x + 1;
					--print("Plot Location = ", i);
					if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
					
						if bLastLand == true then
							landincol = landincol + 1;
							bLastLand = true;
						else
							landincol = 1;
							bLastLand = true;
						end
					else
						if contlandincol < landincol then
							contlandincol = landincol;
						end
						bLastLand = false;
						landincol = 0;
					end
				end

				--print("Checking Col:", x, "Continuous Land In Col: ", contlandincol);

				if landincol_prev1 + landincol_prev2 + contlandincol < 3 * chokepoint then
					--print("Choke Point in Col: ", x);
					bXChkFail = true;
				end
				landincol_prev2 = contlandincol;
				landincol_prev1 = landincol_prev2;
			end



			--check x choke points
			print("-----------------------------------");
			print("Checking X Chokes");
			print("-----------------------------------");
			startcol = 0;
			cont = 0;
			biggest = 0;
			for y = 2, iH-2 do
				bfland = false;
				landincol = 0;
		
				for x = 1, iW  do
					local i = iW * y + x;
					--print("Plot Location = ", i);
					if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
						landincol = landincol + 1;
						bfland = true;
					end
				end
		
				if bfland == false then
					--print("No Land Found in Row: ", y);
					bprev = false;
					if cont > biggest then
						biggest = cont;
						mainstart = startcol;
						mainend = y-1;
					end
					cont = 0;
					startcol = 0;
				else
					--print("Land Found In Row: ", y, "Qty: ", landincol);
					if startcol == 0 then
						startcol = y;
					end
					bprev = true;
					cont = cont + 1;	
				end
			end
	
			ystart = mainstart;
			yend = mainend;

			chkstart = mainstart + 5;
			chkend = mainend -  5;
			--print("-----");
			--print("Mainland Start Row: ", chkstart);
			--print("Mainland End Row: ", chkend);
			--print("-----");
			for y = chkstart, chkend do
				landincol = 0;
				contlandincol = 0;
				for x = 1, iW  do
					local i = iW * y + x;
					--print("Plot Location = ", i);
					if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
					
						if bLastLand == true then
							landincol = landincol + 1;
							bLastLand = true;
						else
							landincol = 1;
							bLastLand = true;
						end
					else
						if contlandincol < landincol then
							contlandincol = landincol;
						end
						bLastLand = false;
						landincol = 0;
					end
				end

				--print("Checking Col:", y, "Continuous Land In Col: ", contlandincol);

				if contlandincol < chokepoint then
					--print("Choke Point in Row: ", y);
					bYChkFail = true;
				end
			end



			if bXChkFail == true then
				print("X Check: False");
			else
				print("X Check: True");
			end

			if bYChkFail == true then
				print("Y Check: False");
			else
				print("Y Check: True");
			end

			if (bXChkFail == true or bYChkFail == true) then
				print("##############################################");
				print("Map No Good");
				print("##############################################");
				bMapOK = false;
			else
				print("##############################################");
				print("Map Passes");
				print("##############################################");
				bMapOK = true;
			
				cencol = xstart + ((xend - xstart) / 2);
				colshift = (iW/2)-cencol;
				print("Pangaea X Starts At Col: ", xstart, " And Edns At Col: ", xend);
				print("Center X of Lanmass is at Col: ", cencol, "Shift Need: ", colshift);
				xshiftamt = math.ceil(colshift);
				print("Actual Integer Shift Applied: ", xshiftamt);
				if xshiftamt > 0 then
					xshift = 1;
				elseif xshiftamt < 0 then
					xshift = 2;
				else
					xshift = 0;
				end

				print("##############################################");
				cencol = ystart + ((yend - ystart) / 2);
				colshift = (iH/2)-cencol;
				print("Pangaea Y Starts At Col: ", ystart, " And Edns At Col: ", yend);
				print("Center Y of Lanmass is at Col: ", cencol, "Shift Need: ", colshift);
				yshiftamt = math.ceil(colshift);
				print("Actual Integer Shift Applied: ", yshiftamt);
				print("##############################################");
				if yshiftamt > 0 then
					yshift = 1;
				elseif yshiftamt < 0 then
					yshift = 2;
				else
					yshift = 0;
				end
			end

		

		
		end

		--####################################################
		--clear area around pangaea
		local iW, iH = Map.GetGridSize();
		for x = 0, xstart - 1 do --clear west side of map
			for y = 0, iH - 1 do
				destPlotIndex = iW * y + x + 1;
				self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
			end
		end


		for x = xend + 1, iW - 1 do --clear east side of map
			for y = 0, iH - 1 do
				destPlotIndex = iW * y + x + 1;
				self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
			end
		end

		for y = 0, ystart - 1 do --clear south side of map
			for x = 0, iW - 1 do
				destPlotIndex = iW * y + x + 1;
				self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
			end
		end
	
		for y = yend + 1, iH - 1 do --clear north side of map
			for x = 0, iW - 1 do
				destPlotIndex = iW * y + x + 1;
				self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
			end
		end

		--map generated now shift to center
		-- Copy-on-shift: read from a scratch snapshot, write plotTypes. Avoids in-place races
		-- and replaces nil/OOB reads (whole-row ocean "slices") with explicit margin ocean.
		local plotCount = iW * iH;
		local shiftScratch = {};
		for si = 1, plotCount do
			shiftScratch[si] = self.plotTypes[si];
		end

		-- x shift first
		if xshift == 1 then --shift east
			print("-----------------------------------");
			print("Shifting East........");
			print("-----------------------------------");

			local dx = math.abs(xshiftamt);
			for y = 0, iH - 1 do
				for x = 0, iW - 1 do
					local destPlotIndex = iW * y + x + 1;
					local sx = x - dx;
					if sx >= 0 then
						local sourcePlotIndex = iW * y + sx + 1;
						self.plotTypes[destPlotIndex] = shiftScratch[sourcePlotIndex] or PlotTypes.PLOT_OCEAN;
					else
						self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
					end
				end
			end
		elseif xshift == 2 then --shift west
			print("-----------------------------------");
			print("Shifting West........");
			print("-----------------------------------");

			local dx = math.abs(xshiftamt);
			for y = 0, iH - 1 do
				for x = 0, iW - 1 do
					local destPlotIndex = iW * y + x + 1;
					local sx = x + dx;
					if sx < iW then
						local sourcePlotIndex = iW * y + sx + 1;
						self.plotTypes[destPlotIndex] = shiftScratch[sourcePlotIndex] or PlotTypes.PLOT_OCEAN;
					else
						self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
					end
				end
			end

		else
			--no shift
		end

		if xshift ~= 0 then
			for si = 1, plotCount do
				shiftScratch[si] = self.plotTypes[si];
			end
		end

		-- now shift y
		if yshift == 1 then --shift north
			print("-----------------------------------");
			print("Shifting North........");
			print("-----------------------------------");

			local dy = math.abs(yshiftamt);
			for y = 0, iH - 1 do
				for x = 0, iW - 1 do
					local destPlotIndex = iW * y + x + 1;
					local sy = y - dy;
					if sy >= 0 then
						local sourcePlotIndex = iW * sy + x + 1;
						self.plotTypes[destPlotIndex] = shiftScratch[sourcePlotIndex] or PlotTypes.PLOT_OCEAN;
					else
						self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
					end
				end
			end

		elseif yshift == 2 then --shift south
			print("-----------------------------------");
			print("Shifting South........");
			print("-----------------------------------");

			local dy = math.abs(yshiftamt);
			for y = 0, iH - 1 do
				for x = 0, iW - 1 do
					local destPlotIndex = iW * y + x + 1;
					local sy = y + dy;
					if sy < iH then
						local sourcePlotIndex = iW * sy + x + 1;
						self.plotTypes[destPlotIndex] = shiftScratch[sourcePlotIndex] or PlotTypes.PLOT_OCEAN;
					else
						self.plotTypes[destPlotIndex] = PlotTypes.PLOT_OCEAN;
					end
				end
			end

		else
			--no shift
		end

		--Fjordgenerator by t0m:
		fjord_distance_setting = _lek_fjord_distance_setting_fixed;
		if fjord_distance_setting ~= 1 then
			if fjord_distance_setting == 2 then
				fjord_d = 20;
			elseif fjord_distance_setting == 3 then
				fjord_d = 15;
			elseif fjord_distance_setting == 4 then
				fjord_d = 12;
			elseif fjord_distance_setting == 5 then
				fjord_d = 10;
			elseif fjord_distance_setting == 6 then
				fjord_d = 8;
			else
				fjord_d = 6;
			end
		
			fjord_length_setting = _lek_fjord_length_setting_fixed;
			if fjord_length_setting == 1 then
				fjord_l = 2;
			elseif fjord_length_setting == 2 then
				fjord_l = 3;
			elseif fjord_length_setting == 3 then
				fjord_l = 4;
			elseif fjord_length_setting == 4 then
				fjord_l = 5;
			else
				fjord_l = 6;
			end

			
			y = 9;
			k = 0;
			while (k == 0) -- Starts from bottom left going up. Fjordmaking towards right
			do
				x = 6;
				i = 0;
				while (i == 0)
				do
					local PlotIndex = iW * y + x + 1;
					if self.plotTypes[PlotIndex] ~= PlotTypes.PLOT_OCEAN then
						self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
						j = 1;
						while (j < fjord_l - 1 + Map.Rand(3, ""))
						do
							local rdm = Map.Rand(4, "")
							if (y % 2 == 0) then --even, either y increases or decreases, or x increases
								if rdm == 0 then
									y = y + 1;
								elseif rdm == 1 then
									y = y - 1;
								else
									x = x + 1;
								end
							else --odd, x increases by 1 and y increases or decreases by 1
								x = x + 1;
								if rdm == 0 then
									y = y + 1;
								elseif rdm == 1 then
									y = y - 1;
								end
							end
							if x > iW - 18 then
								i = 1;
							end
							local PlotIndex = iW * y + x + 1;
							self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
							j = j + 1;
						end
						i = 1;
					else
						x = x + 1;
						if x > iW - 18 then
							i = 1;
						end
					end
				end
				y = y + fjord_d - 2 + Map.Rand(5, "");
				if y > iH - 9 then
					k = 1;
				end
				i = 0;
			end
			y = 9;
			k = 0;
			while (k == 0)	-- Starts from bottom right going up. Fjordmaking towards left
			do
				x = iW - 6;
				i = 0;
				while (i == 0)
				do
					local PlotIndex = iW * y + x + 1;
					if self.plotTypes[PlotIndex] ~= PlotTypes.PLOT_OCEAN then
						self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
						j = 1;
						while (j < fjord_l - 1 + Map.Rand(3, ""))
						do
							local rdm = Map.Rand(4, "")
							if (y % 2 == 0) then
								x = x - 1;
								if rdm == 0 then
									y = y + 1;
								elseif rdm == 1 then
									y = y - 1;
								end
							else
								if rdm == 0 then
									y = y + 1;
								elseif rdm == 1 then
									y = y - 1;
								else
									x = x - 1;
								end
							end
							if x < 18 then
								i = 1;
							end
							local PlotIndex = iW * y + x + 1;
							self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
							j = j + 1;
						end
						i = 1;
					else
						x = x - 1;
						if x < 18 then
							i = 1;
						end
					end
				end
				y = y + fjord_d - 2 + Map.Rand(5, "");
				if y > iH - 9 then
					k = 1;
				end
				i = 0;
			end
			x = 10;
			k = 0;
			while (k == 0) -- Starts from top left going right. Fjordmaking downwards.
			do
				y = iH - 6;
				i = 0;
				while (i == 0)
				do
					local PlotIndex = iW * y + x + 1;
					if self.plotTypes[PlotIndex] ~= PlotTypes.PLOT_OCEAN then
						self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
						j = 1;
						while (j < fjord_l - 1 + Map.Rand(3, ""))
						do
							local rdm = Map.Rand(10, "")
							if (y % 2 == 0) then
								if rdm < 4 then
									y = y - 1;
								elseif rdm > 5 then
									y = y - 1;
									x = x - 1;
								elseif rdm == 4 then
									x = x - 1;
								else
									x = x + 1;
								end
							else
								if rdm < 4 then
									y = y - 1;
								elseif rdm > 5 then
									y = y - 1;
									x = x + 1;
								elseif rdm == 4 then
									x = x - 1;
								else
									x = x + 1;
								end
							end
							if y < 3 then
								i = 1;
							end
							local PlotIndex = iW * y + x + 1;
							self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
							j = j + 1;
						end
						i = 1;
					else
						y = y - 1;
						if y < 10 then
							i = 1;
						end
					end
				end
				x = x + fjord_d - 2 + Map.Rand(5, "");
				if x > iW - 10 then
					k = 1;
				end
				i = 0;
			end
			x = 10;
			k = 0;
			while (k == 0) -- Starts from bottom left going right. Fjordmaking upwards.
			do
				y = 6;
				i = 0;
				while (i == 0)
				do
					local PlotIndex = iW * y + x + 1;
					if self.plotTypes[PlotIndex] ~= PlotTypes.PLOT_OCEAN then
						self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
						j = 1;
						while (j < fjord_l - 1 + Map.Rand(3, ""))
						do
							local rdm = Map.Rand(10, "")
							if (y % 2 == 0) then
								if rdm < 4 then
									y = y + 1;
								elseif rdm > 5 then
									y = y + 1;
									x = x - 1;
								elseif rdm == 4 then
									x = x - 1;
								else
									x = x + 1;
								end
							else --odd, x increases by 1 and y increases or decreases by 1
								if rdm < 4 then
									y = y + 1;
								elseif rdm > 5 then
									y = y + 1;
									x = x + 1;
								elseif rdm == 4 then
									x = x - 1;
								else
									x = x + 1;
								end
							end
							if y > iH - 9 then
								i = 1;
							end
							local PlotIndex = iW * y + x + 1;
							self.plotTypes[PlotIndex] = PlotTypes.PLOT_OCEAN;
							j = j + 1;
						end
						i = 1;
					else
						y = y + 1;
						if y > iH - 9 then
							i = 1;
						end
					end
				end
				x = x + fjord_d - 2 + Map.Rand(5, "");
				if x > iW - 10 then
					k = 1;
				end
				i = 0;
			end
		end --fjord-process ends
		
		--#####################
		--add bays to the outter edge of the biggest landmass
		--[[
		local baysdone = false;
		local iW, iH = Map.GetGridSize();

		while baysdone == false do
			local x = Map.Rand(iW, "");
			local y = 6 + Map.Rand((iH-12), "");
			local plot = Map.GetPlot(x, y);

			if plot:IsCoastalLand() then
				--add a bay here



				print("----"); print("Bay Added"); print("----");
				baysdone = true;
			end
		end
		--]]
		--#####################


		local iW, iH = Map.GetGridSize();
		local centerX = iW / 2;
		local centerY = iH / 2;
		local fracFlags = {FRAC_POLAR = true};
		local baysFrac = Fractal.Create(iW, iH, 3, fracFlags, -1, -1);
		local iBaysThreshold = baysFrac:GetHeight(96);  --lakes lavel size
		local axis_list = {0.87, 0.81, 0.75};
		local axis_multiplier = axis_list[sea_level];
		local cohesion_list = {0.36, 0.33, 0.30};
		local cohesion_multiplier = cohesion_list[sea_level];
		majorAxis = centerX * cohesion_multiplier;
		minorAxis = centerY * cohesion_multiplier;
		majorAxisSquared = majorAxis * majorAxis;
		minorAxisSquared = minorAxis * minorAxis;
		local preBaysPlotTypes = {};
		for i = 1, iW * iH do
			preBaysPlotTypes[i] = self.plotTypes[i];
		end
		for y = 0, iH - 1 do
			for x = 0, iW - 1 do
				local deltaX = x - centerX;
				local deltaY = y - centerY;
				local deltaXSquared = deltaX * deltaX;
				local deltaYSquared = deltaY * deltaY;
				local d = deltaXSquared/majorAxisSquared + deltaYSquared/minorAxisSquared;
				if d > 1 then
					local i = y * iW + x + 1;
					local baysVal = baysFrac:GetHeight(x, y);
					if baysVal >= iBaysThreshold then
						self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
					end
				end
			end
		end

		do
			local function idx1(x, y, w)
				return y * w + x + 1;
			end
			local function bfsFarthest(startX, startY, member, w, h, wrapX)
				local dist = {};
				local q = {};
				local head, tail = 1, 1;
				local sk = startX .. "," .. startY;
				dist[sk] = 0;
				q[1] = { startX, startY };
				local bestK, bestD = sk, 0;
				while head <= tail do
					local cx, cy = q[head][1], q[head][2];
					head = head + 1;
					local dk = dist[cx .. "," .. cy];
					for dir = 1, 6 do
						local nx, ny = GetHexNeighbor(cx, cy, dir, w, h, wrapX, false);
						if nx >= 0 and nx < w and ny >= 0 and ny < h then
							local ii = idx1(nx, ny, w);
							if member[ii] then
								local nk = nx .. "," .. ny;
								if dist[nk] == nil then
									dist[nk] = dk + 1;
									if dist[nk] > bestD then
										bestD = dist[nk];
										bestK = nk;
									end
									tail = tail + 1;
									q[tail] = { nx, ny };
								end
							end
						end
					end
				end
				local bx, by = bestK:match("^([^,]+),([^,]+)$");
				return tonumber(bx), tonumber(by), bestD;
			end
			local function bfsDiameter(sx, sy, member, w, h, wrapX)
				local ax, ay = bfsFarthest(sx, sy, member, w, h, wrapX);
				local _, _, diam = bfsFarthest(ax, ay, member, w, h, wrapX);
				return diam;
			end
			local newOcean = {};
			for i = 1, iW * iH do
				if self.plotTypes[i] == PlotTypes.PLOT_OCEAN and preBaysPlotTypes[i] ~= PlotTypes.PLOT_OCEAN then
					newOcean[i] = true;
				end
			end
			local seen = {};
			for i = 1, iW * iH do
				if newOcean[i] and not seen[i] then
					local sy = math.floor((i - 1) / iW);
					local sx = (i - 1) % iW;
					local comp = {};
					local member = {};
					local q = {};
					local qh, qt = 1, 1;
					q[1] = { sx, sy };
					seen[i] = true;
					member[i] = true;
					comp[1] = i;
					while qh <= qt do
						local cx, cy = q[qh][1], q[qh][2];
						qh = qh + 1;
						for dir = 1, 6 do
							local nx, ny = GetHexNeighbor(cx, cy, dir, iW, iH, Map:IsWrapX(), false);
							if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
								local ni = idx1(nx, ny, iW);
								if newOcean[ni] and not seen[ni] then
									seen[ni] = true;
									member[ni] = true;
									comp[#comp + 1] = ni;
									qt = qt + 1;
									q[qt] = { nx, ny };
								end
							end
						end
					end
					local nComp = #comp;
					if nComp >= 6 and nComp <= 22 then
						local diam = bfsDiameter(sx, sy, member, iW, iH, Map:IsWrapX());
						if diam <= 7 and Map.Rand(100, "") < 68 then
							local want = 2 + Map.Rand(4, "");
							want = math.min(want, nComp);
							local chosen = {};
							local seedIdx = comp[1 + Map.Rand(nComp, "")];
							chosen[seedIdx] = true;
							self.plotTypes[seedIdx] = (Map.Rand(100, "") < 65) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
							local added = 1;
							while added < want do
								local found = nil;
								for _, ci in ipairs(comp) do
									if chosen[ci] then
										local cyy = math.floor((ci - 1) / iW);
										local cxx = (ci - 1) % iW;
										for dir = 1, 6 do
											local nx, ny = GetHexNeighbor(cxx, cyy, dir, iW, iH, Map:IsWrapX(), false);
											if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
												local ni = idx1(nx, ny, iW);
												if member[ni] and not chosen[ni] then
													found = ni;
													break;
												end
											end
										end
										if found then break; end
									end
								end
								if not found then break; end
								chosen[found] = true;
								self.plotTypes[found] = (Map.Rand(100, "") < 65) and PlotTypes.PLOT_HILLS or PlotTypes.PLOT_LAND;
								added = added + 1;
							end
						end
					end
				end
			end
		end

		-- Round thin inland seas (elongated from BuildRidges) so center can fit islands.
		local tBeforeRoundInland = (os and os.clock) and os.clock() or 0;
		LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe outer=" .. tostring(outerAttempts)
			.. " layoutAttempt=" .. tostring(laProbe)
			.. " preRoundInlandSeas_dt=" .. tostring(tBeforeRoundInland - tPass0), 2);
		RoundInlandSeas(self);
		local tAfterRoundInland = (os and os.clock) and os.clock() or 0;
		LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe outer=" .. tostring(outerAttempts)
			.. " layoutAttempt=" .. tostring(laProbe)
			.. " roundInlandSeas_dt=" .. tostring(tAfterRoundInland - tBeforeRoundInland), 2);

		local tM0 = (os and os.clock) and os.clock() or 0;
		local nDem = LekDemoteMountainsTouchingOcean(self.plotTypes, self.iNumPlotsX, self.iNumPlotsY, Map:IsWrapX(), false, 0);
		local tM1 = (os and os.clock) and os.clock() or 0;
		LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe demoteOceanAdjMountains_pct=0 n=" .. tostring(nDem)
			.. " dt=" .. tostring(tM1 - tM0), 2);

		local islandsOpt = LekMapGetCustomOption(16);
		local minIslands = (islandsOpt and islandsOpt > 1) and (islandsOpt - 1) or 0;
		local islandGenOpts = nil;
		if minIslands == 0 then
			islandGenOpts = { budgetRetry = false };
		end

		local islandsPlaced = 0;
		local islandsBudgetOk = true;
		local tIs0 = (os and os.clock) and os.clock() or 0;
		local ok, retPlaced, retBudgetOk = pcall(GeneratePangaeaIslands, self, islandGenOpts);
		local tIs1 = (os and os.clock) and os.clock() or 0;
		LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe outer=" .. tostring(outerAttempts)
			.. " layoutAttempt=" .. tostring(laProbe)
			.. " generatePangaeaIslands_dt=" .. tostring(tIs1 - tIs0)
			.. " islandsOk=" .. (ok and "1" or "0"), 1);
		if not ok then
			print("### GeneratePangaeaIslands ERROR (islands skipped): " .. tostring(retPlaced) .. " ###");
			islandsPlaced = 0;
			islandsBudgetOk = false;
		else
			islandsPlaced = tonumber(retPlaced) or 0;
			islandsBudgetOk = (retBudgetOk ~= false);
		end

		--check to make sure map has not failed
		local iNumLandTilesInUse = 0;
		local iW, iH = Map.GetGridSize();
		local landFloorFrac = 0.40;
		local iPercent = (iW * iH) * landFloorFrac;

		for y = 0, iH - 1 do
			for x = 0, iW - 1 do
				local i = iW * y + x + 1;
				if self.plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
					iNumLandTilesInUse = iNumLandTilesInUse + 1;
				end
			end
		end

		if not _lek_mapgen_world_is_small then
			print("######### Map Failure Check #########");
			print(tostring(math.floor(landFloorFrac * 100)) .. "% Of Map Area: ", iPercent);
			print("Map Land Tiles: ", iNumLandTilesInUse);
			print("Islands Placed: ", islandsPlaced, "(min ", minIslands, " required)", " budgetOk=", tostring(islandsBudgetOk));
		end

		local tPass1 = (os and os.clock) and os.clock() or 0;
		local waterSliceBad = LekPangaeaWaterSliceReject(self.plotTypes, iW, iH, 10, 18);
		local basePass = (iNumLandTilesInUse >= iPercent and islandsPlaced >= minIslands and islandsBudgetOk);
		if waterSliceBad and not _lek_mapgen_world_is_small then
			print("######### Map Failure (water-slice heuristic) #########");
		end
		if basePass and not waterSliceBad then
			allcomplete = true;
			_lek_bench_islands_dt = tIs1 - tIs0;
			if not _lek_mapgen_world_is_small then
				print("######### Map Pass #########");
			end
		else
			if not _lek_mapgen_world_is_small then
				print("######### Map Failure #########");
			end
		end
		LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe outer=" .. tostring(outerAttempts)
			.. " layoutAttempt=" .. tostring(laProbe)
			.. " outerPassTotal_dt=" .. tostring(tPass1 - tPass0)
			.. " waterSliceReject=" .. (waterSliceBad and "1" or "0")
			.. " mapPass=" .. ((basePass and not waterSliceBad) and "1" or "0"), 2);
	end

	if allcomplete then
		LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe islandOuterRegen_summary layoutAttempt=" .. tostring(laProbe)
			.. " outcome=pass outerAttemptsToPass=" .. tostring(outerAttempts)
			.. " outerRedrawsBeforePass=" .. tostring(math.max(0, outerAttempts - 1)), 2);
	elseif outerAttempts > MAX_OUTER then
		LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe islandOuterRegen_summary layoutAttempt=" .. tostring(laProbe)
			.. " outcome=max_outer_no_pass outerAttempts=" .. tostring(outerAttempts), 1);
	end

	return self.plotTypes;
end




------------------------------------------------------------------------------

------------------------------------------------------------------------------
local function dbg(msg) print(msg); end

function GeneratePlotTypes()
	if not _lek_mapgen_world_is_small then
		print("### STAGE: GeneratePlotTypes ENTRY ###");
		dbg("### STAGE: GeneratePlotTypes start ###");
	end
	local laTop = _lek_map_layout_attempt or 0;
	local t0 = (os and os.clock) and os.clock() or 0;
	local fractal_world = PangaeaFractalWorld.Create();
	if not _lek_mapgen_world_is_small then
		dbg("### STAGE: fractal created ###");
		print("### STAGE: calling fractal_world:GeneratePlotTypes (may take 1-2 min) ###");
	end
	local tF0 = (os and os.clock) and os.clock() or 0;
	local plotTypes = fractal_world:GeneratePlotTypes();
	local tF1 = (os and os.clock) and os.clock() or 0;
	if not _lek_mapgen_world_is_small then
		dbg("### STAGE: plotTypes generated ###");
	end
	local tS0 = (os and os.clock) and os.clock() or 0;
	SetPlotTypes(plotTypes);
	local tS1 = (os and os.clock) and os.clock() or 0;
	if not _lek_mapgen_world_is_small then
		dbg("### STAGE: SetPlotTypes done ###");
	end
	local tC0 = (os and os.clock) and os.clock() or 0;
	GenerateCoasts();
	local tC1 = (os and os.clock) and os.clock() or 0;
	if not _lek_mapgen_world_is_small then
		dbg("### STAGE: GenerateCoasts done ###");
	end
	_lek_bench_fractal_world_dt = tF1 - tF0;
	_lek_bench_generate_plot_types_lua_total_dt = tC1 - t0;
	LekPangaeaProbeLog("### LekPangaeaPlotTypesProbe layoutAttempt=" .. tostring(laTop)
		.. " fractalWorldGeneratePlotTypes_dt=" .. tostring(tF1 - tF0)
		.. " setPlotTypes_dt=" .. tostring(tS1 - tS0)
		.. " generateCoasts_dt=" .. tostring(tC1 - tC0)
		.. " generatePlotTypes_lua_total_dt=" .. tostring(tC1 - t0), 1);
end
------------------------------------------------------------------------------
function GenerateTerrain()

	local DesertPercent = 22;

	-- Get Temperature setting input by user.
	local temp = LekMapGetCustomOption(2)
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local grassMoist = LekMapGetCustomOption(8);

	local args = {
			temperature = temp,
			iDesertPercent = DesertPercent,
			iGrassMoist = grassMoist,
			};

	local terraingen = TerrainGenerator.Create(args);
	_lekmap_terrain_generator = terraingen;

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);

	-- MOD.EAP: New
	FixCoastLine()
	
	FixIslands();
	FixSolomonsMinesIslandDesert();
	FixSinaiIslandDesert();
	FixGeothermalIslandSnow();
	FixGeothermalIslandForest();

end

------------------------------------------------------------------------------
function FixGeothermalIslandSnow()
	if not _geothermal_snow_plot_indices then return; end
	local iW, iH = Map.GetGridSize();
	for _, idx in ipairs(_geothermal_snow_plot_indices) do
		local x = (idx - 1) % iW;
		local y = math.floor((idx - 1) / iW);
		local plot = Map.GetPlot(x, y);
		if plot and not plot:IsWater() then
			local pt = plot:GetPlotType();
			if pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS or pt == PlotTypes.PLOT_MOUNTAIN then
				local nearMapEdge = (y <= 4) or (y >= iH - 5);
				if nearMapEdge and pt ~= PlotTypes.PLOT_MOUNTAIN and Map.Rand(100, "") < 48 then
					plot:SetTerrainType(TerrainTypes.TERRAIN_TUNDRA, false, false);
				else
					plot:SetTerrainType(TerrainTypes.TERRAIN_SNOW, false, false);
				end
			end
		end
	end
end

------------------------------------------------------------------------------
function FixGeothermalIslandForest()
	if not _geothermal_forest_ring_indices then return; end
	local iW, _ = Map.GetGridSize();
	for _, idx in ipairs(_geothermal_forest_ring_indices) do
		if Map.Rand(100, "") < 10 then
			local x = (idx - 1) % iW;
			local y = math.floor((idx - 1) / iW);
			local plot = Map.GetPlot(x, y);
			if plot and not plot:IsWater() then
				local pt = plot:GetPlotType();
				if (pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS) and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
					plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
				end
			end
		end
	end
end

------------------------------------------------------------------------------
function FixSolomonsMinesIslandDesert()
	if not _solomons_island_mines_plot or not GetHexNeighbor then return; end
	local iW, iH = Map.GetGridSize();
	local wrapX = Map:IsWrapX();
	local wrapY = Map.IsWrapY and Map:IsWrapY() or false;
	local idx = _solomons_island_mines_plot;
	local cx = (idx - 1) % iW;
	local cy = math.floor((idx - 1) / iW);
	local ring1Keys = {};
	local ring1 = {};
	for d = 1, 6 do
		local nx, ny = GetHexNeighbor(cx, cy, d, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			local k = nx .. "," .. ny;
			ring1Keys[k] = true;
			ring1[#ring1 + 1] = { nx, ny };
		end
	end
	for _, p in ipairs(ring1) do
		local plot = Map.GetPlot(p[1], p[2]);
		if plot and not plot:IsWater() then
			local pt = plot:GetPlotType();
			if (pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS) and Map.Rand(100, "") < 80 then
				plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
			end
		end
	end
	local ring2Seen = {};
	for _, p in ipairs(ring1) do
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(p[1], p[2], d, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local k = nx .. "," .. ny;
				if (nx ~= cx or ny ~= cy) and not ring1Keys[k] and not ring2Seen[k] then
					ring2Seen[k] = true;
					local plot = Map.GetPlot(nx, ny);
					if plot and not plot:IsWater() then
						local pt = plot:GetPlotType();
						if (pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS) and Map.Rand(100, "") < 20 then
							plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------------
function FixSinaiIslandDesert()
	if not _sinai_island_plot or not GetHexNeighbor then return; end
	local iW, iH = Map.GetGridSize();
	local wrapX = Map:IsWrapX();
	local wrapY = Map.IsWrapY and Map:IsWrapY() or false;
	local idx = _sinai_island_plot;
	local cx = (idx - 1) % iW;
	local cy = math.floor((idx - 1) / iW);
	local ring1Keys = {};
	local ring1 = {};
	for d = 1, 6 do
		local nx, ny = GetHexNeighbor(cx, cy, d, iW, iH, wrapX, wrapY);
		if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
			local k = nx .. "," .. ny;
			ring1Keys[k] = true;
			ring1[#ring1 + 1] = { nx, ny };
		end
	end
	for _, p in ipairs(ring1) do
		local plot = Map.GetPlot(p[1], p[2]);
		if plot and not plot:IsWater() then
			local pt = plot:GetPlotType();
			if (pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS) and Map.Rand(100, "") < 65 then
				plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
			end
		end
	end
	local ring2Seen = {};
	for _, p in ipairs(ring1) do
		for d = 1, 6 do
			local nx, ny = GetHexNeighbor(p[1], p[2], d, iW, iH, wrapX, wrapY);
			if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
				local k = nx .. "," .. ny;
				if (nx ~= cx or ny ~= cy) and not ring1Keys[k] and not ring2Seen[k] then
					ring2Seen[k] = true;
					local plot = Map.GetPlot(nx, ny);
					if plot and not plot:IsWater() then
						local pt = plot:GetPlotType();
						if (pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS) and Map.Rand(100, "") < 15 then
							plot:SetTerrainType(TerrainTypes.TERRAIN_DESERT, false, false);
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------------
function FixIslands()
	--function to change some of the flat land tundra on islands to plains tiles
	local iW, iH = Map.GetGridSize();
	local biggest_area = Map.FindBiggestArea(False);
	local iAreaID = biggest_area:GetID();

	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x;
			local plot = Map.GetPlotByIndex(i);
			plotAreaID = plot:GetArea();
			if plotAreaID ~= iAreaID then
				local terrainType = plot:GetTerrainType();
				local plotType = plot:GetPlotType();

				if terrainType == TerrainTypes.TERRAIN_TUNDRA then
					if plotType ~= PlotTypes.PLOT_HILLS then
						--give a chance to turn this flat tundra to plains
						local tundratoplains = Map.Rand(100, "Plains Spwan Chance");
						if tundratoplains >= 30 then
							plot:SetTerrainType(TerrainTypes.TERRAIN_PLAINS, false, true);
						end
					end
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function FixCoastLine()

	local iW, iH = Map.GetGridSize();
	local biggest_area = Map.FindBiggestArea(false);
	local iAreaID = biggest_area:GetID();

	-- Pass 1: collect all eligible flat coastal tiles.
	local eligible = {};
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlotByIndex(iW * y + x);
			local pt = plot:GetPlotType();
			if pt == PlotTypes.PLOT_LAND
				and plot:GetArea() == iAreaID
				and plot:IsCoastalLand(8)
				and not plot:IsRiverSide() then
				eligible[y * iW + x] = true;
			end
		end
	end

	local wrapX = Map:IsWrapX();
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			if eligible[y * iW + x] then
				local disk = GetHexDisk(x, y, 2, iW, iH, wrapX, false);
				local landFlats = {};
				local allFlat = true;
				for _, t in ipairs(disk) do
					local px, py = t[1], t[2];
					local p = Map.GetPlot(px, py);
					if p and not p:IsWater() then
						local pt = p:GetPlotType();
						if pt ~= PlotTypes.PLOT_LAND then
							allFlat = false;
							break;
						end
						landFlats[#landFlats + 1] = p;
					end
				end
				if allFlat and #landFlats >= 2 then
					local pick = landFlats[1 + Map.Rand(#landFlats, "")];
					pick:SetPlotType(PlotTypes.PLOT_HILLS, false, true);
				end
			end
		end
	end

	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			if eligible[y * iW + x] then
				local plot = Map.GetPlotByIndex(iW * y + x);
				if plot:GetPlotType() ~= PlotTypes.PLOT_LAND then
				else
					local hillNeighbors = 0;
					for d = 0, 5 do
						local neighbor = Map.PlotDirection(x, y, d);
						if neighbor and neighbor:GetPlotType() == PlotTypes.PLOT_HILLS then
							hillNeighbors = hillNeighbors + 1;
						end
					end
					local threshold;
					if hillNeighbors <= 1 then
						threshold = 20;
					elseif hillNeighbors <= 4 then
						threshold = 80;
					else
						threshold = 101;
					end
					if Map.Rand(100, "") >= threshold then
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, true);
					end
				end
			end
		end
	end

end
------------------------------------------------------------------------------
function FixInlandPancakes()
	local iW, iH = Map.GetGridSize();
	local biggest_area = Map.FindBiggestArea(false);
	local iAreaID = biggest_area:GetID();
	local wrapX = Map:IsWrapX();
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlot(x, y);
			if plot and not plot:IsWater()
				and plot:GetArea() == iAreaID
				and plot:GetPlotType() == PlotTypes.PLOT_LAND
				and not plot:IsCoastalLand(8)
				and not plot:IsRiverSide()
				and plot:GetFeatureType() == FeatureTypes.NO_FEATURE then
				local disk = GetHexDisk(x, y, 2, iW, iH, wrapX, false);
				local hillCt = 0;
				for _, t in ipairs(disk) do
					local p = Map.GetPlot(t[1], t[2]);
					if p and not p:IsWater() and p:GetPlotType() == PlotTypes.PLOT_HILLS then
						hillCt = hillCt + 1;
					end
				end
				if hillCt < 3 and Map.Rand(100, "") < 26 then
					local terr = plot:GetTerrainType();
					local canForest =
						(terr == TerrainTypes.TERRAIN_GRASS or terr == TerrainTypes.TERRAIN_PLAINS or terr == TerrainTypes.TERRAIN_TUNDRA)
						and plot:GetFeatureType() == FeatureTypes.NO_FEATURE;
					if canForest and Map.Rand(100, "") < 38 then
						plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
					else
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, true);
					end
				end
			end
		end
	end
end

function LekPurgeIceAdjacentMainlandNearPoles(edgeRows)
	edgeRows = edgeRows or 4;
	local iW, iH = Map.GetGridSize();
	if iW < 1 or iH < 1 then
		return;
	end
	local landmass = Map.FindBiggestArea(false);
	if not landmass then
		return;
	end
	local mainAid = landmass:GetID();
	local wrapY = Map.IsWrapY and Map:IsWrapY();
	local function nearMapEdgeRow(y)
		if wrapY then
			return false;
		end
		return y < edgeRows or y >= (iH - edgeRows);
	end
	local removed = 0;
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlot(x, y);
			if plot and plot:GetFeatureType() == FeatureTypes.FEATURE_ICE and plot:IsWater() then
				if nearMapEdgeRow(y) then
				else
					local touchMain = false;
					for d = 0, 5 do
						local np = Map.PlotDirection(x, y, d);
						if np then
							local pt = np:GetPlotType();
							if pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS or pt == PlotTypes.PLOT_MOUNTAIN then
								if np:GetArea() == mainAid then
									touchMain = true;
									break;
								end
							end
						end
					end
					if touchMain then
						plot:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
						removed = removed + 1;
					end
				end
			end
		end
	end
	if removed > 0 then
		print("### LekPurgeIceAdjacentMainlandNearPoles removed=" .. tostring(removed) .. " edgeRows=" .. tostring(edgeRows));
	end
end
------------------------------------------------------------------------------
function AddFeatures()

	-- Get Rainfall setting input by user.
	local rain = LekMapGetCustomOption(3)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rain}
	local featuregen = FeatureGenerator.Create(args);

	-- True = allow mountains on coast (skip coastal mountain demotion).
	featuregen:AddFeatures(true);

	-- Sparse forest on snow: 2% per snow flat tile, excluding the 3 rows at each map edge.
	do
		local iW, iH = Map.GetGridSize();
		for y = 3, iH - 4 do
			for x = 0, iW - 1 do
				local plot = Map.GetPlot(x, y);
				if plot
					and plot:GetTerrainType() == TerrainTypes.TERRAIN_SNOW
					and plot:GetPlotType() == PlotTypes.PLOT_LAND
					and plot:GetFeatureType() == FeatureTypes.NO_FEATURE
					and Map.Rand(100, "") < 2 then
					plot:SetFeatureType(FeatureTypes.FEATURE_FOREST, -1);
				end
			end
		end
	end

	LekPurgeIceAdjacentMainlandNearPoles(4);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function StartPlotSystem()
	_lek_run_id = tostring(math.floor((os.clock and os.clock() or 0) * 1000));
	local function appendLekLog(lines)
		if _lek_mapgen_tuple_benchmark_mode or _lek_mapgen_world_is_small then
			return;
		end
		pcall(function()
			if type(LekMapgenDiagLogAppend) == "function" then
				LekMapgenDiagLogAppend(lines);
			end
		end);
	end
	appendLekLog({
		"### RunStage runId=" .. tostring(_lek_run_id) .. " stage=StartPlotSystem.begin"
	});

	local function startPlacementSanity(start_plot_database, stageTag, checkPlayerAssign)
		if not start_plot_database then
			return;
		end
		local runId = tostring(_lek_run_id or "na");
		local nCiv = start_plot_database.iNumCivs or 0;
		local tblOk = 0;
		local bits = {};
		for loop = 1, nCiv do
			local tr = start_plot_database.startingPlots and start_plot_database.startingPlots[loop];
			if tr and type(tr[1]) == "number" and type(tr[2]) == "number" then
				tblOk = tblOk + 1;
				bits[#bits + 1] = string.format("r%d_tbl=%d,%d", loop, tr[1], tr[2]);
			else
				bits[#bits + 1] = string.format("r%d_tbl=nil", loop);
			end
		end
		local nNilPlayer = 0;
		local nMismatch = 0;
		local nWaterStart = 0;
		if checkPlayerAssign == true then
			for loop = 1, nCiv do
				local pid = start_plot_database.player_ID_list[loop];
				local pl = Players[pid];
				local ps = pl and pl:GetStartingPlot();
				local tr = start_plot_database.startingPlots and start_plot_database.startingPlots[loop];
				local sx, sy = nil, nil;
				if tr and type(tr[1]) == "number" and type(tr[2]) == "number" then
					sx, sy = tr[1], tr[2];
				end
				if not ps then
					nNilPlayer = nNilPlayer + 1;
					bits[#bits + 1] = string.format("r%d_pid%d_PLAYER=nil", loop, pid);
				else
					local px, py = ps:GetX(), ps:GetY();
					if sx and (sx ~= px or sy ~= py) then
						nMismatch = nMismatch + 1;
						bits[#bits + 1] = string.format(
							"r%d_pid%d_MISMATCH_tbl(%d,%d)_player(%d,%d)",
							loop, pid, sx, sy, px, py);
					end
					if ps:IsWater() then
						nWaterStart = nWaterStart + 1;
						bits[#bits + 1] = string.format("r%d_pid%d_WATER_START", loop, pid);
					end
				end
			end
		end
		local msg = "### StartSanity runId=" .. runId .. " stage=" .. tostring(stageTag)
			.. " iNumCivs=" .. tostring(nCiv)
			.. " regionTblCoords=" .. tostring(tblOk) .. "/" .. tostring(nCiv)
			.. (checkPlayerAssign and (
				" nilPlayer=" .. tostring(nNilPlayer)
				.. " mismatchTblVsPlayer=" .. tostring(nMismatch)
				.. " waterStart=" .. tostring(nWaterStart)
			) or "")
			.. " regenReq=" .. tostring(_lek_global_six_request_map_regen == true)
			.. " | " .. table.concat(bits, " ");
		if not _lek_mapgen_tuple_benchmark_mode then
			print(msg);
			appendLekLog({ msg });
		end
	end

	local RegionalMethod = 1;

	-- Debug helper: visualize region rectangles by recoloring land and clearing plot features.
	-- This is intentionally executed *after* all start/resources/city-state placement so it
	-- doesn't disrupt the functional placement logic.
	local function DebugPaintRegionsTerrains(start_plot_database)
		if not start_plot_database or not start_plot_database.regionData then return; end
		local regionCount = table.maxn(start_plot_database.regionData);
		print("### DebugPaintRegionsTerrains: regionCount=", tostring(regionCount));

		local iW, iH = Map.GetGridSize();
		local function paintIfLand(x, y, terrain)
			local p = Map.GetPlot(x, y);
			if not (p and not p:IsWater()) then return false; end
			-- Paint a 3x3 block so the marker is easy to spot.
			for dy = -1, 1 do
				for dx = -1, 1 do
					local nx, ny = x + dx, y + dy;
					if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
						local np = Map.GetPlot(nx, ny);
						if np and not np:IsWater() then
							np:SetTerrainType(terrain, false, true);
							np:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
						end
					end
				end
			end
			return true;
		end

		local function paint1IfLand(x, y, terrain)
			local p = Map.GetPlot(x, y);
			if not (p and not p:IsWater()) then return false; end
			p:SetTerrainType(terrain, false, true);
			p:SetFeatureType(FeatureTypes.NO_FEATURE, -1);
			return true;
		end
		-- Outline can be expensive (many SetTerrainType calls). Keep it bounded.
		local outlinePaintCount = 0;
		local outlinePaintCountMax = 2000;
		local function paintOutlineIfLand(x, y, terrain)
			if outlinePaintCount >= outlinePaintCountMax then return false; end
			local p = Map.GetPlot(x, y);
			if not (p and not p:IsWater()) then return false; end
			outlinePaintCount = outlinePaintCount + 1;
			p:SetTerrainType(terrain, false, true);
			-- Don't touch features for outline; terrain repaint is already visible.
			return true;
		end

		local function regionCenter(region)
			local westX, southY, width, height = region[1], region[2], region[3], region[4];
			local cx = (westX + math.floor((width - 1) / 2)) % iW;
			local cy = (southY + math.floor((height - 1) / 2)) % iH;
			return cx, cy;
		end

		local function paintNearestLand(x, y, terrain, searchRadius)
			searchRadius = searchRadius or 3;
			if paintIfLand(x, y, terrain) then return true; end
			for r = 1, searchRadius do
				for dy = -r, r do
					for dx = -r, r do
						local nx, ny = x + dx, y + dy;
						if nx >= 0 and nx < iW and ny >= 0 and ny < iH then
							if paintIfLand(nx, ny, terrain) then return true; end
						end
					end
				end
			end
			return false;
		end

		-- Sort roughly into "rows": higher centerY first (north row), then by centerX.
		local regions = {};
		for _, region in ipairs(start_plot_database.regionData) do
			regions[#regions + 1] = region;
		end
		table.sort(regions, function(a, b)
			local ax, ay = regionCenter(a);
			local bx, by = regionCenter(b);
			if ay == by then return ax < bx; end
			return ay > by;
		end);

		--[[ Snow center + coarse rectangle outline per region (keep helper body for later diagnostics).
		for idx, region in ipairs(regions) do
			local westX, southY, width, height = region[1], region[2], region[3], region[4];
			local targetTerrain = TerrainTypes.TERRAIN_SNOW;

			local rcx, rcy = regionCenter(region);
			local ok = paintNearestLand(rcx, rcy, targetTerrain, 1);
			if ok then
				print("### DebugPaintRegionsTerrains: region", tostring(idx), "center approx", tostring(rcx), tostring(rcy), "painted")
			else
				print("### DebugPaintRegionsTerrains: region", tostring(idx), "center approx", tostring(rcx), tostring(rcy), "no land found")
			end

			local stepX = math.max(1, math.floor(width / 25));
			local stepY = math.max(1, math.floor(height / 25));
			for localX = 0, width - 1, stepX do
				local topY = (southY) % iH;
				local botY = (southY + height - 1) % iH;
				local x = (westX + localX) % iW;
				paintOutlineIfLand(x, topY, targetTerrain);
				paintOutlineIfLand(x, botY, targetTerrain);
			end
			for localY = 0, height - 1, stepY do
				local leftX = (westX) % iW;
				local rightX = (westX + width - 1) % iW;
				local y = (southY + localY) % iH;
				paintOutlineIfLand(leftX, y, targetTerrain);
				paintOutlineIfLand(rightX, y, targetTerrain);
			end
		end
		--]]
	end

	-- Get Resources setting input by user.
	local AllowInlandSea = LekMapGetCustomOption(19)
	local res = LekMapGetCustomOption(14) or 5
	local starts = LekMapGetCustomOption(5)
	--if starts == 7 then
		--starts = 1 + Map.Rand(8, "Random Resources Option - Lua");
	--end

	-- Handle coastal spawns and start bias
	MixedBias = false;
	local IgnoreAllStartBias = false;
	local BalancedCoastalExactTwo = false;
	local ForceAllInlandPlayerSpawns = false;
	-- Option 17 "Coastal Spawns": 1=Civs Only, 2=Force 2, 3=All Inland, 4=Pure Random (must match CustomOptions order).
	if LekMapGetCustomOption(17) == 1 then
		OnlyCoastal = true;
		BalancedCoastal = false;
	end
	if LekMapGetCustomOption(17) == 2 then
		OnlyCoastal = false;
		BalancedCoastal = true;
		BalancedCoastalExactTwo = true;
	end
	if LekMapGetCustomOption(17) == 3 then
		BalancedCoastal = false;
		OnlyCoastal = false;
		ForceAllInlandPlayerSpawns = true;
	end
	if LekMapGetCustomOption(17) == 4 then
		BalancedCoastal = false;
		OnlyCoastal = false;
	end
	
	if LekMapGetCustomOption(18) == 1 then
	CoastLux = true
	end

	if LekMapGetCustomOption(18) == 2 then
	CoastLux = false
	end

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()

	local function shortCircuitStartPlotSystemIfRegen(stageTag)
		if _lek_global_six_request_map_regen ~= true then
			return false;
		end
		_lek_bench_short_circuit_stage = tostring(stageTag or "na");
		startPlacementSanity(start_plot_database, stageTag, false);
		local att = _lek_map_layout_attempt or 1;
		local maxL = _lek_global_six_regen_max_layouts;
		if type(maxL) ~= "number" or maxL < 1 then
			maxL = 4;
		end
		local msg = "### LekMapGen StartPlotSystem short_circuit runId=" .. tostring(_lek_run_id or "na")
			.. " layout=" .. tostring(att) .. "/" .. tostring(maxL)
			.. " reason=_lek_global_six_request_map_regen"
			.. " regenReason=" .. tostring(_lek_global_six_request_map_regen_reason or "na")
			.. " stage=" .. tostring(stageTag);
		if LekPlacementProbeAt then
			LekPlacementProbeAt(1, msg);
		elseif LekPlacementProbeLog then
			LekPlacementProbeLog(msg);
		else
			print(msg);
			appendLekLog({ msg });
		end
		if LekMapgenFormatBench6SummaryLine and LekMapgenEmitBench6OneLine then
			local benchLine = LekMapgenFormatBench6SummaryLine(start_plot_database);
			if benchLine then
				LekMapgenEmitBench6OneLine(benchLine);
			end
		end
		return true;
	end

	do
		-- UI: 1 = Legacy, 2 = Global six. Older saves with value 3 map to 2.
		local paceSel = 2;
		local okP, vP = pcall(function()
			return LekMapGetCustomOption(13);
		end);
		if okP and type(vP) == "number" and vP >= 1 then
			paceSel = math.floor(vP + 0.5);
		end
		if paceSel < 1 then
			paceSel = 2;
		elseif paceSel > 2 then
			paceSel = 2;
		end
		start_plot_database._lek_global_six_skip_tuple_use_legacy = (paceSel == 1);
		start_plot_database._lek_global_six_tuple_regen_on_solver_fail = false;
		start_plot_database._lek_global_six_one_map_placement_mode = (paceSel == 2);
		start_plot_database._lek_global_six_tuple_skip_dfs_rank1_head_s2 = (paceSel == 2);
		if paceSel == 1 then
			start_plot_database._lek_global_six_pace_fast = false;
			start_plot_database._lek_global_six_fatal_on_exhausted = false;
			start_plot_database._lek_global_six_regen_max_layouts = 1;
			start_plot_database._lek_global_six_tuple_relax_min_layout = false;
			start_plot_database._lek_global_six_tuple_minimal_s2_fallback_max_layout = false;
			start_plot_database._lek_global_six_one_map_placement_mode = false;
		else
			start_plot_database._lek_global_six_pace_fast = false;
			start_plot_database._lek_global_six_fatal_on_exhausted = false;
			start_plot_database._lek_global_six_regen_max_layouts = 1;
			start_plot_database._lek_global_six_tuple_relax_min_layout = false;
			start_plot_database._lek_global_six_tuple_minimal_s2_fallback_max_layout = false;
			-- nil relaxation_phases → 4a LekGlobalSix_DefaultTupleRelaxationPhases()
		end
	end

	     start_plot_database._lek_global_six_solver = true;
	     start_plot_database._lek_global_six_ripple_dry_run = false;
	     start_plot_database._lek_tuple_pool_diag = false;
	     -- Section5 (bias feasibility) hardness policy:
	     -- Coastal + river remain hard constraints; region priority/avoid are softened
	     -- to mimic legacy practical outcomes (usually satisfied, but not map-killing).
	     start_plot_database._lek_global_six_s5_avoid_hard = false;
	     start_plot_database._lek_global_six_s5_prim_hard = false;
	     start_plot_database._lek_global_six_coastal_bias_requires_salt = true;
	     start_plot_database._lek_global_six_coastal_disk3_max_salt_water_pct = 40;
	     start_plot_database._lek_global_six_coastal_salt_water_disk_radius = 3;
	     -- Per-phase defaults from 4a unless _lek_global_six_tuple_relaxation_phases is set.
	     start_plot_database._lek_global_six_max_fail_complete = 1000;
	     start_plot_database._lek_global_six_max_leaf_evals = 8000;
	     -- Tuple stress testing toggle (manual perf experiments):
	     -- false = normal day-to-day budgets
	     -- true  = expensive search to test whether deeper tuple effort meaningfully improves tuple_ok rate
	     local tupleStressMode = false;
	     if tupleStressMode then
		start_plot_database._lek_global_six_max_fail_complete = 12000;
		start_plot_database._lek_global_six_max_leaf_evals = 40000;
		-- Optional pool breadth bump for stress studies.
		start_plot_database._lek_global_six_max_candidates_per_region = 48;
	     end
	     start_plot_database._lek_global_six_force_geometry_only = true;
	     start_plot_database._lek_global_six_force_geometry_sample_count = 1000;
	     start_plot_database._lek_global_six_force_geometry_candidate_cap = 36;
	     start_plot_database._lek_global_six_force_geometry_center_band_min = 11;
	     start_plot_database._lek_global_six_force_geometry_center_band_max = 16;
	     start_plot_database._lek_global_six_force_geometry_target_center_d = 13;
	     start_plot_database._lek_enable_virtual_six_retries = false;
	     start_plot_database._lek_disable_virtual_six = true;
	     start_plot_database._lek_flatten_region_start_tiers = false
	     -- _lek_stronger_bias 
	     start_plot_database.centerBias = 20
	     start_plot_database.middleBias = 50
	     -- 
	     start_plot_database._lek_collide_coastals = true
		-- Interacts with CoastLux, makes that option undefined -- however true/false just marks guarantee/random
		-- CoastLux = false
		start_plot_database._lek_coastal_refish = false
		start_plot_database._lek_regional_lux_require_start_same_area = true
	if type(start_plot_database._lek_global_six_regen_max_layouts) == "number" and start_plot_database._lek_global_six_regen_max_layouts >= 1 then
		_lek_global_six_regen_max_layouts = start_plot_database._lek_global_six_regen_max_layouts;
	end
	
	if not _lek_mapgen_tuple_benchmark_mode then
		print("Dividing the map in to Regions.");
	end
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = RegionalMethod,
		start_locations = starts,
		resources = res,
		AllowInlandSea = AllowInlandSea,
		CoastLux = CoastLux,
		NoCoastInland = (OnlyCoastal == true) or (ForceAllInlandPlayerSpawns == true),
		BalancedCoastal = BalancedCoastal,
		BalancedCoastalExactTwo = BalancedCoastalExactTwo,
		ForceAllInlandPlayerSpawns = ForceAllInlandPlayerSpawns,
		MixedBias = MixedBias,
		IgnoreAllStartBias = IgnoreAllStartBias,
		};
	do
		local ok, err = pcall(function() start_plot_database:GenerateRegions(args) end);
		if not ok then
			local msg = "### GenerateRegions CRASH runId=" .. tostring(_lek_run_id or "na") .. " err=" .. tostring(err);
			print(msg); appendLekLog({ msg });
		end
	end

	if start_plot_database._lek_global_six_skip_tuple_use_legacy == true then
		_lek_mapgen_tuple_benchmark_mode = false;
	else
		_lek_mapgen_tuple_benchmark_mode = true;
	end
	if _lek_mapgen_tuple_benchmark_mode then
		_lek_bench_tuple_ok = nil;
		_lek_bench_tuple_why = "";
		_lek_bench_tuple_leaf = nil;
		_lek_bench_tuple_fail_complete = nil;
		_lek_bench_tuple_relax = "";
		_lek_bench_tuple_tier = "";
		_lek_bench_regional_lux_repair_cleared = 0;
		_lek_bench_lux_regional_shortfall_queued = 0;
		_lek_bench_spacing_min_nearest = nil;
		_lek_bench_spacing_avg_nearest = nil;
		_lek_bench_spacing_median_second = nil;
		_lek_bench_spacing_max_second = nil;
		_lek_bench_spacing_min_center = nil;
		_lek_bench_spacing_coastal_n = nil;
		_lek_bench_spacing_salt_adj_n = nil;
		_lek_bench_short_circuit_stage = nil;
		_lek_global_six_request_map_regen_reason = nil;
		_lek_bench_hex_ok = nil;
		_lek_bench_hex_rot = nil;
		_lek_bench_hex_ringR = nil;
		_lek_bench_feas_bn = nil;
		_lek_bench_feas_xmin = nil;
		_lek_bench_feas_h2max = nil;
		_lek_bench_feas_margmin = nil;
		_lek_bench_feas_k = nil;
	end

	--[[ Debug: snow terrain on region centers + rectangle outline (expensive). Re-enable when diagnosing regions.
	print("### DEBUG region markers paint START")
	DebugPaintRegionsTerrains(start_plot_database)
	print("### DEBUG region markers paint END")
	--]]

	if not _lek_mapgen_tuple_benchmark_mode then
		print("Choosing start locations for civilizations.");
	end

	do
		local ok, err = pcall(function() start_plot_database:ChooseLocations() end);
		if not ok then
			local msg = "### ChooseLocations CRASH runId=" .. tostring(_lek_run_id or "na") .. " err=" .. tostring(err);
			print(msg); appendLekLog({ msg });
			local maxRegenL = _lek_global_six_regen_max_layouts;
			if type(maxRegenL) ~= "number" or maxRegenL < 1 then
				maxRegenL = 4;
			end
			local att = _lek_map_layout_attempt or 1;
			local dsbOk, dsbV = pcall(function()
				return Game.GetCustomOption("GAMEOPTION_DISABLE_START_BIAS");
			end);
			local biasSkipsSix = (dsbOk and dsbV == 1);
			if AssignStartingPlots.LekGlobalSix_CanRequestLayoutRegenForPlacementGate(start_plot_database)
				and start_plot_database._lek_global_six_solver == true
				and not biasSkipsSix
				and start_plot_database.iNumCivs == 6
				and att < maxRegenL then
				_lek_global_six_request_map_regen_reason = "ChooseLocations_pcall_err";
				_lek_global_six_request_map_regen = true;
				local rq = "### LekGlobalSix mapRegen request runId=" .. tostring(_lek_run_id or "na")
					.. " layout=" .. tostring(att) .. "/" .. tostring(maxRegenL)
					.. " reason=ChooseLocations_pcall_err";
				appendLekLog({ rq });
				if LekPlacementProbeAt then
					LekPlacementProbeAt(1, rq);
				elseif LekPlacementProbeLog then
					LekPlacementProbeLog(rq);
				else
					print(rq);
				end
			end
		end
	end

	if shortCircuitStartPlotSystemIfRegen("short_circuit_before_BA_table_only") then
		return;
	end

	startPlacementSanity(start_plot_database, "after_ChooseLocations", false);
	
	if not _lek_mapgen_tuple_benchmark_mode then
		print("Normalizing start locations and assigning them to Players.");
	end
	do
		local ok, err = pcall(function() start_plot_database:BalanceAndAssign(args) end);
		if not ok then
			local msg = "### BalanceAndAssign CRASH runId=" .. tostring(_lek_run_id or "na") .. " err=" .. tostring(err);
			print(msg);
			appendLekLog({ msg });
		end
	end
	do
		local ok, err = pcall(function()
			if start_plot_database and start_plot_database.LekGlobalSix_ForceApplyExpectedPlayerStarts then
				start_plot_database:LekGlobalSix_ForceApplyExpectedPlayerStarts();
			end
		end);
		if not ok then
			local msg = "### LekGlobalSix forceBiasApply CRASH runId=" .. tostring(_lek_run_id or "na") .. " err=" .. tostring(err);
			print(msg);
			appendLekLog({ msg });
		end
	end
	do
		local ok, err = pcall(function()
			if start_plot_database and start_plot_database.LekGlobalSix_LogForceBiasAssignmentAudit then
				start_plot_database:LekGlobalSix_LogForceBiasAssignmentAudit();
			end
		end);
		if not ok then
			local msg = "### LekGlobalSix forceBiasAudit CRASH runId=" .. tostring(_lek_run_id or "na") .. " err=" .. tostring(err);
			print(msg);
			appendLekLog({ msg });
		end
	end

	do
		local nR4 = LekDemoteRing4CoastalMountainsNearCoastalMajors(start_plot_database);
		if not _lek_mapgen_tuple_benchmark_mode then
			local msg = "### LekMapGen demote_ring4_coastal_mtn n=" .. tostring(nR4)
				.. " runId=" .. tostring(_lek_run_id or "na");
			print(msg);
			appendLekLog({ msg });
		end
	end

	if shortCircuitStartPlotSystemIfRegen("after_BalanceAndAssign") then
		return;
	end

	-- After BalanceAndAssign, rescue any player still without a starting plot.
	-- Global-six 6p: only unused region starts; no random land scan; request regen if still missing.
	do
		local missing_pids = {};
		for loop = 1, start_plot_database.iNumCivs do
			local pid = start_plot_database.player_ID_list[loop];
			local pl = Players[pid];
			if pl and pl:IsEverAlive() and not pl:IsMinorCiv() then
				if pl:GetStartingPlot() == nil then
					missing_pids[#missing_pids + 1] = pid;
				end
			end
		end
		if #missing_pids > 0 then
			local strictSix = (start_plot_database._lek_global_six_solver == true)
				and ((start_plot_database.iNumCivs or 0) == 6);
			local rescue_candidates = {};
			local used_plots = {};
			for loop = 1, start_plot_database.iNumCivs do
				local pid = start_plot_database.player_ID_list[loop];
				local pl = Players[pid];
				if pl then
					local sp = pl:GetStartingPlot();
					if sp then used_plots[sp:GetX() .. "," .. sp:GetY()] = true; end
				end
			end
			for r = 1, start_plot_database.iNumCivs do
				local t = start_plot_database.startingPlots[r];
				if t and type(t[1]) == "number" and type(t[2]) == "number" then
					local k = t[1] .. "," .. t[2];
					if not used_plots[k] then
						rescue_candidates[#rescue_candidates + 1] = { t[1], t[2] };
					end
				end
			end
			if #rescue_candidates == 0 and not strictSix then
				local iW, iH = Map.GetGridSize();
				for y = 1, iH - 2 do
					for x = 0, iW - 1 do
						local p = Map.GetPlot(x, y);
						if p and (p:GetPlotType() == PlotTypes.PLOT_LAND or p:GetPlotType() == PlotTypes.PLOT_HILLS) then
							rescue_candidates[#rescue_candidates + 1] = { x, y };
							if #rescue_candidates >= 20 then break; end
						end
					end
					if #rescue_candidates >= 20 then break; end
				end
			elseif #rescue_candidates == 0 and strictSix then
				local zmsg = "### StartPlotSystem RESCUE strict_global_six no_unused_region_start runId="
					 .. tostring(_lek_run_id or "na") .. " missing_majors=" .. tostring(#missing_pids);
				print(zmsg);
				if not _lek_mapgen_tuple_benchmark_mode then
					appendLekLog({ zmsg });
				end
			end
			local rescue_log = {};
			for i, pid in ipairs(missing_pids) do
				local cand = rescue_candidates[i];
				if cand then
					local p = Map.GetPlot(cand[1], cand[2]);
					if p then
						Players[pid]:SetStartingPlot(p);
						rescue_log[#rescue_log + 1] = "pid=" .. pid .. "->(" .. cand[1] .. "," .. cand[2] .. ")";
					else
						rescue_log[#rescue_log + 1] = "pid=" .. pid .. "->FAILED";
					end
				else
					rescue_log[#rescue_log + 1] = "pid=" .. pid .. "->NO_CANDIDATE";
				end
			end
			local msg = "### StartPlotSystem RESCUE runId=" .. tostring(_lek_run_id or "na")
				.. " rescued=" .. #missing_pids .. " " .. table.concat(rescue_log, " | ");
			if not _lek_mapgen_tuple_benchmark_mode then
				print(msg);
				appendLekLog({ msg });
			end
			if strictSix then
				local anyNil = false;
				for _, pid2 in ipairs(missing_pids) do
					local pl2 = Players[pid2];
					if pl2 and pl2:GetStartingPlot() == nil then
						anyNil = true;
						break;
					end
				end
				if anyNil then
					local maxRegenL = _lek_global_six_regen_max_layouts;
					if type(maxRegenL) ~= "number" or maxRegenL < 1 then
						maxRegenL = 4;
					end
					local att = _lek_map_layout_attempt or 1;
					local canRegen = AssignStartingPlots.LekGlobalSix_CanRequestLayoutRegenForPlacementGate(start_plot_database)
						and (att < maxRegenL);
					local rmsg = "### StartPlotSystem RESCUE strict_global_six incomplete runId="
						.. tostring(_lek_run_id or "na")
						.. " requestRegen=" .. (canRegen and "1" or "0")
						.. " layout=" .. tostring(att) .. "/" .. tostring(maxRegenL);
					if not _lek_mapgen_tuple_benchmark_mode then
						print(rmsg);
						appendLekLog({ rmsg });
					end
					if canRegen then
						_lek_global_six_request_map_regen_reason = "after_BA_missing_major_start_strict_rescue";
						_lek_global_six_request_map_regen = true;
					else
						error("Lekmap: global-six majors without starting plots after strict rescue; regen exhausted.");
					end
				end
			end
		end
	end

	if shortCircuitStartPlotSystemIfRegen("after_StartPlotSystem_rescue") then
		return;
	end

	-- Validation log: report any remaining issues after rescue.
	do
		local problems = {};
		for loop = 1, start_plot_database.iNumCivs do
			local pid = start_plot_database.player_ID_list[loop];
			local pl = Players[pid];
			if pl and pl:IsEverAlive() and not pl:IsMinorCiv() then
				if pl:GetStartingPlot() == nil then
					problems[#problems + 1] = "player " .. tostring(pid) .. " still missing";
				end
			end
		end
		if #problems > 0 then
			local msg = "### Lekmap FATAL runId=" .. tostring(_lek_run_id or "na") .. " post-rescue issues: " .. table.concat(problems, "; ");
			print(msg);
			if not _lek_mapgen_tuple_benchmark_mode then
				appendLekLog({ msg });
			end
		end
	end

	startPlacementSanity(start_plot_database, "after_BalanceAndAssign_rescue", true);

	-- Post-pass instrumentation: log major start spacing for 6-player games.
	-- This gives us an objective baseline for "fairness" (nearest-neighbor distance + spread).
	do
		local iNumCivs = start_plot_database.iNumCivs or 0;
		if iNumCivs == 6 then
			local iW, iH = Map.GetGridSize();
			local centerX, centerY = math.floor(iW / 2), math.floor(iH / 2);
			local player_ID_list = start_plot_database.player_ID_list or {};

			local starts = {}; -- { pid=, x=, y=, coastal=, dCenter= }
			for _, pid in ipairs(player_ID_list) do
				local pl = Players[pid];
				if pl and pl:IsAlive() then
					local sp = pl:GetStartingPlot();
					if sp then
						local x, y = sp:GetX(), sp:GetY();
						local m = AssignStartingPlots.LekGlobalSix_MeasureBiasConditionsAtXY(start_plot_database, x, y);
						local saltOnly = (start_plot_database._lek_global_six_coastal_bias_requires_salt == true);
						local coast;
						if saltOnly then
							coast = (m.alongOcean == true);
						else
							coast = ((m.alongOcean or m.nextToLake) == true);
						end
						starts[#starts + 1] = { pid = pid, x = x, y = y, coastal = coast };
					end
				end
			end

			if #starts == 6 then
				local function dist(ax, ay, bx, by)
					if Map.PlotDistance then return Map.PlotDistance(ax, ay, bx, by); end
					if PlotDistance then return PlotDistance(ax, ay, bx, by); end
					return nil;
				end

				for i = 1, 6 do
					starts[i].dCenter = dist(starts[i].x, starts[i].y, centerX, centerY) or -1;
				end

				local nearest = {};
				local secondNearest = {};
				for i = 1, 6 do
					local dists = {};
					for j = 1, 6 do
						if i ~= j then
							local d = dist(starts[i].x, starts[i].y, starts[j].x, starts[j].y);
							if d ~= nil then dists[#dists + 1] = d; end
						end
					end
					table.sort(dists);
					nearest[i] = dists[1] or -1;
					secondNearest[i] = dists[2] or -1;
				end

				local nearestSorted = {};
				local secondNearestSorted = {};
				for i = 1, 6 do
					nearestSorted[#nearestSorted + 1] = nearest[i];
					secondNearestSorted[#secondNearestSorted + 1] = secondNearest[i];
				end
				table.sort(nearestSorted);
				table.sort(secondNearestSorted);
				local function median(arr)
					local n = #arr;
					if n == 0 then return -1; end
					if n % 2 == 1 then return arr[(n + 1) / 2]; end
					return (arr[n / 2] + arr[n / 2 + 1]) / 2;
				end

				local sum = 0;
				for i = 1, 6 do sum = sum + nearestSorted[i]; end
				local avgNearest = sum / 6;
				local sum2 = 0;
				for i = 1, 6 do sum2 = sum2 + secondNearestSorted[i]; end
				local avgSecondNearest = sum2 / 6;

				if _lek_mapgen_tuple_benchmark_mode then
					_lek_bench_spacing_min_nearest = nearestSorted[1];
					_lek_bench_spacing_avg_nearest = avgNearest;
					_lek_bench_spacing_median_second = median(secondNearestSorted);
					_lek_bench_spacing_max_second = secondNearestSorted[#secondNearestSorted] or -1;
					local minCenter = starts[1].dCenter or -1;
					for i = 2, 6 do
						if starts[i].dCenter < minCenter then
							minCenter = starts[i].dCenter;
						end
					end
					_lek_bench_spacing_min_center = minCenter;
					local cn = 0;
					for i = 1, 6 do
						if starts[i].coastal then cn = cn + 1; end
					end
					_lek_bench_spacing_coastal_n = cn;
					local saltAdj = 0;
					local pdc = start_plot_database.plotDataIsCoastal;
					if pdc then
						for i = 1, 6 do
							local pi = starts[i].y * iW + starts[i].x + 1;
							if pdc[pi] == true then
								saltAdj = saltAdj + 1;
							end
						end
					end
					_lek_bench_spacing_salt_adj_n = saltAdj;
				end

				local lines = {};
				local runId = tostring(_lek_run_id or "na");
				lines[#lines + 1] = "### StartSpacing6P runId=" .. runId ..
					" center=(" .. centerX .. "," .. centerY .. ")" ..
					" nearestSorted=" .. tostring(table.concat(nearestSorted, ",")) ..
					" avgNearest=" .. tostring(avgNearest) ..
					" medianNearest=" .. tostring(median(nearestSorted)) ..
					" secondNearestSorted=" .. tostring(table.concat(secondNearestSorted, ",")) ..
					" avgSecondNearest=" .. tostring(avgSecondNearest) ..
					" medianSecondNearest=" .. tostring(median(secondNearestSorted));
				for i = 1, 6 do
					lines[#lines + 1] = "### StartSpacing6P: pid=" .. tostring(starts[i].pid) ..
						" x,y=(" .. starts[i].x .. "," .. starts[i].y .. ")" ..
						" coastal=" .. tostring(starts[i].coastal) ..
						" dCenter=" .. tostring(starts[i].dCenter) ..
						" nearest=" .. tostring(nearest[i]) ..
						" secondNearest=" .. tostring(secondNearest[i]);
				end
				lines[#lines + 1] = "### StartSpacing6P legacy_was_used=" ..
					tostring(start_plot_database._lek_choose_locations_legacy_start_placement == true) ..
					" runId=" .. runId;
				if not _lek_mapgen_tuple_benchmark_mode then
					LekMapgenDiagLogAppend(lines);
				end
			else
				local short = "### StartSpacing6P: could not collect 6 start plots, got " .. tostring(#starts)
					.. " runId=" .. tostring(_lek_run_id or "na");
				if not _lek_mapgen_tuple_benchmark_mode then
					print(short);
					appendLekLog({ short });
				elseif LekMapgenEmitBench6OneLine then
					LekMapgenEmitBench6OneLine(short);
				end
			end
		end
	end

	if not _lek_mapgen_tuple_benchmark_mode then
		print("Placing Natural Wonders.");
	end
	local wonders = LekMapGetCustomOption(7)
	if wonders == 14 then
		wonders = Map.Rand(13, "Number of Wonders To Spawn - Lua");
	elseif wonders == 15 then
		wonders = 3 + Map.Rand(4, "NW count hidden opt 15");
	elseif wonders == 16 then
		wonders = Map.Rand(5, "") + 2
	else
		wonders = wonders - 1;
	end

	if not _lek_mapgen_tuple_benchmark_mode then
		print("########## Wonders ##########");
		print("Natural Wonders To Place: ", wonders);
	end

	local wonderargs = {
		wonderamt = wonders,
	};
	start_plot_database:PlaceNaturalWonders(wonderargs);
	FixInlandPancakes();
	if not _lek_mapgen_tuple_benchmark_mode then
		print("Placing Resources and City States.");
	end
	appendLekLog({
		"### RunStage runId=" .. tostring(_lek_run_id or "na") .. " stage=before.PlaceResourcesAndCityStates"
	});
	start_plot_database:PlaceResourcesAndCityStates()
	appendLekLog({
		"### RunStage runId=" .. tostring(_lek_run_id or "na") .. " stage=after.PlaceResourcesAndCityStates"
	});

	startPlacementSanity(start_plot_database, "after_PlaceResourcesAndCityStates", true);

	if LekMapgenFormatBench6SummaryLine and LekMapgenEmitBench6OneLine then
		local benchLine = LekMapgenFormatBench6SummaryLine(start_plot_database);
		if benchLine then
			LekMapgenEmitBench6OneLine(benchLine);
		end
	end

	if _lek_global_six_request_map_regen == true then
		local att = _lek_map_layout_attempt or 1;
		local maxL = _lek_global_six_regen_max_layouts;
		if type(maxL) ~= "number" or maxL < 1 then
			maxL = 4;
		end
		local msg = "### LekMapGen StartPlotSystem short_circuit runId=" .. tostring(_lek_run_id or "na")
			.. " layout=" .. tostring(att) .. "/" .. tostring(maxL)
			.. " skip=post_PlaceResources capital_lux_minimum_or_other_regen";
		if LekPlacementProbeAt then
			LekPlacementProbeAt(1, msg);
		elseif LekPlacementProbeLog then
			LekPlacementProbeLog(msg);
		else
			print(msg);
			appendLekLog({ msg });
		end
		return;
	end

	-- Debug region repaint can be heavy; keep it off while we debug stalls.
	-- DebugPaintRegionsTerrains(start_plot_database)
end
