#!/usr/bin/env bash
# Onsite backup of an ASDEV site layout (release meta + manifests).
# Does NOT dump secrets into the archive by default.
# Safe: --dry-run does not write. Live write only when --execute set.
set -euo pipefail

SITE_ROOT="${ASDEV_SITE_ROOT:-/srv/asdev/sites/persiantoolbox}"
BACKUP_ROOT="${ASDEV_BACKUP_ROOT:-/srv/asdev/backups/persiantoolbox}"
EXECUTE=false
DRY_RUN=true
INCLUDE_SHARED_ENV=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Backup ASDEV site release pointer + metadata (not full node_modules).

Options:
  --site-root <path>     default /srv/asdev/sites/persiantoolbox
  --backup-root <path>   default /srv/asdev/backups/persiantoolbox
  --execute              actually write backup (default is dry-run)
  --dry-run              force dry-run (default)
  --include-shared-env   include shared/env* (owner must ensure encrypted storage)
  -h, --help
EOF
}

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site-root) SITE_ROOT="$2"; shift 2 ;;
    --backup-root) BACKUP_ROOT="$2"; shift 2 ;;
    --execute) EXECUTE=true; DRY_RUN=false; shift ;;
    --dry-run) DRY_RUN=true; EXECUTE=false; shift ;;
    --include-shared-env) INCLUDE_SHARED_ENV=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1" ;;
  esac
done

TS=$(date -u +%Y%m%dT%H%M%SZ)
DEST="${BACKUP_ROOT}/${TS}"

echo "========================================"
echo "  ASDEV SITE BACKUP"
echo "  site_root=$SITE_ROOT"
echo "  dest=$DEST"
echo "  mode=$([ "$EXECUTE" = true ] && echo EXECUTE || echo DRY_RUN)"
echo "========================================"

if [[ ! -d "$SITE_ROOT" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[DRY RUN] site_root missing (ok on non-IRAN host): $SITE_ROOT"
    ok "Dry-run complete"
    exit 0
  fi
  err "site_root not found: $SITE_ROOT"
fi

current=""
if [[ -e "$SITE_ROOT/current" ]]; then
  current=$(readlink -f "$SITE_ROOT/current" 2>/dev/null || true)
fi

log "current=${current:-none}"

if [[ "$DRY_RUN" == "true" ]]; then
  log "[DRY RUN] Would mkdir -p $DEST"
  log "[DRY RUN] Would copy release.meta, pid, list releases/"
  log "[DRY RUN] Would write backup.manifest"
  [[ "$INCLUDE_SHARED_ENV" == "true" ]] && log "[DRY RUN] Would include shared env (sensitive)"
  ok "Dry-run complete"
  exit 0
fi

mkdir -p "$DEST"
{
  echo "created_at=$TS"
  echo "site_root=$SITE_ROOT"
  echo "current=${current:-}"
  echo "host_alias=IRAN_PROD"
} >"$DEST/backup.manifest"

if [[ -n "$current" && -f "$current/release.meta" ]]; then
  cp -a "$current/release.meta" "$DEST/release.meta"
fi
if [[ -f "$SITE_ROOT/asdev-runtime.pid" ]]; then
  cp -a "$SITE_ROOT/asdev-runtime.pid" "$DEST/asdev-runtime.pid"
fi
if [[ -d "$SITE_ROOT/releases" ]]; then
  ls -1 "$SITE_ROOT/releases" >"$DEST/releases.list" || true
fi
if [[ -e "$SITE_ROOT/current" ]]; then
  readlink "$SITE_ROOT/current" >"$DEST/current.link" || true
fi

if [[ "$INCLUDE_SHARED_ENV" == "true" && -d "$SITE_ROOT/shared" ]]; then
  mkdir -p "$DEST/shared"
  # copy only env-like files; caller must protect DEST
  find "$SITE_ROOT/shared" -maxdepth 2 \( -name '.env*' -o -name 'env' -o -name '*.env' \) \
    -type f -exec cp -a {} "$DEST/shared/" \; 2>/dev/null || true
  log "WARN: shared env included — encrypt offsite; never commit"
fi

# lightweight tarball of meta only
tar -C "$DEST" -czf "${DEST}.tar.gz" . 2>/dev/null || tar -czf "${DEST}.tar.gz" -C "$DEST" .
ok "backup written dest=$DEST archive=${DEST}.tar.gz"
echo "BACKUP_OK path=$DEST"
