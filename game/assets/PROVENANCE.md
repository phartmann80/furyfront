# Asset provenance — Vertical Slice 0.1

All V0.1 world/combat visuals are **engine primitives** (CapsuleMesh, BoxMesh, CSG-equivalent StaticBody boxes, generated ImageTexture HUD, procedural AudioStreamWAV tones), except the `/play/` start menu still.

No Call of Duty, Activision, or other copyrighted game assets are used.

| Asset | Source | License |
| --- | --- | --- |
| Ironfall Depot graybox | Generated in `ironfall_builder.gd` | Original |
| Operator Vex FPS arms / capsule allies | Generated meshes | Original placeholder |
| Shadowbreaker capsules | Generated meshes | Original placeholder |
| KF-16 / WASP-9 / K5 viewmodel | BoxMesh placeholder | Original placeholder |
| Gunshot / alarm / impact | Procedural WAV in `audio_director.gd` | Original |
| HUD / touch buttons | Godot Controls | Original |
| Play start background | `assets/ui/start_background.jpg` | User-provided cinematic still; live Controls overlay the menu |
| Muzzle shader | `game/shaders/muzzle_flash.gdshader` | Original |

Replace placeholders with original authored art before any store listing. Keep this file updated when real GLB/OGG lands.
