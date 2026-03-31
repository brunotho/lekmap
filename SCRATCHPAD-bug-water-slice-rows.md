# Bug scratchpad: horizontal water “slice” through land (3 rows + noise)

## Symptom

- A **horizontal band** of **ocean/water** cuts through **land** (Pangaea-style mass).
- Band is about **three Y rows** wide, **not** a clean full-row trench: **some land tiles remain** inside the band (“noise”).
- **Fjord generator off** for repro attempts (ruled out as cause for those runs).

## Repeatable detail (one reporter observation)

- Suspect **fixed global rows** **`y = 17, 18, 19`** on the affected map(s)—worth confirming with a screenshot + `Map.GetGridSize()` on the same roll.
- If rows are stable across seeds after normalizing map size, that points at code using **literal indices** or an off-by-one tied to **world height** (e.g. wrap, shift margin, choke check window).

## Already tried (repo)

- **`LekmapPangaeaFractalv5.3.lua`**: Pangea **centre `plotTypes` shifts** now use a **scratch buffer + in-bounds sources** (commit `243a2fb`) so OOB shift reads don’t paint spurious ocean. **Slices still reported** after that change—so either another system draws the band, or shift isn’t the only cause.

## Suspects to check next (when repro handy)

1. **Y/X shift** — log **`yshiftamt` / `xshiftamt`** and map **`iW, iH`** on rolls that slice; see if slice Y aligns with **`iH - k`** or **`yshiftamt`** margins.
2. **Pangaea margin clear** loops (`xstart`/`xend`/`ystart`/`yend`) vs **shift** — interaction if bbox wrong.
3. **`2_HBFractalWorld.lua`** rift / drift paths (horizontal drift, `westOfRift` / `eastOfRift` by row).
4. **Post-terrain** passes (islands, coast cleanup) that touch **narrow horizontal** strips.

## What to capture on next occurrence

- Map script + **world size**, **`iW, iH`**, **wrap** flags, relevant **custom options**.
- **Screenshot** with grid / yields on (identify **Y** of band).
- **`plotTypes`** or Lua **print** for a vertical column through the slice (optional dev build).
- Whether a **regen** with same seed/settings reproduces (if the game exposes that).

## Status

- **Open** — rare (~order 1/100 rolls); frequency monitoring only.

---

## Sample B — single full row, clean (no in-band noise), **row 41**

**Contrast with main “3 rows + noise” report:** here the defect is allegedly **one horizontal row** of water (**`y = 41`** on the reporter grid), **without** scattered land tiles inside the band.

**Hypothesis split:**

- **B1:** If truly **one** row, suspect a loop or formula keyed to **`y == 41`** / **`y == f(iH)`** (height-dependent) rather than the **three-row** choke/rift path.
- **B2:** If repro only on one **world size**, compare **`iH`** to **41** (e.g. **`iH - 1 - k`**, margin strip, wrap seam).

**Capture:** same as § **What to capture on next occurrence**, explicitly noting **`iW, iH`**, **`y=41`** land→water transition along **two** **X** columns (east/west margin + mid-map).

---

*Related earlier note: “destructive horizontal strip-ocean fill after Y shift” was **disabled** in Lekmap (comments in `LekmapPangaeaFractalv5.3.lua` ~1352)—keep in mind when diffing legacy behaviour.*
