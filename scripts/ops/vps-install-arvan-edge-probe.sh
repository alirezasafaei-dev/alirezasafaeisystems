#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_SCRIPT="/tmp/asdev-install-arvan-edge-probe.sh"

cat <<'REMOTE' | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "cat > '$REMOTE_SCRIPT' && chmod +x '$REMOTE_SCRIPT' && sudo bash '$REMOTE_SCRIPT' && sudo rm -f '$REMOTE_SCRIPT'"
#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p /var/log/asdev-monitoring /var/lib/asdev-edge-probe /etc/asdev-monitoring
sudo chmod 755 /var/log/asdev-monitoring
sudo chmod 700 /var/lib/asdev-edge-probe

if [[ ! -f /etc/asdev-monitoring/edge-probe.env ]]; then
  cat <<'EOF_ENV' | sudo tee /etc/asdev-monitoring/edge-probe.env >/dev/null
ALERT_MIN_INTERVAL_SECONDS=1200
MAX_TTFB_MS=4000
MAX_TOTAL_MS=12000
EOF_ENV
  sudo chmod 640 /etc/asdev-monitoring/edge-probe.env
fi

cat <<'EOF_SCRIPT' | sudo tee /usr/local/bin/asdev-arvan-edge-probe.sh >/dev/null
#!/usr/bin/env bash
set -euo pipefail

DATE_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOG_FILE="${LOG_FILE:-/var/log/asdev-arvan-edge-probe.log}"
LOCK_FILE="${LOCK_FILE:-/var/lock/asdev-arvan-edge-probe.lock}"
STATE_DIR="${STATE_DIR:-/var/lib/asdev-edge-probe}"
ALERT_MIN_INTERVAL_SECONDS="${ALERT_MIN_INTERVAL_SECONDS:-1200}"
MAX_TTFB_MS="${MAX_TTFB_MS:-4000}"
MAX_TOTAL_MS="${MAX_TOTAL_MS:-12000}"

if [[ -f /etc/asdev-monitoring/edge-probe.env ]]; then
  # shellcheck disable=SC1091
  source /etc/asdev-monitoring/edge-probe.env
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[$DATE_UTC] edge-probe skipped (lock active)" >> "$LOG_FILE"
  exit 0
fi

mkdir -p "$STATE_DIR"

domains=(
  "persiantoolbox.ir"
  "alirezasafaeisystems.ir"
  "audit.alirezasafaeisystems.ir"
)
edges=(
  "185.143.233.235"
  "185.143.234.235"
)

severity="ok"
declare -a failures=()
declare -a slows=()

probe_one() {
  local host="$1"
  local ip="$2"
  local metrics
  metrics="$(curl -sS -o /dev/null --max-time 15 \
    --resolve "${host}:443:${ip}" \
    -w '%{http_code} %{time_starttransfer} %{time_total}' \
    "https://${host}/" || echo 'ERR 99 99')"
  printf '%s' "$metrics"
}

for d in "${domains[@]}"; do
  for ip in "${edges[@]}"; do
    out="$(probe_one "$d" "$ip")"
    code="$(echo "$out" | awk '{print $1}')"
    ttfb_s="$(echo "$out" | awk '{print $2}')"
    total_s="$(echo "$out" | awk '{print $3}')"
    ttfb_ms="$(awk -v s="$ttfb_s" 'BEGIN{printf "%.0f", s*1000}')"
    total_ms="$(awk -v s="$total_s" 'BEGIN{printf "%.0f", s*1000}')"

    echo "[$DATE_UTC] host=$d edge=$ip code=$code ttfb_ms=$ttfb_ms total_ms=$total_ms" >> "$LOG_FILE"

    if [[ "$code" != "200" ]]; then
      severity="warn"
      failures+=("$d@$ip code=$code")
    elif (( ttfb_ms > MAX_TTFB_MS || total_ms > MAX_TOTAL_MS )); then
      severity="warn"
      slows+=("$d@$ip ttfb=${ttfb_ms}ms total=${total_ms}ms")
    fi
  done
done

should_send_alert() {
  local now last_file last
  now="$(date +%s)"
  last_file="$STATE_DIR/last-alert-epoch"
  if [[ ! -f "$last_file" ]]; then
    echo "$now" > "$last_file"
    return 0
  fi
  last="$(cat "$last_file" 2>/dev/null || echo 0)"
  [[ -z "$last" ]] && last=0
  if (( now - last >= ALERT_MIN_INTERVAL_SECONDS )); then
    echo "$now" > "$last_file"
    return 0
  fi
  return 1
}

send_telegram_alert() {
  local msg="$1"
  if [[ -f /opt/asdev-monitoring/.env ]]; then
    # shellcheck disable=SC1091
    source /opt/asdev-monitoring/.env
  fi
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    return 0
  fi
  if ! should_send_alert; then
    return 0
  fi
  curl -sS --max-time 10 -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${msg}" >/dev/null || true
}

if [[ "$severity" != "ok" ]]; then
  fail_txt="$(printf '%s; ' "${failures[@]}")"
  slow_txt="$(printf '%s; ' "${slows[@]}")"
  send_telegram_alert "ASDEV Edge Probe Alert
host: $(hostname)
time: $DATE_UTC
failures: $fail_txt
slow: $slow_txt"
fi

echo "[$DATE_UTC] edge-probe done severity=$severity" >> "$LOG_FILE"
EOF_SCRIPT

sudo chmod 750 /usr/local/bin/asdev-arvan-edge-probe.sh
sudo chown root:root /usr/local/bin/asdev-arvan-edge-probe.sh

cat <<'EOF_CRON' | sudo tee /etc/cron.d/asdev-arvan-edge-probe >/dev/null
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CRON_TZ=Asia/Tehran
*/10 * * * * root /usr/local/bin/asdev-arvan-edge-probe.sh >> /var/log/asdev-arvan-edge-probe.log 2>&1
EOF_CRON
sudo chmod 644 /etc/cron.d/asdev-arvan-edge-probe

cat <<'EOF_LOGROTATE' | sudo tee /etc/logrotate.d/asdev-arvan-edge-probe >/dev/null
/var/log/asdev-arvan-edge-probe.log {
    weekly
    rotate 8
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF_LOGROTATE

echo "installed:/usr/local/bin/asdev-arvan-edge-probe.sh"
echo "cron:/etc/cron.d/asdev-arvan-edge-probe"
echo "logrotate:/etc/logrotate.d/asdev-arvan-edge-probe"
echo "config:/etc/asdev-monitoring/edge-probe.env"
REMOTE

echo "Arvan edge probe installed on VPS."
