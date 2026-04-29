#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/dev/.ssh/id_ed25519}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
REMOTE_SCRIPT="/tmp/asdev-install-redis-monitoring.sh"

cat <<'REMOTE' | ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$SSH_HOST" "cat > '$REMOTE_SCRIPT' && chmod +x '$REMOTE_SCRIPT' && sudo bash '$REMOTE_SCRIPT' && sudo rm -f '$REMOTE_SCRIPT'"
#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p /opt/asdev-monitoring /var/log/asdev-monitoring /var/lib/asdev-redis-watch
sudo chmod 755 /opt/asdev-monitoring /var/log/asdev-monitoring
sudo chmod 700 /var/lib/asdev-redis-watch

if [[ ! -f /etc/asdev-monitoring/redis-watch.env ]]; then
  sudo mkdir -p /etc/asdev-monitoring
  cat <<'EOF_ENV' | sudo tee /etc/asdev-monitoring/redis-watch.env >/dev/null
# Redis watch tuning
ALERT_MIN_INTERVAL_SECONDS=1200
MAX_MEMORY_PCT=75
MAX_REJECTED_CONNECTIONS_DELTA=5
MAX_BLOCKED_CLIENTS=5
MAX_LATENCY_MS=120
EOF_ENV
  sudo chmod 640 /etc/asdev-monitoring/redis-watch.env
fi

cat <<'EOF_WATCH' | sudo tee /usr/local/bin/asdev-redis-watch.sh >/dev/null
#!/usr/bin/env bash
set -euo pipefail

DATE_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOG_FILE="${LOG_FILE:-/var/log/asdev-redis-watch.log}"
STATE_DIR="${STATE_DIR:-/var/lib/asdev-redis-watch}"
REPORT_DIR="${REPORT_DIR:-/var/log/asdev-monitoring}"
LOCK_FILE="${LOCK_FILE:-/var/lock/asdev-redis-watch.lock}"
ALERT_MIN_INTERVAL_SECONDS="${ALERT_MIN_INTERVAL_SECONDS:-900}"
MAX_MEMORY_PCT="${MAX_MEMORY_PCT:-85}"
MAX_REJECTED_CONNECTIONS_DELTA="${MAX_REJECTED_CONNECTIONS_DELTA:-0}"
MAX_BLOCKED_CLIENTS="${MAX_BLOCKED_CLIENTS:-3}"
MAX_LATENCY_MS="${MAX_LATENCY_MS:-60}"

if [[ -f /etc/asdev-monitoring/redis-watch.env ]]; then
  # shellcheck disable=SC1091
  source /etc/asdev-monitoring/redis-watch.env
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[$DATE_UTC] redis-watch skipped (lock active)" >> "$LOG_FILE"
  exit 0
fi

mkdir -p "$STATE_DIR" "$REPORT_DIR"

REDIS_URL=""
if [[ -f /etc/asdev-redis/credentials.env ]]; then
  REDIS_URL="$(sed -n 's/^REDIS_URL=//p' /etc/asdev-redis/credentials.env | head -n1)"
fi

if [[ -z "$REDIS_URL" ]]; then
  echo "[$DATE_UTC] redis-watch no REDIS_URL found" >> "$LOG_FILE"
  exit 1
fi

redis_info_raw="$(redis-cli --no-auth-warning -u "$REDIS_URL" INFO 2>/dev/null || true)"
if [[ -z "$redis_info_raw" ]]; then
  echo "[$DATE_UTC] redis-watch failed to fetch INFO" >> "$LOG_FILE"
  exit 1
fi

get_info() {
  local key="$1"
  printf '%s\n' "$redis_info_raw" | awk -F: -v k="$key" '$1==k {print $2; found=1} END{if(!found) print ""}' | tr -d '\r'
}

used_memory="$(get_info used_memory)"
maxmemory="$(get_info maxmemory)"
blocked_clients="$(get_info blocked_clients)"
rejected_connections="$(get_info rejected_connections)"
evicted_keys="$(get_info evicted_keys)"
connected_clients="$(get_info connected_clients)"
uptime_in_seconds="$(get_info uptime_in_seconds)"
instantaneous_ops_per_sec="$(get_info instantaneous_ops_per_sec)"

latency_us="$(redis-cli --no-auth-warning -u "$REDIS_URL" --raw LATENCY LATEST 2>/dev/null | awk 'NR==4 {print $1; exit}')"
[[ -n "$latency_us" ]] || latency_us=0
latency_ms=$(( latency_us / 1000 ))

used_memory="${used_memory:-0}"
maxmemory="${maxmemory:-0}"
blocked_clients="${blocked_clients:-0}"
rejected_connections="${rejected_connections:-0}"
evicted_keys="${evicted_keys:-0}"
connected_clients="${connected_clients:-0}"
uptime_in_seconds="${uptime_in_seconds:-0}"
instantaneous_ops_per_sec="${instantaneous_ops_per_sec:-0}"

if [[ "$maxmemory" -gt 0 ]]; then
  memory_pct="$(awk -v u="$used_memory" -v m="$maxmemory" 'BEGIN{printf "%.2f", (u/m)*100}')"
else
  memory_pct="0.00"
fi

prev_rejected_file="$STATE_DIR/prev_rejected_connections"
prev_evicted_file="$STATE_DIR/prev_evicted_keys"
prev_rejected=0
prev_evicted=0
[[ -f "$prev_rejected_file" ]] && prev_rejected="$(cat "$prev_rejected_file" 2>/dev/null || echo 0)"
[[ -f "$prev_evicted_file" ]] && prev_evicted="$(cat "$prev_evicted_file" 2>/dev/null || echo 0)"

delta_rejected=$(( rejected_connections - prev_rejected ))
delta_evicted=$(( evicted_keys - prev_evicted ))
(( delta_rejected < 0 )) && delta_rejected=0
(( delta_evicted < 0 )) && delta_evicted=0

echo "$rejected_connections" > "$prev_rejected_file"
echo "$evicted_keys" > "$prev_evicted_file"

severity="ok"
declare -a alerts=()

memory_pct_int="$(printf '%.0f' "$memory_pct")"
if (( memory_pct_int >= MAX_MEMORY_PCT )); then
  severity="warn"
  alerts+=("memory_pct=${memory_pct} threshold=${MAX_MEMORY_PCT}")
fi
if (( delta_rejected > MAX_REJECTED_CONNECTIONS_DELTA )); then
  severity="warn"
  alerts+=("rejected_connections_delta=${delta_rejected}")
fi
if (( blocked_clients > MAX_BLOCKED_CLIENTS )); then
  severity="warn"
  alerts+=("blocked_clients=${blocked_clients}")
fi
if (( latency_ms > MAX_LATENCY_MS )); then
  severity="warn"
  alerts+=("latency_ms=${latency_ms}")
fi
if (( delta_evicted > 0 )); then
  severity="warn"
  alerts+=("evicted_keys_delta=${delta_evicted}")
fi

run_id="$(date -u +%Y%m%dT%H%M%SZ)"
json_report="$REPORT_DIR/redis-watch-${run_id}.json"
latest_json="$REPORT_DIR/redis-watch-latest.json"

cat > "$json_report" <<EOF_JSON
{
  "generated_at_utc": "$DATE_UTC",
  "severity": "$severity",
  "metrics": {
    "used_memory_bytes": $used_memory,
    "maxmemory_bytes": $maxmemory,
    "used_memory_percent": $memory_pct,
    "connected_clients": $connected_clients,
    "blocked_clients": $blocked_clients,
    "rejected_connections_total": $rejected_connections,
    "rejected_connections_delta": $delta_rejected,
    "evicted_keys_total": $evicted_keys,
    "evicted_keys_delta": $delta_evicted,
    "latency_ms_latest": $latency_ms,
    "instantaneous_ops_per_sec": $instantaneous_ops_per_sec,
    "uptime_in_seconds": $uptime_in_seconds
  }
}
EOF_JSON
ln -sfn "$json_report" "$latest_json"

{
  echo "[$DATE_UTC] severity=$severity memory_pct=$memory_pct connected=$connected_clients blocked=$blocked_clients rejected_delta=$delta_rejected evicted_delta=$delta_evicted latency_ms=$latency_ms ops=$instantaneous_ops_per_sec"
} >> "$LOG_FILE"

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
  local message="$1"
  local env_file="/opt/asdev-monitoring/.env"
  if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    source "$env_file"
  fi
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    return 0
  fi
  if ! should_send_alert; then
    return 0
  fi
  curl -sS --max-time 10 \
    -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${message}" >/dev/null || true
}

if [[ "$severity" != "ok" ]]; then
  details="$(printf '%s; ' "${alerts[@]}")"
  send_telegram_alert "ASDEV Redis Alert
host: $(hostname)
time: $DATE_UTC
severity: $severity
details: $details"
fi
EOF_WATCH

sudo chmod 750 /usr/local/bin/asdev-redis-watch.sh
sudo chown root:root /usr/local/bin/asdev-redis-watch.sh

cat <<'EOF_CRON' | sudo tee /etc/cron.d/asdev-redis-watch >/dev/null
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CRON_TZ=Asia/Tehran
*/10 * * * * root /usr/local/bin/asdev-redis-watch.sh >> /var/log/asdev-redis-watch.log 2>&1
EOF_CRON
sudo chmod 644 /etc/cron.d/asdev-redis-watch

cat <<'EOF_LOGROTATE' | sudo tee /etc/logrotate.d/asdev-redis-watch >/dev/null
/var/log/asdev-redis-watch.log {
    weekly
    rotate 8
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
EOF_LOGROTATE

echo "installed:/usr/local/bin/asdev-redis-watch.sh"
echo "cron:/etc/cron.d/asdev-redis-watch"
echo "logrotate:/etc/logrotate.d/asdev-redis-watch"
echo "config:/etc/asdev-monitoring/redis-watch.env"
REMOTE

echo "Redis monitoring stack installed on VPS."
