#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_SCRIPT="/tmp/asdev-install-pg-backup.sh"

cat <<'REMOTE' | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "cat > '$REMOTE_SCRIPT' && chmod +x '$REMOTE_SCRIPT' && sudo bash '$REMOTE_SCRIPT' && sudo rm -f '$REMOTE_SCRIPT'"
#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF_SCRIPT' | sudo tee /usr/local/bin/asdev-postgres-backup.sh >/dev/null
#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="/var/backups/asdev-postgres"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
RUN_TS="$(date -u +%Y%m%dT%H%M%SZ)"
TARGET_DIR="$BACKUP_ROOT/$RUN_TS"
LOG_PREFIX="[asdev-postgres-backup]"

DBS=(
  "asdev_audit_production"
  "asdev_audit_staging"
  "persian_tools_prod"
  "persian_tools_staging"
  "asdev_portfolio_production"
  "asdev_portfolio_staging"
)

notify_telegram() {
  local msg="$1"
  local env_file="/opt/asdev-monitoring/.env"
  if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    source "$env_file"
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
      curl -sS -m 10 --retry 1 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${msg}" >/dev/null || true
    fi
  fi
}

cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    notify_telegram "🚨 ASDEV PostgreSQL backup failed on $(hostname) at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "$LOG_PREFIX failed exit_code=$exit_code"
  fi
}
trap cleanup EXIT

mkdir -p "$TARGET_DIR"
chmod 700 "$BACKUP_ROOT" "$TARGET_DIR"
chown postgres:postgres "$BACKUP_ROOT" "$TARGET_DIR"

echo "$LOG_PREFIX start ts=$RUN_TS target=$TARGET_DIR"
for db in "${DBS[@]}"; do
  out_file="$TARGET_DIR/${db}.dump"
  echo "$LOG_PREFIX dumping db=$db"
  runuser -u postgres -- pg_dump -Fc -d "$db" -f "$out_file"
done

(
  cd "$TARGET_DIR"
  sha256sum ./*.dump > SHA256SUMS
)

find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" -print -exec rm -rf {} +
echo "$LOG_PREFIX done ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF_SCRIPT

sudo chmod 750 /usr/local/bin/asdev-postgres-backup.sh
sudo chown root:root /usr/local/bin/asdev-postgres-backup.sh

cat <<'EOF_CRON' | sudo tee /etc/cron.d/asdev-postgres-backup >/dev/null
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CRON_TZ=Asia/Tehran
40 3 * * * root /usr/local/bin/asdev-postgres-backup.sh >> /var/log/asdev-postgres-backup.log 2>&1
EOF_CRON

sudo chmod 644 /etc/cron.d/asdev-postgres-backup

cat <<'EOF_LOGROTATE' | sudo tee /etc/logrotate.d/asdev-postgres-backup >/dev/null
/var/log/asdev-postgres-backup.log {
    weekly
    rotate 8
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF_LOGROTATE

echo "installed:/usr/local/bin/asdev-postgres-backup.sh"
echo "cron:/etc/cron.d/asdev-postgres-backup"
echo "logrotate:/etc/logrotate.d/asdev-postgres-backup"
REMOTE

echo "Installed PostgreSQL backup automation on VPS."
