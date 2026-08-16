# Fury Front — Visual Benchmark 0.2

Date: 2026-08-16  
Branch: `feat/v02-visual-benchmark`  
Base production: `000fc959a15e869d675cadf0be5b8bad2169aa03`  
Rollback (keep): `/var/www/furyfront/releases/866893a`

V0.1 gameplay is **accepted**. 0.2 does **not** add modes or systems. It turns the working graybox FPS into the first believable visual of Fury Front: Ironfall Depot and Broken Perimeter first.

## Scope lock

Do not begin: Battle Royale, DMZ, extra maps, store, Battle Pass, ranked, full multiplayer, complete 27-weapon set, complete operator roster.

Human-playtest blockers on https://furyfront.app/play/ outrank art.

## First Visual Approval Gate

Present these **before** bulk-producing the rest of 0.2:

| Deliverable | This branch (engineering sample) | Production art (blocked on Meshy confirmation) |
| --- | --- | --- |
| Assault operator | Silhouette / kit language documented; 3P still capsule until GLB | Original elite operator GLB |
| First-person arms | Camera-parented glove/arm placeholders + pose bounds | Production arms matching operator |
| KF-16 | Named viewmodel parts, mag, sights, muzzle + shell markers. **Balance JSON untouched** | Production rifle GLB |
| Phantom Infiltrator | Slimmer stealth placeholder + visor/comms kit | Production infiltrator GLB |
| One Ironfall combat area | Gate courtyard modular overlay (layout preserved) | Swap overlay for kit GLBs after approval |
| Muzzle / impact VFX | Shader flash, sparks, dust, alarm pulse, breach overlay | Texture sheets later if budget allows |
| Web performance | Budgets in `docs/23-v02-performance-budget.md` | Measure again after first GLB import |
| Provenance | Updated `game/assets/PROVENANCE.md` | Meshy task IDs + license on import |

Do **not** bulk-produce Signal Hacker, Heavy Enforcer, full depot kit, or the full audio library until this gate is approved.

## Art direction (original — not Call of Duty)

### Assault operator

Modern elite military operator. Realistic proportions. Plate carrier, tactical armor, setting-appropriate helmet/headgear, gloves, ammo/storage, radio/comms. Believable military materials. Visually **Fury Front**, not a copyrighted operator.

This mesh sets the standard for later characters. Gameplay identity of Vex (Assault) stays in data; cosmetics do not change stats.

### First-person arms

Compatible with the player camera and KF-16. Animation **boundaries** only (not the full library):

idle · walk sway · sprint · ADS · fire · recoil · reload · weapon switch

### KF-16

Believable modern/future assault rifle, original Fury Front design. Preserve canonical stats in `data/weapons.json` / `game/resources/balance/weapons.json`. Art must not change RPM, damage, mag, recoil pattern, or ADS times.

Required nodes: weapon mesh, materials, magazine, sights, muzzle, FPS pose, reload pose foundation, muzzle-flash attachment, shell-eject point.

### Phantom Infiltrator

Agile, stealth-focused, lighter equipment, advanced infiltration tech. Human / human-enhanced — not a monster.

Signal Hacker and Heavy Enforcer wait until the gate passes. Their tactical identities stay: EW specialist vs heavier human silhouette.

### Ironfall Depot kit (gate first)

Do not remodel the map. Preserve markers, hollow buildings, nav, and collision of the approved layout. Replace the **most visible graybox** at the gate with reusable pieces: concrete/metal, floors, doors, security doorway, barriers, crates, sandbags, signage, industrial lights, cameras, fencing. Command-center / server / comms kit pieces come after gate approval.

### Combat presentation

Muzzle flash, bullet impacts, sparks, dust hits, hit feedback, recoil presentation, environmental smoke, alarm lighting, Shadowbreach distortion. No expensive destruction.

### Audio

First sound **benchmark** is planned, not bulk-recorded in this gate: KF-16 gunshot, reload, mag handling, impacts, footsteps, Shadowbreaker fire, base alarm, radio, Ironfall ambience. Positional where appropriate. Procedural WAV remains until licensed/original recordings land with provenance.

## Meshy (production 3D)

Godot imports **GLB**. Do not generate FBX for this runtime.

Balance at start of 0.2: **100 credits**.

Recommended first-gate pack (wait for explicit credit confirmation):

| Step | Credits | Count | Subtotal |
| --- | --- | --- | --- |
| Preview (meshy-5 / non-latest) | 5 | 4 models | 20 |
| Refine | 10 | 4 | 40 |
| Remesh (game topology) | 5 | 4 | 20 |
| **Total** | | | **80** |

Models: Assault operator (T-pose), FPS arms, KF-16, Phantom Infiltrator.

Meshy-6 preview at 20 each would be 80 before refine and would **exceed** the 100-credit balance once remesh is included. Concept stills (nano-banana-pro) are out of budget for this gate.

No Meshy call until the user confirms this spend.

## Infrastructure (non-blocking, this branch)

- nginx: remove duplicate `mp4` MIME under `/media/` (inherit `mime.types`). No routing change. No TuGPT change. Reload, not restart.
- Godot: drop unused Android export preset so Web export does not probe Gradle `build-tools`. Do not install the Android SDK.

## Human playtest (parallel, still open)

https://furyfront.app/play/ — pointer lock, sensitivity, move, ADS, fire, reload, death/respawn (stats survive), Comms restore, data theft, extraction, commander, Results freeze, Esc reacquire. Record FPS and memory in combat. Automated browsers cannot finish pointer-lock FPS; a human pass is required.
