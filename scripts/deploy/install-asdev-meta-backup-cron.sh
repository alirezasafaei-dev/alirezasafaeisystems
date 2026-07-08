#!/usr/bin/env bash
# Install user crontab entry for ASDEV meta backup (not monitoring live timers).
# Safe: does not touch nginx/DNS/SSL/prod process. Idempotent.
set -euo pipefail

PLATFORM_ROOT="${ASDEV_PLATFORM_ROOT:-/home/asdev/asdev-platform}"
WRAPPER="${ASDEV_META_BACKUP_WRAPPER:-$HOME/bin/asdev-meta-backup.sh}"
CRON_SCHEDULE="${ASDEV_META_BACKUP_CRON:-15 3 * * *}"
SITE_ROOT="${ASDEV_SITE_ROOT:-/srv/asdev/sites/persiantoolbox}"
BACKUP_ROOT="${ASDEV_BACKUP_ROOT:-/srv/asdev/backups/persiantoolbox}"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--execute]

Install daily meta-backup cron for CRITICAL_SITE layout.

Default schedule: 15 3 * * * (03:15 UTC)
EOF
}

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

EXECUTE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --execute) EXECUTE=true; DRY_RUN=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

if [[ "$EXECUTE" != "true" ]]; then
  DRY_RUN=true
fi

log "platform=$PLATFORM_ROOT wrapper=$WRAPPER schedule='$CRON_SCHEDULE'"

if [[ "$DRY_RUN" == "true" ]]; then
  log "[DRY RUN] Would write $WRAPPER and install cron"
  exit 0
fi

mkdir -p "$(dirname "$WRAPPER")" "$HOME/logs" "$BACKUP_ROOT"

cat >"$WRAPPER" <<WRAP
#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:\$HOME/.local/bin:\$PATH"
BASE="$PLATFORM_ROOT"
LOG="\$HOME/logs/asdev-meta-backup.log"
mkdir -p "\$(dirname "\$LOG")"
{
  echo "==== \$(date -u +%Y-%m-%dT%H:%M:%SZ) meta-backup start ===="
  bash "\$BASE/scripts/deploy/asdev-backup-site.sh" \\
    --site-root "$SITE_ROOT" \\
    --backup-root "$BACKUP_ROOT" \\
    --execute
  cd "$BACKUP_ROOT"
  ls -1d 20* 2>/dev/null | sort | head -n -14 | while read -r d; do
    rm -rf "\$d" "\${d}.tar.gz" 2>/dev/null || true
  done
  echo "==== \$(date -u +%Y-%m-%dT%H:%M:%SZ) meta-backup end ===="
} >>"\$LOG" 2>&1
WRAP
chmod +x "$WRAPPER"

CRON_LINE="$CRON_SCHEDULE $WRAPPER"
( crontab -l 2>/dev/null | grep -v 'asdev-meta-backup.sh' || true; echo "$CRON_LINE" ) | crontab -
log "crontab installed"
crontab -l | grep asdev-meta-backup || true
log "INSTALL_OK"
