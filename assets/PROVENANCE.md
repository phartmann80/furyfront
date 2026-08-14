# Fury Front marketing & cinematic assets — provenance

| Asset | Path | Notes |
| --- | --- | --- |
| Hero still | `assets/hero-still.png` | Landing key art only — operators at Ironfall Depot. No baked-in title or buttons. Deployed as `/media/hero-still.png`. HTML owns all overlay copy. |
| Play start background | `assets/play-start-background.jpg` | Godot `/play/` start menu still. Runtime copy: `game/assets/ui/start_background.jpg`. Live Godot Controls own title, quality, and Start — do not rely on pixels in the still. |
| Hero cinematic | `assets/hero-video/hero.MP4` | Original Fury Front cinematic for the Watch Trailer modal. **Do not rename or replace without approval.** H.264/AAC, ~848×464, ~10 s, ~2 MB. |
| Hero poster fallback | `assets/breached_entrance.webp` | Alternate still. Not the active landing hero. |
| Squad / operator reference stills | `assets/*.webp` | Marketing/reference imagery. Not shipped in V0.1 Godot PCK. |

Game runtime placeholders remain documented in `game/assets/PROVENANCE.md`.
