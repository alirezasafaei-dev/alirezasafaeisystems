#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="/var/backups/my-portfolio"
FREQUENCY="daily"
ENV_NAME="production"
DRILL_ROOT="/tmp/my-portfolio-restore-drill"
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  restore-drill-onsite.sh [options]

Options:
  --frequency <daily|weekly|monthly>   Backup frequency bucket (default: daily)
  --env <production|staging>           Environment name (default: production)
  --backup-root <path>                 Backup root (default: /var/backups/my-portfolio)
  --drill-root <path>                  Restore drill root (default: /tmp/my-portfolio-restore-drill)
  --dry-run                            Show actions without modifying filesystem
  -h, --help                           Show this help
USAGE
}

log() { printf '[restore-drill] %s\n' "$*"; }
die() { printf '[restore-drill][error] %s\n' "$*" >&2; exit 1; }

run() {
  # Prefer argv form: run mkdir -p "$dir"
  # Legacy single-string form still accepted without eval.
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  if [[ $# -gt 1 ]]; then
    "$@"
  else
    /bin/bash -c "$1"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --frequency) FREQUENCY="${2:-}"; shift 2 ;;
    --env) ENV_NAME="${2:-}"; shift 2 ;;
    --backup-root) BACKUP_ROOT="${2:-}"; shift 2 ;;
    --drill-root) DRILL_ROOT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

case "$FREQUENCY" in
  daily|weekly|monthly) ;;
  *) die "--frequency must be one of: daily, weekly, monthly" ;;
esac

bucket_dir="${BACKUP_ROOT}/${FREQUENCY}"
[[ -d "$bucket_dir" ]] || die "Missing backup bucket: $bucket_dir"

latest_archive="$(ls -1t "$bucket_dir"/my-portfolio-"$ENV_NAME"-"$FREQUENCY"-*.tar.gz 2>/dev/null | head -n1 || true)"
[[ -n "$latest_archive" ]] || die "No archive found for env=$ENV_NAME frequency=$FREQUENCY in $bucket_dir"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
restore_dir="${DRILL_ROOT}/${ENV_NAME}-${FREQUENCY}-${timestamp}"
sha_file="${latest_archive}.sha256"
manifest_file="${latest_archive}.manifest.txt"

log "selected archive: $latest_archive"
run "mkdir -p '$restore_dir'"

if [[ -f "$sha_file" ]]; then
  if [[ "$DRY_RUN" == "1" ]]; then
    log "would verify checksum using $sha_file"
  else
    (cd "$(dirname "$latest_archive")" && sha256sum -c "$(basename "$sha_file")")
  fi
else
  log "checksum file not found, continuing: $sha_file"
fi

run "tar -xzf '$latest_archive' -C '$restore_dir'"

check_path() {
  local p="$1"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "would verify path exists: $p"
    return 0
  fi
  [[ -e "$p" ]] || die "missing restored path: $p"
}

if [[ -f "$manifest_file" ]]; then
  while IFS= read -r original_path; do
    [[ -n "$original_path" ]] || continue
    check_path "${restore_dir}${original_path}"
  done < "$manifest_file"
else
  check_path "${restore_dir}/var/www/my-portfolio/shared/env"
fi

if [[ "$DRY_RUN" == "0" ]]; then
  printf 'restore_drill_timestamp=%s\narchive=%s\nrestore_dir=%s\n' \
    "$timestamp" "$latest_archive" "$restore_dir" \
    > "${restore_dir}/RESTORE_DRILL_RESULT.txt"
  log "wrote result file: ${restore_dir}/RESTORE_DRILL_RESULT.txt"
fi

log "restore drill completed successfully"
