# Master plan: reliability, tuple proof, islands, perf (try order)

**Start here (single narrative + backlog):** [SCRATCHPAD-unified-placement-and-bias-spec.md](./SCRATCHPAD-unified-placement-and-bias-spec.md)

Cross-links: [hard coastal + bias tiers](./SCRATCHPAD-hard-coastal-quota-architecture.md), [tuple roadmap + bias modes](./SCRATCHPAD-tuple-roadmap-bias-and-performance.md), [placement glossary](./SCRATCHPAD-start-placement-architecture.md).

## Architecture we do not break

- **Order:** `GenerateRegions` → `ChooseLocations` (tuple or legacy) → `BalanceAndAssign` → resources/CS. Tuple fixes `startingPlots[r]` before player↔region assignment.
- **Hard vs soft:** Coastal quota / plist rules (per coastal doc); geometry phases; optional **post-tuple** checks (e.g. min pairwise among **players** via `LekAssertGlobalSixPlayerMinPairwiseOrRegen`).
- **Medium escape phases (`mL123_esc`, `mL4_esc`, `mL5_esc`):** Tail row(s) in each layout’s phase table — very loose S1/S2, **`first_nearest_max = nil`**, **`skip_min_pairwise`** skips §2’s **Start Distance (opt 6)** clause **during tuple OK only**. **`mL5_esc` alone is not enough** on layouts 1–4: those tables used to keep **`first_nearest_max = 13`** through all phases, so a **`g6` line with `zF…` (only first-nearest fails)** would exhaust the ladder **before** any layout-5 phase. Final majors must still pass opt 6 after assign unless you change that assert or the menu option.

---

## Why Pangaea “outer” rerolls **inside one layout**

In `LekmapPangaeaFractalv5.3.lua` → `PangaeaFractalWorld:GeneratePlotTypes`, **`allcomplete`** loops up to **`MAX_OUTER`** (**55** when map option **16** requests a positive **min island** count — `minIslands = option16 - 1`; **25** when **minIslands = 0**). Each **outer** pass: new fractal land/water, **coasts**, then **`GeneratePangaeaIslands`**, then **land fraction / water-slice / budget** checks. Any check fails → **redraw** the same layout attempt **without** incrementing map **layout** (layout regen is separate).

If all outers fail, **`_lek_pangaea_max_outer_failed`** is set → **`BalanceAndAssign`** clears major starts → **dead on spawn** (by design). This is **independent** of global-six.

**Compact failure line (verbosity 1):** `### LekPangaeaMapFail o=… la=… pass=0 L0|1 iplaced/need B0|1 W0|1 nL=… need=…` — **L** land floor met, **i** islands placed vs **minIslands**, **B** island budget OK, **W** water-slice reject (1 = bad).

**Island seed A/B (verbosity 1, end of each `runOnce`):** `### islS la=… o=… bt=… nTry=… g=ok/fail r=ok/fail x=ok/fail br=… gui=0|1` — **g** = guided bucket + ripple precompute, **r** = legacy ring-bias probes, **x** = random‑x / ripple / override paths; **br** = bucket rebuild count (~ placed+1); **gui** = guided band on. **Regression:** `g` fails explode while `r`/`x` ok → guided/BFS mismatch; **improvement:** higher `g` ok / `nTry` down at same `spent` vs old builds.

---

## Island seed search (why it feels random)

In `3_PangaeaIslands.lua`, `tryOneSpot`:

1. Picks **y** (sometimes banded per island type), **x** often **`Map.Rand(iW)`** on ocean, or **ring-biased** probes (`pullBack`+`effMin`/`effMax`) that require a random ocean tile whose ripple hits pangaea land at a ring in **[rLo,rHi]**.
2. From ocean `(x,y)`, **ripple** finds nearest **pangea** land ring; filters **`pangeaTiles`**, cluster/tiny heuristics, then **`TryPlaceIsland`**.

Failures → **many attempts** inside `placeAndCount` (cap ~180) and **budget retry** paths → long **`generatePangaeaIslands_dt`** and many **`LekIslandPlaced`** / **`budget_retry_exhausted`** lines.

**Your idea (guided seeds):** Precompute **coastline / offshore bands** (distance-to-pangaea-land field or sparse “good ocean” list) and sample seeds from **that** set instead of uniform random ocean. Fits current architecture (still calls `TryPlaceIsland`); biggest win when **budget_met** is rare. **Risk:** biased island clustering — needs design targets.

---

## Compressed log format (`g6|...`)

Emitted at verbosity 1 when `_lek_global_six_compact_log ~= false` (default).

| Token | Meaning |
|-------|---------|
| `g6` | global-six chooseStarts one-liner |
| `r` | runId |
| `L` | layoutAtt/max |
| `o` | 1 success, 0 fail |
| `w` | why / first_fail (truncated) |
| `fc`,`lv`,`mf` | failComplete, leafEvals, maxFail cap |
| `p` | phase index |
| last pipe segment | short phase name |
| `z…` | §2 subcounts when fail and s2-dominated sampling ran: **`P`**=min pairwise (opt6), **`2`**=second-nearest cap, **`F`**=first-nearest cap (need **`first_nearest_max = nil`** or missing from phase — see **`mL123_esc` / `mL4_esc`**), **`X`**=unparsed (e.g. `missing_i`) |
| **`|bmS` / `|bmL`** | **`bmS`**=strict §5 predicates; **`bmL`**=legacy-soft non-coastal (river/prim/avoid) for that chooseStarts attempt |

Full phase diagnostics: `_lek_mapgen_log_verbosity=3`, see `tuplePhase end` **`s2z=`** histogram.

**Copy-back (paste to assistant):** With default **`_lek_global_six_compact_log`** (on in `4a`), **`_lek_mapgen_log_verbosity=1`** is enough for the full tuple outcome: one **`g6|…`** line per `chooseStarts` attempt. If **`w`** is **`s2`** (truncated) or you need histogram detail, one run at **verbosity 3** captures **`s2z=`** on phase end; long legacy line: set `start_plot_database._lek_global_six_compact_log = false` in the map script block where other tuple flags live.

---

## Step list (what we try, in order)

| Step | Goal | Success signal (logs / behavior) |
|------|------|-----------------------------------|
| **A** | Medium **tuple** almost never fails: per-layout **`mL*_esc`** + `skip_min_pairwise` + no first-nearest cap | **`g6|…|o1`** on bad rolls; **`zF`** on early layouts → was missing **`mL123_esc`**/ **`mL4_esc`**; if still **`o0`** and **`w`** not `s2`, failure is **S5/S6/S3/S1/pool** |
| **A′** | If tuple **o1** but **`LEK MAJOR MIN PAIRWISE`** or regen: align **opt 6** or assert with escape policy | No spurious regen after assign; doc intentional tradeoff |
| **B** | **§2 diagnosis**: `z` / `s2z` shows **P vs 2 vs F** dominance | Know whether to loosen **opt6** vs **s2max** vs **firstNearest** |
| **C** | **DFS / snapshot** perf (incremental undo, per-layout candidate cache) | Lower **`dt_startPlotSystem`** for same caps; fewer seconds per failed layout |
| **D** | **Island** guided ocean seed list / ring priors; if **`max_outer`** still fire, re-tune **MAX_OUTER** or option **16** pressure | Lower **`outerAttempts`**, shorter **`generatePangaeaIslands_dt`**, fewer **`max_outer`** hits; **`LekPangaeaMapFail`** shows which clause failed |
| **D′** | **`3_PangaeaIslands.lua`** time caps (see file header constants): **`PANGAEA_RUNONCE_MAX_CLOCK`**, **`PANGAEA_BUDGET_TIER_MAX_CLOCK`**, **`PANGAEA_BUDGET_FAST_FAIL_*`**, tighter **`MAX_TRIES_PER_BUDGET`** / common-fill idle / **`placeAndCount`** caps | **`budget_retry_exhausted`** and bad outers should stay **~seconds–low tens of seconds**, not **~100s+**; if success rate drops, loosen caps slightly |
| **E** | **Coastal quota / bias modes** (P0–P1 other scratchpads) | Medium ≡ Slow bias philosophy; fewer **s5** injective fails |

---

## Revision log

| Date | Note |
|------|------|
| 2026-04-05 | **SSOT:** [SCRATCHPAD-unified-placement-and-bias-spec.md](./SCRATCHPAD-unified-placement-and-bias-spec.md) (pipeline + bias tiers + P0–P4 merge). |
| 2026-04-05 | Initial master plan: try order, island/outer explanation, compact `g6` legend, escape-phase caveat for opt6 assert. |
| 2026-04-05 | Copy-back recipe: verbosity 1 + default compact = pasteable `g6`; v3 for `s2z`; `_lek_global_six_compact_log = false` for long line. |
| 2026-04-05 | **`mL123_esc` / `mL4_esc`**: same escape as **`mL5_esc`** on layouts 1–4; fixes **`zF`-only** §2 fails that never reached **`mL5_esc`**. |
| 2026-04-05 | Pangaea: **`MAX_OUTER=55`** when **`minIslands>0`**; **`LekPangaeaMapFail`** one-liner per failed outer for land / island count / budget / water-slice. |
| 2026-04-05 | Islands: tighter **`runOnce`** / tier clocks, **`fast_fail`**, fewer **`maxTriesPerBudget`** and common-fill tries — cuts **`~100s budget_retry_exhausted`** wall time (step **D′**). |
| 2026-04-05 | **`3_PangaeaIslands`**: dynamic **ocean-only BFS** from snapshot pangaea land → ring buckets; **guided** **`tryOneSpot`** samples the type’s ring band; buckets **rebuild after each placement** (non-pangea land blocks). Toggle **`PANGAEA_GUIDED_OCEAN_BAND`**. |
| 2026-04-05 | **`islS`** one-line **`tryOneSpot`** seed stats (`g`/`r`/`x` ok/fail, **`nTry`**, **`br`**, **`gui`**) at mapgen verbosity **1** for improvement vs regression. |
