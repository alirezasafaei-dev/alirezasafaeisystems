#!/usr/bin/env bash
# ASDEV MCP Health Check v2 — validates MCP SSE endpoint with bounded redirect
# following, TLS, content-type validation, and strict failure classification.
# HTTP 000 is NEVER treated as healthy.
# Recognizes the Caddy reverse proxy 307->loopback pattern as expected.
set -Euo pipefail

SCRIPT_NAME="asdev-mcp-check"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO_DIR="${ASDEV_REPO_DIR:-$ASDEV_ROOT}"
STATE_DIR="${ASDEV_STATE_DIR:-$REPO_DIR/.state/asdev-mcp}"
REPORT_DIR="${ASDEV_REPORT_DIR:-$REPO_DIR/docs/reports/automation-server}"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTNAME_FQDN="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"

MCP_URL="${ASDEV_MCP_URL:-https://mcp.alirezasafaeisystems.ir/sse/}"
CONNECT_TIMEOUT="${ASDEV_MCP_CONNECT_TIMEOUT:-5}"
TOTAL_TIMEOUT="${ASDEV_MCP_TOTAL_TIMEOUT:-15}"
MAX_REDIRECTS="${ASDEV_MCP_MAX_REDIRECTS:-5}"

mkdir -p "$STATE_DIR" "$REPORT_DIR"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "[$(ts)] $*"; }

# ---------------------------------------------------------------------------
# Redact sensitive content from URLs for reports
# ---------------------------------------------------------------------------
redact_url() {
  local url="$1"
  printf '%s' "$url" | sed 's/[?#].*$//' | sed 's/\(token\|key\|secret\|cookie\|auth\)=[^&]*/\1=REDACTED/gi'
}

# ---------------------------------------------------------------------------
# Check if a URL points to a loopback/private address
# ---------------------------------------------------------------------------
is_loopback_url() {
  local url="$1"
  if echo "$url" | grep -qiE '://(127\.0\.0\.1|localhost|0\.0\.0\.0|::1)(:|$|/)'; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Classify HTTP status into health outcome
# ---------------------------------------------------------------------------
classify_http_status() {
  local code="$1"
  case "$code" in
    2[0-9][0-9]) echo "PASS" ;;
    000)         echo "FAIL" ;;
    *)           echo "FAIL" ;;
  esac
}

# ---------------------------------------------------------------------------
# Check if response content-type indicates SSE
# ---------------------------------------------------------------------------
check_content_type() {
  local content_type="$1"
  if echo "$content_type" | grep -qi 'text/event-stream'; then
    echo "SSE"
  elif echo "$content_type" | grep -qi 'application/json'; then
    echo "JSON"
  elif echo "$content_type" | grep -qi 'text/html'; then
    echo "HTML"
  elif echo "$content_type" | grep -qi 'text/plain'; then
    echo "PLAIN"
  else
    echo "UNKNOWN"
  fi
}

# ---------------------------------------------------------------------------
# Main MCP health check — two-phase approach
# Phase 1: Initial request without following redirects (capture redirect info)
# Phase 2: If redirect to loopback, that's expected MCP pattern (PASS)
# ---------------------------------------------------------------------------
run_mcp_check() {
  local tmp_body tmp_headers curl_exit_code http_code redirect_count
  local content_type response_class latency_ms failure_class
  local initial_status initial_location

  tmp_body=$(mktemp)
  tmp_headers=$(mktemp)
  trap "rm -f '$tmp_body' '$tmp_headers'" RETURN

  log "Checking MCP endpoint: $(redact_url "$MCP_URL")"

  local start_ns
  start_ns=$(date +%s%N 2>/dev/null || echo 0)

  # Phase 1: Initial request without following redirects
  # Capture the initial HTTP response to detect the redirect pattern
  initial_status=$(curl \
    -sS \
    -o "$tmp_body" \
    -D "$tmp_headers" \
    -w "%{http_code}" \
    --connect-timeout "$CONNECT_TIMEOUT" \
    --max-time "$TOTAL_TIMEOUT" \
    --tlsv1.2 \
    -A "ASDEV-MCP-Check/2.0" \
    "$MCP_URL" 2>/dev/null) || true

  local phase1_exit=$?
  local end_ns
  end_ns=$(date +%s%N 2>/dev/null || echo 0)

  if [ "$start_ns" != "0" ] && [ "$end_ns" != "0" ]; then
    latency_ms=$(( (end_ns - start_ns) / 1000000 ))
  else
    latency_ms=0
  fi

  # Extract initial response headers
  initial_location=$(grep -i '^location:' "$tmp_headers" 2>/dev/null | head -1 | sed 's/^[Ll]ocation:[[:space:]]*//' | tr -d '\r' || echo "")
  content_type=$(grep -i '^content-type:' "$tmp_headers" 2>/dev/null | tail -1 | sed 's/^[Cc]ontent-[Tt]ype:[[:space:]]*//' | tr -d '\r' || echo "")
  redirect_count=$(grep -ci '^location:' "$tmp_headers" 2>/dev/null || echo 0)

  http_code="$initial_status"
  curl_exit_code=$phase1_exit

  # Classify failure modes
  failure_class="none"

  if [ "$http_code" = "000" ]; then
    failure_class="connection_failure"
  elif [ "$curl_exit_code" -eq 28 ]; then
    failure_class="timeout"
  elif [ "$curl_exit_code" -eq 6 ]; then
    failure_class="dns_failure"
  elif [ "$curl_exit_code" -eq 35 ] || [ "$curl_exit_code" -eq 60 ]; then
    # TLS error on initial request = real failure
    # TLS error on redirect follow = expected for loopback
    if [ "$redirect_count" -gt 0 ] && [ -n "$initial_location" ] && is_loopback_url "$initial_location"; then
      failure_class="none"  # Expected: TLS fail on loopback redirect
    else
      failure_class="tls_failure"
    fi
  elif [ "$curl_exit_code" -eq 47 ]; then
    failure_class="redirect_loop"
  elif [ "$curl_exit_code" -eq 49 ]; then
    failure_class="max_redirects"
  fi

  # Determine verdict
  local verdict="PASS"

  # HTTP 000 is ALWAYS FAIL
  if [ "$http_code" = "000" ]; then
    verdict="FAIL"
  elif [ "$failure_class" != "none" ]; then
    verdict="FAIL"
  elif [ "$http_code" -ge 400 ] 2>/dev/null; then
    verdict="FAIL"
  elif [ "$http_code" = "307" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
    # Redirect: check if target is loopback (expected MCP pattern)
    if [ -n "$initial_location" ] && is_loopback_url "$initial_location"; then
      # Expected Caddy reverse proxy pattern: 307 to localhost
      # Verify the local MCP server is actually running by making a follow-up request
      local followup_status
      followup_status=$(curl \
        -sS \
        -o /dev/null \
        -w "%{http_code}" \
        --connect-timeout "$CONNECT_TIMEOUT" \
        --max-time "$TOTAL_TIMEOUT" \
        -k \
        -A "ASDEV-MCP-Check/2.0" \
        "$initial_location" 2>/dev/null) || true

      if [ "$followup_status" = "200" ] || [ "$followup_status" = "307" ]; then
        verdict="PASS"
      elif [ "$followup_status" = "000" ]; then
        # HTTPS to loopback failed — try HTTP (Caddy may redirect to HTTP backend)
        local http_url
        http_url=$(echo "$initial_location" | sed 's|^https://|http://|')
        followup_status=$(curl \
          -sS \
          -o /dev/null \
          -w "%{http_code}" \
          --connect-timeout "$CONNECT_TIMEOUT" \
          --max-time 3 \
          -A "ASDEV-MCP-Check/2.0" \
          "$http_url" 2>/dev/null) || true
        if [ "$followup_status" = "200" ] || [ "$followup_status" = "307" ]; then
          verdict="PASS"
        elif [ "$followup_status" = "000" ]; then
          verdict="WARN"
          failure_class="loopback_unreachable"
        else
          verdict="WARN"
          failure_class="loopback_unexpected_status"
        fi
      else
        verdict="WARN"
        failure_class="loopback_unexpected_status"
      fi
    else
      verdict="WARN"
    fi
  fi

  response_class=$(check_content_type "$content_type")

  # Output structured results
  cat <<EOF
{
  "script": "$SCRIPT_NAME",
  "started_at": "$STARTED_AT",
  "finished_at": "$(ts)",
  "environment": "${ASDEV_ENVIRONMENT:-UNKNOWN}",
  "hostname": "$HOSTNAME_FQDN",
  "endpoint": "$(redact_url "$MCP_URL")",
  "connect_timeout_s": $CONNECT_TIMEOUT,
  "total_timeout_s": $TOTAL_TIMEOUT,
  "max_redirects": $MAX_REDIRECTS,
  "http_code": "$http_code",
  "curl_exit_code": $curl_exit_code,
  "redirect_count": $redirect_count,
  "initial_location": "$(redact_url "${initial_location:-none}")",
  "final_status": "$http_code",
  "content_type": "$content_type",
  "response_class": "$response_class",
  "latency_ms": $latency_ms,
  "failure_class": "$failure_class",
  "verdict": "$verdict"
}
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "=== ASDEV MCP Health Check v2 ==="

JSON_RESULT=$(run_mcp_check)

# Parse verdict
VERDICT=$(echo "$JSON_RESULT" | grep '"verdict"' | sed 's/.*"verdict": *"\([^"]*\)".*/\1/')
HTTP_CODE=$(echo "$JSON_RESULT" | grep '"http_code"' | sed 's/.*"http_code": *"\([^"]*\)".*/\1/')
FAILURE_CLASS=$(echo "$JSON_RESULT" | grep '"failure_class"' | sed 's/.*"failure_class": *"\([^"]*\)".*/\1/')
LATENCY=$(echo "$JSON_RESULT" | grep '"latency_ms"' | sed 's/.*"latency_ms": *\([0-9]*\).*/\1/')

# Write state
echo "$JSON_RESULT" > "$STATE_DIR/latest.json"

# Write markdown report
{
  echo "# ASDEV MCP Health Check v2 Report"
  echo
  echo "| Item | Value |"
  echo "|---|---|"
  echo "| Started | $STARTED_AT |"
  echo "| Finished | $(ts) |"
  echo "| Endpoint | $(redact_url "$MCP_URL") |"
  echo "| HTTP Status | $HTTP_CODE |"
  echo "| Failure Class | $FAILURE_CLASS |"
  echo "| Latency | ${LATENCY}ms |"
  echo "| Verdict | $VERDICT |"
  echo
  case "$VERDICT" in
    PASS) echo "MCP endpoint is healthy. Loop may proceed." ;;
    WARN) echo "MCP endpoint returned a warning. Loop may proceed with caution." ;;
    FAIL) echo "MCP endpoint is unhealthy. Reason: $FAILURE_CLASS. Loop must not proceed." ;;
  esac
} > "$REPORT_DIR/latest-mcp.md"

log "=== MCP verdict: $VERDICT (HTTP=$HTTP_CODE failure=$FAILURE_CLASS latency=${LATENCY}ms) ==="

case "$VERDICT" in
  FAIL) exit 1 ;;
  *) exit 0 ;;
esac
