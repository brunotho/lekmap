# Spec: hard coastal start quota vs soft every-other bias (Medium ≡ Slow architecture)

**Canonical overview + merged backlog:** [SCRATCHPAD-unified-placement-and-bias-spec.md](./SCRATCHPAD-unified-placement-and-bias-spec.md)

Related: [SCRATCHPAD-tuple-roadmap-bias-and-performance.md](./SCRATCHPAD-tuple-roadmap-bias-and-performance.md) (bias-first vs legacy-soft layering, performance, logging). [SCRATCHPAD-master-plan-try-order.md](./SCRATCHPAD-master-plan-try-order.md) (ordered experiments, `g6` log legend, islands vs outer loop).

## Goal (clarity check: yes — this doc is the agreed spec)

We want **one** global-six tuple / §5 architecture for **pace 13 = Medium (2)** and **pace 13 = Very Slow (3)**. The **only** intentional differences between those two paces are:

1. **`regen_max_layouts`** (how many map layouts we try before giving up).
2. **How many relaxation phases** run per layout (tuple phase table length / structure).
3. **How aggressively numeric “demands” relax** across phases: §1 band (`s1_min` / `s1_max`), §2 cap (`s2_max`), `first_nearest_max`, DFS budgets (`max_fail_complete`, `max_leaf_evals`), and any similar numeric gates.

We do **not** want different *bias philosophy* between Medium and Slow (e.g. “coastal is soft on Medium, hard on Slow”) anymore.

---

## 1. Single source of truth for “how many coastal starts”

Treat **`LekGlobalSix_Section5_BuildPlayerBiasPlist`** (`4a_HBAssignStartingPlots.lua`) as authoritative **after** all plist mutations in that function:

- Natural `CivNeedsCoastalStart` (respecting `MixedBias` / `CivNeedsPlaceFirstCoastalStart`).
- `ForceAllInlandPlayerSpawns` / `IgnoreAllStartBias` (coastal → flex).
- **`_lek_tuple_force_two_coastal_majors`** (`BalancedCoastalExactTwo` / Force 2 Coastals): upgrades flex (by tier) until **`coastalCount() == 2`**, with the existing guard when **exactly one** natural mandatory coastal exists.

**Hard quota:**

- Let **`N_coastal =` number of list entries with `tag == "coastal"`** in the final plist returned by `BuildPlayerBiasPlist`.

That number is the **non-relaxing** target for global-six placement: the accepted assignment must place exactly **`N_coastal`** majors on plots that satisfy the **same coastal predicate** used for coastal bias (today: salt vs lake governed by `_lek_global_six_coastal_bias_requires_salt` and `MeasureBiasConditionsAtXY` / `alongOcean` / `nextToLake` as wired in tuple pools).

**Map option 17** already feeds `OnlyCoastal`, `BalancedCoastal`, `BalancedCoastalExactTwo`, `ForceAllInlandPlayerSpawns`; the plist builder encodes the result as tags. **No second parallel definition** of “needed coastals” in the relax ladder — avoid drift from legacy counting vs tuple counting.

---

## 2. Hard vs soft constraints (legacy-like except coastal count)

| Constraint | Strictness |
|------------|------------|
| **Coastal count + coastal predicate** for the **`N_coastal`** plist slots tagged `coastal` | **HARD** — never downgraded in a relax phase; never traded for looser §1/§2. If the map cannot satisfy `N_coastal`, behavior is **regen / next layout / fail** (same family as today for tuple fatals), not “pretend a flex took a coastal slot” or “treat coastal as flex.” |
| **River**, **pri1**, **prim**, **avoid**, **flex** (and ordering / injective extras besides coastal quota) | **SOFT** — may be imperfect across phases, analogous to legacy `BalanceAndAssign` best-effort: predicates or matching can loosen, duplicates or misses allowed after enough relaxation. |
| **Numeric geometry** (§1 annulus, §2 cap, first-nearest cap, etc.) | **PACE-SCHEDULED** — relaxes according to the **phase table**; Medium uses fewer phases / faster escalation than Slow; **coastal quota is not part of this schedule**. |

**Important nuance:** “Hard coastal” means **quota + predicate for tagged players**, not necessarily “every injective dimension including river stays hard.” River and region priority can remain **soft** per product goal (adjust if you later decide river should be hard again — this doc assumes only coastal count is hard).

---

## 3. Why the current `_lek_global_six_s5_coastal_hard = false` (Medium) conflicts

Setting coastal “soft” by treating coastal-tagged players like **flex** for §5 injective / feasibility **breaks the hard quota**: the solver can **assign fewer than `N_coastal`** salt/coastal plots while still passing relaxed injective checks.

**Target fix:** split responsibilities:

1. **Coastal quota layer** — always enforced: at least `N_coastal` regions must be assigned to players whose plist tag is `coastal`, and those assignments must lie in each region’s **coastal-eligible** pool (per salt/lake rules).
2. **Soft bias layer** — river / prim / avoid / pri1 / flex matching can use the existing relaxation and legacy-like slack without overriding (1).

---

## 4. Target architecture (shared by Medium and Slow)

### 4.1 Plist

- Unchanged entry point: **`BuildPlayerBiasPlist`** remains the single definition of tags and **`N_coastal`**.

### 4.2 Feasibility gate (`LekGlobalSix_TupleBiasFeasibilityFromPools`)

- **Necessary condition:** count of regions with `canCoastal` (under current salt rule) **≥ `N_coastal`**.
- **Matching:** injective (or max-flow style) requirement for **non-coastal tags** may be phased / softened per global settings; **coastal slots** remain **dedicated**: `N_coastal` distinct regions must map to `N_coastal` coastal-tagged players via coastal-eligible plots.

Implementation sketch (conceptual):

- **Phase A (hard):** bipartite check — coastal-tagged players ↔ coastal-capable regions (each region capacity 1). If Hall/defect fails → skip or fail phase early (same as today’s “impossible” skip).
- **Phase B (soft):** existing feasibility for river / prim / … with relaxation hooks; may omit or weaken injective as phases progress.

### 4.3 §5 acceptance / DFS (`LekGlobalSix_OK_Section5_BalanceAndAssignFeasible` and tuple DFS)

- **Accept** a candidate tuple only if **exactly** the assignments for plist entries with **`tag == "coastal"`** satisfy the coastal predicate on the chosen plot.
- **Do not** re-tag coastal as flex in Medium for injective convenience.
- Ordering heuristics (coastal-first DFS, ring-first, etc.) stay as today; pace only changes budgets and numeric caps from the phase table.

### 4.4 §4 and other gates

- **§4 two-coastal geometry** (if still applies) must remain **consistent** with **`N_coastal`** and map options: if `N_coastal > 2`, §4’s “two coastal” naming may be legacy — confirm whether §4 is “at least two on the cycle” or exactly two; document any interaction so §4 does not contradict `N_coastal` from plist.

(Add a short follow-up audit item: read `LekGlobalSix_OK_Section4_TwoCoastalGeoCycle` vs Force 2 vs **OnlyCoastal**.)

---

## 5. Pace 13 = Medium vs Very Slow — **only** these differ

| Knob | Medium (2) | Very Slow (3) |
|------|------------|----------------|
| `_lek_global_six_regen_max_layouts` | lower (e.g. 5) | higher |
| Tuple phase table | fewer rows per layout band | more rows |
| Numeric relaxation per phase | reaches looser caps sooner | more gradual steps |
| `max_fail_complete` / `max_leaf_evals` | smaller per phase (tighter budget) | larger |
| **`N_coastal` enforcement** | **same as Slow** | **same as Medium** |

Remove any pace branch that sets `_lek_global_six_s5_coastal_hard = false` **unless** it is replaced by the split hard-quota / soft-rest logic above (ideally delete that flag entirely in favor of explicit quota checks).

Pace **1 (Fast)** may keep **legacy-only** path (`_lek_global_six_skip_tuple_use_legacy`); out of scope except ensuring legacy also respects the same `N_coastal` semantics where applicable.

---

## 6. Rework path (ordered)

1. **Document `N_coastal` helper** — one function or inline: `countCoastalTags(pl)` after `BuildPlayerBiasPlist`; use in logs (`### LekGlobalSix … nCoastalRequired=…`).
2. **Refactor feasibility** — coastal **capacity ≥ N_coastal** + coastal matching never skipped; decouple “soft injective” from coastal tags.
3. **Refactor §5 `pred` / DFS** — coastal-tagged players always use coastal predicate on assigned plot; flex/others follow relaxed rules.
4. **Delete or repurpose `_lek_global_six_s5_coastal_hard`** — Medium should not globally soft-coast; if a flag remains, it should mean something other than “ignore coastal tag” (or be removed).
5. **Align `LekmapPangaeaFractalv5.3.lua`** — remove `paceSel == 2` coastal-soft assignment; keep only layout count + phase tables + numeric budgets differing from Slow.
6. **Regression checks** — scenarios: Force 2 with 0 natural coastal bias; OnlyCoastal + mixed civs; all inland; salt-only vs lake; tuple skip vs pass; ensure fatals still surface when `N_coastal` truly impossible.
7. **§4 audit** — ensure cycle coastal constraint still makes sense for `N_coastal ∈ {0,1,2,3,…}`.

---

## 7. Open questions (resolve during implementation)

- **OnlyCoastal (option 17 == 1):** does plist force **all six** to `coastal`, or only **bias** coastal civs? Current builder only tags `CivNeedsCoastalStart`; confirm `NoCoastInland` / placement hooks enforce “everyone coastal” if that is the design.
- **CoastLux **and** coastal predicate:** confirm menus don’t introduce a second “coastal” definition for lux vs start.
- **Legacy `BalanceAndAssign`** when tuple is off: ensure **same `N_coastal`** interpretation so Fast/Slow behavior doesn’t diverge on counting.

---

## 8. Success criteria

- Medium and Slow **both** fail regen / layout when **`N_coastal` cannot** be satisfied; **both** accept layouts where only non-coastal biases are imperfect.
- No behavioral branch “Medium ignores coastal quota in §5 but Slow doesn’t.”
- Diff between Medium and Slow is **measurable** only in **layouts tried**, **phases**, and **numeric relaxation / budgets**, not in coastal strictness.
