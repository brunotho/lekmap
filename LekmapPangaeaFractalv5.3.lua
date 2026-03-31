------------------------------------------------------------------------------
--	FILE:	 Lekmapv2.2.lua (Modified Pangaea_Plus.lua)
--	AUTHOR:  Original Bob Thomas, Changes HellBlazer, lek10, EnormousApplePie, Cirra, Meota, t0mtezuma
--	PURPOSE: Global map script - Simulates a Pan-Earth Supercontinent, with
--           numerous tectonic island chains.
------------------------------------------------------------------------------
--	Copyright (c) 2011 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------


-- :2863 using Hax function if coastal
-- :9291 call to expand coastal plots

include("4_HBMapGenerator");
include("2_HBFractalWorld");
include("6_HBFeatureGenerator");
include("5_HBTerrainGenerator");
include("IslandMaker");
include("MultilayeredFractal");
include("3_PangaeaIslands");
include("X_IslandHelpers");
print("### LekmapPangaeaFractal: includes done ###");

-- Lane A: max full-map regens when global-six tuple solver rejects (spec target: 4 layouts = 1 + 3 retries).
-- Overridden per roll from start_plot_database._lek_global_six_regen_max_layouts inside StartPlotSystem.
_lek_global_six_regen_max_layouts = 4;
-- Regen loop runs up to N full map gens per start; leave false until solver + machine can bear it (bisect baseline).
_lek_enable_hb_generatemap_regen_loop = false;
_lek_map_layout_attempt = nil;
_lek_global_six_request_map_regen = false;

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "A Fractal Pangaea - Lekmap v5.3",
		Description = "A map script made for Lekmod based of HB's Mapscript v8.1. Pangaea - Fractal",
		IsAdvancedMap = false,
		IconIndex = 0,
		SortIndex = 2,
		SupportsMultiplayer = true,
	CustomOptions = {
			-- 1
			{
				Name = "TXT_KEY_MAP_OPTION_WORLD_AGE", -- 1
				Values = {
					"TXT_KEY_MAP_OPTION_THREE_BILLION_YEARS",
					"TXT_KEY_MAP_OPTION_FOUR_BILLION_YEARS",
					"TXT_KEY_MAP_OPTION_FIVE_BILLION_YEARS",
					"No Mountains",
					"TXT_KEY_MAP_OPTION_RANDOM",
					
				},
				DefaultValue = 2,
				SortPriority = -99,
			},

			-- 2
			{
				Name = "TXT_KEY_MAP_OPTION_TEMPERATURE",	-- 2 add temperature defaults to random
				Values = {
					"TXT_KEY_MAP_OPTION_COOL",
					"TXT_KEY_MAP_OPTION_TEMPERATE",
					"TXT_KEY_MAP_OPTION_HOT",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -98,
			},

			-- 3
			{
				Name = "TXT_KEY_MAP_OPTION_RAINFALL",	-- 3 add rainfall defaults to random
				Values = {
					"TXT_KEY_MAP_OPTION_ARID",
					"TXT_KEY_MAP_OPTION_NORMAL",
					"TXT_KEY_MAP_OPTION_WET",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -97,
			},

			-- 4
			{
				Name = "TXT_KEY_MAP_OPTION_SEA_LEVEL",	-- 4 add sea level defaults to random.
				Values = {
					"TXT_KEY_MAP_OPTION_LOW",
					"TXT_KEY_MAP_OPTION_MEDIUM",
					"TXT_KEY_MAP_OPTION_HIGH",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -96,
			},

			-- 5
			{
				Name = "Start Quality",	-- 5 start quality
				Values = {
					"Legendary Start - Strat Balance",
					"Legendary - Strat Balance + Uranium",
					"TXT_KEY_MAP_OPTION_STRATEGIC_BALANCE",
					"Strategic Balance With Coal",
					"Strategic Balance With Aluminum",
					"Strategic Balance With Coal & Aluminum",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -95,
			},

			-- 6
			{
				Name = "Start Distance",	-- 6 start distance
				Values = {
					"Close",
					"Normal",
					"Far - Warning: May sometimes crash during map generation",
				},
				DefaultValue = 2,
				SortPriority = -94,
			},

			-- 7
			{
				Name = "Natural Wonders", -- 7 number of natural wonders to spawn
				Values = {
					"0",
					"1",
					"2",
					"3",
					"4",
					"5",
					"6",
					"7",
					"8",
					"9",
					"10",
					"11",
					"12",
					"Random",
					"Default",
					"Between 3-5",
					"Between 2-6",
				},
				DefaultValue = 15,
				SortPriority = -93,
			},

			-- 8
			{
				Name = "Grass Moisture",	-- add setting for grassland moisture (8)
				Values = {
					"Wet",
					"Normal",
					"Dry",
				},

				DefaultValue = 2,
				SortPriority = -92,
			},

			-- 9
			{
				Name = "Rivers",	-- add setting for rivers (9)
				Values = {
					"Sparse",
					"Average",
					"Plentiful",
				},

				DefaultValue = 2,
				SortPriority = -91,
			},

			-- 10
			{
				Name = "Tundra",	-- add setting for tundra (10)
				Values = {
					"Sparse",
					"Average",
					"Plentiful",
				},

				DefaultValue = 2,
				SortPriority = -90,
			},

			-- 11
			{
				Name = "Land Size X",	-- add setting for land type (11)
				Values = {
					"Default -10 tiles",
					"Default -8 tiles",
					"Default -6 tiles",
					"Default -4 tiles",
					"Default -2 tiles",
					"Default (58 on Small)",
					"Default +2 tiles",
					"Default +4 tiles",
					"Default +6 tiles",
					"Default +8 tiles",
					"Default +10 tiles",
				},

				DefaultValue = 6,
				SortPriority = -89,
			},

			-- 12
			{
				Name = "Land Size Y",	-- add setting for land type (12)
				Values = {
					"Default -10 tiles",
					"Default -8 tiles",
					"Default -6 tiles",
					"Default -4 tiles",
					"Default -2 tiles",
					"Default (52 on Small)",
					"Default +2 tiles",
					"Default +4 tiles",
					"Default +6 tiles",
					"Default +8 tiles",
					"Default +10 tiles",

				},

				DefaultValue = 6,
				SortPriority = -88,
			},

			-- 13
			{
				Name = "TXT_KEY_MAP_OPTION_RESOURCES",	-- add setting for resources (13)
				Values = {
					"1 -- Nearly Nothing",
					"2",
					"3",
					"4",
					"5 -- Default",
					"6",
					"7",
					"8",
					"9",
					"10 -- Almost no normal tiles left",
				},

				DefaultValue = 5,
				SortPriority = -87,
			},

			-- 14
			{
				Name = "Balanced Regionals",	-- add setting for removing OP luxes from regional pool (14)
				Values = {
					"Yes",
					"No",
				},

				DefaultValue = 1,
				SortPriority = -90,
			},

			-- 15
			{
				Name = "Islands",	-- add setting for islands (15)
				Values = {
					"No Islands",
					"1",
					"2",
					"3",
					"4",
					"5",
					"6",
					"7",
					"8 - Default",
					"9",
					"10",
					"11",
					"12",
					"13",
					"14",
					"15",
					"16",
					"17",
					"18",
					"19",
					"20",
					"21",
					"22",
					"23",
					"24",
					"Between 6-10",
					"Between 8-12",
					"Between 10-14",
				},

				DefaultValue = 9,
				SortPriority = -86,
			},

			-- 16
			{
				Name = "Coastal Spawns",	-- Can inland civ spawn on the coast (16)
				Values = {
					"Coastal Civs Only",
					"Random",
					"Random+ (~2 coastals)",
				},

				DefaultValue = 1,
				SortPriority = -85,
			},

			-- 17
			{
				Name = "Coastal Luxes",	-- Can coast spawns have non-coastal luxes (17)
				Values = {
					"Guaranteed",
					"Random",
				},

				DefaultValue = 1,
				SortPriority = -84,
			},

			-- 18
			{
				Name = "Inland Sea Spawns",	-- Can coastal civ spawn on inland seas (18)
				Values = {
					"Allowed",
					"Not allowed",
				},

				DefaultValue = 2,
				SortPriority = -83,
			},
			
			-- 19
			{
				Name = "Fjord Distance",	-- Distance between fjords (19)
				Values = {
					"No fjords",
					"20 tiles",
					"15 tiles",
					"12 tiles",
					"10 tiles -- Default",
					"8 tiles",
					"6 tiles",
				},

				DefaultValue = 1,
				SortPriority = -82,
			},
			
			--20
			{
				Name = "Fjord Length",	-- Length of fjords (20)
				Values = {
					"2 tiles -- Default",
					"3 tiles",
					"4 tiles",
					"5 tiles",
					"6 tiles",
				},

				DefaultValue = 1,
				SortPriority = -81,
			},
		},
	};
end
------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	
	local LandSizeXDuel = 22 + (Map.GetCustomOption(11) * 2);
	local LandSizeYDuel = 18 + (Map.GetCustomOption(12) * 2);

	local LandSizeXTiny = 36 + (Map.GetCustomOption(11) * 2);
	local LandSizeYTiny = 30 + (Map.GetCustomOption(12) * 2);

	local LandSizeXSmall = 32 + (Map.GetCustomOption(11) * 2);
	local LandSizeYSmall = 40 + (Map.GetCustomOption(12) * 2);

	local LandSizeXStandard = 54 + (Map.GetCustomOption(11) * 2);
	local LandSizeYStandard = 48 + (Map.GetCustomOption(12) * 2);

	local LandSizeXLarge = 62 + (Map.GetCustomOption(11) * 2);
	local LandSizeYLarge = 54 + (Map.GetCustomOption(12) * 2);

	local LandSizeXHuge = 70 + (Map.GetCustomOption(11) * 2);
	local LandSizeYHuge = 62 + (Map.GetCustomOption(12) * 2);

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

	-- Widen thin inland seas: convert bordering land to ocean so they look rounder.
	local ASPECT_THRESHOLD = 1.25;   -- round when even mildly elongated
	local MIN_SIZE = 6;              -- round when >5 tiles
	local MAX_EXPAND_BODIES = 2;
	local MAX_ROUND_ITER = 12;
	local MIN_LAND_NEIGHBORS = 1;
	local MIN_DIST_FROM_OPEN_OCEAN = 4;  -- only nibble land this many hex steps from open ocean (expand toward center)
	local numExpanded = 0;
	for _, comp in ipairs(components) do
		local tiles = {};
		for k in pairs(comp) do tiles[#tiles + 1] = inlandSet[k]; end
		if #tiles >= MIN_SIZE then
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
			if (aspectX >= ASPECT_THRESHOLD or aspectY >= ASPECT_THRESHOLD) and numExpanded < MAX_EXPAND_BODIES then
				numExpanded = numExpanded + 1;
				for iter = 1, MAX_ROUND_ITER do
					local candidateSet = {};
					for _, t in ipairs(tiles) do
						local sx, sy = t[1], t[2];
						for d = 1, 6 do
							local nx, ny = GetHexNeighbor(sx, sy, d, iW, iH, wrapX, wrapY);
							if nx >= 0 and nx < iW and ny >= 0 and ny < iH and isLand(nx, ny) then
								local adjOpenOcean = false;
								for d2 = 1, 6 do
									local nnx, nny = GetHexNeighbor(nx, ny, d2, iW, iH, wrapX, wrapY);
									if nnx >= 0 and nnx < iW and nny >= 0 and nny < iH and openOcean[nny * iW + nnx] then adjOpenOcean = true; break; end
								end
								local nk = ny * iW + nx;
								local distToOcean = distToOpenOcean[nk];
								local farEnoughFromEdge = (distToOcean == nil) or (distToOcean >= MIN_DIST_FROM_OPEN_OCEAN);
								if not adjOpenOcean and farEnoughFromEdge then
									local landNeighbors = 0;
									for d2 = 1, 6 do
										local nnx, nny = GetHexNeighbor(nx, ny, d2, iW, iH, wrapX, wrapY);
										if nnx >= 0 and nnx < iW and nny >= 0 and nny < iH and isLand(nnx, nny) then landNeighbors = landNeighbors + 1; end
									end
									if landNeighbors >= MIN_LAND_NEIGHBORS then
										local key = nx .. "," .. ny;
										if not candidateSet[key] then candidateSet[key] = {nx, ny}; end
									end
								end
							end
						end
					end
					local candidates = {};
					for _, v in pairs(candidateSet) do candidates[#candidates + 1] = v; end
					if #candidates == 0 then break; end
					local pick = candidates[1 + Map.Rand(#candidates, "RoundInlandSea")];
					local lx, ly = pick[1], pick[2];
					plotTypes[pidx(lx, ly)] = PlotTypes.PLOT_OCEAN;
					tiles[#tiles + 1] = {lx, ly};
					comp[ly * iW + lx] = true;
				end
			end
			-- Rebuild tiles from comp so spray runs over the full inland sea (original + any newly rounded/enlarged).
			tiles = {};
			for k in pairs(comp) do
				local x = k % iW;
				local y = math.floor(k / iW);
				tiles[#tiles + 1] = {x, y};
			end
			-- Recompute bbox after rounding for spray gating.
			minX, maxX, minY, maxY = iW, -1, iH, -1;
			for _, t in ipairs(tiles) do
				local x, y = t[1], t[2];
				if x < minX then minX = x; end
				if x > maxX then maxX = x; end
				if y < minY then minY = y; end
				if y > maxY then maxY = y; end
			end
			w, h = maxX - minX + 1, maxY - minY + 1;
			aspectX = w / math.max(1, h);
			aspectY = h / math.max(1, w);
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
			-- Spray only in rounder seas (aspect < 2.2) to avoid a straight line of paint down thin channels.
			local doSpray = (aspectX < 2.2 and aspectY < 2.2);
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
		end
	end
end

------------------------------------------------------------------------------
function PangaeaFractalWorld:GeneratePlotTypes(args)
	if(args == nil) then args = {}; end
	
	local allcomplete = false;
	local outerAttempts = 0;
	local MAX_OUTER = 25;

	while allcomplete == false do
		outerAttempts = outerAttempts + 1;
		print("### Pangaea attempt " .. outerAttempts .. "/" .. MAX_OUTER .. " ###");
		if outerAttempts > MAX_OUTER then
			print("[Pangaea] MAX_OUTER reached, accepting map");
			break;
		end

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

		local sea_level = Map.GetCustomOption(4)
		if sea_level == 4 then
			sea_level = 1 + Map.Rand(3, "Random Sea Level - Lua");
		end
		local world_age = Map.GetCustomOption(1)
		if world_age == 5 then
			world_age = 1 + Map.Rand(3, "Random World Age - Lua");
		end

		-- Set Sea Level according to user selection.
		local water_percent = sea_level_normal;
		local fjorddistmodif = Map.GetCustomOption(19);		-- Small effect added based on fjord settings
		local fjordlengthmodif = Map.GetCustomOption(20);
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
		fjord_distance_setting = Map.GetCustomOption(19);
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
		
			fjord_length_setting = Map.GetCustomOption(20);
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
		RoundInlandSeas(self);

		local islandsOpt = Map.GetCustomOption(15);
		local minIslands = (islandsOpt and islandsOpt > 1) and (islandsOpt - 1) or 0;
		local islandGenOpts = nil;
		if minIslands == 0 then
			islandGenOpts = { budgetRetry = false };
		end

		local islandsPlaced = 0;
		local islandsBudgetOk = true;
		local ok, retPlaced, retBudgetOk = pcall(GeneratePangaeaIslands, self, islandGenOpts);
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

		print("######### Map Failure Check #########");
		print(tostring(math.floor(landFloorFrac * 100)) .. "% Of Map Area: ", iPercent);
		print("Map Land Tiles: ", iNumLandTilesInUse);
		print("Islands Placed: ", islandsPlaced, "(min ", minIslands, " required)", " budgetOk=", tostring(islandsBudgetOk));

		if iNumLandTilesInUse >= iPercent and islandsPlaced >= minIslands and islandsBudgetOk then
			allcomplete = true;
			print("######### Map Pass #########");
		else
			print("######### Map Failure #########");
		end
	end

	return self.plotTypes;
end




------------------------------------------------------------------------------

------------------------------------------------------------------------------
local function dbg(msg) print(msg); end

function GeneratePlotTypes()
	print("### STAGE: GeneratePlotTypes ENTRY ###");
	dbg("### STAGE: GeneratePlotTypes start ###");
	local fractal_world = PangaeaFractalWorld.Create();
	dbg("### STAGE: fractal created ###");
	print("### STAGE: calling fractal_world:GeneratePlotTypes (may take 1-2 min) ###");
	local plotTypes = fractal_world:GeneratePlotTypes();
	dbg("### STAGE: plotTypes generated ###");
	SetPlotTypes(plotTypes);
	dbg("### STAGE: SetPlotTypes done ###");
	GenerateCoasts();
	dbg("### STAGE: GenerateCoasts done ###");
end
------------------------------------------------------------------------------
function GenerateTerrain()

	local DesertPercent = 22;

	-- Get Temperature setting input by user.
	local temp = Map.GetCustomOption(2)
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local grassMoist = Map.GetCustomOption(8);

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
	local iW, _ = Map.GetGridSize();
	for _, idx in ipairs(_geothermal_snow_plot_indices) do
		local x = (idx - 1) % iW;
		local y = math.floor((idx - 1) / iW);
		local plot = Map.GetPlot(x, y);
		if plot and not plot:IsWater() then
			local pt = plot:GetPlotType();
			if pt == PlotTypes.PLOT_LAND or pt == PlotTypes.PLOT_HILLS or pt == PlotTypes.PLOT_MOUNTAIN then
				plot:SetTerrainType(TerrainTypes.TERRAIN_SNOW, false, false);
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
------------------------------------------------------------------------------
function AddFeatures()

	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(3)
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
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function StartPlotSystem()
	_lek_run_id = tostring(math.floor((os.clock and os.clock() or 0) * 1000));
	local function appendLekLog(lines)
		LekMapgenDiagLogAppend(lines);
	end
	appendLekLog({
		"### RunStage runId=" .. tostring(_lek_run_id) .. " stage=StartPlotSystem.begin"
	});

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

		for idx, region in ipairs(regions) do
			local westX, southY, width, height = region[1], region[2], region[3], region[4];
			-- Make region markers conspicuous: paint them all as SNOW.
			local targetTerrain = TerrainTypes.TERRAIN_SNOW;

			local rcx, rcy = regionCenter(region);
			local ok = paintNearestLand(rcx, rcy, targetTerrain, 1);
			if ok then
				print("### DebugPaintRegionsTerrains: region", tostring(idx), "center approx", tostring(rcx), tostring(rcy), "painted")
			else
				print("### DebugPaintRegionsTerrains: region", tostring(idx), "center approx", tostring(rcx), tostring(rcy), "no land found")
			end

			-- Outline: draw the outer rectangle boundary (1 tile thick).
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
	end

	-- Get Resources setting input by user.
	local AllowInlandSea = Map.GetCustomOption(18)
	local res = Map.GetCustomOption(13)
	local starts = Map.GetCustomOption(5)
	--if starts == 7 then
		--starts = 1 + Map.Rand(8, "Random Resources Option - Lua");
	--end

	-- Handle coastal spawns and start bias
	MixedBias = false;
	if Map.GetCustomOption(16) == 1 then
		OnlyCoastal = true;
		BalancedCoastal = false;
	end	
	if Map.GetCustomOption(16) == 2 then
		BalancedCoastal = false;
		OnlyCoastal = false;
	end
	
	if Map.GetCustomOption(16) == 3 then
		OnlyCoastal = true;
		BalancedCoastal = true;
	end
	
	if Map.GetCustomOption(17) == 1 then
	CoastLux = true
	end

	if Map.GetCustomOption(17) == 2 then
	CoastLux = false
	end

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()

	     -- Lane A: global-six hook + OK diag logs. false = quiet maps; true = probe (set true when testing).
	     start_plot_database._lek_global_six_solver = true;
	     start_plot_database._lek_global_six_ripple_dry_run = true;
	     start_plot_database._lek_global_six_max_fail_complete = 1000;
	     start_plot_database._lek_global_six_max_leaf_evals = 1000;
	     start_plot_database._lek_global_six_regen_max_layouts = 4;
	     start_plot_database._lek_enable_virtual_six_retries = false;
	     start_plot_database._lek_disable_virtual_six = true;
	     -- start_plot_database._lek_enable_virtual_six_retries = true
	     -- start_plot_database._lek_disable_virtual_six = false
	     start_plot_database._lek_flatten_region_start_tiers = false
	     -- start_plot_database._lek_flatten_region_start_tiers = true
	     -- _lek_stronger_bias 
	     start_plot_database.centerBias = 20
	     start_plot_database.middleBias = 50
	     -- 
	     start_plot_database._lek_collide_coastals = true
		-- Interacts with CoastLux, makes that option undefined -- however true/false just marks guarantee/random
		-- CoastLux = false
		start_plot_database._lek_coastal_refish = false
	if type(start_plot_database._lek_global_six_regen_max_layouts) == "number" and start_plot_database._lek_global_six_regen_max_layouts >= 1 then
		_lek_global_six_regen_max_layouts = start_plot_database._lek_global_six_regen_max_layouts;
	end
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = RegionalMethod,
		start_locations = starts,
		resources = res,
		AllowInlandSea = AllowInlandSea,
		CoastLux = CoastLux,
		NoCoastInland = OnlyCoastal,
		BalancedCoastal = BalancedCoastal,
		MixedBias = MixedBias;
		};
	do
		local ok, err = pcall(function() start_plot_database:GenerateRegions(args) end);
		if not ok then
			local msg = "### GenerateRegions CRASH runId=" .. tostring(_lek_run_id or "na") .. " err=" .. tostring(err);
			print(msg); appendLekLog({ msg });
		end
	end

	-- Paint region markers immediately after region creation so we can verify
	-- region geometry even if later placement logic hangs.
	print("### DEBUG region markers paint START")
	DebugPaintRegionsTerrains(start_plot_database)
	print("### DEBUG region markers paint END")

	print("Choosing start locations for civilizations.");

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
			if _lek_enable_hb_generatemap_regen_loop == true
				and start_plot_database._lek_global_six_solver == true
				and not biasSkipsSix
				and start_plot_database.iNumCivs == 6
				and att < maxRegenL then
				_lek_global_six_request_map_regen = true;
				local rq = "### LekGlobalSix mapRegen request runId=" .. tostring(_lek_run_id or "na")
					.. " layout=" .. tostring(att) .. "/" .. tostring(maxRegenL)
					.. " reason=ChooseLocations_pcall_err";
				print(rq);
				appendLekLog({ rq });
				if LekPlacementProbeLog then
					LekPlacementProbeLog(rq);
				end
			end
		end
	end
	
	print("Normalizing start locations and assigning them to Players.");
	do
		local ok, err = pcall(function() start_plot_database:BalanceAndAssign(args) end);
		if not ok then
			local msg = "### BalanceAndAssign CRASH runId=" .. tostring(_lek_run_id or "na") .. " err=" .. tostring(err);
			print(msg);
			appendLekLog({ msg });
		end
	end

	-- After BalanceAndAssign, rescue any player still without a starting plot.
	-- This catches both BalanceAndAssign crashes (pcall above) and mismatch bugs.
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
			-- Collect all valid region plots as rescue candidates.
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
			-- Fallback: scan for any land tile if region pool empty.
			if #rescue_candidates == 0 then
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
			print(msg);
			appendLekLog({ msg });
		end
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
			appendLekLog({ msg });
		end
	end

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
						local coast = sp:IsCoastalLand() or false;
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
				LekMapgenDiagLogAppend(lines);
			else
				print("### StartSpacing6P: could not collect 6 start plots, got " .. tostring(#starts));
			end
		end
	end

	print("Placing Natural Wonders.");
	local wonders = Map.GetCustomOption(7)
	if wonders == 14 then
		wonders = Map.Rand(13, "Number of Wonders To Spawn - Lua");
	elseif wonders == 15 then
		wonders = Map.Rand(3, "") + 3
	elseif wonders == 16 then
		wonders = Map.Rand(5, "") + 2
	else
		wonders = wonders - 1;
	end

	print("########## Wonders ##########");
	print("Natural Wonders To Place: ", wonders);

	local wonderargs = {
		wonderamt = wonders,
	};
	start_plot_database:PlaceNaturalWonders(wonderargs);
	FixInlandPancakes();
	print("Placing Resources and City States.")
	appendLekLog({
		"### RunStage runId=" .. tostring(_lek_run_id or "na") .. " stage=before.PlaceResourcesAndCityStates"
	});
	start_plot_database:PlaceResourcesAndCityStates()
	appendLekLog({
		"### RunStage runId=" .. tostring(_lek_run_id or "na") .. " stage=after.PlaceResourcesAndCityStates"
	});

	-- Debug region repaint can be heavy; keep it off while we debug stalls.
	-- DebugPaintRegionsTerrains(start_plot_database)
end
