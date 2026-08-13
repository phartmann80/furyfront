# Fury Front

Fast, cinematic, multiplayer-ready FPS. **Godot 4** combat runtime. **Android native APK is the first product.** iOS, desktop, and web are secondary. The combat client is not a React/Capacitor/Cordova wrapper.

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
4. **Android 60 FPS** on supported hardware is the benchmark. 120 FPS is optional Ultra only. Web does not dictate Android graphics.
5. **Server will be truth** when online. V0.1 is offline/local with the same combat functions.
6. **No pay-to-win.** Cosmetics fund the game. Shop/Pass/crates are documented, not implemented in V0.1.

## Locked stack

| Layer | Choice |
| --- | --- |
| Game client | Godot 4.x, Mobile renderer (Vulkan) on Android, Forward+ on high desktop, Compatibility fallback for web |
| Android | Native export APK (priority 1) |
| iOS | Native export (priority 2) |
| Desktop | Native (editor + Windows/Linux/macOS) |
| Web | Secondary; capability-selected, Compatibility renderer |
| Companion / HQ web | Optional later — accounts, admin, marketing. **Not combat.** |
| Game servers | Godot dedicated / headless later. Not in V0.1. |
| Backend | TypeScript stubs (`packages/server`) — matchmaking after combat loop |
| Content | V0.1 ships in the APK. Future: PCK packs + CDN. No Unity Addressables. |

Rejected: Unity 6, Unreal as primary, Capacitor/Cordova combat wrappers, WebGPU-as-baseline.

## Vertical Slice 0.1

Install on Android → Ironfall Depot → control a Fury Front assault operator → fire the **KF-16** (plus WASP-9, K5 sidearm, knife) → fight Shadowbreaker AI → complete **Operation: Broken Perimeter**.

Do not expand to 27 weapons, 12 operators, 8 maps, BR, store, ranked, or full matchmaking until that loop is good.

```
Godot boots → Android config → FPS move → mobile controls → KF-16
→ damage → Shadowbreaker AI → Ironfall graybox → Base Defense
→ HUD → VFX/audio → optimize → APK
```

## Repository map

```
data/                      Canonical JSON (weapons, maps, factions, missions)
docs/                      GDD, netcode (future), UI, audio
game/                      Godot 4 project (the runtime)
packages/shared            TS combat/XP/economy + CI
packages/server            Matchmaking stubs (not wired)
scripts/validate.mjs       Canonical data CI
scripts/sync-godot-data.mjs
samples/_quarantine        Unity / Unreal / URP samples (not used)
mockups/                   HTML HUD/HQ references
```

## Design invariants (prototype)

- Health 100. Armor is a separate absorb pool; mode rules may differ later (MP vs Recon Protocol).
- Input is abstracted: touch is first-class; keyboard/mouse is for editor testing.
- One weapon definition feeds HUD, FPS, AI, and future netcode.

See `docs/01-game-design-document.md`, `docs/11-technical-architecture.md`, `docs/17-vertical-slice-01.md`.
