# Tuple solver roadmap: bias layering, coastal quota, geometry, performance

**Unified narrative:** [`SCRATCHPAD-unified-placement-and-bias-spec.md`](./SCRATCHPAD-unified-placement-and-bias-spec.md)

Companion docs: [`SCRATCHPAD-hard-coastal-quota-architecture.md`](./SCRATCHPAD-hard-coastal-quota-architecture.md) (hard `N_coastal` + soft other biases), [`SCRATCHPAD-start-placement-architecture.md`](./SCRATCHPAD-start-placement-architecture.md) (pipeline glossary).

---

## Product intent (from design chat)

1. **Biases first (best effort):** Across the six regions on this layout, **search for assignments that satisfy civ start biases** where the map allows — including multiple feasible bias matchings when geometry still branches.
2. **Then mirror legacy slack:** If biases **cannot** all be satisfied (injective matching / pools), **adopt the same relaxed expectations as legacy `BalanceAndAssign`** for non-critical tags — not silent cheating on counts that legacy itself would enforce.
3. **Geometry on top of that:** Run **numeric relaxation** (centre band, second-nearest cap, min pairwise, etc.) **in the phase ladder**, knowing whether we are in “strict bias” vs “legacy-like soft bias” mode for a given phase.

Hard coastal quota work in the other scratchpad is the **mechanism** for “which biases stay hard”; this doc is **order of reasoning** and **engineering backlog**.

---

## Constraint tiers (target model)

| Tier | Meaning | Examples |
|------|---------|----------|
| **H — hard** | If impossible → regen layout or fatal (same family as today). | `N_coastal` from plist + coastal predicate (per coastal-quota spec). |
| **S — strict attempt** | Must hold in **early** tuple phases; may drop to L in later phases or after bias slack mode engages. | River, prim, avoid, pri1 injective matching **while** we claim “bias-first”. |
| **L — legacy-like** | Match legacy: best-effort, swaps, some tags soften. | Avoid/prim soft flags; partial misses allowed. |

**Phase coupling:** Early phases = **H + S** geometry and **S** bias matching. Later phases or a dedicated flag = **H** geometry (coastal count) unchanged, **L** bias matching for non-coastal tags, geometry numeric caps relaxed per pace table.

---

## Implementation phases (recommended order)

### P0 — Align coastal quota doc with code

Follow **section 6 rework path** in `SCRATCHPAD-hard-coastal-quota-architecture.md`: single `N_coastal` helper, feasibility + §5 predicate split, remove or redefine `_lek_global_six_s5_coastal_hard` so Medium/Slow do not diverge on coastal philosophy.

### P1 — Explicit “bias slack mode” for the tuple solver

- **Detect** after full bias-feasibility / early DFS stats: e.g. injective failure dominated by river/prim/avoid, not coastal quota.
- **Switch** §5 check inside `LekGlobalSix_OK_RunAll` (or a wrapper) to use **legacy-soft predicates** for tags in tier L while keeping **H** checks unchanged.
- **Log** once per phase: `biasMode=strict|legacySoft` so logs stay interpretable.

### P2 — Order of evaluation (fail fast on soft bias)

When in **strict** mode: optional **cheap** bipartite pre-check per leaf (or every N fails) before expensive §6. When in **legacySoft**: run **geometry-first** partial checks first if measurements show most leaves die on S2/S1.

*(Intertwined multi-solution:* if multiple bias matchings exist, DFS already branches; consider **canonicalizing** by tie-break on `LekGlobalSix_TiebreakMaxCentrDeviation` only **after** a bias-feasible partial assignment — future refinement.)*

### P3 — Legacy parity audit

When tuple accepts with `biasMode=legacySoft`, document the same guarantees legacy would give for river/prim/avoid (and where intentional differences remain).

### P4 — Performance (see below)

Do **after** correctness of H/S/L is clear; otherwise faster search amplifies wrong tuples.

---

## Performance backlog (from architecture review)

High impact:

1. **DFS state:** Replace per-node **full 11-layer grid snapshot** with **incremental undo** for tuple search, or copy only layers `PlaceImpactAndRipples` mutates for this path.
2. **Pool build:** Cache per layout: tuple-style plot list + one `EvaluateCandidatePlot` pass; **filter by S1 band per phase** without re-evaluating every plot.
3. **Regen cost:** Improving early-layout success rate reduces **full map regens** (often dominant wall time).

Medium:

4. Tighter **Medium** phase budgets if pools stay large; optional **rank-1 S2** precheck (already present, guard false negatives).
5. Ship **`_lek_global_six_ripple_dry_run = false`**, **`_lek_tuple_pool_diag = false`** for normal play.

Logging:

6. **`_lek_mapgen_log_verbosity`**: `1` = one-line chooseStarts result; `2` = begin + extended tuple summary; `3` = phase/DFS/diag (see comment atop `4a_HBAssignStartingPlots.lua`).

---

## Open decisions

- **When** to flip `strict → legacySoft`: only between **relaxation phases**, or also **within** a phase after N successive S5-dominant failures?
- **§4 two-coastal geometry** vs variable `N_coastal`: audit `LekGlobalSix_OK_Section4_TwoCoastalGeoCycle` vs option 17 / plist (noted in coastal-quota doc).
- **OnlyCoastal:** confirm plist vs `NoCoastInland` for “everyone coastal”.

---

## Revision log

| Date | Note |
|------|------|
| 2026-04-05 | Initial roadmap: bias-first + legacy mirror + geometry; links coastal-quota spec; perf + log verbosity notes. |
| 2026-04-05 | Medium layout 5: tail phase **`mL5_esc`** (loose S1/S2, `first_nearest_max=nil`, `skip_min_pairwise` for tuple §2 only). **Also `mL123_esc` / `mL4_esc`** so layouts 1–4 are not stuck on **`first_nearest_max=13`** (`g6` **`zF…`**). **`_lek_global_six_compact_log=false`** restores long `chooseStarts` line. |
