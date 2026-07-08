#!/usr/bin/env bash
# Production application-layer health (loopback).
# Safe: HTTP GET only. No nginx/DNS/deploy mutation.
set -euo pipefail

HOST="${PROD_APP_HOST:-127.0.0.1}"
PORT="${PROD_APP_PORT:-3100}"
READY_PATH="${PROD_READY_PATH:-/api/ready}"
HEALTH_PATH="${PROD_HEALTH_PATH:-/api/health}"
TIMEOUT="${HTTP_TIMEOUT_SECS:-5}"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check production app-layer on loopback (default 127.0.0.1:3100).

Optional:
  --host <host>     default 127.0.0.1
  --port <port>     default 3100
  --timeout <secs>  default 5
  --dry-run         print plan only
  -h, --help
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

probe() {
  local path="$1" label="$2"
  local url="http://${HOST}:${PORT}${path}"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY RUN] Would GET $label ($url)"
    return 0
  fi
  local out code t
  out=$(curl -sS -o /dev/null -w "%{http_code} %{time_total}" \
    --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" "$url" 2>/dev/null || true)
  code=$(awk '{print $1}' <<<"${out:-000 0}")
  t=$(awk '{print $2}' <<<"${out:-000 0}")
  if [[ "$code" =~ ^2 ]]; then
    ok "$label HTTP $code (${t}s)"
    return 0
  fi
  err "$label HTTP ${code:-000} (${t:-0}s) url=$url"
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --dry-run|--check) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

echo "========================================"
echo "  PROD APP-LAYER CHECK"
echo "  ${HOST}:${PORT}"
echo "========================================"

failures=0
probe "$READY_PATH" "ready" || failures=$((failures + 1))
probe "$HEALTH_PATH" "health" || failures=$((failures + 1))

if [[ "$failures" -eq 0 ]]; then
  ok "App-layer healthy"
  exit 0
fi
err "App-layer check failures=$failures"
exit 1
