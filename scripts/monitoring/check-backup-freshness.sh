#!/usr/bin/env bash
# Backup freshness checker (local metadata only).
# Safe: reads mtime of backup marker/dir. No restore, no deletion, no secrets.
set -euo pipefail

BACKUP_ROOT="${ASDEV_BACKUP_ROOT:-}"
MAX_AGE_HOURS="${BACKUP_MAX_AGE_HOURS:-36}"
DRY_RUN=false
CHECK_MODE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Check whether the newest backup artifact is fresh enough.

Optional:
  --backup-root <path>   Directory containing backup artifacts
  --max-age-hours <n>    Maximum allowed age in hours (default: 36)
  --dry-run              Print planned checks only
  --check                Alias for --dry-run
  -h, --help             Show help

Env:
  ASDEV_BACKUP_ROOT      Default backup root when --backup-root omitted
  BACKUP_MAX_AGE_HOURS   Default max age
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
warn() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $*"; }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --backup-root)   BACKUP_ROOT="$2"; shift 2 ;;
      --max-age-hours) MAX_AGE_HOURS="$2"; shift 2 ;;
      --dry-run)       DRY_RUN=true; shift ;;
      --check)         CHECK_MODE=true; shift ;;
      -h|--help)       usage; exit 0 ;;
      *)               err "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  echo "========================================"
  echo "  BACKUP FRESHNESS CHECK"
  echo "  max_age_hours=$MAX_AGE_HOURS"
  echo "========================================"

  if [[ "$DRY_RUN" == "true" || "$CHECK_MODE" == "true" ]]; then
    log "[DRY RUN] Would inspect backup root: ${BACKUP_ROOT:-<unset>}"
    log "[DRY RUN] Would compare newest artifact mtime against ${MAX_AGE_HOURS}h"
    ok "Dry-run complete"
    exit 0
  fi

  if [[ -z "$BACKUP_ROOT" ]]; then
    warn "ASDEV_BACKUP_ROOT / --backup-root not set — skip with non-blocking warning"
    echo "STATUS=SKIPPED_NO_ROOT"
    exit 0
  fi

  if [[ ! -d "$BACKUP_ROOT" ]]; then
    err "backup root not found"
    echo "STATUS=MISSING_ROOT"
    exit 1
  fi

  local newest
  newest=$(find "$BACKUP_ROOT" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 || true)
  if [[ -z "$newest" ]]; then
    err "no backup artifacts found under backup root"
    echo "STATUS=EMPTY"
    exit 1
  fi

  local epoch path age_hours
  epoch=$(awk '{print int($1)}' <<<"$newest")
  path=$(awk '{ $1=""; sub(/^ /,""); print }' <<<"$newest")
  # Do not print full path if deep/sensitive; show basename only.
  local base
  base=$(basename "$path")
  age_hours=$(( ( $(date +%s) - epoch ) / 3600 ))

  if [[ $age_hours -gt $MAX_AGE_HOURS ]]; then
    err "newest backup '$base' is ${age_hours}h old (max ${MAX_AGE_HOURS}h)"
    echo "STATUS=STALE age_hours=$age_hours artifact=$base"
    exit 1
  fi

  ok "newest backup '$base' is ${age_hours}h old"
  echo "STATUS=FRESH age_hours=$age_hours artifact=$base"
}

main "$@"
