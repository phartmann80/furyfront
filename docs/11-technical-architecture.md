# Technical Architecture

## 1. Decision: Godot 4 is the game runtime

Unity 6, Unreal, Unity Addressables, Unity Mobile Export, Unreal packaging, and Capacitor/Cordova/React/Three.js combat wrappers are **rejected**.

| Option | Verdict |
| --- | --- |
| Godot 4.x web (Compatibility / GLES3) | **Primary.** V0.1 target. |
| Godot desktop | Later packaging if useful |
| Godot native Android / iOS | Fallback after a web-wrapper spike |
| Web wrapper (WebView hosting the same export) | Spike after Web V0.1 — do not implement now |
| Capacitor / Cordova / React combat client | Forbidden for the FPS loop |
| Unity 6 URP | Quarantined (`samples/_quarantine`) |
| Unreal Pixel Streaming | Rejected as web combat client |

### Export order

1. PC Web  
2. Desktop  
3. Android (wrapper or native — decide after spike)  
4. iOS (same)  

One Godot gameplay project. Do not fork a second combat codebase for mobile.

## 2. Graphics capability tiers

Applied at boot (web defaults Medium). Player can pick High / Medium / Low on the start screen.

| Tier | Shadows | Particles | 3D scale | FPS target |
| --- | --- | --- | --- | --- |
| High | On | Full | 1.0 | 60 at 1080p |
| Medium | On | Reduced | 0.85 | 60 |
| Low | Off | Minimal | 0.7 | 60 if possible |

Renderer:

- Web (production): **`gl_compatibility`**
- Android later: **Mobile** (`rendering_method.mobile`)
- Desktop editor: Compatibility for web parity; Forward+ only for art review, not the ship path

Never assume WebGPU. Decal nodes are not used (quad impacts instead). Glow is off (Compatibility cost).

## 3. Client topology (V0.1)

```
furyfront.app/              Website — hero cinematic, PLAY FURY FRONT
furyfront.app/play/         Godot Web (index.html + wasm + pck)
  StartMenu (click → audio unlock + pointer lock)
  InputService (WASD/mouse primary, touch kept)
  PlayerMotor + WeaponController
  CombatMath (from data/*.json via ContentCatalog)
  Shadowbreaker AI + NavigationRegion3D
  MissionDirector (Broken Perimeter)
  HUD + ResultsScreen
```

**Infrastructure lock:** our own HTTPS server at `furyfront.app`. Vercel/Netlify are not production requirements.

See `docs/21-server-architecture.md` for deployment pipeline, health endpoint, and future multiplayer gateway.

Online later:

```
Browser client  →  WebSocket / WebRTC (evaluate before picking)
Dedicated Godot/headless validates HP, kills, objectives
Do not choose a transport that cannot run from the browser
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

V0.1: Ironfall + four weapons + four enemy archetypes live in the **web PCK**. Keep the first download far below the old 3–8 GB client assumption.

Later production:

| Pack | Delivery |
| --- | --- |
| Core wasm + boot PCK | Initial HTTPS download |
| Map PCK | Streamed / DLC |
| Operators / weapons | Cached packs |
| Audio / cinematics | Optional |
| Cosmetics / seasonal | Optional, never required to boot combat |

See `docs/18-content-packs.md` and `docs/20-web-hosting.md`.

## 6. Mobile (deferred)

Touch HUD and `InputService` stay. They are hidden unless `OS.has_feature("mobile")`.

After Web V0.1, spike **wrapper vs native Godot export**. Do not implement the wrapper now.

## 7. Networking (after V0.1 combat)

Browser-compatible transport first (WebSocket at minimum). Headless Linux Godot build, 30 Hz sim, rewind window 120/180 ms, client never authors damage. Matchmaking stays in `packages/server` until the FPS loop is proven.

Simulated latency tests (30 / 80 / 150 ms, loss, jitter) are a **gate for calling netcode done**, not a V0.1 deliverable.

## 8. Godot folder conventions

See `game/` — `scripts/` is split by domain (`core`, `player`, `combat`, `weapons`, `ai`, `objectives`, `input`, `ui`, …). No giant Scripts dump. Autoloads listed in `docs/17-vertical-slice-01.md`.
