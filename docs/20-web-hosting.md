# Web hosting — Fury Front PC Web V0.1

**Domain:** [furyfront.app](https://furyfront.app)  
**Infrastructure:** our own HTTPS server — not Vercel/Netlify-dependent.

Primary runtime: **Godot 4 web export**, Compatibility renderer (`gl_compatibility`).  
Threading: **off** (`variant/thread_support=false`). Template: `web_nothreads_release.zip`.

## Site vs game

| Path | Layer |
| --- | --- |
| `/` | Fury Front website — hero cinematic, PLAY button |
| `/play/` | Godot Web game — Ironfall Depot V0.1 |
| `/health` | JSON health + build version |

Do not embed marketing website UI inside the Godot runtime.

## Headers (required)

| Header | Value | Why |
| --- | --- | --- |
| `Content-Type` `.wasm` | `application/wasm` | Browser instantiate |
| `Content-Type` `.js` | `application/javascript` | Engine loader |
| `Content-Type` `.pck` | `application/octet-stream` | Game pack |
| `Content-Type` `.mp4` | `video/mp4` via `/etc/nginx/mime.types` | Hero cinematic. Do **not** redeclare `mp4` under `location /media/` (duplicate extension warning). |
| `Cache-Control` `index.html` | `no-cache` | Versioning |
| `Cache-Control` wasm/pck/js (versioned) | `public, max-age=31536000, immutable` | Only for `/play/index.<commit>.*` |
| `Cache-Control` `/health`, `version.json` | `no-cache, must-revalidate` | Commit + deployedAt |
| `Cache-Control` hero video | `public, max-age=31536000, immutable` | Stable cinematic |
| `X-Content-Type-Options` | `nosniff` | Security |
| `Accept-Ranges` | `bytes` | Video streaming |

## Headers (NOT required for V0.1)

Threaded Godot web is **disabled**. Do **not** need COOP/COEP unless threads are enabled later.

## Compression

gzip for `.wasm`, `.js`, `.css`, `.html` via Node server or nginx. Brotli optional in nginx.

## Deployment

```
node scripts/validate.mjs
godot --headless --path game --export-release Web export/web/index.html
node scripts/build-deploy.mjs
# rsync dist/furyfront/ → production /var/www/furyfront/releases/<commit>
```

See `docs/21-server-architecture.md` and `deploy/nginx/furyfront.app.conf`.

## Local preview

```bash
node scripts/build-deploy.mjs
node scripts/serve-furyfront.mjs
```

- Site: `http://127.0.0.1:8080/`
- Game: `http://127.0.0.1:8080/play/`
- Health: `http://127.0.0.1:8080/health`

Legacy game-only preview: `node scripts/serve-web.mjs` (port 8088).

## Web compatibility audit (Godot project)

| System | Verdict |
| --- | --- |
| Renderer | `gl_compatibility` — required for web |
| Shaders | `muzzle_flash.gdshader` is GLES3-safe |
| Particles | No GPUParticles3D |
| Textures | Procedural / default |
| Audio | Unlock after click (browser autoplay) |
| Navigation | NavigationAgent3D; **avoidance off on web** |
| Input | Pointer lock after Start; touch kept |
| Physics | GodotPhysics3D — OK |
| Networking | Stub; future must be browser-capable |
| Threads | Export unthreaded |
| GDExtensions | None |
| Decals | Not used (quad impacts) |
