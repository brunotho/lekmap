# Claude handoff — 2026-09-27 (after release 6.0.5)

## Where things stand
- **6.0.5 is released**: `main` = `dev` = release commit on GitHub (brunotho/lekmap). Changelog: `Changelog_v6.0.5`.
- The user is playing full test games on 6.0.5 and will come back with findings.
- Release values are in place: logs off (`_lek_mapgen_logs = false` in both lobby leaves),
  `LEK_CENTRAL_VOLCANO_CHANCE = 5`.
- Old branches: `mapgen-tuning` (local + origin) is fully merged into main and can be deleted if the user agrees;
  `origin/release/v5.3-testing` is an old remote branch (ask before deleting).

## Resuming test work
1. Work on `dev` (`git checkout dev`). This folder is the game's live copy, so the checked-out branch is what loads.
2. Set `_lek_mapgen_logs = true` in `LekmapPangaeaFractal.lua` and `Lekmap_EquatorRing.lua`.
3. To look at the central volcano, temporarily raise `LEK_CENTRAL_VOLCANO_CHANCE` (release value 5).
4. User tests by rolling Small maps with default settings (mostly Fractal Pangaea) and reports tile coordinates.
   Answer from `Logs/LekmapIslandMap.log` (always the map currently open; check its timestamp — a release build
   writes no logs). Lookup: `grep "xy=X,Y "`.
5. Before a release: flip the values back, bump VERSION / README / both map names, add `Changelog_vX`.

## Watch list (from the 6.0.5 round)
- **Luxury crowding**: `LekmapLandStats.log` has `### LekLuxSummary randomTarget/randomWanted/randomPlaced/typesShort`
  per map. Sea regionals now sit on the mainland coast 4-6 from the capital (2+1 split between both coast
  directions, spacing radius 1, none within 3 of the capital). If random luxuries come up short, lower
  regional spacing further or loosen the placement band.
- **Flat ridge bending** (`### LekFlatRidges runs/bent/shortened`) also runs on Equator Ring; the user has not
  judged it there yet — may need to be skipped on the ring's long east-west chains.
- A very large unexplained island was seen once at 3/22 on a release map (no logs). Best guess: wrap soft
  land bridge (x=3 is next to the wrap seam). User said a one-off is fine.
- Rework candidates: `wrapSoftLandbridge` (can look like rubble on the seam), `splinteredCliffs` (thin snake).
  Unbuilt idea: no islands in narrow straits (except connectors).

## Island system in one paragraph
Engine `Lekmap_IslandEngine.lua`, per-map policies `Lekmap_Islands_FractalPangaea.lua` / `_EquatorRing.lua`,
placers `XX_island_*.lua` (catalog `Lekmap_IslandCatalog.lua`, includes in `3_PangaeaIslands.lua`; commented-out
includes are parked ideas). Rules: every island keeps exactly one water tile to the mainland
(`maxMainlandGap = 2`; `mainlandGapByType` lets splinteredCliffs / shatteredRing / volcanicRing sit one further
out; hotspotTrail exempt), 2 water tiles between islands (`islandGap`), only polarMerge and wrapSoftLandbridge
may touch the mainland (they still keep `islandGap`). Crescent odds 0. Coastal bonus islands (4a,
`PlaceCoastalBonusIslands`) and shore specks follow the one-tile rule too. Central volcano: pipeline
`LekPaintCentralVolcano` (blocks the engine's JunglePeak; Geothermal skips Krakatoa if the volcano has it).
Details: `SCRATCHPAD-island-architecture.md`.

## How to verify changes
- No Lua in the shell by default: `pip install lupa`, compile-check each changed file with `lupa.lua51`
  `loadstring`. Civ5 map scripts have no `_G` — set `_G = nil` in any harness.
- **Island engine harness**: `python scripts/island_engine_harness.py [seeds] [type]` runs the whole engine on
  a synthetic pangaea and prints the per-type water gap to the mainland plus ASCII samples of `type`.
- 4a (start placement / resources) cannot be run offline. New `AssignStartingPlots:Foo` methods must be called as
  `AssignStartingPlots.Foo(self, …)` (or be plain globals); `PlaceLuxuries_OLD` duplicates much of
  `PlaceLuxuries` — edit the live one.
- Errors inside pcall'd stages are silent in-game: check `LekmapPipelineFlow.log` (`*_error`) and Lua.log
  (`PlaceResources_err`, `Runtime Error`).

## Docs kept in the repo
- `LEKMAP-DEBUG-MANUAL.txt` — log switches and log strings.
- `LEKMAP-STRATEGIC-RESOURCE-TUNING-SPEC.txt` — horse/iron requirements (code: LekStratAudit).
- `SCRATCHPAD-island-architecture.md` — island engine / policy design.
- `SCRATCHPAD-equator-ring-followups.md`, `SCRATCHPAD-equator-ring-placement.md` — ring notes and ring-native
  placer plan.
- `SCRATCHPAD-placement-spec-v0.md` (referenced from 4a comments), `SCRATCHPAD-placement-mission-spec.md` —
  global-six (Geometric Balance) start placement contract and phase plan.
- `scripts/lekmap_log_digest.py` (log batch digest), `scripts/island_engine_harness.py`.
Older placement scratchpads, the April tuple handoff, the strategic tuning batch comparison, `legacy/` and two
never-included island placers (CoastalHorn, CrescentAndStar) were removed 2026-09-27 (git history has them).
