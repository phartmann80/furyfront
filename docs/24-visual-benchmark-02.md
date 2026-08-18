# Fury Front — Visual Benchmark 0.2

Date: 2026-08-16  
Branch: `art/v02-gate-a`  
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

## Meshy (removed)

Meshy is **not** used. V2 GLBs are locally authored (`tools/generate_v02_benchmark_glbs.py`) and imported at `game/assets/v02/`.

## First visual gate (V1) — not approved

V1 kitbash (960 / 288 / 200 / 776 tris, single material, cylindrical UVs, faction-colored albedo bands) passed the **technical** pipeline gate and failed the **visual** gate. Too sparse to establish production identity.

## Second visual gate (V2)

Same four assets only. Layered hard-surface, UV islands, albedo + normal + ORM, 2–3 materials, documented joint empties without skin weights. Benchmark: `res://scenes/benchmark/visual_gate.tscn` (keys 1–7, N/I lighting). Skeleton markers: `game/assets/v02/SKELETON.md`.

Ironfall still uses the approved layout overlay only; the gate courtyard received a material/branding pass, not a full kit.

### V2 measured (2026-08-16, this branch, not deployed)

Godot 4.7.1 Compatibility, Intel UHD 1080p inspection scene. Play path still uses V0.1 placeholders.

| Asset | Tris | Verts | Mats | GLB | GPU tex (S3TC+mips) |
| --- | --- | --- | --- | --- | --- |
| Assault | 14624 | 43872 | 3 | 1.51 MB | ~2.67 MB |
| Phantom | 10852 | 32556 | 3 | 1.14 MB | ~2.67 MB |
| KF-16 | 5820 | 17460 | 2 | 0.63 MB | ~2.67 MB |
| FPS arms | 4468 | 13404 | 2 | 0.50 MB | ~2.67 MB |

KF-16 nodes preserved: `MuzzleFlash`, `ShellEject`, `Magazine`, `AdsAlign`. Weapon balance JSON unchanged.

| Budget | V0.1 live | V2 web export (local) |
| --- | --- | --- |
| pck | 1.45 MB | **13.13 MB** (+11.68) |
| wasm | ~39.5 MB | 37.68 MB |
| `/play/` approx | ~39.4 MB | **51.08 MB** |
| `/play/` ceiling | 55 MB | still under |
| Benchmark draw calls | — | 7–15 |
| Benchmark FPS @ 1080p | — | 60 (settled, Intel UHD, inspection only) |
| GPU tex for 4 assets | — | 10.67 MB compressed |

Art growth is at the ~12 MB pck allowance. Further 1K atlases will need LODs or shared textures before more characters.

This pass is **denser authored kitbash**, not DCC-sculpted production identity. If the visual gate rejects V2, do not run another Python primitive pass — switch to a local DCC (Blender) or another no-Meshy mesh pipeline.

### DCC pipeline (Blender 4.5, local — 2026-08-16)

Portable Blender 4.5.10 LTS on the **dev machine only** (`%LOCALAPPDATA%\Programs\Blender-4.5.10\`). Cursor drives it via `tools/blender/ff_dcc.py`. Blend sources: `art/v02/src/` (not packed). Concept refs: `art/v02/refs/`. Clay/wire: `art/v02/renders/` (gitignored). Runtime GLBs **replace** kitbash in `game/assets/v02/`. Shots excluded from PCK (`assets/v02/shots/*`).

Godot-confirmed (Compatibility, 1920×1080, `visual_gate.tscn`):

| Asset | Tris | Verts | Mats | GLB | Rig |
| --- | ---: | ---: | ---: | ---: | --- |
| Assault | 21996 | 11082 | 3 | 697 KB | `AssaultRig` auto-weights |
| Phantom | 17266 | 8659 | 3 | 509 KB | `PhantomRig` auto-weights |
| KF-16 | 8968 | 4560 | 2 | 717 KB | MuzzleFlash, ShellEject, Magazine, AdsAlign |
| FPS arms | 7024 | 3552 | 2 | 194 KB | `ArmsRig` auto-weights |

Arms over the 6k budget. KF-16 over the written 8k Medium cap, inside the 5k–10k user band.

| Budget | V0.1 live | V2 kitbash (superseded) | DCC replace (local, not deployed) |
| --- | --- | --- | --- |
| pck | 1.45 MB | 13.13 MB | **3.14 MB** |
| wasm | ~39.5 MB | 37.68 MB | 37.68 MB |
| `/play/` approx | ~39.4 MB | 51.08 MB | **40.82 MB** |
| `/play/` ceiling | 55 MB | under | under (headroom restored by dropping 1K atlases) |
| Benchmark draw | — | 7–15 | 7 (inspection) / 15 (Ironfall overlay) |
| 1080p FPS | — | 60 settled | **58** settled native inspection (`godot_import_stats.json`); overlay FPS during PNG capture is not the settled figure |
| GPU tex | — | 10.67 MB S3TC | default glTF materials (no 1K atlases) |
| Browser FPS / JS heap | — | V2 play path only | **not re-measured in a browser this pass** — do not treat native 58 as a `/play/` combat number |

KF-16 nodes preserved. Weapon balance JSON unchanged. Production remains `000fc95`. **Not deployed.**

**Visual gate: fail.** Pipeline proof only. Bodies are skin/remesh mannequins with jagged plate shells, mitten hands, featureless helmet volumes. KF-16 is still stacked boxes/cylinders with a rail array. UVs are smart-project; materials are 2–3 Principled slots without authored albedo/normal/ORM. Auto-weights exist; no animation clips.

Do not request visual approval on this pass. Unattended bpy is not enough for production identity. Next authorized step, if taken, is a real human base mesh (authored or CC0 with provenance) plus interactive hard-surface for the KF-16 in the same four-asset Blender files — not another generator rewrite and not Meshy.

### DCC refine (metaball + shrinkwrap — 2026-08-16/17)

Same four assets, portable Blender only. Replaced the skin/extract-shell GLBs in place. Rigging deferred.

Godot-confirmed (`visual_gate.tscn`, Compatibility, 1920×1080):

| Asset | Tris | Verts | Mats (Godot) | Textures | GLB |
| --- | ---: | ---: | ---: | --- | ---: |
| Assault | 11760 | 6028 | 4 | 256 albedo | 640 KB |
| Phantom | 9060 | 4640 | 4 | 256 albedo | 548 KB |
| KF-16 | 8576 | 4364 | 2 | 256 albedo | 377 KB |
| FPS arms | 4112 | 2128 | 2 | 256 albedo | 276 KB |

KF-16 nodes: `MuzzleFlash`, `ShellEject`, `Magazine`, `AdsAlign`. Weapon JSON unchanged. Collision/nav hulls untouched.

| | This refine (local, not deployed) |
| --- | --- |
| Native 1080p settled FPS | **60** (`godot_import_stats.json`) |
| Draw | 9 inspection / 17 Ironfall overlay |
| Rigging | deferred — no armature this pass |
| pck (local web export) | **3.14 MB** (same band as prior DCC replace; `/play/` ≈ **40.82 MB** vs 55 MB ceiling) |
| Browser FPS / JS heap | not re-measured in a browser this pass — native 60 is inspection only |

**Visual gate: still fail.** Metaball body is one volume (bbox ~1.84 m tall, arms present) but still reads as lumpy capsules, thin neck/waist, and shrinkwrap plates that sit as boxes. KF-16 still reads as assembled blocks. FPS arms are off-camera in the current viewmodel placement. Do not request visual approval.

### Gate A2 (hm08 clay revision — 2026-08-17)

Focused revision on `feat/v02-visual-benchmark`. Production remains `000fc95`. Not deployed. Textures hold. Rigging hold. Weapon JSON untouched.

Godot 4.7.1 Compatibility import (`visual_gate.tscn`, 1920×1080):

| Asset | Runtime tris | GLB | Notes |
| --- | ---: | ---: | --- |
| Assault | 38070 | 906 KB | hm08 + thicker carrier, seated pouches, straps, knee mounts, boot cuffs |
| Phantom | 35506 | 838 KB | X-harness + sternum, proud pack, boot cuffs |
| KF-16 | 4472 | 115 KB | One YZ body profile; MuzzleFlash, ShellEject, Magazine, AdsAlign |
| FPS arms | 1112 | 33 KB | Weapon-local wrap-gloves + forearm tubes, parented to KF-16 |

**Gate A: not approved. Gate A2: not approved.** Do not request approval on this pass.

What moved: review scene still loads only the four clay GLBs; silhouettes stay human and distinguishable; kit stays shrinkwrapped/seated rather than extracted shells; KF-16 nodes import; FPS arms now parent to the rifle so hip and ADS share one pose.

What still blocks:

1. FPS grip is the highest remaining miss. Hands are closed wrap volumes and forearm tubes, not a seated trigger hand and a wrapped support hand. Contact is approximate; intersections and float are still visible in hip / ADS / intersect shots.
2. KF-16 is one profile instead of stacked boxes, but still reads angular at gameplay distance. Receiver, magwell, and stock need another form pass before they read as one service rifle.
3. Kit has more thickness and attachment language (insert, pouch flaps, straps, knee mounts) but still reads as fitted primitives in clay.

Evidence: Blender `art/v02/renders/` (gitignored, local DCC); review set of record `game/assets/v02/shots/` (`gate_fps_kf16.png`, `gate_fps_ads.png`, `gate_fps_intersect.png`, `gate_kf16_receiver.png`, operator front/¾/back/sil/helmet/kit/wire).

### Grip pass (2026-08-18) — not approved

Production remains `000fc95`. Not deployed. Godot in-engine capture still held until the grip passes. Review shots for this pass are Blender FOV-75 workbench frames copied into `game/assets/v02/shots/` so they resolve inside the feature-branch commit.

| Asset | Tris | Notes |
| --- | ---: | --- |
| FPS arms | **5704** | hm08 short extract. Budget ≤6k, not regressed. |
| KF-16 | 4472 | Unchanged nodes: MuzzleFlash, ShellEject, Magazine, AdsAlign |

Locked from earlier passes: palm plane-snap, contact-driven wrap-digit curl, single weapon-local pose, hip/ADS offsets, FOV 75.

This pass (authored last-mile on the solver start): support palm on the handguard **left face**; trigger index two-segment swing through the guard; authored trigger thumb approach.

### Clearance pass (2026-08-18, follow-up) — not a pass candidate

Biased to clearance over penetration: trigger palm/web push +X; index arc translated +6 mm outboard after seating; support palm 8.5 mm off the left face with lighter C-curl; support cuff translated toward camera.

**Own review: still fail.** Index remains at the guard opening but still reads as clipping the guard wall in `gate_fps_trigger.png`. Support fingers still punch the top-left handguard corner in `gate_fps_support.png`. Thumb web improved but not cleanly seated. Wrist cuff is less of a hang, still a short extract edge.

Do not request Gate A / A2 approval on this pass.

### Receiving-geometry pass (2026-08-18) — not a pass candidate

The pose loop could not converge: a ~20 mm gloved index cannot occupy a 7 mm well. This pass scales the KF-16 to the hand (winter trigger well + support-corner relief), then re-seats the same hm08 extracts. Interactive viewport posing remains withdrawn. Weapon JSON frozen. Nodes unchanged.

| Region | Before (`7834f4a`) | After |
| --- | --- | --- |
| Guard well X (inner) | 7 mm | authored through-cut 55 mm (side `outboard_sd` +11.7 mm) |
| Opening YZ (authored cut) | 22 × 16 mm | 36 × 38 mm, placed forward of the grip |
| Support top-left | left face x ≈ −17 mm, unchamfered top | left face x ≈ −11.5 mm; rail-profile chamfer + extra left-top bite |
| KF-16 tris | 4472 | **4628** (≤8k) |
| FPS arms tris | 5704 | **5704** (≤6k) |

Nodes (unchanged): MuzzleFlash Godot `(0, 0.028, -0.58)`; ShellEject `(0.04, 0.04, -0.04)`; Magazine Blender `(0, 0.055, -0.068)`; AdsAlign Godot `(0, 0.078, -0.02)`.

**Own review: still fail.** Index tip reports near the well but `gate_fps_trigger.png` still shows the shaft through the guard wall. Support fingers still clip the handguard corner in `gate_fps_support.png`. Thumb web clearance restored (`min_sd=+0.0024`). Cuff unchanged from clearance pass.

Do not request Gate A / A2 approval on this pass.

### Final scripted re-seat (2026-08-18) — fail; human-posing handoff

One pass only, then stop. Re-derived the trigger index (park outboard, YZ hinge, −X enter) against the 36×38 mm well; deepened the support-corner scoop. Index tip reached the opening; the shaft still read through the wall. Support scoop boolean was a no-op (verts 60→60); fingers still through. Web clearance regressed when the whole trigger hand was re-framed.

**Hard stop.** Runtime GLBs and `game/assets/v02/shots/` stay at `7cbad49` (last receiving-geo pose). Do not iterate scripted posing again.

Handoff for a human viewport pass:

- Instructions: `game/assets/v02/handoff/README.md`
- Scene: `art/v02/handoff/grip_pose.blend` (RHand / LHand unposed extracts, current KF-16, cameras `cam_hip` `cam_ads` `cam_trigger` `cam_support`)
- Import fallback: `game/assets/v02/handoff/grip_unposed.glb`
- Rebuild the scene: `blender --background --python tools/blender/ff_gate_a.py -- --root <repo> --only handoff --skip-gender`

After the human saves the blend, a later pass bakes `ff_fps_arms.glb` and refreshes the grip shot set.

Do not request Gate A / A2 approval on this pass.

### Assault kit integration (2026-08-18) — not a pass candidate

Posing session is pending; KF-16 remains geometry-locked at `7cbad49`. This checkpoint is Assault kit only. Phantom kit, hidden-body collapse, and rifle work are separate reports.

| Asset | Tris | GLB | Notes |
| --- | ---: | ---: | --- |
| Assault | **41234** | 1002 KB | MOLLE webbing, mag/admin/dump/lumbar pouches, drop-leg, NVG shroud + ARC rails, dual knee straps, gaiter/tongue boots. Full hm08 kept. |
| Phantom | 35506 | 838 KB | Unchanged this checkpoint |
| KF-16 | 4628 | 121 KB | Frozen at `7cbad49` |
| FPS arms | 5704 | 135 KB | Frozen until grip bake |

Still clay. Carrier now has attachment language (webbing rows, pouch flaps/tabs, strap buckles, mounted knee caps). Helmet reads high-cut with a shroud and side rails rather than a plain bowl. Drop-leg is a seated thigh volume, not a shrinkwrap panel. Midriff still shows under the plate; boots are still blocky. Collapse to ~22–25k LOD0 is the next Assault workstream after Phantom kit, not this commit.

Evidence: `game/assets/v02/shots/gate_assault.png`, `gate_assault_34.png`, `gate_assault_back.png`, `gate_assault_helmet.png`, `gate_assault_kit.png`, `gate_assault_wire.png`, `gate_silhouette.png`. Grip and KF-16 shots untouched.

Do not request Gate A / A2 approval on this pass.

- nginx: remove duplicate `mp4` MIME under `/media/` (inherit `mime.types`). No routing change. No TuGPT change. Reload, not restart.
- Godot: drop unused Android export preset so Web export does not probe Gradle `build-tools`. Do not install the Android SDK.

## Human playtest (parallel, still open)

https://furyfront.app/play/ — pointer lock, sensitivity, move, ADS, fire, reload, death/respawn (stats survive), Comms restore, data theft, extraction, commander, Results freeze, Esc reacquire. Record FPS and memory in combat. Automated browsers cannot finish pointer-lock FPS; a human pass is required.
