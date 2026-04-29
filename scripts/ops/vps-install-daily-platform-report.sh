#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_SCRIPT="/tmp/asdev-install-daily-platform-report.sh"

cat <<'REMOTE' | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "cat > '$REMOTE_SCRIPT' && chmod +x '$REMOTE_SCRIPT' && sudo bash '$REMOTE_SCRIPT' && sudo rm -f '$REMOTE_SCRIPT'"
#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p /var/log/asdev-monitoring
sudo chmod 755 /var/log/asdev-monitoring

cat <<'EOF_DAILY' | sudo tee /usr/local/bin/asdev-daily-platform-report.sh >/dev/null
#!/usr/bin/env bash
set -euo pipefail

DATE_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REPORT_FILE="/var/log/asdev-monitoring/daily-platform-$(date -u +%Y%m%dT%H%M%SZ).md"
LATEST_LINK="/var/log/asdev-monitoring/daily-platform-latest.md"

check_http() {
  local url="$1"
  timeout 8 curl -sS -o /tmp/asdev_daily_resp.json -w '%{http_code}' "$url" || echo "ERR"
}

redis_json="/var/log/asdev-monitoring/redis-watch-latest.json"
redis_severity="unknown"
redis_memory_pct="n/a"
if [[ -f "$redis_json" ]]; then
  redis_severity="$(jq -r '.severity // "unknown"' "$redis_json" 2>/dev/null || echo unknown)"
  redis_memory_pct="$(jq -r '.metrics.used_memory_percent // "n/a"' "$redis_json" 2>/dev/null || echo n/a)"
fi

ready_portfolio="$(check_http 'http://127.0.0.1:3002/api/ready')"
ready_toolbox="$(check_http 'http://127.0.0.1:3000/api/ready')"
ready_audit_prod="$(check_http 'http://127.0.0.1:3010/api/ready')"
ready_audit_staging="$(check_http 'http://127.0.0.1:3011/api/ready')"

pm2_summary="$(
  su - deploy -c 'pm2 jlist --silent 2>/dev/null' 2>/dev/null | jq -r '.[] | "\(.name):\(.pm2_env.status)"' 2>/dev/null \
  || pm2 jlist --silent 2>/dev/null | jq -r '.[] | "\(.name):\(.pm2_env.status)"' 2>/dev/null \
  || echo 'pm2_unavailable'
)"
disk_free="$(df -h / | awk 'NR==2 {print $4}')"
load_avg="$(awk '{print $1","$2","$3}' /proc/loadavg)"

{
  echo "# ASDEV Daily Platform Report"
  echo
  echo "- generated_at_utc: $DATE_UTC"
  echo "- disk_free_root: $disk_free"
  echo "- load_avg_1_5_15: $load_avg"
  echo
  echo "## Redis"
  echo "- severity: $redis_severity"
  echo "- memory_percent: $redis_memory_pct"
  echo
  echo "## Readiness"
  echo "- portfolio (3002): $ready_portfolio"
  echo "- toolbox (3000): $ready_toolbox"
  echo "- audit production (3010): $ready_audit_prod"
  echo "- audit staging (3011): $ready_audit_staging"
  echo
  echo "## PM2"
  printf '%s\n' "$pm2_summary" | sed 's/^/- /'
} > "$REPORT_FILE"

ln -sfn "$REPORT_FILE" "$LATEST_LINK"

if [[ -f /opt/asdev-monitoring/.env ]]; then
  # shellcheck disable=SC1091
  source /opt/asdev-monitoring/.env
fi
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  summary="ASDEV Daily Report
time: $DATE_UTC
redis: ${redis_severity} (mem ${redis_memory_pct}%)
ready: portfolio=${ready_portfolio}, toolbox=${ready_toolbox}, audit-prod=${ready_audit_prod}, audit-stg=${ready_audit_staging}
disk_free: ${disk_free}
load: ${load_avg}"
  timeout 10 curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${summary}" >/dev/null || true
fi

echo "DAILY_REPORT=$REPORT_FILE"
EOF_DAILY

sudo chmod 750 /usr/local/bin/asdev-daily-platform-report.sh
sudo chown root:root /usr/local/bin/asdev-daily-platform-report.sh

cat <<'EOF_CRON' | sudo tee /etc/cron.d/asdev-daily-platform-report >/dev/null
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CRON_TZ=Asia/Tehran
15 9 * * * root /usr/local/bin/asdev-daily-platform-report.sh >> /var/log/asdev-daily-platform-report.log 2>&1
EOF_CRON
sudo chmod 644 /etc/cron.d/asdev-daily-platform-report

cat <<'EOF_LOGROTATE' | sudo tee /etc/logrotate.d/asdev-daily-platform-report >/dev/null
/var/log/asdev-daily-platform-report.log {
    weekly
    rotate 8
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF_LOGROTATE

cat <<'EOF_SUDOERS' | sudo tee /etc/sudoers.d/asdev-monitoring-daily-report >/dev/null
deploy ALL=(root) NOPASSWD: /usr/local/bin/asdev-daily-platform-report.sh
EOF_SUDOERS
sudo chmod 440 /etc/sudoers.d/asdev-monitoring-daily-report
sudo visudo -cf /etc/sudoers.d/asdev-monitoring-daily-report >/dev/null

echo "installed:/usr/local/bin/asdev-daily-platform-report.sh"
echo "cron:/etc/cron.d/asdev-daily-platform-report"
echo "logrotate:/etc/logrotate.d/asdev-daily-platform-report"
echo "sudoers:/etc/sudoers.d/asdev-monitoring-daily-report"
REMOTE

echo "Daily platform report stack installed on VPS."
