#!/usr/bin/env bash
# Read-only preflight for staging rebind 3000 → 3200.
# Does NOT stop staging, redeploy, or touch production.
set -euo pipefail

PROD_PORT="${PROD_PORT:-3100}"
STG_OLD="${STG_OLD_PORT:-3000}"
STG_NEW="${STG_NEW_PORT:-3200}"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run]

Check port occupancy and health before a staging rebind.
Never kills processes.
EOF
}

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
warn(){ echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown: $1"; exit 1 ;;
  esac
done

echo "========================================"
echo "  STAGING REBIND PREFLIGHT (read-only)"
echo "  prod=$PROD_PORT stg_old=$STG_OLD stg_new=$STG_NEW"
echo "========================================"

if [[ "$DRY_RUN" == "true" ]]; then
  log "[DRY RUN] Would check listeners and health on $PROD_PORT/$STG_OLD/$STG_NEW"
  exit 0
fi

failures=0

port_listen() {
  local p="$1"
  if ss -ltn 2>/dev/null | grep -qE ":${p}\\b"; then
    echo "listen"
  else
    echo "free"
  fi
}

for label_port in "prod:$PROD_PORT" "stg_old:$STG_OLD" "stg_new:$STG_NEW"; do
  label=${label_port%%:*}
  p=${label_port##*:}
  state=$(port_listen "$p")
  log "$label port $p → $state"
done

# health probes
probe() {
  local p="$1" name="$2"
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 5 "http://127.0.0.1:${p}/api/ready" 2>/dev/null || echo 000)
  if [[ "$code" =~ ^2 ]]; then
    ok "$name :$p ready HTTP $code"
  else
    if [[ "$name" == "stg_new" ]]; then
      ok "$name :$p not up yet (expected before rebind) code=$code"
    else
      err "$name :$p ready HTTP $code"
      failures=$((failures + 1))
    fi
  fi
}

probe "$PROD_PORT" "prod"
probe "$STG_OLD" "stg_old"
probe "$STG_NEW" "stg_new"

stg_new_state=$(port_listen "$STG_NEW")
if [[ "$stg_new_state" != "free" ]]; then
  warn "target staging port $STG_NEW is not free — rebind blocked until free"
  failures=$((failures + 1))
else
  ok "target port $STG_NEW free"
fi

log "Plan doc: docs/ops/staging-rebind-3000-to-3200.md"
log "This script never stops staging."

if [[ "$failures" -eq 0 ]]; then
  ok "REBIND_PREFLIGHT_PASS (still plan-only until approval)"
  exit 0
fi
err "REBIND_PREFLIGHT_FAIL failures=$failures"
exit 1
