# Claude handoff — 2026-09-26 (dev branch, mid-tuning)

## Where things stand
- **Branch `dev`** holds all work since release **6.0.4** (on `main` + GitHub). `main` = what people play; do not merge
  `dev` into `main` until the user asks to release. Next release will be **6.0.5**.
- `dev` is pushed to GitHub as a backup. Old branch `mapgen-tuning` is fully merged into main (can be deleted if the user agrees).
- User tests by rolling maps in-game (Small, default settings, Fractal Pangaea mostly) and reports island tile
  coordinates; answer from `Logs/LekmapIslandMap.log` (always the map currently open).

## Testing-only values on `dev` (revert before release)
- `_lek_mapgen_logs = true` in `LekmapPangaeaFractal.lua` and `Lekmap_EquatorRing.lua` (release: `false`).
- `LEK_CENTRAL_VOLCANO_CHANCE = 100` in `Lekmap_PangaeaPipeline.lua` (release: `1`).
- On release also: bump `VERSION`, README, both map names (`Lekmap 6.0.5 -- …`), add `Changelog_v6.0.5`.

## Pending evaluation (user is judging by rolling)
- **Regional luxury max distance 7 → 6** (`LEK_REGIONAL_LUX_MAX_DIST`, 4 call sites in 4a). Watch: regionals clumped
  next to capitals, fewer random luxes near starts, coastal sea-regionals shortfalls.
- **Island count** after budget normalization (every type's budget = avg tiles / 11.5) and the new 2-water-tile island
  spacing (`islandGap = 2`). If still too many: raise common costs (pebble/strip ~0.37 → ~0.6) and trim shore specks
  (`shoreSpecks` in the island policies).
- **Fish** rates `LEK_FISH_RING_FREQ = { 3.5, 7, 16 }` — user says it looks okay now.
- Possible next rework candidates: `splinteredCliffs` (last seen as a thin 10-tile snake), wrapSoftLandbridge
  (can look like scattered rubble on the seam). Optional unbuilt idea: no islands in narrow straits (except connectors).

## What changed on `dev` since 6.0.4 (high level)
Landmass: restored the enforced choke check (removing it caused pinched pangaeas; now fast because island crashes are
fixed), MAX_MIDDLE 200 guard. Water 56 kept.
Islands (engine `Lekmap_IslandEngine.lua`, policies `Lekmap_Islands_*.lua`):
- Fixed 0-based plotTypes indexing in 15 island files; Sinai rewritten (wonder on centre, extra peaks ≥2 away, axial
  rotation); PolarMerge outward arm drift ≤1; SplinteredCliffsTiny rebuilt as **sea stacks** (single-peak row one
  water tile off shore, max 2/map); ShoreSineChain rebuilt (follows coast, cohesive islets ≤5 tiles); ClusterOfTiny no
  mountains; new types **hotspotTrail**, **atollRing** (max 1/map); ShoreSineChain enabled on Pangaea.
- Engine rules: gap guard (non-connector islands keep ≥1 water tile from pre-island land; connectors =
  polarMerge, wrapSoftLandbridge, ridgePeak, mountainWall); seeds anchor to the **mainland only**; closest tile within
  `maxMainlandGap = 3`; `islandGap = 2` water tiles between different placements; `maxPerType` caps; dots revived but
  rare (odds 1, early dot phase off); budgets normalized.
- **Shore specks** pass (tiny 3–5, strips 1–2, one water tile off mainland, outside the budget).
- Island vegetation 80% (jungle in tropics, forest elsewhere); coastal bonus islands forest 80%.
Central structures (Fractal Pangaea only, `Lekmap_PangaeaPipeline.lua`):
- Inland-sea rules (≥6 from ocean, ≤7 span, capital clearance fill, coastal starts ignore inland seas).
- Central sea (30%) replaced "grow & round"; **central volcano** (JunglePeak stamp, caldera + 1-tile moat + 3–5 noise
  flips, Krakatoa/Sri Pada/mountain 40/40/20, 60–80% jungle, 3–6 spike mountains, anchor within radius 6 of centre,
  capitals kept ≥5 from peak in the Geometric Balance pools); when any central sea exists all other inland water is
  filled; mountain groups within 2 of the centerpiece water demoted.
Terrain/resources: polar 2 rows forced snow + tundra buffer next to snow; medium mountain ridges pass (3–5 ridges of
3–4, 25% one 5–6 clump); tropical luxes banned within 8 rows of map edges; fish ring bias; regionals max 6.
Logging: see memory `lekmap-logging` — LandStats (appended), PipelineFlow (per map), IslandMap (per map, bays too).

## How to verify code changes (important)
- There is no Lua in the shell by default; `pip install lupa` was used. Compile-check every changed file with
  `lupa.lua51` `loadstring`. For behaviour, a harness loads `3_PangaeaIslands` with stubbed `Map`/`PlotTypes` and a
  synthetic elliptical pangaea (44×52) and runs `GeneratePangaeaIslands` many seeds.
- **Always set `_G = nil` in the harness** (Civ5 map scripts have no `_G`).
- 4a (start placement / resources) cannot be harness-tested; be careful: new `AssignStartingPlots:Foo` methods must be
  called as `AssignStartingPlots.Foo(self, …)` (the object copies an explicit method list). Locals must be defined
  before the closures that use them.
- Errors inside pcall'd stages are silent in-game: check `LekmapPipelineFlow.log` (`islands_error`, `*_error`) and
  Lua.log (`PlaceResources_err`, `Runtime Error`).
