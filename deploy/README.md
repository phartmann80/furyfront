# Fury Front — production deployment

**Domain:** `furyfront.app`  
**Architecture:** landing `/` + Godot game `/play/` on **our Linux server** (not Vercel/Netlify).

## Prerequisites

- SSH key access to production host (no passwords in repo)
- nginx installed with `deploy/nginx/furyfront.app.conf`
- Godot 4.7.1 + web export templates on build machine
- `rsync`, `node`, `git`, `bash`

## Configure once

```bash
cp deploy/deploy.env.example deploy/deploy.env
# Edit deploy/deploy.env — SSH user/host, remote paths (deploy.env is gitignored)
chmod +x deploy/deploy-furyfront.sh
```

## Release layout (server)

```
/var/www/furyfront/
  releases/
    <commit>/          # full dist bundle
  current  → releases/<commit>/
  previous → releases/<older>/
```

## Deploy (when authorized)

```bash
./deploy/deploy-furyfront.sh plan     # build locally, show target
./deploy/deploy-furyfront.sh deploy   # build, rsync, symlink, nginx -t, reload
```

Each deploy:

1. Runs `validate` + Godot Web export + `build-deploy.mjs`
2. Versions Godot wasm/pck/js as `index.<commit>.*`
3. rsync to `releases/<commit>/`
4. Stamps `deployedAt` in `health.json` + `version.json`
5. Atomically switches `current` symlink (saves old path in `previous`)
6. Runs `nginx -t` before reload
7. Logs to `deploy/logs/` (gitignored)

## Rollback

```bash
./deploy/deploy-furyfront.sh rollback
```

Switches `current` → `previous` release, runs `nginx -t`, reloads nginx.

Manual rollback:

```bash
ssh deploy@furyfront.app
ln -sfn /var/www/furyfront/releases/<older-commit> /var/www/furyfront/current
sudo nginx -t && sudo systemctl reload nginx
```

## Verify

```bash
curl -s https://furyfront.app/health | jq
curl -sI https://furyfront.app/play/index.html | grep -i cache
```

## Caching strategy

| Asset | Policy |
| --- | --- |
| `index.html`, `/play/index.html` | `no-cache, must-revalidate` |
| `/health`, `version.json` | `no-cache` — includes commit + deployedAt |
| `/play/index.<commit>.{wasm,js,pck}` | `immutable` — commit in filename prevents wasm/pck mismatch |
| `/media/hero.MP4` | long immutable (stable cinematic) |
| `/css`, `/js` | short cache; HTML uses `?v=<commit>` |

## Do not deploy until

Production server has been inspected (OS, nginx, DNS, TLS, ports, existing apps). See `docs/21-server-architecture.md`.
