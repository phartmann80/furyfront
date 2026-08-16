# Visual Benchmark 0.2 — web performance budget

Date: 2026-08-16  
Runtime: Godot 4.7.1.stable, `gl_compatibility`, unthreaded Web export  
Target: **60 FPS at 1080p** on appropriate PC hardware in a desktop browser

Fury Front remains a **PC browser game first**. Screenshot-level density is not a goal. LODs and High / Medium / Low exist from the start. `GraphicsProfile` defaults to **Medium on web**.

Do not import high-resolution art in bulk until this budget is the import gate.

## Current production (accepted V0.1)

Commit `000fc959a15e869d675cadf0be5b8bad2169aa03`. Measured ship size:

| Payload | Size |
| --- | --- |
| Landing (`/`) | ~4.56 MB |
| `/play/` total | ~39.37 MB |
| Engine wasm | ~39.5 MB |
| Game pck | ~1.45 MB |
| Site + game | ~43.92 MB |

Wasm dominates download. Art growth must stay in the pck, not a second engine.

## Quality tiers

| | High (native later) | Medium (web default) | Low |
| --- | --- | --- | --- |
| 3D scale | 1.0 | 0.85 | 0.70 |
| Particle scale | 1.0 | 0.65 | 0.35 |
| Directional shadows | on | on | off |
| Local light shadows | off | off | off |
| Impact decals | on | on | off |
| `Engine.max_fps` | 60 | 60 | 60 |

No omni shadows on web. One directional shadow caster maximum.

## Geometry

| Asset | LOD0 | LOD2 | Notes |
| --- | --- | --- | --- |
| Assault operator (3P) | ≤ 25k tris | ≤ 4k | Stricter than docs/14 40k because of web |
| FPS arms | ≤ 6k | 2k | Viewmodel only |
| KF-16 FPS | ≤ 8k | 2.5k | Mag / sights / muzzle as separate nodes, not extra materials if avoidable |
| Phantom Infiltrator | ≤ 18k | ≤ 3.5k | Lighter silhouette than Assault |
| Kit piece (wall, crate, door) | 2–4k | 0.6–1.2k | Shared materials |
| Visible tris in a 1080p Medium view | ≤ 150k | | Gate courtyard is the first measured scene |

Use 2 LODs minimum on characters and hero weapons before they ship in `/play/`.

## Textures

| Class | Medium | Low | High (native) |
| --- | --- | --- | --- |
| Characters / weapons | 1024 | 512 | 2048 |
| Kit trim / signage | 512–1024 | 256–512 | 1024 |
| VFX sheets | 256–512 | 128–256 | 512 |

GPU texture memory (estimated bound, compressed):

- Medium: ≤ **180 MB**
- Low: ≤ **96 MB**

Prefer one albedo + packed ORM per mesh. Skip unique normal maps on kit trim for Medium/Low if the silhouette already reads.

## Materials and draw calls

| Budget | Medium | Low |
| --- | --- | --- |
| Unique materials in view | ≤ 24 | ≤ 14 |
| Draw calls | ≤ 250 | ≤ 140 |
| GPUParticles3D | **none** on web | none |

Reuse kit materials. Do not give every crate its own StandardMaterial3D.

## Lighting

| | Medium web |
| --- | --- |
| Directional lights | 1 |
| Unshadowed local Omni/Spot | ≤ 4 in view (muzzle flash is transient) |
| Local shadows | 0 |
| Glow / SSR / SDFGI / VoxelGI | off |

Alarm lighting is unshadowed omni energy pulses, not extra shadow casters.

## Particles / VFX

CPU / mesh flashes only (current `VfxBus` pattern).

| Tier | Simultaneous mesh flashes + puffs |
| --- | --- |
| Low | ≤ 80 |
| Medium | ≤ 400 |
| High | ≤ 800 |

No full environment destruction. Impacts are decal + spark + dust puff.

## Gameplay density

| | Cap |
| --- | --- |
| Simultaneous Shadowbreaker AI | 8 (current wave sizes) |
| Allies on screen | 4 |
| Smoke volumes | 3 |

Do not raise AI count to fill a prettier courtyard.

## Audio memory

| | Budget |
| --- | --- |
| Compressed banks in `/play/` | ≤ 8 MB |
| Voices simultaneous | ≤ 16 (positional `AudioStreamPlayer3D`) |

V0.2 first gate still uses procedural WAV. Real cues replace tones without raising this cap.

## Web download

| | Cap |
| --- | --- |
| `/play/` total | ≤ **55 MB** |
| Art-driven pck growth vs V0.1 | ≤ **12 MB** |
| Landing | no change required for 0.2 |

If a GLB pushes the pck over 12 MB of *new* art, remesh / atlas / drop a LOD before importing the next character.

## Import gate

Before a production mesh lands in `game/assets/`:

1. Triangle count at LOD0 / LOD2
2. Texture resolution and estimated VRAM
3. Material count
4. Provenance row in `game/assets/PROVENANCE.md`
5. Medium-tier screenshot is not a ship criterion — frame time is

Measured combat FPS and browser memory from a human playthrough of https://furyfront.app/play/ outrank visual expansion when they show a V0.1 blocker.
