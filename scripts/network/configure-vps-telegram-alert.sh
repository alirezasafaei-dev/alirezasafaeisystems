#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
ENV_FILE="/etc/default/asdev-health-watch"
BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"
ALERT_INTERVAL="${ALERT_MIN_INTERVAL_SECONDS:-900}"

if [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
  echo "Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID first." >&2
  echo "Example:" >&2
  echo "TELEGRAM_BOT_TOKEN=... TELEGRAM_CHAT_ID=... $0" >&2
  exit 1
fi

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" \
  "sudo bash -lc 'cat > \"$ENV_FILE\" <<ENVCONF
TELEGRAM_BOT_TOKEN=$BOT_TOKEN
TELEGRAM_CHAT_ID=$CHAT_ID
ALERT_MIN_INTERVAL_SECONDS=$ALERT_INTERVAL
ENVCONF
chmod 600 \"$ENV_FILE\"
sed -n \"1,20p\" \"$ENV_FILE\" | sed -E \"s/(TELEGRAM_BOT_TOKEN=).+/\\1***REDACTED***/\"
/usr/local/bin/asdev-health-watch.sh || true
'"

echo "Configured Telegram alert env on VPS."
