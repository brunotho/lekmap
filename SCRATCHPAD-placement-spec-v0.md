# Placement spec v0.3 (authoritative)

Target behaviour for **global six-start placement** (Pangaea / **6 players only** for now). Implementation: **Lane A** — clean slate for the new solver; **vanilla / pre-Lekmap code paths stay in the file but are commented out rather than deleted** when superseded.

- Related: [`SCRATCHPAD-start-placement-architecture.md`](./SCRATCHPAD-start-placement-architecture.md) (what the **current** code does).
- Narrative / balance notes: [`SCRATCHPAD-start-balance.md`](./SCRATCHPAD-start-balance.md).

---

## Strategy: strict first

Implement **full strictness** (all `OK` clauses + full `EvaluateCandidatePlot` gates, **zero slack** at first) and **log every failed predicate** (counts + last-failure detail). Measure **6-tuple attempts**, **map regens**, wall-clock. **Relaxation only after metrics**, not preemptively.

---

## Scope

- **Six majors only.** 4p / 8p **out of scope** until this path is stable.
- **`GAMEOPTION_DISABLE_START_BIAS`:** do **not** enter the new solver — use **vanilla / today** `ChooseLocations` → `BalanceAndAssign` flow only for that game.

---

## Terminology + code pointers

| Term | Meaning | Where in repo |
|------|---------|----------------|
| **`region_number` `r`** | Index **1…`iNumCivs`**. Each **r** owns one rectangle from **`GenerateRegions`** (`self.regionData[r]`). | `4a_HBAssignStartingPlots.lua` — `regionData`, `GenerateRegions` |
| **`self.startingPlots[r]`** | **Table** `{ x, y, score? }` = capital **for region r** before players are attached. **`ChooseLocations` / new solver** fills this; **`BalanceAndAssign`** then gives each **player** one region’s plot. | Written ~`L3692+` in `FindStart` / virtual six; read **`BalanceAndAssign`** ~`L6508+` |
| **`self.regionTypes[r]`** | Integer **terrain/region class** for luxuries / `EvaluateCandidatePlot` (grassland, hills, …). Passed as **`region_type`** into **`EvaluateCandidatePlot`**. | `DetermineRegionTypes`, **`EvaluateCandidatePlot(plotIndex, region_type)`** ~`L3115` |
| **`self.distanceData`** | Per-plot **ripple** from placed starts; drives **`distance_bias`** in **`EvaluateCandidatePlot`**. Initialized in **`AssignStartingPlots.Create`** ~`L254`. | **`PlaceImpactAndRipples`** ~`L2847+` |
| **`distance_bias`** | `self.distanceData[plotIndex]` — if **> 0**, **`EvaluateCandidatePlot`** sets **`goodSoFar = false`** (plot treated as **fallback** tier for crowding). | ~`L3152`, ~`L3444` |
| **`EvaluateCandidatePlot`** | Returns **`finalScore`, `meets_minimums`**. For **`OK`**, only **`meets_minimums`** is a **hard** gate unless you explicitly add **`finalScore`** tie-break between two passing 6-tuples. | ~`L3115–L3459` |
| **`CivNeedsCoastalStart`**, **`CivNeedsRiverStart`** | **XML-driven** booleans. | **`1_HBMapmakerUtilities.lua`** ~`L775`, ~`L785` |
| **`PlaceImpactAndRipples(x,y)`** | Writes **`distanceData`** ripples + **resource/CS/NW** impact layers for one placed start. **`OK`** simulation uses **full** calls, not distance-only. | ~`L2847` |

**Civ bias vs tile quality:** XML **priority/avoid** = **region type** per **`self.regionTypes[r]`** (tundra, jungle, forest, …). **`EvaluateCandidatePlot(`** is **local rings** + **`distance_bias`** for **site** quality. **Early bind:** fix a **civ↔region `r`** plan (and coast/river needs) **before** coordinate search so **`BalanceAndAssign`** can match the same multiset.

**`MixedBias` / `CivNeedsPlaceFirstCoastalStart`:** mirror the same **pre-pass logic** `ChooseLocations` uses today (including random clearing of coastal need when **`MixedBias`** rolls), so the solver’s planned civ-needs match what **`BalanceAndAssign`** expects.

---

## Resolved design choices

| Topic | Decision |
|--------|----------|
| **Ring shape (OK §1)** | **Option A** locked: **`R = 13`**, **`δ = 1`** → allowed **`d(p) ∈ {12,13,14}`** to map centre ( **`Map.PlotDistance` / `PlotDistance`** ). |
| **OK §7 / site quality** | **Full** **`EvaluateCandidatePlot`** + **full** **`PlaceImpactAndRipples`** in **fixed region order 1→6**, then snapshot-restore layers after each failed tuple. |
| **Inland salt (OK §4)** | Hex **distance ≤ 3** from start; count **salt ocean** (**`IsWater` and not `IsLake`**) **`≤ 4`** per **non-coastal** start. (**Single authoritative numbers**; any older heuristic using **d≤4** in interim code is **obsolete** once the solver lands.) |
| **Coastal adjacency on ring** | **Only** when **exactly two** coastal majors: **`C`** not adjacent to **`C`** on the **geographic** six-cycle. |
| **Ring geometry (2-coastal rule)** | **Random rotation** of which geometric slot is cycle index 0 (per attempt). |
| **Ripple simulation order** | **Fixed `r = 1…6`**. |
| **Player count** | **Six only** for this path. |
| **`GAMEOPTION_DISABLE_START_BIAS`** | **Vanilla path only** — no new global solver. |
| **Legacy code hygiene (Lane A)** | Prefer **commenting out** superseded **vanilla-era** branches over deleting them, so diffs stay reviewable and rollback is easy. |
| **Interim `LekVirtualSix` / heuristics** | Treated as **pre-spec** exploration; **remove or disable** when the global-`OK` solver is wired — do **not** treat **32× shuffle / inland-salt tiebreak** as the target contract. |

---

## Ring shape — Option B (reserve only)

**Option B** (minimise radial spread subject to **`dCenter≤18`**, **`d₂≤15`**, …) stays **documented** in earlier notes as a **pressure valve** if Option A regen rate is bad — **not** v0.3 default.

---

## River / forest wording

- **River need:** satisfiable via **`plot:IsRiverSide() or plot:IsFreshWater()`** on the **assigned** start for that civ/region (match **`FindStart`** / classification where possible).
- **“Forest” in XML bias:** for **v0.3** there is **no extra OK clause** beyond **region priority/avoid** (forest is a **region class**, not a separate ring count). **Optional** later: hard predicate on capital / ring forest count — only if you add it explicitly.

---

## `BalanceAndAssign` handoff

The six **`startingPlots[r]`** must be compatible with **`BalanceAndAssign`**’s coast / river / priority / avoid matching **for some** assignment order consistent with **`player_ID_list`**. If impossible, change **`BalanceAndAssign`** (larger project) — not a silent mismatch.

---

## Global `OK` checklist (v0.3)

1. **Ring band:** **`d(p) ∈ [12,14]`** to centre (Option A).  
2. **`dCenter ≤ 18`** for all six (same distance function as today).  
3. **`d₂ ≤ 15`** for each start (second-nearest of five others).  
4. **Inland salt:** non-coastal starts: **≤ 4** salt-ocean hexes within **d ≤ 3**.  
5. **Two coastals:** on rotated geographic cycle, **no adjacent `C`/`C`**.  
6. **Bias:** planned **civ↔region** satisfies XML coast / river / region priority / avoid together with **actual** plot flags at those coordinates.  
7. **Site quality:** **`EvaluateCandidatePlot`** → **`meets_minimums == true`** per **`r`**, after simulating **six** **`PlaceImpactAndRipples`** in order **1→6**.

---

## Search + regen + fallback

- **100** failed **complete** 6-tuples **per map layout**.  
- **4** map layouts total (**1** initial **+** **3** regens) ⇒ **400** failed tuples max before **fallback**.  
- **Fallback:** **`ChooseLocations`** as today (**including** interim virtual-six block **until** removed/disabled per Lane A).  
- Log **failure kind** each time (ring, **d₂**, salt, 2-coastal, bias, **`meets_minimums`**, ripples, …).

---

## Still TBD (ask before inventing)

- Any **new** rule that **contradicts** vanilla **`BalanceAndAssign`** ordering (e.g. forcing a **specific** player index to a region **before** vanilla’s phases).  
- **Map script hook** exact line — implement when touching **`ChooseLocations`**.

---

## Revision log

| Date | Note |
|------|------|
| 2026-03-27 | Split from start-balance; folding + open questions. |
| 2026-03-27 | v0.1–v0.2: pointer table, random ring, **400** tries, full ripples, bias clarity. |
| 2026-03-27 | **v0.3 authoritative:** **R/δ** locked, **inland salt** **d≤3 / max4** canonical, **`GAMEOPTION`**, **Lane A** + comment-not-delete, **`MixedBias` parity**, **forest** = region class only unless extended, interim virtual-six **non-contract**, **`finalScore`** optional tie-break only. |
