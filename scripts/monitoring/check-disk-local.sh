#!/usr/bin/env bash
# Local disk capacity checker for OWNER_PC / AUTOMATION_HOST.
# Safe: read-only df. No mutation. Paths are generic mount points only.
set -euo pipefail

WARN_PCT="${DISK_WARN_PCT:-80}"
CRIT_PCT="${DISK_CRIT_PCT:-90}"
DRY_RUN=false
CHECK_MODE=false
PATHS=("/" "/home")
ERRORS=0
WARNINGS=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [path ...]

Check local disk usage against warn/crit thresholds.

Optional:
  --warn-pct <n>   Warning threshold percent used (default: 80)
  --crit-pct <n>   Critical threshold percent used (default: 90)
  --dry-run        Print planned checks only
  --check          Alias for --dry-run
  -h, --help       Show help

Exit codes:
  0  ok (or dry-run)
  1  critical threshold exceeded
  2  warning threshold exceeded (no critical)
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
warn() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $*"; WARNINGS=$((WARNINGS + 1)); }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }

main() {
  local positional=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --warn-pct) WARN_PCT="$2"; shift 2 ;;
      --crit-pct) CRIT_PCT="$2"; shift 2 ;;
      --dry-run)  DRY_RUN=true; shift ;;
      --check)    CHECK_MODE=true; shift ;;
      -h|--help)  usage; exit 0 ;;
      --)         shift; positional+=("$@"); break ;;
      -*)         err "Unknown option: $1"; usage; exit 1 ;;
      *)          positional+=("$1"); shift ;;
    esac
  done
  if [[ ${#positional[@]} -gt 0 ]]; then
    PATHS=("${positional[@]}")
  fi

  echo "========================================"
  echo "  LOCAL DISK CHECK"
  echo "  warn>=${WARN_PCT}% crit>=${CRIT_PCT}%"
  echo "========================================"

  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    for p in "${PATHS[@]}"; do
      log "[DRY RUN] Would check disk usage for: $p"
    done
    ok "Dry-run complete"
    exit 0
  fi

  local path used_pct avail_mb
  for path in "${PATHS[@]}"; do
    if [[ ! -e "$path" ]]; then
      warn "path missing: $path"
      continue
    fi
    used_pct=$(df -P "$path" | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    avail_mb=$(df -kP "$path" | awk 'NR==2 {print int($4/1024)}')
    if [[ -z "$used_pct" ]]; then
      warn "unable to read usage for $path"
      continue
    fi
    if [[ "$used_pct" -ge "$CRIT_PCT" ]]; then
      err "$path used ${used_pct}% (avail ${avail_mb}MB) >= crit ${CRIT_PCT}%"
    elif [[ "$used_pct" -ge "$WARN_PCT" ]]; then
      warn "$path used ${used_pct}% (avail ${avail_mb}MB) >= warn ${WARN_PCT}%"
    else
      ok "$path used ${used_pct}% (avail ${avail_mb}MB)"
    fi
  done

  echo "========================================"
  echo "ERRORS=$ERRORS WARNINGS=$WARNINGS"
  if [[ $ERRORS -gt 0 ]]; then
    exit 1
  fi
  if [[ $WARNINGS -gt 0 ]]; then
    exit 2
  fi
}

main "$@"
