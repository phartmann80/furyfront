# Asset provenance — Vertical Slice 0.1 / Visual Benchmark 0.2

No Call of Duty, Activision, or other copyrighted game assets are used. Meshy is **not** part of the Fury Front pipeline.

## Runtime placeholders (V0.1 gameplay)

| Asset | Source | License |
| --- | --- | --- |
| Ironfall Depot graybox hull | Generated in `ironfall_builder.gd` | Original |
| Ironfall gate kit sample | Generated in `depot_kit.gd` / `gate_presentation.gd` | Original placeholder — layout unchanged |
| Muzzle / impact / spark / dust | `vfx_bus.gd` + `shaders/muzzle_flash.gdshader` | Original |
| Gunshot / alarm / impact | Procedural WAV in `audio_director.gd` | Original |
| HUD / touch buttons | Godot Controls | Original |
| Play start background | `assets/ui/start_background.jpg` | Generated 1920×1080 battlefield plate |

Gameplay collision and navigation still use the V0.1 hulls. Visual GLBs must not replace those hulls.

## V0.2 Gate A clay — current imported baseline

Generated 2026-08-17 (operators / KF-16) and 2026-08-18 (FPS arms grip pass) by `tools/blender/ff_gate_a.py` on **portable Blender 4.5.10 LTS**. Development machine only. Not installed on production. No Meshy.

Stale metaball/DCC albedo-normal-ORM PNGs and earlier Godot shots were moved to `art/v02/archive/stale-pre-hm08-gate-a/` (gitignored). They are not in the benchmark scene.

### Human base

| | |
| --- | --- |
| Topology | MakeHuman **hm08** (`base.obj` via MPFB `HumanService.create_human()`) |
| Tooling | MPFB2 **v2.0.17** (`80919fa4682335c41847f761a4d79dcad4124732`), portable Blender 4.5 only |
| Graphical license | **CC0 1.0** (MakeHuman Community bundled graphical assets) |
| Code license | MPFB addon **GPL-3.0**; MakeHuman app **AGPL**. Neither is shipped in the Fury Front runtime, web export, or `game/assets/` |
| Vendor tree | `tools/blender/vendor/` (gitignored) |
| Source body | 13,378 verts / 26,752 tris after helper bake (scale 0.1 = meters) |
| Gender macros | `macro.json`: 0 = female, 1 = male. Live chest-front probe confirms male = 1.0 |

Only resulting game meshes (GLB) are intended to ship.

### Current GLBs (Godot 4.7.1 imported, Gate A2 clay)

Godot Compatibility import 2026-08-17 (operators / KF-16, 1920×1080). FPS arms and KF-16 receiving-geo pass 2026-08-18. Operator kit then hidden collapse + LOD 2026-08-18. Counts from Blender export (Godot recapture still held).

| asset_id | tris | verts | source body tris | GLB | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| ff_op_assault | 36234 | 18411 | 26752 | 891 KB | LOD0; cummerbund + hidden collapse; kit 14658 |
| ff_op_assault_lod2 | 3999 | 2282 | — | 126 KB | combat-distance LOD2 |
| ff_sb_phantom | 32912 | 16624 | 26752 | 797 KB | LOD0; hidden collapse; kit 11182 |
| ff_sb_phantom_lod2 | 3500 | 1907 | — | 109 KB | combat-distance LOD2 |
| ff_wpn_kf16 | 4628 | 2344 | — | 121 KB | winter trigger well + support-corner relief; nodes unchanged |
| ff_fps_arms | 5704 | 2856 | — | 135 KB | hm08 short extract re-seated after receiving-geo edit |

No textures, no production materials, no rig. Weapon balance JSON untouched. Collision/nav hulls untouched.

**Hidden-geo strategy:** kit shrinkwraps onto an armless wrap cage. Covered body verts (under armor/harness/helmet, minus face/neck/hands/feet/shoulders/elbows/knees) are collapse-decimated for LOD0. LOD2 is a full-mesh collapse of the joined character to the combat-distance cap. FPS arms remain a separate 1P viewmodel.

Blend sources: `art/v02/src/` (local DCC, not in git). Blender clay: `art/v02/renders/` (gitignored). Review shots: `game/assets/v02/shots/` (excluded from Web export). Grip-checkpoint frames in that folder are the current Blender FOV-75 workbench captures; Godot in-engine recapture is held until the grip passes.
