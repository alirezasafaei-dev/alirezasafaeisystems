#!/usr/bin/env bash
# Multi-sample stability probe for production app-layer (read-only HTTP).
# No nginx/DNS/deploy mutation. Safe to run on IRAN_PROD.
set -euo pipefail

HOST="${PROD_APP_HOST:-127.0.0.1}"
PORT="${PROD_APP_PORT:-3100}"
SAMPLES="${STABILITY_SAMPLES:-5}"
TIMEOUT="${HTTP_TIMEOUT_SECS:-5}"
MAX_MS="${STABILITY_MAX_MS:-2000}"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sample /api/ready and /api/health multiple times; fail on non-2xx or slow responses.

Optional:
  --host --port --samples N --max-ms N --timeout N --dry-run
EOF
}

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --samples) SAMPLES="$2"; shift 2 ;;
    --max-ms) MAX_MS="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown: $1"; exit 1 ;;
  esac
done

echo "========================================"
echo "  PROD STABILITY SAMPLE"
echo "  ${HOST}:${PORT} samples=$SAMPLES max_ms=$MAX_MS"
echo "========================================"

if [[ "$DRY_RUN" == "true" ]]; then
  log "[DRY RUN] Would sample ready/health ${SAMPLES}x"
  exit 0
fi

failures=0
for path in /api/ready /api/health; do
  for ((i=1; i<=SAMPLES; i++)); do
    out=$(curl -sS -o /dev/null -w "%{http_code} %{time_total}" \
      --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" \
      "http://${HOST}:${PORT}${path}" 2>/dev/null || echo "000 9")
    code=$(awk '{print $1}' <<<"$out")
    t=$(awk '{print $2}' <<<"$out")
    # ms as integer
    ms=$(awk -v t="$t" 'BEGIN{printf "%d", t*1000}')
    if [[ ! "$code" =~ ^2 ]]; then
      err "$path #$i HTTP $code"
      failures=$((failures + 1))
      continue
    fi
    if (( ms > MAX_MS )); then
      err "$path #$i slow ${ms}ms > ${MAX_MS}ms"
      failures=$((failures + 1))
      continue
    fi
    ok "$path #$i HTTP $code ${ms}ms"
  done
done

if [[ "$failures" -eq 0 ]]; then
  ok "STABILITY_SAMPLE_PASS"
  exit 0
fi
err "STABILITY_SAMPLE_FAIL failures=$failures"
exit 1
