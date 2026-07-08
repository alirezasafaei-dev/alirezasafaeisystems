#!/usr/bin/env bash
# Emit a short backup freshness report (stdout + optional file).
# Safe: read-only. Does not change cron or delete backups.
set -euo pipefail

BACKUP_ROOT="${ASDEV_BACKUP_ROOT:-/srv/asdev/backups/persiantoolbox}"
MAX_AGE_HOURS="${BACKUP_MAX_AGE_HOURS:-36}"
OUT_FILE="${ASDEV_BACKUP_REPORT_FILE:-}"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Write a human-readable backup freshness report.

Optional:
  --backup-root <path>   default \$ASDEV_BACKUP_ROOT or /srv/asdev/backups/persiantoolbox
  --max-age-hours <n>    default 36
  --out <file>           also write report to file
  --dry-run
  -h, --help
EOF
}

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup-root) BACKUP_ROOT="$2"; shift 2 ;;
    --max-age-hours) MAX_AGE_HOURS="$2"; shift 2 ;;
    --out) OUT_FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

if [[ "$DRY_RUN" == "true" ]]; then
  log "[DRY RUN] Would inspect $BACKUP_ROOT (max_age=${MAX_AGE_HOURS}h)"
  exit 0
fi

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
STATUS="UNKNOWN"
AGE_H="n/a"
NEWEST="none"
DETAIL=""

if [[ ! -d "$BACKUP_ROOT" ]]; then
  STATUS="MISSING_ROOT"
  DETAIL="backup root not found"
else
  # prefer tar.gz mtime
  newest_file=$(find "$BACKUP_ROOT" -maxdepth 1 -type f \( -name '*.tar.gz' -o -name '*.tgz' \) -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2- || true)
  if [[ -z "${newest_file:-}" ]]; then
    newest_file=$(find "$BACKUP_ROOT" -maxdepth 1 -mindepth 1 -type d -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2- || true)
  fi
  if [[ -z "${newest_file:-}" ]]; then
    STATUS="EMPTY"
    DETAIL="no artifacts"
  else
    NEWEST=$(basename "$newest_file")
    mtime=$(stat -c %Y "$newest_file" 2>/dev/null || stat -f %m "$newest_file")
    now=$(date +%s)
    AGE_H=$(( (now - mtime) / 3600 ))
    if (( AGE_H <= MAX_AGE_HOURS )); then
      STATUS="FRESH"
    else
      STATUS="STALE"
    fi
    DETAIL="age_hours=$AGE_H max=$MAX_AGE_HOURS"
  fi
fi

report=$(cat <<EOF
# Backup Freshness Report

- checked_at: $TS
- host_alias: IRAN_PROD (or local executor)
- backup_root: $BACKUP_ROOT
- newest: $NEWEST
- age_hours: $AGE_H
- max_age_hours: $MAX_AGE_HOURS
- status: **$STATUS**
- detail: $DETAIL

Do not commit secrets. Cron schedules not modified by this report.
EOF
)

echo "$report"
if [[ -n "$OUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUT_FILE")"
  printf '%s\n' "$report" >"$OUT_FILE"
  log "wrote $OUT_FILE"
fi

case "$STATUS" in
  FRESH) exit 0 ;;
  STALE|EMPTY|MISSING_ROOT) exit 1 ;;
  *) exit 2 ;;
esac
