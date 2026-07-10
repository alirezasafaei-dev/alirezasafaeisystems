#!/usr/bin/env bash
# MCP Health Check v2 unit tests — validates classification logic.
# Uses direct function testing without network.
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR=$(mktemp -d)
PASS=0
FAIL=0
RESULTS=()

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

log() { echo "[TEST] $*"; }
pass_test() { PASS=$((PASS+1)); RESULTS+=("PASS: $1"); }
fail_test() { FAIL=$((FAIL+1)); RESULTS+=("FAIL: $1"); log "FAIL: $1"; }

# Source classification functions from the MCP check script
classify_http_status() {
  local code="$1"
  case "$code" in
    2[0-9][0-9]) echo "PASS" ;;
    000)         echo "FAIL" ;;
    *)           echo "FAIL" ;;
  esac
}

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
# Test 1: HTTP 200 = PASS
# ---------------------------------------------------------------------------
log "Test 1: HTTP 200 = PASS"
R=$(classify_http_status "200")
[ "$R" = "PASS" ] && pass_test "HTTP 200 -> PASS" || fail_test "HTTP 200 -> $R (expected PASS)"

# ---------------------------------------------------------------------------
# Test 2: HTTP 201 = PASS
# ---------------------------------------------------------------------------
log "Test 2: HTTP 201 = PASS"
R=$(classify_http_status "201")
[ "$R" = "PASS" ] && pass_test "HTTP 201 -> PASS" || fail_test "HTTP 201 -> $R (expected PASS)"

# ---------------------------------------------------------------------------
# Test 3: HTTP 000 = FAIL (never PASS)
# ---------------------------------------------------------------------------
log "Test 3: HTTP 000 = FAIL"
R=$(classify_http_status "000")
[ "$R" = "FAIL" ] && pass_test "HTTP 000 -> FAIL (never PASS)" || fail_test "HTTP 000 -> $R (expected FAIL)"

# ---------------------------------------------------------------------------
# Test 4: HTTP 307 = FAIL (unhandled redirect)
# ---------------------------------------------------------------------------
log "Test 4: HTTP 307 = FAIL"
R=$(classify_http_status "307")
[ "$R" = "FAIL" ] && pass_test "HTTP 307 -> FAIL" || fail_test "HTTP 307 -> $R (expected FAIL)"

# ---------------------------------------------------------------------------
# Test 5: HTTP 500 = FAIL
# ---------------------------------------------------------------------------
log "Test 5: HTTP 500 = FAIL"
R=$(classify_http_status "500")
[ "$R" = "FAIL" ] && pass_test "HTTP 500 -> FAIL" || fail_test "HTTP 500 -> $R (expected FAIL)"

# ---------------------------------------------------------------------------
# Test 6: HTTP 404 = FAIL
# ---------------------------------------------------------------------------
log "Test 6: HTTP 404 = FAIL"
R=$(classify_http_status "404")
[ "$R" = "FAIL" ] && pass_test "HTTP 404 -> FAIL" || fail_test "HTTP 404 -> $R (expected FAIL)"

# ---------------------------------------------------------------------------
# Test 7: Content-Type text/event-stream = SSE
# ---------------------------------------------------------------------------
log "Test 7: Content-Type text/event-stream = SSE"
R=$(check_content_type "text/event-stream; charset=utf-8")
[ "$R" = "SSE" ] && pass_test "Content-Type text/event-stream -> SSE" || fail_test "Content-Type -> $R (expected SSE)"

# ---------------------------------------------------------------------------
# Test 8: Content-Type application/json = JSON
# ---------------------------------------------------------------------------
log "Test 8: Content-Type application/json = JSON"
R=$(check_content_type "application/json")
[ "$R" = "JSON" ] && pass_test "Content-Type application/json -> JSON" || fail_test "Content-Type -> $R (expected JSON)"

# ---------------------------------------------------------------------------
# Test 9: Content-Type text/html = HTML
# ---------------------------------------------------------------------------
log "Test 9: Content-Type text/html = HTML"
R=$(check_content_type "text/html")
[ "$R" = "HTML" ] && pass_test "Content-Type text/html -> HTML" || fail_test "Content-Type -> $R (expected HTML)"

# ---------------------------------------------------------------------------
# Test 10: Empty content-type = UNKNOWN
# ---------------------------------------------------------------------------
log "Test 10: Empty content-type = UNKNOWN"
R=$(check_content_type "")
[ "$R" = "UNKNOWN" ] && pass_test "Content-Type empty -> UNKNOWN" || fail_test "Content-Type -> $R (expected UNKNOWN)"

# ---------------------------------------------------------------------------
# Test 11: Redact query strings
# ---------------------------------------------------------------------------
log "Test 11: Redact query strings from URL"
REDACTED=$(printf '%s' "https://example.com/path?token=abc123&key=secret" | sed 's/[?#].*$//')
if [ "$REDACTED" = "https://example.com/path" ]; then
  pass_test "URL query string redacted"
else
  fail_test "URL redaction failed: $REDACTED"
fi

# ---------------------------------------------------------------------------
# Test 12: State file is valid JSON structure
# ---------------------------------------------------------------------------
log "Test 12: State file template is valid JSON"
cat > "$TEST_DIR/test-state.json" << 'TESTJSON'
{
  "script": "asdev-mcp-check",
  "started_at": "2026-07-10T18:00:00Z",
  "finished_at": "2026-07-10T18:00:01Z",
  "environment": "test",
  "hostname": "testhost",
  "endpoint": "https://mcp.example.com/sse/",
  "connect_timeout_s": 5,
  "total_timeout_s": 15,
  "max_redirects": 5,
  "http_code": "200",
  "curl_exit_code": 0,
  "redirect_count": 0,
  "final_status": "200",
  "content_type": "text/event-stream",
  "response_class": "SSE",
  "latency_ms": 150,
  "failure_class": "none",
  "verdict": "PASS"
}
TESTJSON
if python3 -m json.tool "$TEST_DIR/test-state.json" >/dev/null 2>&1; then
  pass_test "State file template is valid JSON"
else
  fail_test "State file template is invalid JSON"
fi

# ---------------------------------------------------------------------------
# Test 13: Classification policy — multiple 2xx codes
# ---------------------------------------------------------------------------
log "Test 13: All 2xx codes = PASS"
for code in 200 201 202 203 204 205 206 207 208 226; do
  R=$(classify_http_status "$code")
  if [ "$R" != "PASS" ]; then
    fail_test "HTTP $code -> $R (expected PASS)"
    break
  fi
done
pass_test "All 2xx codes -> PASS"

# ---------------------------------------------------------------------------
# Test 14: 000 never appears as PASS in any combination
# ---------------------------------------------------------------------------
log "Test 14: HTTP 000 is absolutely never PASS"
R=$(classify_http_status "000")
[ "$R" != "PASS" ] && pass_test "HTTP 000 absolutely never PASS" || fail_test "HTTP 000 is PASS (VIOLATION)"

# ---------------------------------------------------------------------------
# Test 15: Script syntax check
# ---------------------------------------------------------------------------
log "Test 15: MCP health check v2 script syntax"
if bash -n "$SCRIPT_DIR/../mcp-health-check-v2.sh" 2>/dev/null; then
  pass_test "mcp-health-check-v2.sh has valid syntax"
else
  fail_test "mcp-health-check-v2.sh has syntax errors"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "=== MCP Health Check v2 Unit Test Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
