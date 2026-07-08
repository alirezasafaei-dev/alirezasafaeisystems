#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/var/www/my-portfolio"
BACKUP_ROOT="/var/backups/my-portfolio"
NGINX_DIR="/etc/nginx"
SYSTEMD_DIR="/etc/systemd/system"
FREQUENCY=""
ENV_NAME="production"
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=6
DRY_RUN=0
ALLOW_MISSING_SYSTEM_PATHS=0

usage() {
  cat <<'USAGE'
Usage:
  backup-onsite.sh --frequency <daily|weekly|monthly> [options]

Options:
  --env <production|staging>     Environment name (default: production)
  --base-dir <path>              App base dir (default: /var/www/my-portfolio)
  --backup-root <path>           Backup root (default: /var/backups/my-portfolio)
  --nginx-dir <path>             Nginx config dir (default: /etc/nginx)
  --systemd-dir <path>           systemd unit dir (default: /etc/systemd/system)
  --keep-daily <n>               Daily retention count (default: 7)
  --keep-weekly <n>              Weekly retention count (default: 4)
  --keep-monthly <n>             Monthly retention count (default: 6)
  --dry-run                      Show actions without writing changes
  --allow-missing-system-paths   Skip missing nginx/systemd paths with warning
  -h, --help                     Show this help

Notes:
  - Intended to run on VPS with root/sudo access.
  - Captures:
    - <nginx-dir>
    - <systemd-dir>/my-portfolio-*.service
    - <base-dir>/shared/env
    - SQLite files from shared/env (<env>.db when present)
USAGE
}

log() { printf '[backup] %s\n' "$*" >&2; }
die() { printf '[backup][error] %s\n' "$*" >&2; exit 1; }

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
    # Controlled internal paths only (callers pass simple shell fragments).
    /bin/bash -c "$1"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --frequency) FREQUENCY="${2:-}"; shift 2 ;;
    --env) ENV_NAME="${2:-}"; shift 2 ;;
    --base-dir) BASE_DIR="${2:-}"; shift 2 ;;
    --backup-root) BACKUP_ROOT="${2:-}"; shift 2 ;;
    --nginx-dir) NGINX_DIR="${2:-}"; shift 2 ;;
    --systemd-dir) SYSTEMD_DIR="${2:-}"; shift 2 ;;
    --keep-daily) KEEP_DAILY="${2:-}"; shift 2 ;;
    --keep-weekly) KEEP_WEEKLY="${2:-}"; shift 2 ;;
    --keep-monthly) KEEP_MONTHLY="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --allow-missing-system-paths) ALLOW_MISSING_SYSTEM_PATHS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1" ;;
  esac
done

[[ -n "$FREQUENCY" ]] || die "--frequency is required"
case "$FREQUENCY" in
  daily|weekly|monthly) ;;
  *) die "--frequency must be one of: daily, weekly, monthly" ;;
esac

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
target_dir="${BACKUP_ROOT}/${FREQUENCY}"
archive_name="my-portfolio-${ENV_NAME}-${FREQUENCY}-${timestamp}.tar.gz"
archive_path="${target_dir}/${archive_name}"
manifest_path="${target_dir}/${archive_name}.manifest.txt"
sha_path="${target_dir}/${archive_name}.sha256"

shared_env_dir="${BASE_DIR}/shared/env"
env_db="${shared_env_dir}/${ENV_NAME}.db"

[[ -d "$shared_env_dir" ]] || die "Missing env dir: $shared_env_dir"
if [[ ! -d "$NGINX_DIR" ]]; then
  if [[ "$ALLOW_MISSING_SYSTEM_PATHS" == "1" || "$DRY_RUN" == "1" ]]; then
    log "warning: missing nginx dir, skipping: $NGINX_DIR"
  else
    die "Missing nginx dir: $NGINX_DIR"
  fi
fi

tmp_manifest="$(mktemp)"
cleanup() { rm -f "$tmp_manifest"; }
trap cleanup EXIT

{
  if [[ -d "$NGINX_DIR" ]]; then
    printf '%s\n' "$NGINX_DIR"
  fi
  for svc in my-portfolio-production.service my-portfolio-staging.service; do
    svc_path="${SYSTEMD_DIR}/${svc}"
    if [[ -f "$svc_path" ]]; then
      printf '%s\n' "$svc_path"
    else
      log "warning: missing systemd unit, skipping: $svc_path"
    fi
  done
  printf '%s\n' "$shared_env_dir"
} >"$tmp_manifest"

if [[ -f "$env_db" ]]; then
  printf '%s\n' "$env_db" >>"$tmp_manifest"
fi

log "frequency=$FREQUENCY env=$ENV_NAME base=$BASE_DIR"
run "mkdir -p '$target_dir'"
run "cp '$tmp_manifest' '$manifest_path'"

if [[ "$DRY_RUN" == "1" ]]; then
  log "would create archive: $archive_path"
  log "manifest:"
  cat "$tmp_manifest"
else
  tar -czf "$archive_path" -T "$tmp_manifest"
  sha256sum "$archive_path" > "$sha_path"
  log "created archive: $archive_path"
  log "sha256 file: $sha_path"
fi

case "$FREQUENCY" in
  daily) keep="$KEEP_DAILY" ;;
  weekly) keep="$KEEP_WEEKLY" ;;
  monthly) keep="$KEEP_MONTHLY" ;;
esac

if [[ "$DRY_RUN" == "1" ]]; then
  log "would retain latest $keep archives in $target_dir"
else
  mapfile -t old_archives < <(ls -1t "$target_dir"/my-portfolio-"$ENV_NAME"-"$FREQUENCY"-*.tar.gz 2>/dev/null | tail -n +"$((keep + 1))")
  if [[ "${#old_archives[@]}" -gt 0 ]]; then
    for old in "${old_archives[@]}"; do
      rm -f "$old" "$old.sha256" "$old.manifest.txt" || true
      log "pruned old archive: $old"
    done
  fi
fi

log "done"
