# Vertical Slice 0.1 — engineering status

Date: 2026-08-14

## Platform mandate

**PC web first.** Godot 4.7.1.stable, Compatibility renderer, unthreaded web export.

Landing page at `furyfront.app/` is **approved for this stage**. Final legal/footer/SEO polish is deferred — see `docs/22-backlog.md`. Primary work is the game at `/play/`.

## Hosting (stable enough — stop unless the game needs it)

- Dedicated nginx vhost + Let's Encrypt for `furyfront.app` / `www.furyfront.app`
- Versioned release `d63bfbf` at `/var/www/furyfront/releases/<commit>/`
- `/health` reports matching WASM / PCK / JS commit
- AtlasLM removed from this host; TuGPT workers preserved
- First orchestration script failed with **exit 2** because of Windows CRLF in the bash file (`set: pipefail` invalid). No server changes that run. Re-uploaded LF and completed.

## What is true in-engine (this pass)

- FPS controller: ground accel/decel, air control, smoothed crouch, sprint FOV, light bob, landing dip, vault
- KF-16: rifle+arms viewmodel, separate recoil offset with recovery, sway, fire punch, empty mag click rate-limit, muzzle smoke/shells (not Low)
- Ironfall: hollow interiors, vehicle yard, underground hall, tagged cover
- Shadowbreakers: investigate gunfire, occupy far side of cover, flank via lateral cover, hackers push servers, phantoms guard hackers
- MissionDirector: phase changes from enemy/objective events; extraction countdown; HUD briefing line
- Full Broken Perimeter playthrough still needs a **manual** browser pass (pointer lock)

## Remaining gameplay blockers

1. Manual playtest of the full mission on HTTPS `/play/`
2. Measure combat FPS / memory on a gaming PC (not empty spawn)
3. KF-16 is still CSG boxes — readable, not production art
4. AI cover uses crate positions; no lean/peek animation
5. Allies still follow the player and do not fight
