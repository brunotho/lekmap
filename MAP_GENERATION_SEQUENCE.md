# Map Generation: New Map → Ready to Play

## High-level flow

The game calls `GenerateMap()` (defined in 4_HBMapGenerator, overridden by Lekmap where needed). That function runs these steps in order:

---

## Step-by-step sequence

### 1. GeneratePlotTypes (Lekmap overrides; uses 2, 3, 4)

**Goal:** Decide which hexes are land vs water, and land elevation (flat, hills, mountain).

| Who | Responsibility |
|-----|-----------------|
| **2_HBFractalWorld** + MultilayeredFractal | Build mainland shape with fractal noise. Fill `plotTypes` with ocean, then paint landmass. |
| **3_PangaeaIslands** | Add islands (polarmerge, dots, pebbles, etc.) into `plotTypes`. **Runs early** – during plot types, before terrain (5), features (6), or starts (4a). |
| **4_HBMapGenerator** | `SetPlotTypes(plotTypes)` sends data to the engine. `GenerateCoasts()` marks shallow vs deep water. |

**Output:** Every plot has a type (ocean, land, hills, mountain). Coasts are set.

---

### 2. GenerateTerrain (Lekmap overrides; uses 5)

**Goal:** Assign climate (grassland, plains, desert, tundra, snow) to land plots.

| Who | Responsibility |
|-----|-----------------|
| **5_HBTerrainGenerator** | Assign terrain from temperature/rainfall. |
| **4_HBMapGenerator** | `SetTerrainTypes()` applies terrain to the map. |
| **Lekmap** | `FixCoastLine()` adds coastal hills. `FixIslands()` tweaks island terrain. |

**Output:** Land plots have terrain types.

---

### 3. Map.RecalculateAreas()

**Goal:** Group connected land/water into areas for pathfinding and logic.

| Who | Responsibility |
|-----|-----------------|
| **Engine** | Recalculates area IDs. |

---

### 4. AddRivers() (4_HBMapGenerator)

**Goal:** Place rivers from high ground to low.

| Who | Responsibility |
|-----|-----------------|
| **4_HBMapGenerator** | River placement logic. |

---

### 5. AddLakes() (4_HBMapGenerator)

**Goal:** Place lakes (after rivers so rivers can flow into them).

| Who | Responsibility |
|-----|-----------------|
| **4_HBMapGenerator** | Lake placement logic. |

---

### 6. AddFeatures() (6_HBFeatureGenerator)

**Goal:** Place forests, jungle, marsh, ice, etc.

| Who | Responsibility |
|-----|-----------------|
| **6_HBFeatureGenerator** | Feature placement based on plot type, terrain, rivers, lakes. Uses **1_HBMapmakerUtilities** for coast data. **Runs after** 3_PangaeaIslands, 5_HBTerrainGenerator, rivers, lakes. |

---

### 7. Map.RecalculateAreas()

**Goal:** Recompute areas after features (e.g. ice) change passability.

---

### 8. StartPlotSystem() (4a_HBAssignStartingPlots)

**Goal:** Place civ starts, natural wonders, and resources.

| Who | Responsibility |
|-----|-----------------|
| **4a_HBAssignStartingPlots** | Civ start plots, natural wonders, strategic/luxury/bonus resources. Uses **1_HBMapmakerUtilities**. |

---

### 9. AddGoodies() (4_HBMapGenerator)

**Goal:** Place antiquity sites, etc.

| Who | Responsibility |
|-----|-----------------|
| **4_HBMapGenerator** | Goody hut–style placement. |

---

### 10. DetermineContinents() (4_HBMapGenerator)

**Goal:** Assign continent IDs for art and logic.

| Who | Responsibility |
|-----|-----------------|
| **4_HBMapGenerator** | Continent assignment. |

---

## "Ready to play"

After step 10, the map is fully generated. The engine then does final setup (e.g. visibility, diplomacy) and shows "Ready to play".

---

## Why these numbers?

**Numbers mirror Lekmap execution order** (LekmapPangaeaFractalv5.2.lua is the arbiter of truth):

| Number | File | When it runs |
|--------|------|--------------|
| **1** | 1_HBMapmakerUtilities | Loaded first (shared utility). No execution step. |
| **2** | 2_HBFractalWorld | 1st: mainland fractal shape |
| **3** | 3_PangaeaIslands | 2nd: islands into plotTypes |
| **4** | 4_HBMapGenerator | 3rd: SetPlotTypes, GenerateCoasts; 5th: AddRivers, AddLakes; 8th: AddGoodies, DetermineContinents |
| **4a** | 4a_HBAssignStartingPlots | 7th: StartPlotSystem (nested under 4) |
| **5** | 5_HBTerrainGenerator | 4th: terrain assignment |
| **6** | 6_HBFeatureGenerator | 6th: AddFeatures |

**Load order (in Lekmap):** 4 → 2 → 6 → 5 → IslandMaker → MultilayeredFractal → 3  
**Execution order:** 2 (fractal) → 3 (islands) → 4 (SetPlotTypes, coasts) → 5 (terrain) → 4 (rivers, lakes) → 6 (features) → 4a (starts) → 4 (goodies, continents).

---

## Include chain (reference)

```
LekmapPangaeaFractalv5.2.lua
├── 4_HBMapGenerator
│   └── 4a_HBAssignStartingPlots
│       └── 1_HBMapmakerUtilities
├── 2_HBFractalWorld
├── 6_HBFeatureGenerator
│   └── 1_HBMapmakerUtilities
├── 5_HBTerrainGenerator
├── IslandMaker (external)
├── MultilayeredFractal (external)
└── 3_PangaeaIslands
    └── IslandHelpers, DotIsland, ChunkIsland, PolarMerge, ...
```
