# Grip pose handoff — human viewport pass

Scripted posing is stopped. Seven automated passes (solver, authored offsets, receiving-geometry, re-derived index) could not seat the index in the well without the shaft reading through metal, or clear the support fingers from the handguard corner.

A human poses in Blender. Bake/export/evidence is a later automated pass.

## Blender version

**Use Blender 4.5.10** (the portable build on the DCC machine):

`%LOCALAPPDATA%\Programs\Blender-4.5.10\blender-4.5.10-windows-x64\blender.exe`

`grip_pose.blend` was saved from 4.5.10. Open it in **4.5.10** (or a later 4.5.x). Do not save this file from an older Blender.

| Your Blender | What to do |
| --- | --- |
| **4.5.10** (required) | Open `art/v02/handoff/grip_pose.blend`. |
| 4.5.x newer than 4.5.10 | Open the blend. Prefer not to save-over until you are done posing, so the file stays on 4.5.10. |
| 4.2 / 4.3 / 4.4 | Do **not** rely on opening the blend. Import `grip_unposed.glb` from this folder into a new 4.5.10 file. Older 4.x may warn or fail on a 4.5.10 blend; saving from them can make the file unreadable in 4.5.10. |
| 3.x or 5.x | Do not use. Import the GLB in 4.5.10 only. |

## Open this

`art/v02/handoff/grip_pose.blend`

If the blend is missing locally, import `grip_unposed.glb` from this folder into a new 4.5.10 file. The rifle is current receiving geometry (`7cbad49`): winter trigger well 36×38 mm, support-corner chamfer. Hands are hm08 short extracts, **unposed** — oriented to the palm neighborhoods only (right grip face, left handguard face). No curl, no index path, no cuff edit.

## Scene

| Object | Role |
| --- | --- |
| `ff_wpn_kf16` | Current gun. Do not move attachment empties (`MuzzleFlash`, `ShellEject`, `Magazine`, `AdsAlign`). |
| `RHand` | Trigger hand extract. Pose this. **Do not rename.** |
| `LHand` | Support hand extract. Pose this. **Do not rename.** |
| `cam_hip` | Gameplay FOV 75, looking +Y (Godot −Z). |
| `cam_ads` | Same FOV, ADS offset. |
| `cam_trigger` | Index / well close-up. |
| `cam_support` | Left-hand / handguard-corner close-up. |

Weapon JSON stays frozen. Do not retopologize. Arms budget ≤6k tris (current extracts are 5704 — do not add geometry). KF-16 ≤8k.

**Do not rename `RHand` or `LHand`.** The bake pass picks those objects up unmodified.

## What to pose (four-item checklist)

1. **Thumb web** on the right of the pistol grip — seated, slight clearance over penetration.
2. **Support fingers** over the top-left handguard — clear the corner; no grey through the digits. The corner is occluded in gameplay; you may hide extra gun verts there if needed, but prefer posing first.
3. **Index** straight in through the winter well (forward of the grip). Tip on/near the trigger. Shaft in the opening, not through the guard wall. Do not reuse the old short-arc through the receiver.
4. **Support wrist cuff** — natural; no hanging extract spike.

Palm on the grip’s right face (trigger) and the handguard’s left face (support) is the established start.

**Bias:** slight visible clearance beats any penetration. If a contact is a close call, leave a gap. Clip-at-rest is a fail, not a seated pose.

Orbit each contact from **three angles** in the viewport before saving. The render is confirmation, not discovery.

## How the pose will be judged (evidence)

After you save, the bake pass will render the same **seven-shot grip set** from this scene (FOV **75** gameplay cameras plus the trigger/support close-ups):

`gate_fps_{hip, ads, trigger, support, wire, hands_wire, intersect}.png`

The four-item bar is scored in those frames, not in a single viewport angle. Leave `cam_hip`, `cam_ads`, `cam_trigger`, and `cam_support` in the file and do not rename them.

## Reference

Put two or three photos of a real two-hand AR grip (right side, left side, shooter POV) on a second monitor. In-repo plates (concept only, not a grip bible):

- `art/v02/refs/ref_fps_arms.png`
- `art/v02/refs/ref_kf16_rifle.png`

## When you are done

Save `art/v02/handoff/grip_pose.blend` (keep the path). **Commit it to `art/v02-gate-a`**, or return the file by any channel if you cannot push. Do not export GLBs unless asked.

The bake pass expects this file unmodified except for the posed `RHand` / `LHand` meshes. It will write `ff_fps_arms.glb`, copy FOV-75 frames into `game/assets/v02/shots/`, and report the SHA.

Do not merge to master. Production stays at `000fc95`.
