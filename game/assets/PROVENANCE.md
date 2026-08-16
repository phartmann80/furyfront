# Asset provenance — Vertical Slice 0.1 / Visual Benchmark 0.2

All V0.1 world/combat visuals are **engine primitives** (CapsuleMesh, BoxMesh, CSG-equivalent StaticBody boxes, generated ImageTexture HUD, procedural AudioStreamWAV tones), except the `/play/` start menu still.

No Call of Duty, Activision, or other copyrighted game assets are used.

| Asset | Source | License |
| --- | --- | --- |
| Ironfall Depot graybox hull | Generated in `ironfall_builder.gd` | Original |
| Ironfall gate kit sample | Generated in `depot_kit.gd` / `gate_presentation.gd` | Original placeholder — layout unchanged |
| Assault FPS arms | Generated in `fps_arms.gd` | Original placeholder |
| Phantom Infiltrator kit | Generated extras on capsule in `shadowbreaker.gd` | Original placeholder |
| KF-16 viewmodel parts + MuzzleFlash / ShellEject / Magazine | Generated in `weapon_manager.gd` | Original placeholder. Balance: `resources/balance/weapons.json` |
| Muzzle / impact / spark / dust | `vfx_bus.gd` + `shaders/muzzle_flash.gdshader` | Original |
| Gunshot / alarm / impact | Procedural WAV in `audio_director.gd` | Original |
| HUD / touch buttons | Godot Controls | Original |
| Play start background | `assets/ui/start_background.jpg` | Generated 1920×1080 battlefield plate; live Controls own the menu |

## V0.2 production GLB (not imported yet)

Blocked on Meshy credit confirmation. When imported, record task id, model, credit cost, and date here. Target formats: GLB. Do not import copyrighted operator or weapon designs.

Replace placeholders with original authored art before any store listing.
