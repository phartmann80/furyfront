# Grip pose handoff — human viewport pass

Scripted posing is stopped. Seven automated passes (solver, authored offsets, receiving-geometry, re-derived index) could not seat the index in the well without the shaft reading through metal, or clear the support fingers from the handguard corner.

A human poses in Blender. Bake/export/evidence is a later automated pass.

## Open this

`art/v02/handoff/grip_pose.blend` (Blender 4.5.10 portable).

If the blend is missing locally, import `grip_unposed.glb` from this folder into a new file. The rifle is current receiving geometry (`7cbad49`): winter trigger well 36×38 mm, support-corner chamfer. Hands are hm08 short extracts, **unposed** — oriented to the palm neighborhoods only (right grip face, left handguard face). No curl, no index path, no cuff edit.

## Scene

| Object | Role |
| --- | --- |
| `ff_wpn_kf16` | Current gun. Do not move attachment empties (`MuzzleFlash`, `ShellEject`, `Magazine`, `AdsAlign`). |
| `RHand` | Trigger hand extract. Pose this. |
| `LHand` | Support hand extract. Pose this. |
| `cam_hip` | Gameplay FOV 75, looking +Y (Godot −Z). |
| `cam_ads` | Same FOV, ADS offset. |
| `cam_trigger` | Index / well close-up. |
| `cam_support` | Left-hand / handguard-corner close-up. |

Weapon JSON stays frozen. Do not retopologize. Arms budget ≤6k tris (current extracts are 5704 — do not add geometry). KF-16 ≤8k.

## What to pose (four-item checklist)

1. **Thumb web** on the right of the pistol grip — seated, slight clearance over penetration.
2. **Support fingers** over the top-left handguard — clear the corner; no grey through the digits. The corner is occluded in gameplay; you may hide extra gun verts there if needed, but prefer posing first.
3. **Index** straight in through the winter well (forward of the grip). Tip on/near the trigger. Shaft in the opening, not through the guard wall. Do not reuse the old short-arc through the receiver.
4. **Support wrist cuff** — natural; no hanging extract spike.

Palm on the grip’s right face (trigger) and the handguard’s left face (support) is the established start. Orbit each contact from three angles before calling it done.

## Reference

Put two or three photos of a real two-hand AR grip (right side, left side, shooter POV) on a second monitor. In-repo plates (concept only, not a grip bible):

- `art/v02/refs/ref_fps_arms.png`
- `art/v02/refs/ref_kf16_rifle.png`

## When you are done

Save the blend. Do not export from Blender unless asked. Message the branch with the blend path; the next pass bakes `ff_fps_arms.glb`, copies FOV-75 frames into `game/assets/v02/shots/`, and reports the SHA.

Do not merge to master. Production stays at `000fc95`.
