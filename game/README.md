# Godot 4 runtime — Fury Front V0.1

Open `game/project.godot` in Godot **4.7.1** (Compatibility renderer for web parity).

```
cd game
# Editor
godot project.godot

# Headless combat tests (after editor imports once)
godot --headless --path . --script res://tests/run_tests.gd

# Web export (unthreaded)
godot --headless --path . --export-release Web ../export/web/index.html
```

Preview (from repo root, after export):

```
node scripts/serve-web.mjs
```

Opens `http://127.0.0.1:8088/` with correct `application/wasm` MIME. Do not open `index.html` as `file://`.

Sync canonical JSON after data edits:

```
node ../scripts/sync-godot-data.mjs
node ../scripts/validate.mjs
```

Android/iOS native export is **not** this milestone. Touch controls remain in the project.

The Web export used to scan a leftover **Android** preset with `gradle_build/use_gradle_build=true`. That probe printed `Unable to open Android 'build-tools' directory` even though the shipped target is Web. The Android preset is removed from `export_presets.cfg`. Do **not** install the Android SDK to silence a Web build.

V0.1 is the accepted graybox FPS. Visual Benchmark 0.2 (`docs/24-visual-benchmark-02.md`) upgrades presentation without changing modes. Performance budgets: `docs/23-v02-performance-budget.md`.

Hosting headers: `docs/20-web-hosting.md`.
