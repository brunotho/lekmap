# Subspec: tuple-pool diagnostics (child of inner constraint set)

**Parent:** Global-six **tuple candidate pool** = plots in region **`r`** that satisfy **all** of:

- **P0 — membership:** `LekGlobalSix_GatherTupleStyleCandidateIndices` (land/hills, area, coast / two-away / three-away exclusions, optional `NoCoast`).
- **P1 — site hard gate:** `EvaluateCandidatePlot` → **`meetsMin`** with **`regionTypes[r]`**, with **`distanceData[plotIndex]` cleared** for that probe (mask-own-impact for search, not live ripples from earlier tuple depth).
- **P2 — §1 annulus:** map-centre hex distance **`d ∈ [9, 18]`** (same as **`OK` §1**).

**Failure class seen in the wild:** **`meetsMin`** true on >=1 raw plot, **`count(P1 ∧ P2) = 0`** — “good tiles exist in the region but **none** sit in the allowed ring” (e.g. whole fertile pocket **`d ∈ [1, 4]`** under map centre).

This document proposes **diagnostic logs** (5–7 **families**, each implementable as one structured line or a tiny block) to classify **why** region **`r`** ends with an **empty tuple pool**, without changing **`OK`**. **No code in repo for this yet** — collect ~5–7 real rolls and extend children if new buckets appear.

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

**Promote** any recurring bucket to its own **child subspec** (D8…) with sharper fields.

---

## Implementation note (future, not now)

Hook location: **`GatherSearchCandidatesOrdered`** exit when `#out==0`**, and/or **once per region** inside **`LekGlobalSix_RunTupleSearch`** pre-DFS, gated by **probe flag** to avoid spam in release maps.

**Related code pointers:** `4a_HBAssignStartingPlots.lua` — `LekGlobalSix_GatherTupleStyleCandidateIndices`, `LekGlobalSix_GatherSearchCandidatesOrdered`, `LekGlobalSix_CountMaskedMeetsMinOutsideInsideCentreBand`, `LekGlobalSix_LogRippleOrderedSampleDryRun`, `EvaluateCandidatePlot`, constants **`LEK_G6_S1_*`**.
