# FPS grip — known polish (not a ship blocker)

Human viewport posing is **cancelled**. The play path ships the automated snap/curl pose: palm plane-snap, light wrap, clearance over penetration. Digit-in-the-well / support-corner contact will still miss on close-ups. That is logged polish, not a freeze.

Do not open `grip_pose.blend` for a posing session. Rebuild the viewmodel with:

```
blender --background --python tools/blender/ff_gate_a.py -- --root <repo> --only arms --skip-gender
```

KF-16 receiving geometry stays at the winter well + corner relief (`7cbad49`). `--only arms` does not re-export the rifle.

Unposed extracts (`grip_unposed.glb`, `art/v02/handoff/grip_pose.blend`) are leftovers from the cancelled handoff. Safe to ignore.
