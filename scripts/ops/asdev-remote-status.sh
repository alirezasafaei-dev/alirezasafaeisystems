#!/usr/bin/env bash
# Read-only remote status for CRITICAL_SITE staging (and optional prod layout).
# Secrets: never print host/IP/password. Load connection from a private env file.
# Default private file is NOT committed; pass ASDEV_VPS_ENV_FILE explicitly.
set -euo pipefail

SITE="${SITE:-persiantoolbox}"
ENV_FILE="${ASDEV_VPS_ENV_FILE:-}"
KEY="${ASDEV_SSH_KEY:-$HOME/.ssh/asdev_vps_ed25519}"
CHECK_STAGING=true
CHECK_PROD_LAYOUT=true

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Read-only IRAN_PROD status (no mutation).

Optional:
  --env-file <path>   Private env with IP/USER/PORT (or VPS_HOST/VPS_USER/VPS_PORT)
  --key <path>        SSH private key (default: ~/.ssh/asdev_vps_ed25519)
  --site <id>         Registry site id (default: persiantoolbox)
  --no-staging        Skip staging runtime checks
  --no-prod-layout    Skip production layout existence checks
  -h, --help

Env:
  ASDEV_VPS_ENV_FILE  Default env file path
  ASDEV_SSH_KEY       Default SSH key path

Output is redacted (no raw IPs).
EOF
}

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file) ENV_FILE="$2"; shift 2 ;;
    --key) KEY="$2"; shift 2 ;;
    --site) SITE="$2"; shift 2 ;;
    --no-staging) CHECK_STAGING=false; shift ;;
    --no-prod-layout) CHECK_PROD_LAYOUT=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1" ;;
  esac
done

[[ -n "$ENV_FILE" ]] || err "Set ASDEV_VPS_ENV_FILE or pass --env-file (private, not in git)"
[[ -f "$ENV_FILE" ]] || err "Env file not found"
[[ -f "$KEY" ]] || err "SSH key not found"

# shellcheck disable=SC1090
set -a
source "$ENV_FILE"
set +a

VPS_HOST="${VPS_HOST:-${IP:-}}"
VPS_USER="${VPS_USER:-${USER:-asdev}}"
# If USER was clobbered to a non-ssh user, prefer asdev when empty-looking
if [[ -z "${VPS_USER}" || "$VPS_USER" == "root" && -n "${IP:-}" ]]; then
  :
fi
VPS_USER="${VPS_USER:-asdev}"
VPS_PORT="${VPS_PORT:-${PORT:-22}}"
[[ -n "$VPS_HOST" ]] || err "Host not set in env file (IP or VPS_HOST)"

log "Connecting (host redacted) as user=${VPS_USER} port=${VPS_PORT}"
log "Site=${SITE} staging=${CHECK_STAGING} prod_layout=${CHECK_PROD_LAYOUT}"

REMOTE_SCRIPT=$(cat <<'EOS'
set +e
export PATH="/home/asdev/node/bin:$PATH"
SITE_ID="__SITE__"
CHECK_STAGING="__CHECK_STAGING__"
CHECK_PROD="__CHECK_PROD__"
STAGING_BASE="/srv/asdev/sites/${SITE_ID}-staging"
PROD_BASE="/srv/asdev/sites/${SITE_ID}"

echo "=== LAYOUT ==="
echo "staging_base_exists=$( [ -d "$STAGING_BASE" ] && echo yes || echo no )"
echo "prod_base_exists=$( [ -d "$PROD_BASE" ] && echo yes || echo no )"
if [ -L "$STAGING_BASE/current" ]; then
  echo "staging_current=$(basename "$(readlink -f "$STAGING_BASE/current")")"
else
  echo "staging_current=none"
fi
if [ -e "$PROD_BASE/current" ]; then
  echo "prod_current=yes"
  if [ -L "$PROD_BASE/current" ]; then
    echo "prod_current_release=$(basename "$(readlink -f "$PROD_BASE/current")")"
  fi
else
  echo "prod_current=no"
fi

if [ "$CHECK_STAGING" = "true" ]; then
  echo "=== STAGING RUNTIME ==="
  if [ -f "$STAGING_BASE/asdev-runtime.pid" ]; then
    PID=$(tr -d '[:space:]' < "$STAGING_BASE/asdev-runtime.pid")
    echo "pid=$PID"
    if kill -0 "$PID" 2>/dev/null; then echo "pid_alive=yes"; else echo "pid_alive=no"; fi
  else
    echo "pid=none"
  fi
  code_r=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:3000/api/ready 2>/dev/null || echo 000)
  code_h=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:3000/api/health 2>/dev/null || echo 000)
  echo "ready_http=$code_r"
  echo "health_http=$code_h"
  if [ -f "$STAGING_BASE/current/release.meta" ]; then
    echo "=== RELEASE META ==="
    cat "$STAGING_BASE/current/release.meta"
  fi
fi

echo "=== HOST RESOURCES ==="
free -m | awk '/Mem:/{print "mem_avail_mb="$7} /Swap:/{print "swap_free_mb="$4}'
df -h / | awk 'NR==2{print "disk_root_used="$5" avail="$4}'
EOS
)

REMOTE_SCRIPT=${REMOTE_SCRIPT//__SITE__/$SITE}
REMOTE_SCRIPT=${REMOTE_SCRIPT//__CHECK_STAGING__/$CHECK_STAGING}
REMOTE_SCRIPT=${REMOTE_SCRIPT//__CHECK_PROD__/$CHECK_PROD_LAYOUT}

ssh -i "$KEY" -p "$VPS_PORT" -o BatchMode=yes -o ConnectTimeout=15 \
  -o StrictHostKeyChecking=accept-new \
  "${VPS_USER}@${VPS_HOST}" bash -s <<<"$REMOTE_SCRIPT" \
  | sed -E 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/<IP>/g'

log "Remote status complete (read-only)"
