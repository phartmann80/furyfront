# Vertical Slice 0.1 — engineering status

Date: 2026-08-16

**V0.1 is complete for engineering purposes.** Production commit **`000fc959a15e869d675cadf0be5b8bad2169aa03`** is accepted. Keep `/var/www/furyfront/releases/866893a` as the rollback point. Visual work continues in `docs/24-visual-benchmark-02.md`.

## Platform mandate

**PC web first.** Godot 4.7.1.stable, Compatibility renderer, unthreaded web export.

Landing page at `furyfront.app/` is **approved for this stage**. Final legal/footer/SEO polish is deferred — see `docs/22-backlog.md`. Primary work is the game at `/play/`.

## GitHub and production baseline

Before this stabilization branch, local `master`, `origin/master`, and live production were synchronized at:

**`866893a94e3cd33c9de33791430ea53d8c4cd5ad`** — `fix: center the play start title on the viewport`

- Remote: `https://github.com/phartmann80/furyfront.git`
- Production `/health` reported the same commit
- This branch does **not** deploy that work. Merge and production deploy wait on review.

Do not treat any other clone or untransferred patch as repository history. Commit `0488748` was never in this repo.

## Hosting (stable enough — stop unless the game needs it)

- Dedicated nginx vhost + Let's Encrypt for `furyfront.app` / `www.furyfront.app`
- Versioned release `866893a` at `/var/www/furyfront/releases/<commit>/`
- `/health` reports matching WASM / PCK / JS commit
- AtlasLM removed from this host; TuGPT workers preserved
- First orchestration script failed with **exit 2** because of Windows CRLF in the bash file (`set: pipefail` invalid). No server changes that run. Re-uploaded LF and completed.

## What is true in-engine (this pass)

- FPS controller: ground accel/decel, air control, smoothed crouch, sprint FOV, light bob, landing dip, vault
- KF-16: rifle+arms viewmodel, separate recoil offset with recovery, sway, fire punch, empty mag click rate-limit, muzzle smoke/shells (not Low)
- Ironfall: hollow interiors, vehicle yard, underground hall, tagged cover
- Shadowbreakers: investigate gunfire, occupy far side of cover, flank via lateral cover, hackers push servers, phantoms guard hackers
- Allies: follow the operator, shoot Shadowbreakers, and use `collision_layer = 0` so they do not body-block
- MissionDirector: phase changes from enemy/objective events; extraction countdown; HUD briefing line
- Full Broken Perimeter playthrough still needs a **manual** browser pass (pointer lock)

## V0.1 stabilization (this branch)

Recreated on `fix/v01-broken-perimeter-stabilization` from `866893a`. Not production until approved.

1. **Respawn vs restart.** `GameState.reset_life()` restores health/armor only. Kills, mission clock, success, and `mission_over` survive death. `reset_run()` is the full restart used at operation start and Return to Start.
2. **No fake grenades.** The "Shadowbreaker grenade!" notify is gone. Enemy grenade entities are not in V0.1.
3. **Results freeze.** Mission end pauses the SceneTree, sets Results to `PROCESS_MODE_ALWAYS`, releases pointer lock, and uses pause-aware `create_timer(..., false)` so reload/fuse/respawn/cleanup cannot resolve behind the screen.
4. **Nav repath throttle.** Enforcer chase and Phantom/Hacker guard paths queue `NavigationAgent3D` targets on a 0.28–0.40 s staggered cooldown instead of every physics frame.
5. **Comms hint is one-shot.** Engineer radio uses `_comms_hint_played` after 8 s, not an `elapsed > 8 && elapsed < 8.05` window.
6. **CI.** `.github/workflows/ci.yml` runs data validation, shared combat math, Godot 4.7.1 import, `tests/run_tests.gd`, and `tests/mission_slice.tscn`.

## Remaining gameplay blockers

1. Manual playtest of the full mission on HTTPS `/play/` (still open; blockers outrank 0.2 art)
2. Measure combat FPS / memory on a gaming PC (not empty spawn)
3. Production GLB for Assault / arms / KF-16 / Phantom waits on Visual Benchmark 0.2 approval and Meshy credit confirmation
4. AI cover uses crate positions; no lean/peek animation
