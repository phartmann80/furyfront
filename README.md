# Fury Front

Fast, cinematic, multiplayer-ready FPS. **Godot 4** combat runtime. **PC web is the first product.** Desktop packaging, then Android/iOS packaged or wrapped clients, come after the browser vertical slice. The combat client is not a React/Three.js/Capacitor shooter.

Canonical numbers live in `data/`. Combat math, XP, and economy rules live in `packages/shared`. Godot loads the same JSON through `ContentCatalog`. Do not fork stats into scripts.

## Factions

| Side | Name |
| --- | --- |
| Friendly | **Fury Front** |
| Enemy | **Shadowbreakers** |

Shadowbreakers are elite human / human-enhanced infiltrators (stealth, EW, drones, hacking, sabotage, dimensional breach tech, squad tactics). They are **not** zombies, undead, or monsters.

## Pillars

1. **Base Defense** is the signature mode. Vertical Slice 0.1 is **Operation: Broken Perimeter** on **Ironfall Depot**.
2. **BALANCE_TARGET_V0:** AR chest TTK ~180–320 ms at 10 m (100 HP, no armor). Guardrail for tests, not a frozen live-ops law.
3. Readable fights: distinct silhouettes, muzzle/impact language, cover and elevation.
4. **PC web 60 FPS at 1080p** on reasonable gaming PCs is the benchmark. High / Medium / Low quality settings scale shadows, particles, and 3D resolution. A pretty scene at 18 FPS is not a shippable build.
5. **Server will be truth** when online. V0.1 is offline/local vs Shadowbreaker AI, with the same combat functions. Future netcode must work from the browser (not native-only transports).
6. **No pay-to-win.** Cosmetics fund the game. Shop/Pass/crates are documented, not implemented in V0.1.

## Locked stack

| Layer | Choice |
| --- | --- |
| Game client | Godot 4.x, **Compatibility (`gl_compatibility`)** as the production renderer for web |
| PC Web | **Priority 1** — Godot web export, HTTPS static host |
| Desktop | Native packaging later if useful |
| Android | Packaged/wrapped web or native Godot export after Web V0.1 (spike, not now) |
| iOS | Same as Android, after web is proven |
| Companion / HQ web | Optional later — accounts, admin, marketing. **Not combat.** |
| Game servers | Godot dedicated / headless later. Not in V0.1. |
| Backend | TypeScript stubs (`packages/server`) — matchmaking after combat loop |
| Content | V0.1 ships in the web PCK. Future: streamed packs + CDN. No Unity Addressables. |

Rejected: Unity 6, Unreal as primary, Capacitor/Cordova/React/Three.js combat wrappers, WebGPU-as-baseline.

## Platform order

1. PC Web (this milestone)
2. Desktop packaging
3. Android packaged/wrapped client
4. iOS packaged/wrapped client

Do not spend this milestone on Android SDK/build-tools. Touch HUD and mobile input stay in the project; they are not the V0.1 acceptance path.

## Vertical Slice 0.1

Open a URL → start screen → Start Operation: Broken Perimeter → Ironfall Depot → WASD / mouse FPS → fire the **KF-16** (plus WASP-9, K5 sidearm, knife) → fight Shadowbreaker AI → complete or fail the mission → results screen.

```
Godot web export → HTTPS (or local MIME-correct server)
→ start screen (click unlocks audio + pointer lock)
→ Ironfall graybox → KF-16 → Shadowbreaker AI → Base Defense → results
```

## Repository map

```
data/                      Canonical JSON (weapons, maps, factions, missions)
docs/                      GDD, netcode (future), UI, audio, web hosting
game/                      Godot 4 project (the runtime)
packages/shared            TS combat/XP/economy + CI
packages/server            Matchmaking stubs (not wired)
scripts/validate.mjs       Canonical data CI
scripts/sync-godot-data.mjs
scripts/serve-web.mjs      Local web preview (wasm MIME)
samples/_quarantine        Unity / Unreal / URP samples (not used)
mockups/                   HTML HUD/HQ references
```

## Design invariants (prototype)

- Health 100. Armor is a separate absorb pool; mode rules may differ later (MP vs Recon Protocol).
- Input is abstracted: keyboard/mouse is the PC-web benchmark; touch remains for future mobile clients.
- One weapon definition feeds HUD, FPS, AI, and future netcode.

See `docs/01-game-design-document.md`, `docs/11-technical-architecture.md`, `docs/17-vertical-slice-01.md`, `docs/20-web-hosting.md`.
