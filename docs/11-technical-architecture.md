# Technical Architecture

## 1. Decision: Godot 4 is the game runtime

Unity 6, Unreal, Unity Addressables, Unity Mobile Export, Unreal packaging, and Capacitor/Cordova combat wrappers are **rejected**.

| Option | Verdict |
| --- | --- |
| Godot 4.x native Android (Mobile / Vulkan) | **Primary.** V0.1 target. |
| Godot iOS export | Priority 2 |
| Godot desktop | Editor + playtest |
| Godot web (Compatibility renderer) | Secondary, capability-selected |
| Capacitor / Cordova / React combat client | Forbidden for the FPS loop |
| Unity 6 URP | Quarantined (`samples/_quarantine`) |
| Unreal Pixel Streaming | Rejected as web combat client |

### Export order

1. Android APK  
2. iOS  
3. Desktop  
4. Web where technically appropriate  

Do not let web memory/shader limits shrink Android quality.

## 2. Graphics capability tiers

Applied at boot from device class (RAM, GPU, refresh). Override in debug.

| Tier | Shadows | Particles | Reflections | Res | FPS target |
| --- | --- | --- | --- | --- | --- |
| Ultra | High | High | SSR/probes | Native | 60, optional 120 |
| High | Medium | Medium | Probes | Dynamic 0.85–1.0 | 60 |
| Medium | Low / baked bias | Low | Off/cubemap | Dynamic 0.7–0.9 | 60 if sustainable |
| Low | Off or blob | Minimal | Off | 0.6–0.75 | 30–60 adaptive |

Renderer:

- Android: **Mobile** (`rendering_method.mobile`)
- Desktop editor Ultra: **Forward+** allowed for art review; ship Android on Mobile
- Web: **gl_compatibility** fallback; never assume WebGPU

## 3. Client topology (V0.1)

```
Godot Android APK
  InputService (touch first, kb/mouse editor)
  PlayerMotor + WeaponController
  CombatMath (from data/*.json via ContentCatalog)
  Shadowbreaker AI + NavigationRegion3D
  MissionDirector (Broken Perimeter)
  HUD
```

Online later:

```
Client predicts move/fire  →  dedicated Godot/headless validates
Snapshot interpolation     →  server owns HP, kills, objectives, results
```

V0.1 is **offline**. Interfaces for `NetSession`, `HitConfirm`, `MatchState` exist as stubs so we do not paint into a corner.

## 4. Canonical data pipeline

```
data/*.json
  → node scripts/validate.mjs
  → node scripts/sync-godot-data.mjs
  → game/resources/balance/*.json
  → ContentCatalog (autoload)
  → WeaponDefinition / EnemyProfile / MissionDefinition
```

Godot Scripts **must not** hardcode KF-16 damage/RPM. `packages/shared` TypeScript mirrors the same formulas for CI.

## 5. Content packing (not Addressables)

V0.1: everything for Ironfall + four weapons + three enemies is **installed in the APK**.

Later production:

| Pack | Delivery |
| --- | --- |
| Core | Installed |
| Map PCK | Streamed / DLC |
| Operators / weapons | Cached packs |
| Audio / cinematics | Optional |
| Cosmetics / seasonal | Optional, never required to boot combat |

See `docs/18-content-packs.md`.

## 6. Android

- Landscape, immersive, touch HUD always present on `DisplayServer.is_touchscreen_available()` or `OS.has_feature("mobile")`.
- Target API documented in `game/export_presets.cfg`.
- 64-bit ARM. Vulkan with GLES3 Compatibility fallback only if a device fails Mobile renderer (export flavor later).

## 7. Networking (after V0.1 combat)

Headless Linux Godot build, 30 Hz sim, rewind window 120/180 ms, client never authors damage. Matchmaking stays in `packages/server` until the FPS loop is proven.

Simulated latency tests (30 / 80 / 150 ms, loss, jitter) are a **gate for calling netcode done**, not a V0.1 deliverable.

## 8. Godot folder conventions

See `game/` — `scripts/` is split by domain (`core`, `player`, `combat`, `weapons`, `ai`, `objectives`, `input`, `ui`, …). No giant Scripts dump. Autoloads listed in `docs/17-vertical-slice-01.md`.
