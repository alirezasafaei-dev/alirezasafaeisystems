#!/usr/bin/env bash
# HTTP healthcheck for CRITICAL_SITE (persiantoolbox.ir).
# Safe: read-only outbound HTTP. No production mutation.
set -euo pipefail

SITE_URL="${CRITICAL_SITE_URL:-https://persiantoolbox.ir}"
READY_PATH="${CRITICAL_SITE_READY_PATH:-/api/ready}"
HEALTH_PATH="${CRITICAL_SITE_HEALTH_PATH:-/api/health}"
TIMEOUT="${HTTP_TIMEOUT_SECS:-10}"
DRY_RUN=false
CHECK_MODE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check CRITICAL_SITE public HTTP endpoints (read-only).

Optional:
  --url <url>         Base URL (default: \$CRITICAL_SITE_URL or https://persiantoolbox.ir)
  --timeout <secs>    Curl connect/max timeout (default: 10)
  --dry-run           Print planned checks only
  --check             Alias for --dry-run
  -h, --help          Show help
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
warn() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $*"; }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

check_url() {
  local url="$1" label="$2"
  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    log "[DRY RUN] Would GET $label ($url)"
    return 0
  fi
  local out code time_total
  out=$(
    curl -sS -o /dev/null \
      -w "%{http_code} %{time_total}" \
      --connect-timeout "$TIMEOUT" \
      --max-time "$TIMEOUT" \
      "$url" 2>/dev/null || true
  )
  code=$(awk '{print $1}' <<<"${out:-000 0}")
  time_total=$(awk '{print $2}' <<<"${out:-000 0}")
  code=${code:-000}
  time_total=${time_total:-0}
  if [[ "$code" =~ ^2 ]]; then
    ok "$label HTTP $code (${time_total}s)"
    return 0
  fi
  err "$label HTTP $code (${time_total}s)"
  return 1
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --url)      SITE_URL="$2"; shift 2 ;;
      --timeout)  TIMEOUT="$2"; shift 2 ;;
      --dry-run)  DRY_RUN=true; shift ;;
      --check)    CHECK_MODE=true; shift ;;
      -h|--help)  usage; exit 0 ;;
      *)          err "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  local base="${SITE_URL%/}"
  local failures=0

  echo "========================================"
  echo "  CRITICAL_SITE HTTP CHECK"
  echo "  Target: $base"
  echo "========================================"

  check_url "$base/" "root" || failures=$((failures + 1))
  check_url "${base}${READY_PATH}" "ready" || failures=$((failures + 1))
  check_url "${base}${HEALTH_PATH}" "health" || failures=$((failures + 1))

  echo "========================================"
  if [[ $failures -gt 0 ]]; then
    err "CRITICAL_SITE HTTP check failed ($failures endpoint(s))"
    exit 1
  fi
  ok "All CRITICAL_SITE HTTP checks passed"
}

main "$@"
