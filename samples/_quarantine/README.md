# Quarantine — engine samples that are not the Fury Front runtime

**Do not use these folders for Vertical Slice 0.1.**

On 2026-08-13 the engine lock changed from Unity 6 / Unreal to **Godot 4**. The files below are preserved because they still document combat math, snapshot ideas, and VFX intent. They are **not** the game client.

## Affected (moved here)

| Path | Why quarantined |
| --- | --- |
| `unity/` | C# motor, hitreg, weapons, snapshots — Unity runtime rejected |
| `shaders/` | URP HLSL (`MuzzleFlash.shader`, `WetLitHint.shader`) — not Godot |
| `unreal/` | Verse / Blueprint notes — not the primary engine |

`samples/shaders/muzzle.glsl` intent was rewritten as `game/shaders/muzzle_flash.gdshader`.

## Still live

- `data/*.json` — canonical balance
- `packages/shared` — TypeScript combat/XP/economy for CI and future servers
- `packages/server` — matchmaking stubs (not wired in V0.1)
- `docs/` — updated to Godot 4 + Android-first
- `mockups/` — HUD/HQ HTML references

If you need a historical C# lag-compensation sketch, read `unity/LagCompensation.cs`. Production hit confirmation will be reimplemented in Godot (offline first, dedicated server later).
