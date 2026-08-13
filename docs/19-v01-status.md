# Vertical Slice 0.1 — engineering status

Date: 2026-08-13 (updated for PC web retarget)

## Platform mandate

**PC web first.** Android APK milestone cancelled for this slice. One Godot gameplay project; touch/mobile input retained for future wrapped/native clients.

## What is true

- Godot **4.7.1.stable** exports a **Web** build (`export/web/`) with Compatibility renderer.
- Canonical JSON validates. Godot headless combat tests pass.
- Local preview: `node scripts/serve-web.mjs` → `http://127.0.0.1:8088/`
- Foundation checkpoint commit: `60ceb13`. Web retarget in follow-up commit.

## Web export artifacts (release, unthreaded)

| File | Raw size |
| --- | ---: |
| `index.wasm` | 39.5 MB |
| `index.pck` | 122 KB |
| `index.js` | 273 KB |
| `index.html` + worklets + icons | ~55 KB |
| **Total on disk** | **~40.0 MB** |
| **gzip (wasm+js+pck+html+worklets)** | **~10.3 MB** |

Initial download is **not** multi-gigabyte. PCK is tiny because V0.1 is procedural graybox + JSON + compiled scripts.

## Browser boot (Playwright smoke)

- Godot boot OK, WebGL2 / GLES3 Compatibility
- Console: `single-threaded, no GDExtension support`
- Start menu renders (title, quality, START OPERATION)
- **Full mission playthrough** not automated end-to-end in CI yet — use manual browser QA for pointer-lock FPS loop

## Remaining before calling Web V0.1 done

1. Manual playtest: start → Ironfall → WASD/mouse → KF-16 → AI → mission results
2. FPS/memory on target gaming PC hardware
3. HTTPS deploy (Cloudflare Pages / nginx / S3+CloudFront)
4. Art pass (arms, KF-16, enemy silhouettes) without breaking 60 FPS budget

## Git

- Remote: **none configured**
- Branch: `master`
- Foundation: `60ceb13`
- Web retarget: see latest commit after this doc update
