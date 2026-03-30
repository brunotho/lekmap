# Placement spec v0.5 (authoritative)

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
| **`BalanceAndAssign` / Variation A** | **Confirmed:** global solver (when implemented) **only** fills **`startingPlots[1…6]`** with plots that satisfy **`OK()`**. **Vanilla `BalanceAndAssign`** owns **player↔region** assignment **unchanged** — **no** custom ordering that forces a given **player index** to a given **`r`** ahead of vanilla phases. |
| **Map centre distance (OK §1)** | **Hard band:** **`8 < d(p) < 19`** (integer distance ⇒ **`9 ≤ d(p) ≤ 18`**) from map centre using **`Map.PlotDistance` / `PlotDistance`** on each final capital plot **`p`**. **Tie-break** among passing 6-tuples: minimise **`M = maxᵢ \|d(pᵢ) − 13\|`** (smallest worst deviation from ideal **13**); if still tied, **secondary:** minimise **`Σᵢ \|d(pᵢ) − 13\|`**. **Replaces** v0.3 **{12,13,14}** annulus. |
| **OK §7 / site quality** | **Full** **`EvaluateCandidatePlot`** + **full** **`PlaceImpactAndRipples`** in **fixed region order 1→6**, then snapshot-restore layers after each failed tuple. |
| **Inland salt (OK §4)** | Hex **distance ≤ 3** from start; count **salt ocean** (**`IsWater` and not `IsLake`**) **`≤ 4`** per **non-coastal** start. (**Single authoritative numbers**; any older heuristic using **d≤4** in interim code is **obsolete** once the solver lands.) |
| **Coastal adjacency on ring** | **Only** when **exactly two** coastal majors: **`C`** not adjacent to **`C`** on the **geographic** six-cycle. |
| **Ring geometry (2-coastal rule)** | **Random rotation** of which geometric slot is cycle index 0 (per attempt). |
| **Ripple simulation order** | **Fixed `r = 1…6`**. |
| **Player count** | **Six only** for this path. |
| **`GAMEOPTION_DISABLE_START_BIAS`** | **Vanilla path only** — no new global solver. |
| **Legacy code hygiene (Lane A)** | Prefer **commenting out** superseded **vanilla-era** branches over deleting them, so diffs stay reviewable and rollback is easy. |
| **Interim `LekVirtualSix` / heuristics** | Treated as **pre-spec** exploration; **remove or disable** when the global-`OK` solver is wired — do **not** treat **32× shuffle / inland-salt tiebreak** as the target contract. |

**Cleanup landed (repo):** Default map script sets **`_lek_enable_virtual_six_retries = false`**, **`_lek_disable_virtual_six = true`**, **`_lek_flatten_region_start_tiers = false`**, **`_lek_global_six_solver = false`**. **`EvaluateCandidatePlot`** map-center / salt **`finalScore`** tweaks are **commented out** in `4a`; virtual-six helpers remain for dev re-enable.

---

## Ring shape — Option B (reserve only)

**Option B** (e.g. minimise radial spread of the six **`d(p)`** subject to **`d₂≤15`**, inland salt, … while staying inside **§1** band **9–18**) stays a **pressure valve** if tuple search is too slow — **not** v0.4 default.

---

## River / forest wording

- **River need:** satisfiable via **`plot:IsRiverSide() or plot:IsFreshWater()`** on the **assigned** start for that civ/region (match **`FindStart`** / classification where possible).
- **“Forest” in XML bias:** for **v0.3** there is **no extra OK clause** beyond **region priority/avoid** (forest is a **region class**, not a separate ring count). **Optional** later: hard predicate on capital / ring forest count — only if you add it explicitly.

---

## `BalanceAndAssign` handoff

The six **`startingPlots[r]`** must be compatible with **`BalanceAndAssign`**’s coast / river / priority / avoid matching **for some** assignment order consistent with **`player_ID_list`**. If impossible, change **`BalanceAndAssign`** (larger project) — not a silent mismatch.

---

## Global `OK` checklist (v0.5)

1. **Map centre distance:** **`9 ≤ d(p) ≤ 18`** for each start (**same** as **`d > 8` and `d < 19`** in integer **`PlotDistance`**). Among passing tuples: **primary** tie-break **`min maxᵢ \|d(pᵢ) − 13\|`**; **secondary** **`min Σᵢ \|d(pᵢ) − 13\|`** (see resolved table).  
2. **`d₂ ≤ 15`** for each start (second-nearest of five others).  
3. **Inland salt:** non-coastal starts: **≤ 4** salt-ocean hexes within **d ≤ 3**.  
4. **Two coastals:** on rotated geographic cycle, **no adjacent `C`/`C`**.  
5. **Bias:** planned **civ↔region** satisfies XML coast / river / region priority / avoid together with **actual** plot flags at those coordinates.  
6. **Site quality:** **`EvaluateCandidatePlot`** → **`meets_minimums == true`** per **`r`**, after simulating **six** **`PlaceImpactAndRipples`** in order **1→6**.

---

## Search + regen + fallback

- **100** failed **complete** 6-tuples **per map layout**.  
- **4** map layouts total (**1** initial **+** **3** regens) ⇒ **400** failed tuples max before **fallback**.  
- **First implementation target** for the above counts; **tune after metrics** (regen rate, wall-clock), not preemptively.  
- **Fallback:** **`ChooseLocations`** as today (**including** interim virtual-six block **until** removed/disabled per Lane A).  
- Log **failure kind** each time (ring, **d₂**, salt, 2-coastal, bias, **`meets_minimums`**, ripples, …).

---

## Map script hook (where the solver runs — options)

**Meaning:** Civ runs **`AssignStartingPlots`** → **`ChooseLocations`** fills **`startingPlots[r]`** → **`BalanceAndAssign`** matches players. The **hook** is the **chosen place** that decides “run **global six-tuple `OK()` solver**” vs “legacy **`ChooseLocations`** / virtual-six / **`FindStart`** per region”. A clear hook keeps **`_lek_global_six_solver`** / **`GAMEOPTION_DISABLE_START_BIAS`** behaviour auditable.

| Option | Idea | Pros | Cons |
|--------|------|------|------|
| **A — Thin hook** | **One** branch at **`ChooseLocations`** (or equivalent) **entry** after setup: e.g. `if _lek_global_six_solver and conditions then LekGlobalSixPlace() else vanilla end`. | Easy to **grep**; one place to enforce **disable-bias** short-circuit; obvious fallback path. | Must thread any **pre-`ChooseLocations`** setup the solver needs into that entry. |
| **B — Scattered guards** | Multiple **`if solver`** checks inside **`FindStart`**, virtual six, drafts, etc. | Can reuse small bits of legacy path. | Easy to **miss a branch**; hard to prove **every** route respects flags and **fallback**. |
| **C — Map script only** | Hook lives in **`LekmapPangaeaFractal…lua`** (or one map file): set flags / call a thin override so **other** map types never see the solver. | **Isolates** Pangaea experiments. | **Duplicate** if a second map script wants the same solver; core **`4a`** may still need a **callable entry** API. |

**When implementing:** pick **A** (recommended), **B**, or **C**; add **`file:line`** (or function name) to the **revision log** so the hook stays documented.

---

## Still TBD (on implementation only)

- Record **exact** **`file:line`** for the chosen hook (see above).

---

## Revision log

| Date | Note |
|------|------|
| 2026-03-27 | Split from start-balance; folding + open questions. |
| 2026-03-27 | v0.1–v0.2: pointer table, random ring, **400** tries, full ripples, bias clarity. |
| 2026-03-27 | **v0.3 authoritative:** **R/δ** locked, **inland salt** **d≤3 / max4** canonical, **`GAMEOPTION`**, **Lane A** + comment-not-delete, **`MixedBias` parity**, **forest** = region class only unless extended, interim virtual-six **non-contract**, **`finalScore`** optional tie-break only. |
| 2026-03-27 | **v0.4:** **§1** centre band **`9 ≤ d ≤ 18`** (**`>8`/`<19`**); **ideal `d = 13`** for tie-break; dropped **{12,13,14}**; merged old **`dCenter ≤ 18`** into this band. |
| 2026-03-27 | **v0.5:** **Variation A** locked for **`BalanceAndAssign`**; tie-break **`min maxᵢ\|d−13\|`** then **`min Σ\|d−13\|`**; search/regen = **first-version target**; **map hook** options table; **`file:line` TBD** on implement. |
