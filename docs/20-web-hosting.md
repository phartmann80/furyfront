# Web hosting — Fury Front PC Web V0.1

Primary runtime: **Godot 4 web export**, Compatibility renderer (`gl_compatibility`).
Threading: **off** (`variant/thread_support=false`). Template: `web_nothreads_release.zip`.

## Headers (required)

| Header | Value | Why |
| --- | --- | --- |
| `Content-Type` `.wasm` | `application/wasm` | Browser instantiate |
| `Content-Type` `.js` | `application/javascript` | Engine loader |
| `Content-Type` `.pck` | `application/octet-stream` | Game pack |
| `Cache-Control` `index.html` | `no-cache` | Versioning |
| `Cache-Control` wasm/pck | `public, max-age=3600` | CDN-friendly; bump filename on release |

## Headers (NOT required for V0.1)

Threaded Godot web is **disabled**. Do **not** need:

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

If threads are enabled later, those two are **mandatory** (SharedArrayBuffer) and a generic static host will fail silently. Template would switch to `web_release.zip`.

## Compression

Serve brotli or gzip for `.wasm` and `.js` if the host supports precompressed files. V0.1 server gzips on the fly when Node zlib is available.

## CDN

Any HTTPS static origin works: S3+CloudFront, Cloudflare Pages, nginx. Set wasm MIME. Do not use file://.

## Versioning

Export to `export/web/` as `index.*`. Production should stamp `index-<gitsha>.pck` later.

## Local preview

```
node scripts/serve-web.mjs
```

Opens `http://127.0.0.1:8088/`

## Web compatibility audit (Godot project)

| System | Verdict |
| --- | --- |
| Renderer | `gl_compatibility` — required for web |
| Shaders | `muzzle_flash.gdshader` is GLES3-safe (unshaded); VFX currently uses lights/quads, not that shader |
| Particles | No GPUParticles3D; smoke is a translucent sphere |
| Textures | Procedural / default; S3TC+ETC2 import flags on |
| Audio | Procedural WAV; unlock after click (browser autoplay) |
| Navigation | NavigationRegion3D + NavigationAgent3D; **avoidance off on web** |
| Input | Pointer lock after Start click; WASD/mouse primary; touch kept |
| Physics | GodotPhysics3D — OK |
| Networking | Stub only; future must be browser-capable |
| Save / FileAccess | `res://` JSON only; no user:// required for V0.1 |
| Threads | Export unthreaded |
| GDExtensions / plugins | None |
| Decals | Not used (Compatibility) |
| Glow | Disabled (Compatibility cost) |


## Headers (required)

| Header | Value | Why |
| --- | --- | --- |
| `Content-Type` `.wasm` | `application/wasm` | Browser instantiate |
| `Content-Type` `.js` | `application/javascript` | Engine loader |
| `Content-Type` `.pck` | `application/octet-stream` | Game pack |
| `Cache-Control` `index.html` | `no-cache` | Versioning |
| `Cache-Control` wasm/pck | `public, max-age=3600` | CDN-friendly; bump filename on release |

## Headers (NOT required for V0.1)

Threaded Godot web is **disabled**. Do **not** need:

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

If threads are enabled later, those two are **mandatory** (SharedArrayBuffer) and a generic static host will fail silently.

## Compression

Serve brotli or gzip for `.wasm` and `.js` if the host supports precompressed files. V0.1 server gzips on the fly when Node zlib is available.

## CDN

Any HTTPS static origin works: S3+CloudFront, Cloudflare Pages, nginx. Set wasm MIME. Do not use file://.

## Versioning

Export to `export/web/` as `index.*`. Production should stamp `index-<gitsha>.pck` later.

## Local preview

```
node scripts/serve-web.mjs
```

Opens `http://127.0.0.1:8088/`
