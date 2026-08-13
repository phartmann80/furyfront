# Maps

## Canonical locations

| ID | Name | Playlist |
| --- | --- | --- |
| `map_ironfall` | Ironfall Depot | Base Defense / Shadow Assault (V0.1) |
| `map_crimson_alley` | Crimson Alley | Future MP |
| `map_skyforge` | Skyforge Outpost | Future MP |
| `map_obsidian_reef` | Obsidian Reef | Recon Protocol |
| `map_sector9` | Sector 9 | Recon Protocol |
| `map_eclipse` | Eclipse Zone | Battle Royale |

Eclipse Zone biomes (future): Ashen Plains, Crystal Wastes, Titan Ridge, Neon Ruins, Verdant Sink, Rift Core.

## Retired concept names

Black Harbor, Ironroot, Solstice, Kiln, Afterlight, Whiteveil, Sprawl, and Ridgeback appeared in the pre-lock GDD. **They were never built as engine maps.** Do not treat Black Harbor as the prototype level. V0.1 geometry is **Ironfall Depot** (graybox CSG, labeled as such in-scene).

---

## Ironfall Depot — V0.1

**Fantasy:** Fury Front forward logistics base. Concrete, blast walls, comms mast, vehicle yard.  
**Playable size (graybox):** ~90 × 70 m, two stories on command + watchtower.  
**Mode:** Base Defense, 4 Fury Front vs Shadowbreaker AI.

```
                    [WATCHTOWER]
                         |
[VEHICLE YARD]----[SECURITY GATE]----[PERIMETER]
       |                 |                 |
[ARMORY]----------[COMMAND CENTER]----[BARRACKS]
       |                 |                 |
[COMMS]-----------[SERVER / INTEL]----[MAINTENANCE]
                         |
              [UNDERGROUND ACCESS]
                         |
                 [EXTRACTION LZ]
```

| Area | Combat job |
| --- | --- |
| Security gate | First contact / checkpoint defense |
| Command center | Primary defend objective |
| Barracks | Interior CQC, flank |
| Armory | Cover + resupply volume |
| Communications | Engineer restore interact |
| Server / intel | Stop data steal |
| Vehicle yard | Exterior mid-range, KF-16 |
| Watchtower | Elevation |
| Maintenance corridor | Choke |
| Underground | Flank into extraction |
| Extraction LZ | Intercept steal team |

Cover every 6–9 m on primary routes. Navmesh baked over floor + ramps (V0.1: `NavigationRegion3D` generated with the graybox).

---

## Shared rules (future MP maps)

- 6v6 long axis 80–110 m  
- First contact 8–14 s  
- Weather as playlist modifier  
- Spawn protection 2.0 s casual / 1.25 s ranked  
