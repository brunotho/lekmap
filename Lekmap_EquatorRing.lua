------------------------------------------------------------------------------
-- Lekmap_EquatorRing.lua — lobby leaf: X-wrapping equatorial land ring
------------------------------------------------------------------------------
include("Lekmap_PipelineFlowLog");
_lek_pangaea_land_shape = "equator_ring";
LekPipelineFlowReset("leaf_EquatorRing");
LekPipelineFlow("leaf_after_shape_set");

_lek_mapgen_log_verbosity = 1;
_lek_mapgen_logs = false;
_lek_mapgen_log_channels = {
	islands = true,
	islands_tiles = true,
	strategics = false,
	starts = false,
	mapgen = false,
	pangaea = false,
	bench = false,
	other = false,
};

LekPipelineFlow("leaf_before_pipeline_include");
include("Lekmap_PangaeaPipeline");
LekPipelineFlow("leaf_after_pipeline_include");

function GetMapScriptInfo()
	LekPipelineFlow("GetMapScriptInfo_call");
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "[COLOR_PLAYER_PURPLE_TEXT]Lekmap 6.0.2 -- Equator Ring[ENDCOLOR]",
		Description = "Lekmap pangaea — land belt wrapping the equator with open polar oceans.",
		IsAdvancedMap = false,
		IconIndex = 0,
		SortIndex = 3,
		SupportsMultiplayer = true,
		CustomOptions = {
			{
				Name = "[COLOR_PLAYER_PURPLE_TEXT]Starting Locations[ENDCOLOR]",
				Values = {
					"[COLOR_PLAYER_PURPLE_TEXT]Legacy (Equator Ring)[ENDCOLOR]",
				},
				DefaultValue = 1,
				SortPriority = -100,
			},
			{
				Name = "[COLOR_PLAYER_PURPLE_TEXT]Coastal Spawns[ENDCOLOR]",
				Values = {
					"[COLOR_PLAYER_PURPLE_TEXT][ICON_CAPITAL]Coastal Civs Only[ENDCOLOR]",
					"[COLOR_PLAYER_PURPLE_TEXT]Force 2 Coastals[ENDCOLOR]",
					"[COLOR_PLAYER_PURPLE_TEXT]All Inland[ENDCOLOR]",
					"[COLOR_PLAYER_PURPLE_TEXT]Pure Random[ENDCOLOR]",
				},
				DefaultValue = 1,
				SortPriority = -98,
			},
		},
	};
end
