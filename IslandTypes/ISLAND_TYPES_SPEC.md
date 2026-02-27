# Island Types – Full Roster & Rarity

## Structure

- **IslandTypes/** (root): IslandHelpers.lua, legacy/, common/, uncommon/, rare/, exceptional/
- **common/**: Dot, Pebble, Strip, ClusterOfTiny
- **uncommon/**: Comma, Split, Chunk, Blob, Waterdrop, SShape, Wishbone, TwinBay, MountainWall, SplinteredCliffs
- **rare/**: Crescent, SteppingStone, EllipseArchipelago, FjordPeninsula, EdgeOfWorld, ArcticMerging, ShatteredRing, Isthmus
- **exceptional/**: VolcanicPeak, JunglePeak, DesertPeak, BrokenHeart, CurledDragon, CrescentAndStar
- **legacy/**: NormalIslandLegacy

## Include Path

All island types use: `include("IslandTypes/IslandHelpers");`

`IslandHelpers` provides: `WrapCoord`, `GetHexNeighbor`, `GetHexNeighbors`, `IsHexAdjacent`, `GetHexDisk`, `ApplyBasicIslandTerrain`, `firstRingYIsEven`, `firstRingYIsOdd`.

## Lua 5.1 compatibility

Civ 5 uses Lua 5.1 (no `goto`). Replace `goto` / `::label::` with `if/else` or loop restructuring.
