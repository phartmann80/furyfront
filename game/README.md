# Godot 4 runtime — Fury Front V0.1

Open `game/project.godot` in Godot 4.3 or newer (Mobile renderer).

```
cd game
# Editor
godot project.godot

# Headless combat tests (after editor imports once)
godot --headless --path . --script res://tests/run_tests.gd
```

Sync canonical JSON after data edits:

```
node ../scripts/sync-godot-data.mjs
node ../scripts/validate.mjs
```

Android: Editor → Editor Settings → Export → Android (SDK, JDK, debug keystore), then Export → Android. APK writes to `export/android/` (gitignored).

V0.1 is a **graybox** FPS: primitives, procedural audio, Operation: Broken Perimeter. It is not a finished game.
