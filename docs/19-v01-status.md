# Vertical Slice 0.1 — engineering status

Date: 2026-08-13

## What is true

Godot 4.7.1 **boots** the Ironfall Depot graybox headless with Mobile renderer. Canonical JSON validates. Combat math tests pass. **An Android APK was not produced** on this machine (Android build-tools directory missing). Do not treat this as a completed phone install.

## Report

1. **Godot version:** 4.7.1.stable.official.a13da4feb
2. **Renderer:** `mobile` (project default). Web fallback `gl_compatibility`. Desktop editor may still use Mobile for Android parity.
3. **Repository status:** Godot project under `game/`. Unity/Unreal/URP samples quarantined in `samples/_quarantine/`.
4. **Branch:** recorded at commit time (see git).
5. **Commit hash:** recorded at commit time.
6. **Project structure:** `game/scripts/{core,player,combat,weapons,ai,objectives,input,audio,persistence,networking,ui,vfx,maps}` + `scenes/bootstrap` + `resources/balance` (synced JSON) + `tests` + `shaders`.
7. **Autoloads:** EventBus, ContentCatalog, GameState, GraphicsProfile, InputService, AudioDirector, VfxBus
8. **Input Map:** registered at runtime (`move_*`, `fire`, `ads`, `reload`, `sprint`, `crouch`, `jump`, `weapon_next`, `grenade`, `tactical`, `interact`, `debug_reset`). Touch HUD duplicates all combat buttons.
9. **Android export status:** **Blocked.** Godot: `Unable to open Android 'build-tools' directory.` Preset exists (`game/export_presets.cfg`, `com.furyfront.game`, arm64-v8a).
10. **Player controller:** CharacterBody3D walk/sprint/crouch/jump/vault ray/ADS/hip fire/reload/switch/grenade/tactical/interact/damage/death/debug reset.
11. **Mobile controls:** left stick, right look zone, Fire, ADS, Reload, Sprint, Crouch, Jump, Frag, Tac, Wpn, Use. Always-on for `mobile` feature.
12. **KF-16:** loaded from `weapons.json` via ContentCatalog. WASP-9, K5, knife on the same manager. No duplicated RPM/damage in Mono-style scripts.
13. **Damage:** CombatMath + HealthComponent (HP 100, separate armor plates). Head/limb/falloff/RPM gate.
14. **Shadowbreaker AI:** Phantom / Hacker / Enforcer / Commander. States patrol→suspicious→investigate→engage (cover/reposition/flank/fire/objective)→search/retreat. Vision cone + LOS + hearing. No magically known player position. Skill profiles recruit/trained/veteran/elite.
15. **Navigation:** NavigationRegion3D + NavigationAgent3D + collider bake (deferred). Direct-seek fallback if mesh empty.
16. **Ironfall Depot:** procedural graybox (not a production art map). Areas: gate, command, barracks, armory, comms, server, yard, watchtower, maintenance, underground ramp, extraction. **Not Black Harbor.**
17. **Base Defense:** MissionDirector runs Operation: Broken Perimeter beats including cinematic overlay, integrity, data transfer, restore interact, extraction, commander.
18. **HUD:** health/armor, ammo, objective, integrity, transfer, extraction lock, squad line, crosshair, hitmarker, interact prompt.
19. **Audio/VFX:** procedural gunshot/reload/impact/explosion/alarm/radio; muzzle light, tracer, decal, smoke, explosion light, breach notify. Placeholders — provenance in `game/assets/PROVENANCE.md`.
20. **Tests:** `node scripts/validate.mjs` OK. `godot --headless --script res://tests/run_tests.gd` OK (KF-16 10 m damage, head, armor, RPM).
21. **APK result:** not built.
22. **APK size:** n/a
23. **FPS / frame time on device:** n/a (no APK). Headless boot on the editor PC succeeded (~3 s quit-after, Mobile renderer).
24. **Memory on device:** n/a
25. **Blockers:** Android SDK build-tools + debug keystore + export templates; real operator/weapon meshes; navmesh quality; dedicated server not started (intentionally).
26. **Canonical migration:** `data/*.json` → `scripts/sync-godot-data.mjs` → `game/resources/balance/*.json` → ContentCatalog. Factions locked. Zombie Horde removed. Maps replaced with Ironfall / Crimson Alley / Skyforge / Obsidian Reef / Sector 9 / Eclipse Zone.

## Quarantine (not deleted)

`samples/_quarantine/unity`, `shaders` (URP), `unreal`.
