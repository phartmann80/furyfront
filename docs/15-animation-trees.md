# Animation trees

## Third person (Animator Controller `FF_Op_TP`)

Parameters: `Speed` (float), `Strafe` (float), `Grounded` (bool), `Slide` (bool), `Crouch` (bool), `TacSprint` (bool), `Ability` (trigger), `Reload` (trigger), `Fire` (bool), `ADS` (bool), `Hit` (trigger), `DeathDir` (int).

```
Base Layer
  Locomotion 2D Freeform (Speed × Strafe)
    WalkBlend, RunBlend, TacSprint
  CrouchBlend
  Slide (root motion 0.45s) → Locomotion
  Jump / Fall / Land
  Mantle (root motion, interrupt fire)

Overlay Layer (Avatar Mask: upper body)
  Empty
  Fire (loop while Fire)
  Reload (interruptible by Fire after 0.15s)
  Ability (full body override 0.2–0.6s)

Additive Layer
  HitReact (4 dirs)
```

## First person (`FF_Arms_FP`)

Per weapon class controller. States: Idle, Fire, ADS_In, ADS_Fire, ADS_Out, Reload, ReloadEmpty, Sprint, Slide, Inspect.

Weapon bone `weapon_root` receives procedural recoil (pitch/yaw) in `WeaponController`.

## Sentry

Idle → Acquire (yaw clamp 45°) → Fire → Destroyed.

## Import

FBX 30 fps, humanoid, root Y-up. No in-place for slide/mantle.
