- Deferred after next test (keep changes minimal now)
- Coastal-region assignment preference by center band (`dCenter` 8-18) during civ-to-region assignment in `BalanceAndAssign()`
- Re-check where to inject center-band preference: `ChooseLocations()` region processing vs `BalanceAndAssign()` coastal region selection
- Validate global vs Small-only scope for each start-placement tweak and optionally gate per map size if needed
- Optional fallback relaxation strategy if stricter inland coast distance causes too many failed inland candidates

- Earlier larger todo list (carry-over)
- Tune ocean gap behavior on Small until target feel is reached; validate with test rolls
- Add map validity gate so map only passes when island placement/budget criteria are truly met; otherwise regenerate map; verify stability
- Implement and tune center-distance penalty for starting plot scoring to reduce center spawns and encourage rough ring distribution; test impact
- Baseline run: capture and compare `LekmapStartSpacing6P.log` metrics (nearest, second-nearest, center distance)
- Compare nearest-neighbor distribution + center spread after each intervention
- Post-pass tuning: if isolation persists, consider second-order correction (angular spread or swap attempts)

- Current test checkpoint
- Max center distance relaxed to 21 (bullseye min-distance hard veto unchanged)
- City-state uninhabited/island allocation enabled again without % cap (random 1-3 target controls it)
- CS policy tweak for test: minimum 1 per region (scales up with high CS:civ ratio), then random 1-3 to uninhabited/islands, then remainder to other assignment flow
- CS regional placement now first attempts legal plots within distance 8 of the major start in that region
- CS filter tweak: removed non-mainland coastal adjacency-to-mainland requirement; method-1 biggest-area restriction no longer applies when area_ID = -1 (uninhabited/global lists)
- Reliability requirement: always verify all majors have valid starts before proceeding; instant-loss guard stays mandatory
- Investigate rare "0 CS visible" runs: log post-CS final actual minor starts (`GetStartingPlot`) to custom file and compare against validity table/discard count
- Potential sequencing rethink for later: generate pangaea -> place majors -> generate islands -> place city states
- Current 0-CS hypothesis: strict `cityStateData` proximity mask can blank all legal CS sites on some Small rolls; log strict vs proximity-relaxed last-chance candidate counts
- 2026-03-26 hotfix: explicit contiguous fill of `city_state_region_assignments[1..iNumCityStates] = -1` at start of `AssignCityStatesToRegionsOrToUninhabited()` in `4a_HBAssignStartingPlots.lua` (around CS assignment setup, ~L7960-L7985) to prevent `ipairs` early-stop from nil gaps
- 2026-03-26 hotfix: disabled horizontal strip-ocean repaint after Y-shift in `LekmapPangaeaFractalv5.3.lua` (`GeneratePlotTypes` centering block, around old north/south shift cleanup loops near ~L1350 and ~L1370) because it can cut across pangaea when wrap/fringe islands merge landmasses
- 2026-03-26 hotfix follow-up: corrected centering/shift loop bounds in `LekmapPangaeaFractalv5.3.lua` from inclusive `0..iW / 0..iH` to `0..iW-1 / 0..iH-1` and added ocean fallback when shifted source index is out-of-range; target is to stop southern-edge full-row terrain corruption (mountain band artifact)
- Rare instant-death remains low-frequency side risk; avoid brute-force reroll confidence testing for now
- Keep instant-death as tracked side-thread: likely buckets = major-start assignment consistency edge case, post-start mutation side effects, sparse/iteration mismatch, centering/shift residual corruption
- When needed later: add final major-start sanity log near gameplay handoff (`pid`, hasStartPlot, coords/plotType) to custom log; only add reroll gate after evidence
- 2026-03-26 test session 1 (~20 main-menu-separate runs): 2 instant-deaths; CS missing once (runId=854841 - had before-resources stage but no CS lines; PlaceResourcesAndCityStates crashed before PlaceCityStates completed); after-resources stage marker never appears in any run (Lua stack ends before that write executes)
- 2026-03-26 test session 2 (same version): sequence (no CS, dead, dead, normal, dead); no-CS run = runId=563857 (begin+StartSpacing+before-resources, no CS lines); dead runs = runId=649463 and 701507 (begin-only, nothing after)
- ROOT CAUSE IDENTIFIED for begin-only instant-deaths: our own FATAL check (post-BalanceAndAssign, LekmapPangaeaFractalv5.3.lua ~L2222-2253) calls error() when a player is missing a start; but in Civ5, error() inside a map script is caught by the engine and execution continues with the broken state — so error() does NOT abort map load, it only aborts the rest of StartPlotSystem (CS, resources, natural wonders never run); game loads into instant-death anyway but now also without CS/resources → error() is actively making things WORSE
- TWO DISTINCT FAILURE MODES: (A) BalanceAndAssign fails to assign a player a start → FATAL check fires → error() wrecks CS/resource pipeline; (B) PlaceResourcesAndCityStates internal crash before PlaceCityStates runs → no CS but player starts OK
- IMMEDIATE FIX NEEDED: change FATAL check to log via appendLekLog (so visible in custom log) then continue without calling error() — stops mode-A from becoming a full pipeline wipe; instant-death from missing start still occurs but at least CS and resources are placed; separately need to fix root cause of BalanceAndAssign missing a player
- CRITICAL TODO: understand why BalanceAndAssign occasionally leaves a player without a start (iNumRemainingPlayers vs iNumRemainingRegions mismatch?); add logging inside BalanceAndAssign around the assignment loop; fix root cause before relaxing other guardrails
- Next design direction: Small/6 virtual full-set solver with quality gates and placement/map retries

--- INSTANT DEATH ROOT CAUSE ANALYSIS ---

BalanceAndAssign flow (4a_HBAssignStartingPlots.lua:6242):
  1. NormalizeStartLocation for all regions
  2. If DisableStartBias: shuffle and assign all → return (always safe)
  3. Build bias lists: coastal, river, region-priority, region-avoid per civ
  4. Phase A - Coastal bias: assign coastal civs to coastal/lake regions
     → civs that can't be matched (iNumUnassignableCoastStarts) remain unassigned
  5. Phase B - River bias: assign river civs to river regions; also handles
     coastal-bias fallbacks to river regions
  6. Phase C - Region priority (single then multi): match to preferred types;
     fallback via FindFallbackForUnmatchedRegionPriority; if returns -1 → civ skipped
     silently (civ_status stays false, no region consumed)
  7. Phase D - Region avoid: if no candidate regions exist → civ skipped silently
  8. Final loop (L6836-6866): build playerList (civ_status==false) and regionList
     (region_status==false), then assign playerListShuffled[i] → regionList[i]
     CRASH POINT: if iNumRemainingPlayers > iNumRemainingRegions, regionList[i] is
     nil for some i → self.startingPlots[nil] → Lua error → player never gets a start
     → Civ5 engine catches the error, continues, game loads with player missing start

HOW iNumRemainingPlayers > iNumRemainingRegions happens:
  Most likely: one of the bias phases sets region_status[r]=true (consuming a region)
  but fails before setting civ_status[pid+1]=true (or vice versa in a subtle way).
  The assignment order in every phase is: SetStartingPlot → region_status=true →
  civ_status=true. A Lua error between lines 2 and 3 would consume a region without
  marking the civ → net: one extra player vs regions in final loop → crash.
  Secondary path: startingPlots[region_number] is nil for some region (ChooseLocations
  failed silently for that region) → accessing [1][2] crashes before region_status is
  set, but civ is already queued → imbalance.

THE FIX (implemented below):
  1. Add nil guard on regionList[index] in final assignment loop (prevents Lua crash)
  2. Add a rescue pass after all assignments: any player still with no starting plot
     gets assigned to any leftover unassigned region, or if none, to any region at all
     as absolute last resort. Log every rescue with runId.
  This is a safety net below all bias logic — guarantees every player gets a start
  regardless of any upstream bias-phase bug. Does not fix the root cause of the
  imbalance but prevents it from loading as instant-death.
  Note: if startingPlots[r] itself is nil (ChooseLocations failed for region r), the
  rescue may also fail → still need ChooseLocations robustness as a longer-term fix.

--- DEEP CRASH HUNT (2026-03-27) ---

ROOT CAUSE 1 — tooCloseToCenter hard veto (4a_HBAssignStartingPlots.lua ~L3373-3376):
  We added `goodSoFar = false` for dCenter < 8. Combined with bestPlotScore = -5000
  initializer in IterateThroughCandidatePlotList (~L3402), eligible plots scoring -9950
  never beat -5000 → bestPlotIndex stays nil → found_eligible=true but bestPlotIndex=nil
  → arithmetic crash at FindCoastalStart L4028 / FindStart L3669.
  FIX: removed `goodSoFar = false` from tooCloseToCenter (L3373). Penalty-only: plots
  stay eligible but score -10000 lower. Any non-penalized plot beats them easily. In
  degenerate regions entirely inside dCenter<8, least-bad center plot wins safely.

ROOT CAUSE 2 — bestPlotScore/-math.huge (4a_HBAssignStartingPlots.lua ~L3402):
  IterateThroughCandidatePlotList initializes bestPlotScore = -5000. Any eligible plot
  scoring below -5000 (e.g. with -10000 penalty) sets found_eligible=true but leaves
  bestPlotIndex nil. FIX: changed to bestPlotScore = -math.huge so any eligible plot
  always sets the index.

ROOT CAUSE 3 — bestFallbackScore/-math.huge (4a_HBAssignStartingPlots.lua ~L3405):
  Same issue for fallback tracker: bestFallbackScore = -5000 prevents penalized fallback
  plots from being indexed. FIX: changed to bestFallbackScore = -math.huge.

ROOT CAUSE 4 — best_fallback_score = 0 in FindStart/FindCoastalStart/FindStartWithoutRegard
  (4a_HBAssignStartingPlots.lua L3804, L4130, L4310):
  Final fallback selection across all candidate sub-lists initializes best_fallback_score=0.
  Penalized entries in fallback_plots score negative → never beat 0 → best_fallback_x/y
  stay nil → PlaceImpactAndRipples(nil,nil) crashes at L9871, NormalizeStartLocation
  crashes at L5386. FIX: all three changed to best_fallback_score = -math.huge.

ROOT CAUSE 5 — luxury_assignment_count nil for mod resources (4a_HBAssignStartingPlots.lua
  L10353 and L10394/L10398):
  AssignLuxuryRoles fallback path iterates luxury_fallback_weights which contains Lekmod
  resource IDs never initialized in luxury_assignment_count → nil < 3 comparison crash.
  Was always crashing silently (no pcall before). In production (with Lekmod) these IDs
  are initialized so crash never happens. FIX: (self.luxury_assignment_count[res_ID] or 0)
  at both comparison sites; also (or 0) in weight calculation at L10398.

DIAGNOSTIC INFRASTRUCTURE ADDED (LekmapPangaeaFractalv5.3.lua):
  - pcall around GenerateRegions, ChooseLocations, BalanceAndAssign → logs CRASH with
    line number instead of silent death.
  - StartPlotSystem-level rescue pass after BalanceAndAssign pcall: any player still
    missing a start gets assigned to an unused region plot or land-scan fallback; logs
    ### StartPlotSystem RESCUE with coordinates.
  - Post-rescue FATAL check logs any player still missing after rescue.
