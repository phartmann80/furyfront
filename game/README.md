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

V0.1 is a **graybox** FPS: primitives, procedural audio, Operation: Broken Perimeter. It is not a finished game.

Hosting headers: `docs/20-web-hosting.md`.
