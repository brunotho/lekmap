# Unified spec: placement pipeline, coastal quota, §5 bias modes, experiments

**Role:** one straight plan humans and agents read first. Deep detail stays in linked scratchpads; this file is the **single narrative + ordered backlog**.

**Read next (depth):** [hard coastal + `N_coastal`](./SCRATCHPAD-hard-coastal-quota-architecture.md) · [tuple roadmap + perf](./SCRATCHPAD-tuple-roadmap-bias-and-performance.md) · [try order + logs + islands](./SCRATCHPAD-master-plan-try-order.md) · [placement glossary](./SCRATCHPAD-start-placement-architecture.md)

---

## 1. Frozen pipeline order (do not reorder casually)

1. **Regions / terrain** — map script finishes land, islands, whatever `GeneratePlotTypes` needs.  
2. **`GenerateRegions`** — six regions, `regionTypes`, rectangles.  
3. **`ChooseLocations`** — tuple **or** legacy: produces **`startingPlots[1…6]`** (region → plot).  
4. **`BalanceAndAssign`** — assigns **players ↔ same six plots** (order ≠ region index); applies XML coast/river/priority/avoid with **legacy staged greedy + fallbacks + random mop-up**.  
5. **Resources / CS / asserts** — luxurious detail elsewhere.

**Invariant:** tuple runs **before** B&A. Tuple’s **virtual §5** exists so accepted tuples do not obviously contradict what B&A can do, **without** re-running the entire B&A state machine inside the DFS.

---

## 2. Conceptual flow (target mental model)

This matches the “straight story” we want code and logs to converge on:

| Step | Meaning |
|------|--------|
| **(1) Map instance** | One layout + outer retries produce a concrete grid and six region pools. |
| **(2) Bias frame** | From **`BuildPlayerBiasPlist`**: **`N_coastal`**, river/prim/avoid/pri1/flex tags. **Hard:** coastal count + coastal predicate for those tags. **Soft:** non-coastal tags may move to **legacy-like** matching when the layout cannot satisfy strict injective needs. |
| **(3) Feasibility / mode** | Cheap checks: e.g. enough **coastal-capable** pool capacity for **`N_coastal`**; optional **strict** non-coastal bipartite probe. If strict non-coastal is hopeless **early**, switch **`biasMode=legacySoft`** for non-coastal only (coastal stays hard). |
| **(4) Tuple search** | Phase ladder drives **§1/§2 numbers** (annulus, second-nearest, first-nearest, optional skip min-pairwise **in OK only** — see escape phases). Within each leaf: **§5** uses the **current** `biasMode` and coastal-hard layer. |
| **(5) B&A** | Real legacy assignment on the accepted plots. |

**Important:** **`mL*_esc`** and per-layout phase tables adjust **geometry gates**, not **`biasMode`** by themselves. Until P1 lands, §5 strictness is mostly **global flags** (`_lek_global_six_s5_*`), which is why Medium/Slow and “late phase” stories drift.

---

## 3. Constraint tiers (single table)

| Tier | Scope | Policy |
|------|--------|--------|
| **H** | Coastal | **`N_coastal`** from plist + coastal predicate (salt/lake per options). **Never** softened for “tuple convenience”. Impossible → next layout / fatal / regen — **prefer failure over silent drop** (see coastal spec). |
| **S** | Non-coastal biases | **Early** phases / `biasMode=strict`: river, prim, avoid, pri1 injective-style matching aligned with current `pred` + `NoCoastInland` interactions. |
| **L** | Non-coastal biases | **`biasMode=legacySoft`**: mirror **outcomes** legacy B&A tends to allow (miss river → random region; avoid miss; `FindFallback`-class prim), **not** a line-by-line copy of B&A’s RNG loops. |
| **G** | Geometry | **§1 / §2 / first-nearest / opt6-related** — relaxed only via **phase table** and map script; **independent** of coastal tier **H**. |

---

## 4. Legacy softening (why “mirror legacy” ≠ “copy B&A”)

Legacy **`BalanceAndAssign`** softens by **stages + capacity + fallbacks + shuffle remainder**, not one global injective check. Coastal civs can land on river/near-river or leftover random if coast slots run short; avoid/priority can fail their stage and still get plots later.

**Implication:** tuple **virtual §5** should use **shared predicates** on plots where possible (“would this plot count as coastal/river/… for this tag?”), but **legacy-soft mode** is a **deliberate relaxation of non-coastal predicates / matching**, not a second full B&A. Coastal **H** stays stricter than legacy unless you explicitly choose product-wise to allow inland coastal-tagged civs (current coastal spec says **no**).

---

## 5. Code state vs target (honest delta)

| Area | Target (this spec + coastal doc) | Code today (watchlist) |
|------|-----------------------------------|-------------------------|
| Coastal Medium vs Slow | Same **H** coastal philosophy | `LekmapPangaeaFractalv5.3.lua` sets **`_lek_global_six_s5_coastal_hard = false`** for pace 2 — **conflicts** hard quota story |
| §5 non-coastal | **S** early → **L** when hopeless | **River** effectively always hard in §5; avoid/prim toggled globally, **not** per-phase `biasMode` |
| Feasibility gate | Coastal **A** + soft **B** (coastal spec §4.2) | Same `pred` family as §5; coastal-soft Medium **undermines** dedicated coastal matching |
| Escape phases | Prove / loosen **G** only | **`mL123_esc` / `mL4_esc` / `mL5_esc`**: **G** only |
| Virtual §5 vs full B&A | Predicate-level handoff | Good enough for “no obvious lie”; not byte-identical to B&A RNG order |
| Best-so-far / appeasability log | Layout-level **strict vs soft** decision + optional “best partial” metric | Partial: `_lek_global_six_tuple_skip_s2_relax_when_s5_heavy_failcombo` routes phases; **no** `biasMode=` token yet |

---

## 6. Single ordered implementation backlog

Merge of coastal spec **§6 rework path** + tuple roadmap **P0–P4**:

1. **P0 — Coastal quota in code** — Implement coastal **H** layer explicitly: **`N_coastal`** helper, feasibility **Phase A** (coastal only), §5 **`pred`** never treats coastal tags as flex on Medium; **remove or repurpose** `_lek_global_six_s5_coastal_hard` per [coastal spec §6](./SCRATCHPAD-hard-coastal-quota-architecture.md).
2. **P1 — `biasMode` on non-coastal** — Per layout or per phase: **`strict` → `legacySoft`** for tier **L** tags only; log **`biasMode=`** on tuple phase begin (and optionally on `g6`). Hook: appeasability probe early or after first phase’s fail-combo stats.
3. **P1′ — River / prim soft in `legacySoft`** — Extend §5 + gate so river (and prim if desired) can match **L** tier when mode flips; keep **H** unchanged.
4. **P2 — Fail-fast order** — In `legacySoft`, prefer cheap **G** checks first if logs show s2-dominated failure; keep **strict** path as today when `biasMode=strict`.
5. **P3 — Legacy parity note** — Short table: for each tag, what legacy can produce vs what `legacySoft` guarantees (intentional deltas called out).
6. **P4 — Perf** — Snapshot/undo, pool cache (tuple roadmap); only after **H/S/L** behavior stable.
7. **§4 audit** — `LekGlobalSix_OK_Section4` vs variable **`N_coastal`** (coastal spec §4.4).
8. **Instrumentation** — Optional **best-partial** score per layout/phase (geometry + bias) for tuning; not blocking P0–P1.

---

## 7. Evaluation / logs (what “done” looks like in output)

- **`g6|…`** — still the compact tuple outcome ([master plan](./SCRATCHPAD-master-plan-try-order.md#compressed-log-format-g6)).  
- **`biasMode=strict|legacySoft`** — once P1 exists, required on phase lines (verbosity ≥2) and optionally appended to compact line.  
- **`### islS`** / **`### LekPangaeaMapFail`** — islands / outer loop health ([master plan](./SCRATCHPAD-master-plan-try-order.md)).  
- **Success:** Medium and Slow differ only in **layouts**, **phase tables**, **budgets** — **not** coastal **H**. **`ws5`** should **drop** after P1 when failures were “strict non-coastal impossible”; **`N_coastal`** impossibilities should **fail fast** at gate, not masquerade as generic s5.

---

## 8. Revision log

| Date | Note |
|------|------|
| 2026-04-05 | Initial unified spec: pipeline, conceptual (1)–(4), tiers H/S/L/G, legacy clarification, code delta table, single P0–P4 backlog, log criteria. |
