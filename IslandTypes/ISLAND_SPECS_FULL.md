# Island Types – Full Specs from Chat History

All specs below are extracted from the agent transcript. Scripts are collected in `IslandTypes/` without wiring.

---

## COMMON (common/)

### Dot
- 1–2 tiles. If 2: two adjacent tiles.
- Hills 50–60%, mountains: size≤6 → 2% for 1, 1% for 2; size≥7 → 5% for 1, 2% for 2.

### Pebble
- 3–4 tiles, compact blob, roughly circular.
- Same terrain rules as Dot.

### Strip
- 4–6 tiles, linear chain, 1 tile wide.
- Straight or gentle curve (40% chance to turn 60° every step).
- Same terrain rules.

---

## UNCOMMON (uncommon/)

### Comma
- 5–7 tiles. Body 4–5, tail 1–2 extending from body.
- Tail 1 tile wide, curving slightly.
- Same terrain rules.

### Split
- 6–9 tiles. Body 4–6, branch 2–3 splitting off at 60°.
- Same terrain rules.

### Chunk
- 6–9 tiles, compact, square-ish (ratio 1:1 to 1:1.5).
- Same terrain rules.

### Blob
- 7–10 tiles, organic irregular mass.
- Same terrain rules.

### Wishbone
- 10–14 tiles. Base 2–3 thick, two arms 3–5 tiles each, 1 tile wide.
- Angle between arms 45–90°.
- Base: Hills 70%, 1–2 mountains. Arms: Hills 50%, no mountains.

### Twin Bay
- Two islands 5–8 tiles each, concave bays facing each other.
- One tip extends into bay of the other. Gap 1–2 water tiles.
- Hills 40–50% on outer edges, flat on bay-facing. No mountains.

### Mountain Wall
- Ridge 3–6 tiles, land depth = ridge length ±1.
- Gaps: len 3 none; len 4 50% one gap; len 5–6 → 45% none, 50% one, 5% two (never at ends).
- Ridge: mountains; adjacent 85% hills; 2nd tile 70%; 3rd 50%; 4th 35%; 5th 25%.
- Ridge perpendicular to mainland.

### Splintered Cliffs
- Variant A (60%): 3–5 mountains, 0–1 non-mountainl-land-tiles, tight cluster.
- Variant B (20%): 3–6 mountains, 2–4 non-mountainl-land-tiles
- Variant C (20%): 5–7 mountains, 6–12 non-mountainl-land-tiles
- Adjacent to mountains: 85% hills. mountain independant islands 70% hill

---

## RARE (rare/)

### Crescent
- Spine 7–9, width 2 at center (rarely 3), tapering to 1 at tips.
- 3 templates (spine 7, 8, 9). 70% orient convex toward open ocean.
- Hills 30–40%.

### Stepping Stone
- Coast → 1 water → stepping stone (1–2 tiles) → 1 water → blob 4–8 tiles.
- Optional 20%: on roughly the opposite of the blob relative to the stepping stone: 1 water (rarely 2) → far island 1–3 tiles.
- Closest mainland tile set to mountain. Stepping stone: mountain 40% hill 60%. Blob: 20% mountain on closest tile if stepping stone mountain, else 5% per tile; 50-70% hills.

### Ellipse Archipelago
- 3–5 islands (2–4 tiles each) along ellipse perimeter. Center water.
- Ellipse 6–9 × 4–6 (shrinks on retries). 60% hills, 40% flat, no mountains.

### Fjord Peninsula
- branching of the mainland pangaea - with contact
- 8–12 tiles from mainland. Width 2–4 at base, tapering to 1 at tip.
- Tip always mountain. 2–4 inlets (1–2 wide, 2–4 deep), alternating sides.
- Ridge aligns with mainland mountain/hill if nearby.

### Edge of World
- Triangle at N/S map edge. Base 6–8, tip 0–3, length 8–10.
- 4–6 mountain ridge along centerline. 75% hills next to mountains, 75% flat at coast.

### Arctic Merging Landmass
- see spec inside file

### Shattered Ring
- Central 6–10 tiles, ring 5–8 islands (1–3 tiles each), scattered across 8 sectors.
- Ring radius 6–9. Center: 80% mountain/hill; ring: 50% hills.

### Cluster of Tiny Islands
- Ellipse cluster. 1–4 tile blips, max 7 segments. 30% flat, 65% hills per 1-tile.
- Radius 1–3 (usually 2).

### Isthmus
- Horizontal bridge connecting pangaea. 4–7 tiles wide, full span.
- 30% splice system, 40% side arm, 30% crescent overlay, 60% splinter islands.
- 1 in 5 maps. Max 1 per map.

---

## EXCEPTIONAL (exceptional/)

### Volcanic Peak (Krakatoa)
- Center mountain, 6-tile caldera lake, land ring 3–5 segments with 1–2 tile gaps.
- 12–18 land tiles. 50–60% hills. Hills near caldera, flat on outer edge.

### Jungle Peak (Sri Pada)
- Center mountain, land ring 1–3 thick. 2–3 rings. 20% chance 1 water gap.
- 40–50% hills near center, 50–60% flat on outer. Exports `_jungle_peak_island_tiles`.

### Desert Peak (Sinai)
- Center mountain, diamond-shaped ring 2 tiles thick. 60–70% hills inner, 70–80% flat outer.
- 30% chance 2–3 adjacent islands (1–2 tiles each).

### Broken Heart
- 7 rows × 6 wide. Variant A: 3-tile lake scar. B: rift to ocean. C: full break, two islands.
- 50% hills, 50% flat. 6 rotations.

### Curled Dragon
- S-curve dragon: 8 rows × 6 wide, ~25 tiles.
- 6 mountains + horn on snout. Lake eye → El Dorado tile. 85% hills next to mountains.

### Crescent and Star
- Crescent 13 tiles in C shape. Bay 5 water tiles. Star: 1 mountain in bay.
- 50–60% hills on crescent. 20% tip mountain.

---

## Placement params (from transcript)

| Type | pullBack | effMin | effMax | budget |
|------|----------|--------|--------|--------|
| dot | 1 | 1 | 6 | 0.5 |
| pebble | 1 | 1 | 6 | 0.5 |
| strip | 1 | 1 | 6 | 0.5 |
| comma | 1 | 1 | 6 | 1 |
| split | 1 | 1 | 6 | 1 |
| chunk | 1 | 1 | 6 | 0.75 |
| blob | 1 | 1 | 6 | 1 |
| waterdrop | 2 | 2 | 5 | 0.6 |
| sShape | 4 | 4 | 6 | 1.2 |
| crescent | 2 | 2 | 4 | 1 |
| cluster | 1 | 1 | 4 | 1 |
| ellipse | 4 | 5 | 6 | 2 |
| shattered | 4 | 4 | 6 | 2 |
| volcanic | 3 | 3 | 5 | 1.25 |
| jungle | 2 | 2 | 5 | 1 |
| desert | 2 | 2 | 5 | 1.5 |
| broken | 3 | 3 | 5 | 1.2 |
| curled | 3 | 3 | 5 | 2 |
| crescentStar | 3 | 3 | 5 | 1.2 |
