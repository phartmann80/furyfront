# FuryFront — Game Design Document

**Version:** 1.1.0  
**Engine:** Godot 4.x  
**Source of truth for numbers:** `/data/*.json`

## 1. High concept

Fury Front is a high-intensity military FPS. Fury Front soldiers defend installations and contest objectives against **Shadowbreakers** — elite infiltrators using stealth, electronic warfare, drones, hacking, sabotage, and dimensional breach technology.

Not sci-fi power armor. Not mil-sim slow. **Not zombies, undead, or monsters.**

**Signature mode:** Base Defense.  
**Vertical Slice 0.1:** Operation: Broken Perimeter — Ironfall Depot.

## 2. Factions

| ID | Name | Role |
| --- | --- | --- |
| `faction_fury_front` | Fury Front | Player / allied military |
| `faction_shadowbreakers` | Shadowbreakers | Enemy infiltrators |

## 3. Target platforms

Priority: **PC web → desktop packaging → Android packaged/wrapped → iOS packaged/wrapped.**

| Tier | Hardware | Target | Notes |
| --- | --- | --- | --- |
| High | Gaming PC browser | 60 FPS at 1080p | Full shadows/particles, native 3D scale |
| Medium | Typical PC browser (default web) | 60 FPS | Reduced particles, 0.85 3D scale |
| Low | Constrained GPU / integrated | 60 if possible | No shadows, 0.7 3D scale, fewer decals |

120 FPS is **not** the baseline. WebGPU is **not** assumed. Production web uses Compatibility (`gl_compatibility`). Mobile native/wrapper comes after Web V0.1 is stable.

## 4. Combat model

| Rule | V0.1 |
| --- | --- |
| Base health | 100 |
| Armor | Separate absorb plates; not extra HP |
| Hitscan | KF-16, WASP-9, K5 |
| Melee | Combat knife |
| Head / limb | From weapon JSON |
| TTK | `BALANCE_TARGET_V0` in `data/balance.json` |

`BALANCE_TARGET_V0` AR chest TTK 180–320 ms at 10 m is a **prototype guardrail**. Playtests can change it. CI still fails **one-frame lethal ARs** (TTK < 50 ms) and inverted damage curves.

Armor rules are **mode-scoped**. Do not assume MP plates equal Recon Protocol / Eclipse Zone.

## 5. Modes (canonical — most are future)

| Mode | Status | Notes |
| --- | --- | --- |
| **Base Defense / Shadow Assault** | V0.1 | Operation: Broken Perimeter |
| Strikeout 5v5 | Future MP | |
| Control Grid | Future MP | |
| Data Harvest | Future MP | |
| Team Deathmatch | Future MP | |
| Search & Destroy | Future MP | |
| Domination | Future MP | |
| DMZ: Recon Protocol | Future | Obsidian Reef, Sector 9 |
| Battle Royale | Future | Eclipse Zone |
| Ranked | Future | No pay-to-win |

**Zombie Horde does not exist.** Removed from data, GDD, UI, and roadmap.

## 6. Canonical environments

| Map | Use |
| --- | --- |
| **Ironfall Depot** | V0.1 Base Defense graybox / production target |
| Crimson Alley | Future MP |
| Skyforge Outpost | Future MP |
| Obsidian Reef | Recon Protocol |
| Sector 9 | Recon Protocol |
| Eclipse Zone | BR (Ashen Plains, Crystal Wastes, Titan Ridge, Neon Ruins, Verdant Sink, Rift Core) |

**Black Harbor, Ironroot, Solstice, Kiln, Afterlight, Whiteveil, Sprawl, Ridgeback** were pre-lock concept names. They are **not** shipping locations. Black Harbor was never an engine map in this repo (docs-only). Ironfall Depot is the only V0.1 space.

## 7. V0.1 content lock

- 1 operator: **Vex** (Assault)
- 3 Shadowbreaker archetypes: Phantom Infiltrator, Signal Hacker, Heavy Enforcer
- Weapons: KF-16, WASP-9, K5 Compact (sidearm), Combat Knife
- 1 map: Ironfall Depot
- 1 mission: Operation: Broken Perimeter
- No shop, battle pass, crates, 125-level implementation, or matchmaking

## 8. Tone

Mature combat. No sexual content. No real-world national armies as named factions.

## 9. Document index

| Doc | Contents |
| --- | --- |
| `02-maps.md` | Canonical locations + Ironfall layout |
| `03-operators.md` | Roster (Vex is V0.1) |
| `04-weapons.md` | Classes; runtime uses JSON |
| `06-game-modes.md` | Modes including Shadow Assault |
| `09-economy.md` | No P2W; shop not in V0.1 |
| `10-multiplayer-architecture.md` | Future authority model |
| `11-technical-architecture.md` | Godot 4 / PC web first |
| `17-vertical-slice-01.md` | Broken Perimeter beat sheet |
| `18-content-packs.md` | Installed vs future PCK |
| `20-web-hosting.md` | Wasm MIME, headers, unthreaded export |
