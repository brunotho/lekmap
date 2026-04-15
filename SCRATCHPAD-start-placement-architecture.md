# Start placement: architecture scratchpad

**Unified plan / spec (read first):** [SCRATCHPAD-unified-placement-and-bias-spec.md](./SCRATCHPAD-unified-placement-and-bias-spec.md)

Purpose: one place to list **what the code actually does** (grouped by effect type) and **what we want next**, so changes stay coherent instead of stacking one-off patches.

**Plain language (same terms as placement spec):** **`GenerateRegions`** = cut map into six chunks; **`ChooseLocations`** = Firaxis step that picks six regional capitals; **`PlaceImpactAndRipples`** = after each capital, mark “too crowded” nearby for later picks; **`distanceData`** = those crowding marks; **`EvaluateCandidatePlot`** = score + pass/fail one city site; **`BalanceAndAssign`** = assign each **player/civ** to one chunk’s capital. Full glossary table: [`SCRATCHPAD-placement-spec-v0.md`](./SCRATCHPAD-placement-spec-v0.md) § Plain language cheat sheet.

---

## Pipeline order (high level)

1. **`GenerateRegions`** — divides map into rectangles + assigns region types / area IDs; fertility stats per region.
2. **`ChooseLocations`** — builds **region assignment order** (low→high avg fertility by default), counts **coastal / river / region-priority** civ needs, may **reserve** regions for priority civs, then runs **`LekRunOneStartPlacementPass`** (per-region `FindCoastalStart` or `FindStart`), optionally **virtual-six** replan for 6 civs, etc.
3. Each placement calls **`PlaceImpactAndRipples`** — updates **`distanceData`** (ripple) and resource/CS/NW layers.
4. **`BalanceAndAssign`** — assigns player↔plot mapping, normalization, team handling (details not fully enumerated here).

---

## A. Hard filters (candidate never wins — score irrelevant)

| Mechanism | What it does |
|-----------|----------------|
| **`EvaluateCandidatePlot` early outs** | Returns `0, false` for excluded plots (`_polar_merge_excluded_plots`, `_fjord_peninsula_excluded_plots`). |
| **Polar edge** | `distFromEdge < 8` → reject (`0, false`). |
| **Snow capital** | Terrain `TERRAIN_SNOW` on candidate tile → reject. |
| **`distance_bias` / ripples** | If `self.distanceData[plotIndex] > 0`, plot is **not** “eligible” (`goodSoFar = false`); massive score cut. Practically: **too close to an already placed start** (or pre-filled island impact). |
| **`FindStart` / `FindCoastalStart` list membership** | Plot must be in **region rectangle**, right **area ID** (or `-1`), **land/hills** (not mountain for coastal path), **not** stuck in “two/three plots from ocean” buckets (inland `FindStart` splits those to separate lists that never compete for normal picks). |
| **Coastal path** | `plotDataIsCoastal`; optional **`AllowInlandSea`** vs `IsCoastalLand(300)` gate; **`NoCoastInland`** can forbid coastal tiles for inland search. |
| **Ring minimums in `EvaluateCandidatePlot`** | After counting food/prod/good/junk in inner → middle → outer rings: if below **`minFood*` / `minProd*` / `minGood*`** or **`junkTotal > maxJunk`**, `goodSoFar = false` (fallback tier only for that plot). |

---

## B. Candidate pool construction (who even gets scored)

| Mechanism | What it does |
|-----------|----------------|
| **`centerBias` / `middleBias`** | Region rectangle is split into **center strip**, **middle annulus**, **outer rim** for **bucketing** candidates (separate Lua tables). |
| **Hydrology sub-buckets** | River vs freshwater vs “dry” vs coastal lists (coastal start has its own partition). |
| **Lekmap: `_lek_flatten_region_start_tiers`** | When **true** (from map script): **merge** center + middle + outer buckets (dedupe) into **one** list, then score together. When **false** (vanilla-style): **ordered** processing — earlier buckets can “win” before later ones are considered. |
| **`FindStartWithoutRegardToAreaID`** | Alternate path: best **landmass** inside region; own lists and fallbacks (used in some fallback flows — not the default per-region happy path). |

---

## C. Per-plot scoring & soft penalties (`EvaluateCandidatePlot`)

These **add/subtract** `finalScore`; **eligibility** still requires passing ring minimums unless in fallback tier.

| Ingredient | Role |
|------------|------|
| **Inner / middle / outer ring tallies** | Food, prod, “good”, junk, river; weighted tables → `innerRingScore`, `middleRingScore`, `outerRingScore`. |
| **`coastScore`** | +40 if `plotDataIsCoastal`. |
| **`saltSeaAdj`** | −3 per adjacent **non-lake salt** hex side. |
| **`tooCloseToCenter`** | `dCenter < 8` → **−10000** (still can be fallback). |
| **Lekmap: rim `dCenter`** | `dCenter > 18` → **−5500**; `> 21` → extra **−12000** (magnitude tunable). |
| **`distance_bias`** | When > 0: `goodSoFar = false`, score reduced by `%` of score — **near existing starts** via ripple overlay. |

**Note:** Fertility-heavy totals can **dominate** modest `dCenter` penalties if rings are much better on one tile than another.

---

## D. Selection rule within one candidate list

| Mechanism | What it does |
|-----------|----------------|
| **`IterateThroughCandidatePlotList`** | Among plots with **`goodSoFar == true`**, pick **highest `finalScore`**; else among fallbacks pick highest fallback score. |
| **Vanilla outer-only path** | When flatten is **off** and only **outer** bucket runs after center/middle exhausted: collect eligibles, pick **best score** (Lekmap changed legacy **Euclidean-to-region-bullseye** tie-break to score there too). |
| **Per-region fallbacks** | Multiple sub-list fallbacks can accumulate; final pick is **max score** among `fallback_plots` entries, else forced grass tile in corner. |

---

## E. Global ordering before / outside `FindStart` (`ChooseLocations`)

| Mechanism | What it does |
|-----------|----------------|
| **Region processing order** | Regions sorted by **average fertility** (low first unless logic edits list). |
| **`iNumCoastNeeded`** | Count civs that **need coastal** starts; first N regions along assignment order that aren’t “inland forced” get **`FindCoastalStart`**. |
| **`MixedBias` roll** | Can **downgrade** weak coastal-bias civs to non-coastal need. |
| **River / region-type priority civs** | **Reserve** matching **`regionTypes[reg]`** slots (`res_reg`); **mutations** to `regionAssignList` / `reg_still_active` when matching. |
| **Reserved / special starts** | Solomons / geothermal (etc.): **`distanceData` pre-seeded** with ripples before main loop so candidates near those plots are **biased or disqualified**. |
| **Lekmap virtual six (6 civs)** | After an initial pass, may **re-roll** six-tuple of regions/placements using **packing score** (`LekMinNearestAmongSix`) and tie-break **`LekVirtualSixInlandOceanUndesirable`** (inland salt-water exposure in hex radius 4). Requires method on **`findStarts`** whitelist in **`Create()`**. |

---

## F. Cross-start spacing layer (`PlaceImpactAndRipples`)

| Mechanism | What it does |
|-----------|----------------|
| **`distanceData` ripples** | Option **6** selects ripple table strength/length; values 1–99 on hex rings; drives **`distance_bias`**. |
| **Resource / luxury / CS / fish / NW impacts** | Separate radii — not start score but **resource and CS placement**. |
| **`_lek_collide_coastals`** | Coastal starts use **`PlaceResourceImpactCoastalMod`** for CS layer (stronger coastal crowding behavior). |

Design intent (comment in code): **~9-tile** crowding philosophy; severe penalty inside **7**, near-prohibitive inside **5** when alternatives exist.

---

## G. Map script → database knobs (Lekmap Pangaea example)

| Field / flag | Typical effect |
|----------------|----------------|
| **`centerBias` / `middleBias`** | Size of center vs middle vs outer **buckets** (still matters for **which tiles appear in which list**; with **flatten**, not order of pick). |
| **`_lek_flatten_region_start_tiers`** | Single merged pool per region/coastal search. |
| **`_lek_collide_coastals`** | Coastal CS impact mod. |
| **`_lek_coastal_refish`** | (Hook; semantics elsewhere.) |
| **`mustBeCoast` / `NoCoastInland` / `BalancedCoastal` / `CoastLux`** | Passed via **`GenerateRegions` / `ChooseLocations` / args** — affect coastal count and eligibility. |

---

## H. What is *not* fully captured above

- **`BalanceAndAssign`** details (swaps, team packing, coastal guarantees after the fact).
- **`NormalizeStartLocation` / rescue** paths in map script if start plot nil.
- Full **virtual-six** eligibility and retry counts.
- **City-state** placement interaction with start ripples.

*(Add bullets here as you audit.)*

---

## I. Desired goals — **to refine together**

_Use this section to phrase the end state in the same “bucket” vocabulary. Mark: required / nice / avoid / measure._

### Hard filters we might add or tighten

- …

### Scoring / priorities we want to dominate fertility

- e.g. map-center distance (`dCenter`), pairwise distances, symmetry, rim vs ring, inland-ocean exposure, …

### Pool construction we want

- e.g. drop bucket system entirely vs keep buckets only for diagnostics; global search per region; …

### Global optimization

- e.g. replace greedy region order + ripples with **one** objective over all six starts; keep ripples as soft only; …

### Telemetry / validation

- e.g. log `dCenter`, min pairwise, virtual-six metrics for every roll; assert bands; …

---

## Revision log

| Date | Note |
|------|------|
| 2026-03-27 | Initial inventory + empty “desired” section. |
