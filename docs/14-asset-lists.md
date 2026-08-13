# Asset lists

Production matrix. Formats: glTF/GLB source → Godot scenes. Textures: 2K desktop, 1K mobile. Audio: WAV 48 kHz source → OGG.

## Maps (per map)

| Asset | Count | Notes |
| --- | --- | --- |
| Modular kit pieces | 80–140 | 2–8k tris each |
| Hero props | 15–25 | Crane, furnace, radar |
| Collision simplified | 1 | Invisible |
| Navmesh | 1 | |
| Light probes / reflection | 1 set | |
| Audio geometry | 1 | |
| VFX volumes (weather) | 3–8 | |
| Minimap render | 1 | |

## Operators (each)

| Asset | Count |
| --- | --- |
| Body mesh LOD0–3 | 4 |
| Face / head |
| 4 outfit variants (launch) | 4 |
| FPS arms matching torso | 1 set |
| Ability VFX | 2–4 |
| VO lines | ~80 |

LOD0 ≤ 40k tris, LOD3 ≤ 4k. Capsule hitbox standard.

## Weapons (each)

| Asset | Count |
| --- | --- |
| World + FPS mesh | 2 |
| Mag / bolt extras | 2–6 |
| Attachments | 12–25 modular |
| Icons 256 | 1 + attachments |
| Audio set | 12–20 cues |
| Muzzle / tracer | 1 shared pool + unique tint |
| Recoil pattern asset | 1 |

## Characters animation

| Set | Clips (approx) |
| --- | --- |
| Locomotion | 40 |
| Combat overlay | 25 |
| FPP per weapon class | 18 |
| Finishers | 1 per operator |

## UI

| Pack | Notes |
| --- | --- |
| HUD atlas | 2k |
| HQ frames | |
| Ranked emblems | 7 ranks × 3 |
| Shop frames | rarity |

## Audio banks

`wpn`, `foley`, `explo`, `streak`, `vo_en`, `ui`, `amb_{map}`, `music`.

## CDN groups

`core`, `map_{id}`, `op_{id}`, `wpn_{id}`, `season_{n}`, `shadow_assault`.

## Naming

`ff_{type}_{name}_{lod}` e.g. `ff_wpn_kf16_fps`, `ff_map_harbor_crane`.
