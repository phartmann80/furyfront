# Audio, VFX, Shaders, Animation

## Sound design profiles

### Mix buses

| Bus | Ceiling | Notes |
| --- | --- | --- |
| Weapons_Player | 0 dB | Priority, duck world −6 dB on fire |
| Weapons_Other | −8 dB | Distance LP 4 kHz @ 40 m |
| Explosions | −2 dB | Limiter, never clip voice |
| Foley | −12 dB | Stance, reload, mantle |
| Scorestreaks | −4 dB | Flybys |
| VO | −6 dB | Callouts |
| Music | −18 dB in-match, −8 HQ | Adaptive intensity 0–1 from gunfire density |
| UI | −10 dB | |

### Weapon audio (per gun)

Layers: mechanic (mech), bang (transient), body (low), tail (space), bass thump (≤ 80 Hz, 1–2 frames), suppress alt, distant (third person).

**KF-16:** Tight 5.56 crack, short tail, high click.  
**Vesper-47:** Heavy 7.62, longer low body, slower cyclic.  
**WASP-9:** High cyclic, metallic, indoor harsh.  
**Longmere:** Distinct boom + bolt, 300 ms exclusive duck.

Occlusion: 2 ray checks, −12 dB + LP if blocked. Harbor rain: extra −2 dB high.

### Positional

HRTF headphones. Footsteps: 4 surfaces (concrete, metal, dirt, snow) × 3 gaits. Enemy footsteps readable 18 m sprint, 9 m walk, 4 m crouch (Nyx −35%).

## VFX budgets (Medium mobile, per view)

| Type | Max |
| --- | --- |
| GPU particles | 2.5 k |
| Decals (impacts) | 48 |
| Lights (muzzle) | 1 local + 4 flashes queued |
| Smoke volumes | 3 |
| Debris meshes | 12 instanced |

### Muzzle

One-shot mesh flash 50–80 ms + light 40 ms + smoke puff. Tracer: mesh quad, 80 m, team-tinted slightly.

### Impacts

Material: concrete, metal, dirt, wood, water, flesh, snow, glass. Each: decal + 8–16 particles + audio switch. Flesh: blood decal optional (setting).

### Explosions

LOD0: fireball mesh 0.4 s, shockwave decal, debris, smoke persist 6 s. LOD1 mobile: billboard + 32 particles. Camera shake 0.35 at 8 m, falloff 20 m. Photosensitive: shake 0.

## Shader graphs (URP)

**LitWorld:** BaseColor, MR, Normal, AO, Detail (concrete). Wetness from weather volume (smoothness + dark albedo).

**OperatorSkin:** Subsurface light (desktop only), dirt mask, team trim emissive 0.2.

**Weapon:** Custom lighting, scratch mask, camo overlay UV2, scope glass (SSR desktop / cube mobile).

**VFX_Muzzle:** Unlit additive, dissolve by age.

**HeatHaze:** Distortion after airstrike/thermite, off on Low.

**AfterlightNeon:** Emissive billboards, clamp 8 on mobile.

Graph files to author in Godot Shader Graph / `.gdshader`. Combat VFX includes in `game/shaders/`. URP HLSL lives in `samples/_quarantine` only.

## Animation trees

### Operator (third person)

```
Locomotion (blend 2D: speed × strafe)
  ├ Walk / Run / TacSprint
  ├ Crouch loc
  ├ Slide (root motion 0.45 s)
  ├ Jump / Fall / Land
  └ Mantle (root motion)
Additive: hit react, grenade throw, ability
Overlay: reload, fire, ADS (upper body)
Death: 4 dirs + explosive
```

### First person (arms + weapon)

```
Idle → Fire loop (per RPM)
     → ADS in/out (weapon-specific curve)
     → Reload (mag / empty)
     → Sprint (bob)
     → Slide / dive
     → Inspect (HQ + long-idle)
```

IK: left hand on magwell/grip (markers). Recoil: procedural pitch/yaw on weapon bone + camera.

### Sentry / drones / juggernaut

Separate controllers. Juggernaut uses heavy locomotion set (shared Golem scale 1.08).

Anim budget: 60 fps desktop, 30 fps distant LOD3 characters.
