# UI / UX

## Visual language

Dark steel, amber accent (`#E8A317` in mockups), stencil numerals, 1 px HUD. Never clutter the center 12° of FOV except hitmarker and ADS optic.

## HUD (in-match)

```
[COMPASS ................. N  NE  E .................]
[KILLFEED]
[STREAK PIPS]
                                              [MINIMAP]
[ABILITY]                          [HITMARKER]
[HEALTH ████]                      [AMMO 28 | 120]
[STANCE]  [OBJECTIVE]              [WEAPON NAME]
[SCORE  42-38]                     [K/D  12/4]
```

- Hitmarker: white X, red on kill, head gold.
- Damage direction: red arc, 400 ms.
- Crosshair: customizable gap/color; turns red on enemy (colorblind shapes).
- Mobile: larger ammo + fire/ADS/lethal clustered right; minimap top-left; gyro toggle.

## HQ (front end)

Tabs: Play, Loadout, Armory, Operators, Shop, Pass, Social, Career.

Play: playlist tiles, party dock bottom, news left. Ranked tile locked to lvl 20.

**Loadout:** 10 slots. Gunsmith 3D inspect (rotate), attachment pickers with **live stat bars** (ADS, recoil, damage range). Compare mode.

## Ranked

Emblem + SR bar. Map veto screen: 6 thumbs, 20 s. End: SR delta with MMR hidden.

## Accessibility

- Colorblind: 4 palettes + icon shapes for flags.
- HUD scale 80–130%.
- Screen shake slider 0–100 (default 60).
- Reduce flash: flashbang → grey + icon (legal photosensitivity).
- Subtitles for operator callouts.
- Hold vs toggle ADS, crouch, sprint.

## Navigation (web vs native)

- Web: ESC menu, Tab scoreboard, 1–4 weapons/streaks, B lethal, Q ability, T chat.
- Controller: face buttons CoD-like (A jump, B crouch/slide, LT ADS, RT fire).
- Touch: customizable two-stick + fire; 5 HUD layouts.

Mockup: `mockups/hud.html`, `mockups/hq.html`.
