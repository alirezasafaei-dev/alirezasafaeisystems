#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

DATE_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REPORT_DIR="${LIVE_SURFACE_REPORT_DIR:-docs/runtime/live-surface}"
REPORT_FILE="${LIVE_SURFACE_REPORT_FILE:-${REPORT_DIR}/live-surface-${DATE_UTC}.md}"
LATEST_LINK="${LIVE_SURFACE_LATEST_REPORT:-${REPORT_DIR}/live-surface-latest.md}"

MONITOR_LINKS_STR="${MONITOR_LINKS:-}"
if [[ -z "$MONITOR_LINKS_STR" ]]; then
  MONITOR_LINKS_STR='https://persiantoolbox.ir/ https://persiantoolbox.ir/api/ready https://alirezasafaeisystems.ir/ https://alirezasafaeisystems.ir/profile https://alirezasafaeisystems.ir/resume.pdf https://alirezasafaeisystems.ir/alireza-safaei-resume.pdf https://audit.alirezasafaeisystems.ir/ https://audit.alirezasafaeisystems.ir/api/ready'
fi
read -r -a MONITOR_LINKS <<< "$MONITOR_LINKS_STR"

EXPECTED_MAX_CERT_DAYS="${EXPECTED_MAX_CERT_DAYS:-14}"
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-10}"
MAX_TIME="${MAX_TIME:-20}"
SSH_HOST="${SSH_HOST:-deploy@185.3.124.93}"
VPS_PUBLIC_IPS="${VPS_PUBLIC_IPS:-}"
ENFORCE_HTTP_REDIRECT="${ENFORCE_HTTP_REDIRECT:-0}"

if [[ -f "${REPORT_DIR}" ]]; then
  echo "invalid LIVE_SURFACE_REPORT_DIR (file exists): ${REPORT_DIR}" >&2
  exit 1
fi

mkdir -p "$REPORT_DIR"

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing required command: $cmd" >&2
    exit 1
  fi
}

need_cmd curl
need_cmd awk
need_cmd date
need_cmd openssl

parse_parts() {
  local url="$1"
  local body="$2"
  local host
  local path="/"
  local without_scheme="${url#*://}"
  host="${without_scheme%%/*}"
  if [[ "$without_scheme" == */* ]]; then
    path="/${without_scheme#*/}"
  fi
  if [[ "$body" == "host" ]]; then
    printf '%s\n' "$host"
  else
    printf '%s\n' "$path"
  fi
}

check_dns() {
  local host="$1"
  local dns_result="fail"
  local addrs
  addrs="$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | xargs || true)"
  if [[ -n "$addrs" ]]; then
    dns_result="ok"
  fi
  if [[ -n "$VPS_PUBLIC_IPS" ]]; then
    local expected_ok="no"
    for expected in $VPS_PUBLIC_IPS; do
      if echo "$addrs" | tr ' ' '\n' | grep -Fxq "$expected"; then
        expected_ok="yes"
        break
      fi
    done
    if [[ "$expected_ok" != "yes" ]]; then
      dns_result="ip-mismatch"
    fi
  fi
  printf '%s\n' "$dns_result|$addrs"
}

check_ssl() {
  local host="$1"
  local cert_raw not_after not_before remaining_days code
  cert_raw="$(echo | openssl s_client -servername "$host" -connect "${host}:443" </dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || true)"
  if [[ -z "$cert_raw" ]]; then
    echo "verify_fail|unknown|unknown|unknown"
    return
  fi
  not_before="$(printf '%s\n' "$cert_raw" | awk -F= '/notBefore/{print $2}')"
  not_after="$(printf '%s\n' "$cert_raw" | awk -F= '/notAfter/{print $2}')"
  if [[ -z "$not_after" ]]; then
    echo "verify_fail|$not_before|unknown|unknown"
    return
  fi
  local now epoch_expiry
  now="$(date -u +%s)"
  epoch_expiry="$(date -u -d "$not_after" +%s 2>/dev/null || echo 0)"
  if (( epoch_expiry <= 0 )); then
    echo "verify_fail|$not_before|$not_after|unknown"
    return
  fi
  remaining_days="$(( (epoch_expiry - now) / 86400 ))"
  if (( remaining_days < 0 )); then
    code="expired"
  elif (( remaining_days <= EXPECTED_MAX_CERT_DAYS )); then
    code="low-window"
  else
    code="ok"
  fi
  echo "${code}|${not_before}|${not_after}|${remaining_days}"
}

check_redirect_to_https() {
  local host="$1"
  local path="$2"
  local code
  code="$(curl -sS -o /dev/null -I -m "$CONNECT_TIMEOUT" --max-time "$MAX_TIME" -w "%{http_code}" "http://${host}${path}" 2>/dev/null || echo ERR)"
  if [[ "$code" == "301" || "$code" == "302" || "$code" == "307" || "$code" == "308" ]]; then
    echo "pass"
  elif [[ "$code" == "200" ]]; then
    echo "pass-no-redirect"
  elif [[ "$ENFORCE_HTTP_REDIRECT" == "0" ]]; then
    echo "warn:${code}"
  else
    echo "fail:${code}"
  fi
}

check_http_code() {
  local url="$1"
  local code
  code="$(curl -sS -o /dev/null -L -m "$CONNECT_TIMEOUT" --max-time "$MAX_TIME" "$url" -w '%{http_code}' 2>/dev/null || echo ERR)"
  echo "$code"
}

failures=0
warnings=0
declare -A domain_seen
overall_status="pass"
timestamped_links=()

{
  echo "# Live Surface Audit"
  echo
  echo "- timestamp_utc: ${DATE_UTC}"
  echo "- vps_host: ${SSH_HOST}"
  echo
  echo "## Targets"
  for link in "${MONITOR_LINKS[@]}"; do
    timestamped_links+=("$link")
  done
  printf '%s\n' "${timestamped_links[@]}" | sed 's/^/- /'
  echo
  echo "## Domain Checks"
  for link in "${MONITOR_LINKS[@]}"; do
    host="$(parse_parts "$link" "host")"
    if [[ "${domain_seen[$host]:-0}" == 1 ]]; then
      continue
    fi
    domain_seen["$host"]=1

    dns_line="$(check_dns "$host")"
    dns_status="${dns_line%%|*}"
    dns_addrs="${dns_line#*|}"
    IFS='|' read -r ssl_status not_before not_after remaining_days <<< "$(check_ssl "$host")"

    redirect_status="$(check_redirect_to_https "$host" "/")"

    if [[ "$dns_status" != "ok" && "$dns_status" != "ip-mismatch" ]]; then
      echo "- ${host}: dns=${dns_status} (a_records=${dns_addrs:-none})"
      failures=$((failures+1))
      overall_status="fail"
    else
      echo "- ${host}: dns=${dns_status} (a_records=${dns_addrs:-none})"
    fi
    echo "  - ssl: ${ssl_status} (not_after=${not_after}, days_left=${remaining_days})"
    echo "  - https_redirect: ${redirect_status}"

    if [[ "$dns_status" == "ip-mismatch" ]]; then
      failures=$((failures+1))
      overall_status="fail"
    fi
    if [[ "$ssl_status" == "verify_fail" || "$ssl_status" == "expired" ]]; then
      failures=$((failures+1))
      overall_status="fail"
    elif [[ "$ssl_status" == "low-window" ]]; then
      warnings=$((warnings+1))
    fi

    if [[ "$redirect_status" == "fail:"* ]]; then
      warnings=$((warnings+1))
    fi
    if [[ "$redirect_status" == "warn:"* && "$dns_status" != "ok" ]]; then
      warnings=$((warnings+1))
    fi
  done
  echo
  echo "## Link Checks"
  for link in "${MONITOR_LINKS[@]}"; do
    host="$(parse_parts "$link" "host")"
    path="$(parse_parts "$link" "path")"
    code="$(check_http_code "$link")"
    redirect_code="$(check_redirect_to_https "$host" "$path")"
    if [[ "$code" != "200" ]]; then
      failures=$((failures+1))
      overall_status="fail"
    fi
    if [[ "$redirect_code" == "fail:"* ]]; then
      failures=$((failures+1))
      overall_status="fail"
    fi
    echo "- ${link} -> ${code} (https path) | redirect=${redirect_code}"
  done
  echo
  echo "## Summary"
  echo "- failures: ${failures}"
  echo "- warnings: ${warnings}"
  echo "- status: ${overall_status}"
  echo "- expected cert window warning threshold: ${EXPECTED_MAX_CERT_DAYS} days"
  echo
} | tee "$REPORT_FILE"

ln -sfn "$REPORT_FILE" "$LATEST_LINK"

echo "report=${REPORT_FILE}"
echo "latest=${LATEST_LINK}"

if [[ "$overall_status" != "pass" ]]; then
  exit 1
fi
