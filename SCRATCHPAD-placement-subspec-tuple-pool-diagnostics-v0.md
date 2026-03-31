# Subspec: tuple-pool diagnostics (child of inner constraint set)

**Parent:** Global-six **tuple candidate pool** = plots in region **`r`** that satisfy **all** of:

- **P0 — membership:** `LekGlobalSix_GatherTupleStyleCandidateIndices` (land/hills, area, coast / two-away / three-away exclusions, optional `NoCoast`).
- **P1 — site hard gate:** `EvaluateCandidatePlot` → **`meetsMin`** with **`regionTypes[r]`**, with **`distanceData[plotIndex]` cleared** for that probe (mask-own-impact for search, not live ripples from earlier tuple depth).
- **P2 — §1 annulus:** map-centre hex distance **`d ∈ [LEK_G6_S1_D_MIN, LEK_G6_S1_D_MAX]`** (same as **`OK` §1**; values may be tuned in `4a_HBAssignStartingPlots.lua`).

**Failure class seen in the wild:** **`meetsMin`** true on >=1 raw plot, **`count(P1 ∧ P2) = 0`** — “good tiles exist in the region but **none** sit in the allowed ring” (e.g. whole fertile pocket **`d ∈ [1, 4]`** under map centre).

**Implementation status:** **`tupleProbeLayer`**, **`tuplePoolDiag`**, **`tupleHeadCells` / `tupleHeadPairwise` / `tupleHeadSecondNearest`**, **`tupleSearch` `failHist`**, etc. live in **`4a_HBAssignStartingPlots.lua`**, gated by **`start_plot_database._lek_tuple_pool_diag`** (default on in Lekmap when set). Proposed-only rows below (D2–D4 sampling, D8b–d detail) may still be future work.

**Convention:** one line prefix e.g. `### LekGlobalSix tuplePoolDiag runId=… region=r…` so grepping is easy.

---

## Child D1 — Band vs meetsMin counts (baseline, already partially present)

**Intent:** Same as today’s **`no_candidates`** line, but **normative** for this subspec so D2–D7 attach to it.

**Fields (minimum):** `allRawCount`, `meetsMinCount` (with cleared `distanceData`), `inS1band_meetsMin`, `dCenter_min`, `dCenter_max` among **meetsMin-only** plots (not necessarily in band).

**Distinguishes:** “no land in region” vs “nothing meetsMin” vs “**annulus miss**” (your r=5 case).

---

## Child D2 — Histogram of `d(mapCentre)` for meetsMin plots

**Intent:** See **where** the fertile pocket sits relative to §1.

**Proposed output (compact):** bucket counts for **`d`** in ranges **`[0–8]`**, **`[9–18]`**, **`[19–…]`** over plots with **`meetsMin`** (and optionally over **allRaw** for contrast). Alternatively: list **`k` sample `(d, plotIndex)`** pairs: **`k=6`** smallest **`d`**, **`k=6`** largest **`d`** among meetsMin.

**Distinguishes:** cluster **inside hole** of annulus vs straddling vs **only** outer rim past 18.

---

## Child D3 — meetsMin false: top failure buckets (sampled)

**Intent:** When **`meetsMinCount ≪ allRaw`**, know **why** plots fail **`EvaluateCandidatePlot`** before geometry.

**Proposed output:** For a **sample** of N plots (e.g. first 40 by scan order, or stratified by **`d`**) — or **aggregate only**: counts by **reason** if the engine exposes a single **`goodSoFar` / ring / junk / early-out** path. If not cheap, **bin** into: **`early_excluded`** (polar, fjord, snow, edge&lt;8), **`ring_minimums`**, **`distance_bias>0`** (ripple / reserve — **important:** for tuple search this should be measured **both** with cleared `distanceData` **and** optionally **live** snapshot to catch “pool built with cleared but reality has reserves”).

**Distinguishes:** region “bad soil” vs **rippleAlreadyOccupied** vs snow/edge dominance.

---

## Child D4 — Region rectangle vs map centre (geometry meta)

**Intent:** Correlate **D2** with **where the region box sits**.

**Proposed output:** Region **`r`**: rect **`west,south,w,h`**, **centroid** **`(cx_r, cy_r)`** (tile or continuous), **min / max / mean `d(regionTile, mapCentre)`** over **all land tiles in rect** (cheap approximation), and **overlap fraction** of rect area with annulus (**% plots with `d∈[9,18]`** among land in rect, ignoring meetsMin).

**Distinguishes:** “rectangle never intersects annulus” vs “intersects but **meetsMin** only on wrong side” vs “**thin** intersection → one civ eats it in DFS order”.

---

## Child D5 — Ripple dry-run alignment (which depth fails)

**Intent:** Explain **`in_order_pick_failed no_eligible_plot_r=k`** relative to tuple **`no_candidates`**.

**Proposed output:** After **simulated** places for **`1…k-1`**, for region **`k`**: count **eligible** = meetsMin ∧ (bias==0 or policy) ∧ inBand optional — i.e. mirror **exact** ripple dry-run elig rule in numbers; plus **first reason** if count=0 (**all filtered by bias** vs **meetsMin**).

**Distinguishes:** **global crowding simulation** eating the annulus vs pure **per-region** annulus miss (same as D1 but **dynamic**).

---

## Child D6 — Candidate ordering stress (cap truncation)

**Intent:** **`GatherSearchCandidatesOrdered`** sorts by **`|d-13|`** then score then **`plotIndex`**, then **caps** top **K** (e.g. 36). Rarely, **useful** combos might need rank >K per region.

**Proposed output:** For failing tuple: log **`#cands_before_cap`**, **`cap`**, and whether **any** in-band meetsMin exists **beyond** cap (scan without sort: true/false). If true, failure mode = **ordering/cap**, not geometry.

**Distinguishes:** true **empty** intersection vs **solver visibility** artifact.

---

## Child D7 — Cross-region annulus capacity (quick feasibility)

**Intent:** One roll-level line: among **`r=1…6`**, how many have **`inS1band_meetsMin ≥ 1`**; min/max of that count per roll. Optional: **sum** of max independent picks (not implementing matching — just **inventory**).

**Distinguishes:** **single** weak region vs **most** regions starved (map-scale annulus too thin for six **good** sites).

---

## Roll campaign (operator note)

For ~**5–7** starts, paste **`tuplePoolDiag`** lines (or full `### LekGlobalSix` block). Tag each roll with:

1. **Primary bucket** from D1/D2 (e.g. **annulus_miss_inner**, **annulus_miss_outer**, **meetsMin_rare**, **cap_truncation**, **bias_dominated**).
2. Whether **regen** would likely help (**geometry** changes) vs **unlikely** (same landmass layout family).

**Promote** any recurring bucket to its own **child subspec** (D9…) with sharper fields.

---

## Child D8 — Ripple / reserve / **bias** footprint vs tuple probe

**Intent:** See whether **non-zero `distanceData`** (and sibling impact layers) **before** or **during** tuple search add “false tension”: candidates look good with **`distanceData` cleared** (solver probe) but **`EvaluateCandidatePlot` / §6** with **true** ripples would fail, or **`no_eligible_plot_r=k`** fires because **dry-run** treats bias strictly.

**Parent link (conceptual):** **`OK` §6** runs after full **`PlaceImpactAndRipples`** in order 1→6. **`§5`** checks civ↔region feasibility from **actual** start plots (`MeasureBiasConditionsNoNormalize`). **ChooseLocations** may **reserve** regions / pre-seed **Solomons / geothermal** ripples. If we “pre-satisfy” XML in the **legacy** branch but the **tuple** path builds pools with **cleared** `distanceData`, we need visibility into whether **reserves** or **planned coastal counts** shrink the **effective** annulus∧meetsMin intersection.

**Proposed output (one roll, a few lines — all gated by probe flag):**

| Line | Content |
|------|--------|
| **D8a `biasLayerSnapshot_preChooseLocations`** | Grid: **`count(distanceData[i]>0)`**, **`max(distanceData)`**, same for **`playerCollisionData`** / **`cityStateData`** if non-trivial; list **reserved feature plot indices** (Solomons, geothermal, polar merge, fjord exclude — whatever exists on this script). |
| **D8b `civNeedsSummary`** | From the same **`ChooseLocations`** pre-pass as legacy: **`iNumCoastNeeded`**, **`MixedBias` roll outcomes** (if logged), coarse **tag histogram** (coastal / river / pri1 / prim / avoid / flex) from **`L plist` construction** in **`LekGlobalSix_OK_Section5`** — or duplicate that sort/count **once** without full DFS. |
| **D8c `tupleProbeBiasContrast` (optional, sampled)** | For **one** failing region **`r`**: among **top M** tuple-order candidates by **(ringDev, score)**, report **how many** have **`distanceData[plot]==0`** vs **`>0`** at **StartPlotSystem.begin** snapshot (unchanged during tuple). Many **`>0`** ⇒ reserves or pre-ripple **eat** the annulus even before first placed start. |
| **D8d `section5FeasibilityAfterLegacy`** | Already partially covered by **`LekGlobalSix_OK diag`** after fallthrough; for **solver-only** rolls: explicitly log **`s5_ok`** + detail **before** legacy mutates starts (harder — can skip v1). **MVP:** keep relying on existing OK diag post-legacy; D8b is the **pre-placement** bias pressure. |

**Distinguishes:** pure geometry (**D2**) vs **masked-by-ripple** pool shrink vs **§5 infeasible** no matter geometry.

---

## Appendix A — Roll digest (operator-pasted logs, ~6 games)

Rough **taxonomy** from supplied **`###`** blocks (no new code). Map/regen **off**; budgets **1000/8000** where shown.

| runId (approx) | Tuple outcome | Notes |
|----------------|---------------|--------|
| 429002 | **fail** `failComplete=leafEvals=1000`, `last_fail=s2` | Ripple dry-run **complete** then `first_fail=s1`. Full budget burned on **§2** in search; legacy fails **s1/s2/s6**. |
| 504683 | Same pattern **`last_fail=s2`**, budget 1000 | Ripple **`no_eligible_plot_r=6`** (dynamic crowding or meetsMin under dry-run rule at **r=6**). |
| 573210 | **`no_candidates_r=6`**, `leafEvals=0` | **Outer** annulus miss: `meetsMin=7`, **`inS1band=0`**, `dCenterRange=**19–21**` (compare to **inner 1–4** case on another roll). |
| 605268 | Exhaust **s2** | Ripple complete + **§6 pass** on legacy OK diag; still **s1/s2** fail — legacy vs tuple targets differ. |
| 675068 | Exhaust **s2** | Same family as 429002 / 605268. |
| 798096 | Exhaust **s2** | Legacy **d=22** on one start (**§1** rim); **s6** fail on diag. |

**Takeaway for subspec work:** failure modes split into (1) **§2 saturation** with full leaf budget, (2) **`no_candidates`** = **inner-only** or **outer-only** meetsMin vs **§1** band, (3) ripple dry-run **fail at r=6** while tuple still runs (pool non-empty) — **D5/D8** targeted.

---

## Child D9 — List-head geometry vs §2 (**implemented**)

**Intent:** Check whether **§1 list ordering** (prefer **`|d(map centre) − TARGET_D|`**) yields six **first** candidates whose **pairwise** graph distances are even **in the ballpark** of **`LEK_G6_S2_SECOND_NEAREST_MAX`** *before* ripples and deeper DFS.

**Log lines (after `byRegion` built, before DFS):**

| Prefix | Content |
|--------|---------|
| **`### LekGlobalSix tupleHeadCells`** | Per **`r=1..6`**: head tile **`x,y`**, **`plotIndex`**, **`dMapC`** (`dMapCenter`), **`ringDev`**, **`score`**. |
| **`### LekGlobalSix tupleHeadPairwise`** | All **15** pairs **`d_i_j`** for **`1 ≤ i < j ≤ 6`** via **`LekGlobalSix_PlotDistance`** (same measure as §2). |
| **`### LekGlobalSix tupleHeadSecondNearest`** | **`r1..r6`** = second-smallest distance among the other five head points; **`s2_cap`** = current **`LEK_G6_S2_SECOND_NEAREST_MAX`**. |

**Interpretation:** If **every** `tupleHeadSecondNearest` is already **`> s2_cap`**, the six “best ring” heads are **incoherent** with §2 — search order / annulus / cap may be wrong before spending **`max_fail_complete`** leaves.

---

## Appendix B — Tuning inventory & search behaviour (do not lose)

Single checklist of **everything** we have named while iterating on global-six. Not all need changing at once.

### B.1 Spec / geometry coherence **(1)**

| Item | Notes |
|------|--------|
| **`LEK_G6_S1_D_MIN` / `D_MAX` / `TARGET_D`** | Annulus + sort key **`ringDev = \|d − TARGET_D\|`**; widening **`D_MAX`** admits more plots; does not fix pairwise spacing. |
| **`LEK_G6_S2_SECOND_NEAREST_MAX`** | Per civ: sort the **five** rival distances, take **2nd smallest**; must be **≤** cap. **Map-centre ring** does **not** imply this — validate on **`tupleHeadPairwise`**. |
| **§3–§6** | Salt, coastal cycle, bias (`§5`), **`EvaluateCandidatePlot`** post-ripple (`§6`); **`failHist`** can show **`s5`** / **`s6`**. |

### B.2 Search algorithm **(2)**

| Item | Notes |
|------|--------|
| **DFS order** | **`depth` = region index **1→6**; **region 6’s** list index changes **fastest** in an **unbounded** full DFS. |
| **Global `failComplete` / `leafEvals`** | At **each** `dfs` entry: if **`bestPack` nil** and **`failComplete ≥ maxFail`** (or leaf cap), **return immediately**. The first region‑1 list head can **burn the entire** failure budget while varying **`r2..r6`**; later region‑1 candidates may get **zero** further leaf evaluations after the cap trips. |
| **`perRegionCap`** (`_lek_global_six_max_candidates_per_region`, default **36**) | Truncates tail of each region’s sorted list → **never** tried. |
| **Candidate sort** | **`ringDev`** then **`score`** then **`plotIndex`** inside §1 band. |
| **`PlaceImpactAndRipples`** during DFS | Changes effective spacing / §3 / §6 vs **cleared-`distanceData`** pool probe. |

### B.3 Alternative search directions **(2.1–2.3)**

| Id | Idea |
|----|------|
| **2.1** | Random / shuffled tuples over a **small** capped set (e.g. **7^6**) — uniform coverage; avoids **r1** order lock-in but loses structured ring sort. |
| **2.2** | **Coastal-first** or **ascending `searchOrderedN`** (thin pool regions first) when assigning **DFS variable order** or **partial** passes. |
| **2.3** | Look-ahead / geometric projection from one fixed region — **heaviest**; defer until **2.1/2.2** data. |

### B.4 Other threads

| Item | Notes |
|------|--------|
| **`no_candidates`** | **`meetsMin ∧ §1` empty** for some **`r`** — **search reorder irrelevant**; fix band / region land / **`meetsMin`**. |
| **Ripple dry-run vs tuple** | Same seed: **`no_eligible_plot_r=k`** vs non-empty **`searchOrderedN`** — **different** rules/path; debug alignment separately. |
| **Budgets** | **`_lek_global_six_max_fail_complete`**, **`_lek_global_six_max_leaf_evals`** in **`LekmapPangaeaFractalv5.3.lua`**; **`leafEvals`** must stay **≥** useful leaf count or cap stops search first. |
| **Regen** | **`_lek_global_six_regen_max_layouts`**, **`tuple_solver_no_accepted_tuple`**. |

### B.5 Recommended sequencing

1. **Relaxed constants + D9 head logs** on test rolls → see if bottleneck is **tight §2/§1** vs **search**.  
2. If heads look **§2-viable** but solver still fails → **`perRegionCap`**, **DFS order**, **global-cap semantics**, **2.1/2.2**.  
3. If heads are **already §2-dead** → **spec / annulus / TARGET_D** before deep search work.

---

## Implementation note (future, not now)

Hook location: **`GatherSearchCandidatesOrdered`** exit when `#out==0`**, and/or **once per region** inside **`LekGlobalSix_RunTupleSearch`** pre-DFS, gated by **probe flag** to avoid spam in release maps.

**Related code pointers:** `4a_HBAssignStartingPlots.lua` — `LekGlobalSix_GatherTupleStyleCandidateIndices`, `LekGlobalSix_GatherSearchCandidatesOrdered`, `LekGlobalSix_CountMaskedMeetsMinOutsideInsideCentreBand`, `LekGlobalSix_LogRippleOrderedSampleDryRun`, `EvaluateCandidatePlot`, constants **`LEK_G6_S1_*`**.
