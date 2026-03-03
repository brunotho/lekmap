# Pangaea Embrace – Generation Sequence (from spec)

## 1. Location / placement
- Pick north or south map edge
- Scan inward to find pangea extent (west/east columns, maxDistFromEdge)
- Validate: span ≥ 15, minimum gap 20% between arms
- Anchors: westAnchor = extent.west, eastAnchor = extent.east

## 2. Arm geometry (early)
- Arm width: 1–8 tiles, **varies gradually along length**
- Generally thickens toward map edge (not always)
- Arms curve: west arm curves eastward, east arm curves westward
- Arms must touch map edge

## 3. Phase 1: Paint arm land
- Build west arm from westAnchor toward edge
- Build east arm from eastAnchor toward edge
- Width varies per row (thinner at pangea, thicker at edge)

## 4. Mountain ridges
- Heavy mountain presence along arms
- Irregular ridge, flexible position (left/right/center of arm)
- Splintered: gaps every 3–5 tiles, 40% chance per gap

## 5. Ocean gaps
- Minimum 1 gap always
- Full cut through arm with water
- Position: 2–3 tiles off map edge
- Width: 1–4 tiles each

## 6. Terrain (hills/flat)
- Adjacent to mountains: 80% hills
- 2nd tile from mountains: 65%
- 3rd+ tile: 50%
- Coastal edges: flat 90%
