# Fury Front V0.2 — local Blender DCC

Blender belongs on the **development machine only**. Do not install it on the production server.

Portable 4.5.10 LTS (no admin):

`%LOCALAPPDATA%\Programs\Blender-4.5.10\blender-4.5.10-windows-x64\blender.exe`

Gate A clay (hm08 via MPFB2, already installed in this portable Blender):

```
blender --background --python tools/blender/ff_gate_a.py -- --root C:\Users\hartm\furyfront
```

Earlier metaball generator (superseded, do not use for Gate A):

```
blender --background --python tools/blender/ff_dcc.py -- --root C:\Users\hartm\furyfront
```

Writes:

- `game/assets/v02/*.glb` (runtime, replaces kitbash)
- `art/v02/src/*.blend` (DCC source, not packed)
- `art/v02/renders/` (clay/wire previews, gitignored)

Meshy is not used.
