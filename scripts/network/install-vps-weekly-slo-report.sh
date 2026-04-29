#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_SCRIPT="/usr/local/bin/asdev-weekly-slo-report.sh"
CRON_FILE="/etc/cron.d/asdev-weekly-slo-report"
ENV_FILE="/etc/default/asdev-health-watch"

LOCAL_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_WEEKLY_SCRIPT="$LOCAL_SCRIPT_DIR/vps-weekly-slo-report.sh"

if [[ ! -f "$LOCAL_WEEKLY_SCRIPT" ]]; then
  echo "Missing $LOCAL_WEEKLY_SCRIPT" >&2
  exit 1
fi

cat "$LOCAL_WEEKLY_SCRIPT" | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo tee '$REMOTE_SCRIPT' >/dev/null && sudo chmod 755 '$REMOTE_SCRIPT'"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "sudo bash -lc '
cat > $CRON_FILE <<CRON
55 23 * * 0 root . $ENV_FILE; $REMOTE_SCRIPT
CRON
chmod 644 $CRON_FILE
'
sudo bash -lc '. $ENV_FILE; $REMOTE_SCRIPT' || true
sudo sed -n '1,80p' $CRON_FILE
sudo ls -lt /var/log/asdev-health-weekly-*.md 2>/dev/null | head -n 3 || true
sudo sed -n '1,120p' /var/log/asdev-health-weekly-latest.md 2>/dev/null || true"

echo "Installed weekly SLO report cron."
