# Fury Front — Server Architecture

**Domain:** [furyfront.app](https://furyfront.app)

## Infrastructure lock

Fury Front uses **our own server infrastructure**.

Vercel, Netlify, `.dls.so`, and other third-party frontend platforms are **not** required parts of the production architecture. They may be used for experiments only — never as the canonical delivery path.

## Primary topology (V0.1)

```
Godot 4 Game
  → Web Export
  → Our Server / HTTPS (furyfront.app)
  → PC Browser
```

### Layer separation

| Layer | Responsibility |
| --- | --- |
| **Website / hero** (`/`) | Marketing landing, cinematic hero, PLAY button |
| **Godot web game** (`/play/`) | Actual FPS runtime — no marketing UI inside Godot |
| **Server services** (future) | Auth, accounts, matchmaking, authoritative multiplayer |

The **player PC renders** all 3D, animation, VFX, HUD, and audio. The server does **not** stream rendered video.

## V0.1 server scope (implemented foundation)

| Requirement | Status |
| --- | --- |
| HTTPS | nginx TLS config provided; cert on production host |
| Godot web-build hosting | `/play/` from deploy bundle |
| WASM MIME | `application/wasm` |
| Compression | gzip in Node server; nginx gzip in prod config |
| Static asset delivery | site + media + play |
| PCK delivery | `/play/index.pck` |
| Browser caching | Commit-versioned Godot wasm/pck/js; HTML + health no-cache |
| Versioned builds | `version.json`, `health.json`, `manifest.json` + git commit |
| Security headers | nosniff, frame, referrer, permissions |
| Godot threading headers | **not required** — export is unthreaded |
| Deployment structure | `deploy/deploy-furyfront.sh` + nginx template |
| Logging | `deploy/logs/` + nginx access/error |
| Health endpoint | `GET /health` → `health.json` (nginx static, no Node) |

Gameplay remains **local vs Shadowbreaker AI** during V0.1.

## Deployment pipeline

Reproducible flow — no manual production edits after deploy:

```
Git repository
  → npm run validate
  → Godot Web export (export/web/)
  → node scripts/build-deploy.mjs
  → dist/furyfront/ artifact
  → ./deploy/deploy-furyfront.sh deploy
  → /var/www/furyfront/releases/<commit>
  → symlink current → release
  → nginx -t && reload
  → https://furyfront.app
```

Every deployed version maps to a **Git commit**. Godot engine files are renamed `index.<commit>.{wasm,js,pck}` so immutable caching cannot mix artifacts across releases.

See `deploy/README.md` for rollback and caching rules.

### Commands

```bash
# Validate + assemble (requires Godot export already built)
node scripts/validate.mjs
godot --headless --path game --export-release Web export/web/index.html
node scripts/build-deploy.mjs

# Local preview (production-like)
node scripts/serve-furyfront.mjs
```

## URL map

| URL | Content |
| --- | --- |
| `https://furyfront.app/` | Landing page + hero video |
| `https://furyfront.app/play/` | Godot Web V0.1 |
| `https://furyfront.app/health` | JSON health + version |
| `https://furyfront.app/media/hero.MP4` | Hero cinematic (single copy) |

## Future multiplayer architecture (not V0.1)

```
Godot Browser Client
  ↕ secure browser-compatible transport (WebSocket / WebRTC — TBD)
Fury Front Multiplayer Gateway
  ↕
Authoritative Match Server
  ↕
Fury Front Backend Services
  ↕
Database / Persistence
```

Server eventually owns authoritative state: health, armor, damage, kills, objectives, match results, spawns, teams. **Never trust browser clients** for competitive outcomes.

## Mobile (deferred)

After PC web is proven: thin wrapper vs native Godot export spike. **One Godot project**, multiple distribution targets.

## Server inspection report

> Inspected on **2026-08-13** from the development workstation. **Production server for furyfront.app was not accessible from this environment** — values below are from the dev machine unless marked *planned*.

| # | Item | Value |
| --- | --- | --- |
| 1 | Server OS | Dev: Windows 11 Home 10.0.26200 · *Prod: Linux recommended (nginx)* |
| 2 | CPU | Dev: Intel Core i3-1005G1, 2C/4T · *Prod: inspect on host* |
| 3 | RAM | Dev: 8 GB · *Prod V0.1 est.: 2–4 GB sufficient for static+Node* |
| 4 | Storage | Dev: 446 GB free on C: · *Prod: ≥20 GB for releases + logs* |
| 5 | Network/uplink | Dev: Wi-Fi 192.168.100.6 · *Prod: inspect ISP/uplink on host* |
| 6 | Web server / reverse proxy | *Planned:* nginx → static root or Node `serve-furyfront.mjs` |
| 7 | Domain plan | `furyfront.app` — apex + www → our server A/AAAA |
| 8 | HTTPS status | **Not live from this repo** — certbot/Let's Encrypt on prod |
| 9 | Deployment directory | `/var/www/furyfront/current` (*planned*) · local: `dist/furyfront/` |
| 10 | Godot deploy method | `build-deploy.mjs` copies `export/web/` → `play/` |
| 11 | Compression | gzip (Node + nginx); brotli optional in nginx |
| 12 | Cache | HTML no-cache; wasm/pck/media 24h immutable; version.json no-cache |
| 13 | Security headers | See `deploy/nginx/furyfront.app.conf` |
| 14 | Build/version strategy | Git SHA in `version.json`; release dirs symlinked |
| 15 | Monitoring/logging | `/health` JSON; nginx access log; uptime in health |
| 16 | Conflicting services | Dev machine only — no prod conflicts inspected |
| 17 | V0.1 resource estimate | **1 vCPU, 2 GB RAM, 10 GB disk** for static site + ~40 MB game bundle |

## Related docs

- `docs/20-web-hosting.md` — MIME, threading, Godot web specifics
- `docs/11-technical-architecture.md` — client + server topology
- `deploy/nginx/furyfront.app.conf` — production nginx template
