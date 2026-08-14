#!/usr/bin/env bash
# Fury Front production deployment — our Linux server at furyfront.app
# Usage:
#   ./deploy/deploy-furyfront.sh plan      # build + show what would upload
#   ./deploy/deploy-furyfront.sh deploy    # build, rsync, symlink, nginx reload
#   ./deploy/deploy-furyfront.sh rollback  # switch current → previous release
#   ./deploy/deploy-furyfront.sh releases  # list remote releases
#
# Configure: cp deploy/deploy.env.example deploy/deploy.env (gitignored)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/deploy/deploy.env"
LOG_DIR="${ROOT}/deploy/logs"
LOCAL_DIST="${ROOT}/dist/furyfront"

log() { echo "[$(date -Iseconds)] $*" | tee -a "${LOG_FILE:-/dev/null}"; }

load_env() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Missing ${ENV_FILE}. Copy deploy/deploy.env.example and configure SSH (no secrets in git)."
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  : "${FURYFRONT_SSH_HOST:?}"
  : "${FURYFRONT_SSH_USER:?}"
  : "${FURYFRONT_REMOTE_ROOT:?}"
  FURYFRONT_SSH_PORT="${FURYFRONT_SSH_PORT:-22}"
  FURYFRONT_RELEASES_DIR="${FURYFRONT_RELEASES_DIR:-releases}"
  FURYFRONT_CURRENT_LINK="${FURYFRONT_CURRENT_LINK:-current}"
  FURYFRONT_PREVIOUS_LINK="${FURYFRONT_PREVIOUS_LINK:-previous}"
  FURYFRONT_KEEP_RELEASES="${FURYFRONT_KEEP_RELEASES:-5}"
  FURYFRONT_NGINX_TEST_CMD="${FURYFRONT_NGINX_TEST_CMD:-sudo nginx -t}"
  FURYFRONT_NGINX_RELOAD_CMD="${FURYFRONT_NGINX_RELOAD_CMD:-sudo systemctl reload nginx}"
}

ssh_cmd() {
  ssh -p "${FURYFRONT_SSH_PORT}" ${FURYFRONT_RSYNC_SSH:+ -o IdentitiesOnly=yes} \
    "${FURYFRONT_SSH_USER}@${FURYFRONT_SSH_HOST}" "$@"
}

rsync_release() {
  local commit="$1"
  local remote_release="${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_RELEASES_DIR}/${commit}"
  log "rsync → ${FURYFRONT_SSH_USER}@${FURYFRONT_SSH_HOST}:${remote_release}"
  rsync -avz --delete \
    ${FURYFRONT_RSYNC_SSH:+-e "ssh -p ${FURYFRONT_SSH_PORT} ${FURYFRONT_RSYNC_SSH}"} \
    "${LOCAL_DIST}/" \
    "${FURYFRONT_SSH_USER}@${FURYFRONT_SSH_HOST}:${remote_release}/"
}

build_local() {
  log "local build start"
  local args=()
  [[ "${FURYFRONT_SKIP_VALIDATE:-0}" == "1" ]] && args+=(--skip-validate)
  [[ "${FURYFRONT_SKIP_GODOT_EXPORT:-0}" == "1" ]] && args+=(--skip-export)
  (cd "${ROOT}" && node scripts/build-deploy.mjs "${args[@]}")
  [[ -f "${LOCAL_DIST}/version.json" ]] || { log "ERROR: dist/furyfront missing"; exit 1; }
  log "local build ok"
}

commit_from_dist() {
  node -e "console.log(JSON.parse(require('fs').readFileSync('${LOCAL_DIST}/version.json','utf8')).commit)"
}

activate_release() {
  local commit="$1"
  local deployed_at
  deployed_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local remote_release="${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_RELEASES_DIR}/${commit}"
  local remote_root="${FURYFRONT_REMOTE_ROOT}"

  log "activate release ${commit} on server"
  ssh_cmd bash -s <<EOF
set -euo pipefail
RELEASE="${remote_release}"
ROOT="${remote_root}"
COMMIT="${commit}"
DEPLOYED_AT="${deployed_at}"
CURRENT="${FURYFRONT_CURRENT_LINK}"
PREVIOUS="${FURYFRONT_PREVIOUS_LINK}"

if [[ ! -d "\${RELEASE}" ]]; then
  echo "Release directory missing: \${RELEASE}" >&2
  exit 1
fi

# Stamp deployment time into version + health JSON (production /health source)
python3 - <<PY
import json
from pathlib import Path
release = Path("${remote_release}")
deployed_at = "${deployed_at}"
for name in ("version.json", "health.json"):
    p = release / name
    v = json.loads(p.read_text(encoding="utf-8"))
    v["deployedAt"] = deployed_at
    v["status"] = "ok"
    p.write_text(json.dumps(v, indent=2) + "\n", encoding="utf-8")
PY

mkdir -p "\${ROOT}"
if [[ -L "\${ROOT}/\${CURRENT}" ]]; then
  OLD=\$(readlink -f "\${ROOT}/\${CURRENT}")
  ln -sfn "\${OLD}" "\${ROOT}/\${PREVIOUS}"
fi
ln -sfn "\${RELEASE}" "\${ROOT}/\${CURRENT}"

${FURYFRONT_NGINX_TEST_CMD}
${FURYFRONT_NGINX_RELOAD_CMD}
echo "Active: \${COMMIT} at \${DEPLOYED_AT}"
EOF
  log "activate ok"
}

prune_releases() {
  [[ "${FURYFRONT_KEEP_RELEASES}" == "0" ]] && return
  log "prune old releases (keep ${FURYFRONT_KEEP_RELEASES})"
  ssh_cmd bash -s <<EOF
set -euo pipefail
ROOT="${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_RELEASES_DIR}"
KEEP=${FURYFRONT_KEEP_RELEASES}
cd "\${ROOT}" || exit 0
ls -1dt */ 2>/dev/null | tail -n +\$((KEEP + 1)) | while read -r d; do
  rm -rf "\${d%/}"
  echo "pruned \${d%/}"
done
EOF
}

cmd_plan() {
  build_local
  local commit
  commit="$(commit_from_dist)"
  log "PLAN commit=${commit}"
  log "  local bundle: ${LOCAL_DIST}"
  log "  remote: ${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_RELEASES_DIR}/${commit}/"
  log "  symlink: ${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_CURRENT_LINK} → release"
  log "  site: https://furyfront.app/"
  log "  game: https://furyfront.app/play/"
  log "  health: https://furyfront.app/health"
}

cmd_deploy() {
  mkdir -p "${LOG_DIR}"
  LOG_FILE="${LOG_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"
  load_env
  build_local
  local commit
  commit="$(commit_from_dist)"
  rsync_release "${commit}"
  activate_release "${commit}"
  prune_releases
  log "DEPLOY COMPLETE commit=${commit}"
  log "Verify: curl -s https://furyfront.app/health"
}

cmd_rollback() {
  mkdir -p "${LOG_DIR}"
  LOG_FILE="${LOG_DIR}/rollback-$(date +%Y%m%d-%H%M%S).log"
  load_env
  log "rollback start"
  ssh_cmd bash -s <<EOF
set -euo pipefail
ROOT="${FURYFRONT_REMOTE_ROOT}"
PREV="\${ROOT}/${FURYFRONT_PREVIOUS_LINK}"
CURR="\${ROOT}/${FURYFRONT_CURRENT_LINK}"
if [[ ! -L "\${PREV}" ]]; then
  echo "No previous release symlink at \${PREV}" >&2
  exit 1
fi
TARGET=\$(readlink -f "\${PREV}")
ln -sfn "\${TARGET}" "\${CURR}"
${FURYFRONT_NGINX_TEST_CMD}
${FURYFRONT_NGINX_RELOAD_CMD}
echo "Rolled back to \${TARGET}"
EOF
  log "rollback ok"
}

cmd_releases() {
  load_env
  ssh_cmd "ls -la ${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_RELEASES_DIR}/ 2>/dev/null; echo '---'; ls -la ${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_CURRENT_LINK} ${FURYFRONT_REMOTE_ROOT}/${FURYFRONT_PREVIOUS_LINK} 2>/dev/null"
}

main() {
  local cmd="${1:-}"
  case "${cmd}" in
    plan) cmd_plan ;;
    deploy) cmd_deploy ;;
    rollback) cmd_rollback ;;
    releases) cmd_releases ;;
    *)
      echo "Usage: $0 {plan|deploy|rollback|releases}"
      exit 1
      ;;
  esac
}

main "${1:-}"
