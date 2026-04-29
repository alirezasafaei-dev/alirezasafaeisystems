#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_SCRIPT="/usr/local/bin/asdev-health-watch.sh"
CRON_FILE="/etc/cron.d/asdev-health-watch"
ENV_FILE="/etc/default/asdev-health-watch"
LOGROTATE_FILE="/etc/logrotate.d/asdev-health-watch"

LOCAL_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_WATCH_SCRIPT="$LOCAL_SCRIPT_DIR/vps-health-watch.sh"

if [[ ! -f "$LOCAL_WATCH_SCRIPT" ]]; then
  echo "Missing $LOCAL_WATCH_SCRIPT" >&2
  exit 1
fi

cat "$LOCAL_WATCH_SCRIPT" | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo tee '$REMOTE_SCRIPT' >/dev/null && sudo chmod 755 '$REMOTE_SCRIPT'"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo bash -lc '
if [[ ! -f \"$ENV_FILE\" ]]; then
  cat > \"$ENV_FILE\" <<ENVCONF
# Optional Telegram alerts
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
# Minimum interval between alerts in seconds
ALERT_MIN_INTERVAL_SECONDS=900
ENVCONF
  chmod 600 \"$ENV_FILE\"
fi

cat > $CRON_FILE <<CRON
*/5 * * * * root . $ENV_FILE; $REMOTE_SCRIPT
CRON
chmod 644 $CRON_FILE
cat > $LOGROTATE_FILE <<ROT
/var/log/asdev-health-watch.log {
  daily
  rotate 14
  missingok
  notifempty
  compress
  delaycompress
  copytruncate
}
ROT
chmod 644 $LOGROTATE_FILE
'
sudo run-parts --test /etc/cron.d >/dev/null 2>&1 || true
sudo $REMOTE_SCRIPT || true
sudo tail -n 40 /var/log/asdev-health-watch.log || true
sudo sed -n \"1,120p\" $ENV_FILE
sudo sed -n \"1,80p\" $CRON_FILE
sudo sed -n \"1,80p\" $LOGROTATE_FILE"

echo "Installed VPS health watch."
