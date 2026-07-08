#!/usr/bin/env bash
# Deploy status for a site root (default CRITICAL_SITE production layout).
# Safe: filesystem + process read-only. No mutation.
set -euo pipefail

SITE_ROOT="${ASDEV_SITE_ROOT:-/srv/asdev/sites/persiantoolbox}"
ENV_NAME="${ASDEV_ENV_NAME:-production}"
EXPECT_PORT="${ASDEV_EXPECT_PORT:-3100}"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Validate deploy layout: current symlink, release.meta, pid, optional port.

Optional:
  --site-root <path>   default /srv/asdev/sites/persiantoolbox
  --env <name>         expected environment in release.meta (default production)
  --port <n>           expected runtime_port (default 3100)
  --dry-run            print plan only
  -h, --help
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site-root) SITE_ROOT="$2"; shift 2 ;;
    --env) ENV_NAME="$2"; shift 2 ;;
    --port) EXPECT_PORT="$2"; shift 2 ;;
    --dry-run|--check) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

echo "========================================"
echo "  DEPLOY STATUS CHECK"
echo "  root=$SITE_ROOT env=$ENV_NAME"
echo "========================================"

if [[ "$DRY_RUN" == "true" ]]; then
  log "[DRY RUN] Would resolve $SITE_ROOT/current"
  log "[DRY RUN] Would read release.meta and asdev-runtime.pid"
  log "[DRY RUN] Would expect runtime_port=$EXPECT_PORT"
  ok "Dry-run complete"
  exit 0
fi

failures=0

if [[ ! -e "$SITE_ROOT/current" ]]; then
  err "missing current symlink at $SITE_ROOT/current"
  exit 1
fi

current=$(readlink -f "$SITE_ROOT/current" 2>/dev/null || true)
if [[ -z "$current" || ! -d "$current" ]]; then
  err "current does not resolve to a directory"
  exit 1
fi
ok "current → $current"

meta="$current/release.meta"
if [[ ! -f "$meta" ]]; then
  err "missing release.meta"
  failures=$((failures + 1))
else
  ok "release.meta present"
  env_got=$(grep -E '^environment=' "$meta" | head -1 | cut -d= -f2- || true)
  port_got=$(grep -E '^runtime_port=' "$meta" | head -1 | cut -d= -f2- || true)
  rel_got=$(grep -E '^release_id=' "$meta" | head -1 | cut -d= -f2- || true)
  commit_got=$(grep -E '^commit=' "$meta" | head -1 | cut -d= -f2- || true)
  log "release_id=${rel_got:-?} commit=${commit_got:0:12}… env=${env_got:-?} port=${port_got:-?}"
  if [[ -n "$env_got" && "$env_got" != "$ENV_NAME" ]]; then
    err "environment mismatch: got=$env_got want=$ENV_NAME"
    failures=$((failures + 1))
  fi
  if [[ -n "$port_got" && "$port_got" != "$EXPECT_PORT" ]]; then
    err "runtime_port mismatch: got=$port_got want=$EXPECT_PORT"
    failures=$((failures + 1))
  fi
fi

pid_file="$SITE_ROOT/asdev-runtime.pid"
if [[ ! -f "$pid_file" ]]; then
  err "missing pid file $pid_file"
  failures=$((failures + 1))
else
  pid=$(tr -d '[:space:]' <"$pid_file" || true)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    ok "pid $pid alive"
  else
    err "pid not alive (file=$pid_file value=${pid:-empty})"
    failures=$((failures + 1))
  fi
fi

if [[ "$failures" -eq 0 ]]; then
  ok "DEPLOY_OK"
  exit 0
fi
err "DEPLOY_FAIL failures=$failures"
exit 1
