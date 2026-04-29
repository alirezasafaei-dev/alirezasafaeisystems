#!/usr/bin/env bash
set -euo pipefail

DATE_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOG_FILE="${LOG_FILE:-/var/log/asdev-health-watch.log}"
STATE_DIR="${STATE_DIR:-/var/lib/asdev-health-watch}"
ALERT_MIN_INTERVAL_SECONDS="${ALERT_MIN_INTERVAL_SECONDS:-900}"
LOCK_FILE="${LOCK_FILE:-/var/lock/asdev-health-watch.lock}"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[$DATE_UTC] health-watch skipped (lock active)" >> "$LOG_FILE"
  exit 0
fi

ORIGIN_URLS=(
  "http://127.0.0.1:3000/"
  "http://127.0.0.1:3002/api/ready"
  "http://127.0.0.1:3010/api/ready"
)
EDGE_URLS=(
  "https://persiantoolbox.ir/api/ready"
  "https://alirezasafaeisystems.ir/api/ready"
  "https://audit.alirezasafaeisystems.ir/api/ready"
)
ARVAN_EDGE_IPS=(
  "185.143.233.235"
  "185.143.234.235"
)

check_url() {
  local url="$1"
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "$url" || echo ERR)"
  printf '%s' "$code"
}

check_edge_url() {
  local url="$1"
  local code host path
  code="$(check_url "$url")"
  if [[ "$code" == "200" ]]; then
    printf '%s' "$code"
    return 0
  fi

  host="$(printf '%s' "$url" | sed -E 's#https?://([^/]+)/?.*#\1#')"
  path="$(printf '%s' "$url" | sed -E 's#https?://[^/]+(/.*)?#\1#')"
  [[ -n "$path" ]] || path="/"

  for ip in "${ARVAN_EDGE_IPS[@]}"; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 --resolve "${host}:443:${ip}" "https://${host}${path}" || echo ERR)"
    if [[ "$code" == "200" ]]; then
      printf '%s' "$code"
      return 0
    fi
  done

  printf '%s' "${code}"
}

should_send_alert() {
  local now last_file last
  now="$(date +%s)"
  last_file="$STATE_DIR/last-alert-epoch"
  mkdir -p "$STATE_DIR"
  if [[ ! -f "$last_file" ]]; then
    echo "$now" > "$last_file"
    return 0
  fi
  last="$(cat "$last_file" 2>/dev/null || echo 0)"
  if [[ -z "$last" ]]; then
    last=0
  fi
  if (( now - last >= ALERT_MIN_INTERVAL_SECONDS )); then
    echo "$now" > "$last_file"
    return 0
  fi
  return 1
}

send_telegram_alert() {
  local message="$1"
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    return 0
  fi
  if ! should_send_alert; then
    return 0
  fi

  curl -sS --max-time 10 \
    -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${message}" \
    >/dev/null || true
}

status=0
declare -a failures=()
{
  echo "[$DATE_UTC] health-watch start"
  for u in "${ORIGIN_URLS[@]}"; do
    c="$(check_url "$u")"
    echo "origin $u -> $c"
    if [[ "$c" != "200" ]]; then
      status=1
      failures+=("origin $u => $c")
    fi
  done
  for u in "${EDGE_URLS[@]}"; do
    c="$(check_edge_url "$u")"
    echo "edge   $u -> $c"
    if [[ "$c" != "200" ]]; then
      status=1
      failures+=("edge $u => $c")
    fi
  done
  echo "[$DATE_UTC] health-watch done status=$status"
  echo
} >> "$LOG_FILE"

if (( status != 0 )); then
  host="$(hostname)"
  details="$(printf '%s; ' "${failures[@]}")"
  send_telegram_alert "ASDEV Health Alert
host: ${host}
time: ${DATE_UTC}
status: ${status}
failures: ${details}"
fi

exit "$status"
