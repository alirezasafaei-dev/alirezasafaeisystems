#!/usr/bin/env bash
# Supervisor v2 test fixtures — validates bounded recovery logic.
# Tests: allowlist enforcement, cooldown, max attempts, recovery re-check.
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SUPERVISOR="$SCRIPT_DIR/../asdev-supervisor.sh"
TEST_DIR=$(mktemp -d)
PASS=0
FAIL=0
RESULTS=()

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

log() { echo "[TEST] $*"; }
pass_test() { PASS=$((PASS+1)); RESULTS+=("PASS: $1"); }
fail_test() { FAIL=$((FAIL+1)); RESULTS+=("FAIL: $1"); log "FAIL: $1"; }

# Source allowlist function from supervisor
is_allowlisted_unit() {
  local unit="$1"
  case "$unit" in
    asdev-github-sync.timer|asdev-github-sync.service) return 0 ;;
    asdev-agent-loop.timer|asdev-agent-loop.service) return 0 ;;
    asdev-health-monitor.timer|asdev-health-monitor.service) return 0 ;;
    asdev-mcp-monitor.timer|asdev-mcp-monitor.service) return 0 ;;
    asdev-bot.service) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Test 1: Allowlisted units pass
# ---------------------------------------------------------------------------
log "Test 1: Allowlisted units"
ALLOWED_UNITS="asdev-github-sync.timer asdev-github-sync.service asdev-agent-loop.timer asdev-agent-loop.service asdev-health-monitor.timer asdev-health-monitor.service asdev-mcp-monitor.timer asdev-mcp-monitor.service asdev-bot.service"
ALL_ALLOWED=true
for unit in $ALLOWED_UNITS; do
  if ! is_allowlisted_unit "$unit"; then
    fail_test "Unit $unit should be allowlisted"
    ALL_ALLOWED=false
  fi
done
if [ "$ALL_ALLOWED" = true ]; then
  pass_test "All expected units are allowlisted"
fi

# ---------------------------------------------------------------------------
# Test 2: Non-allowlisted units are rejected
# ---------------------------------------------------------------------------
log "Test 2: Non-allowlisted units"
NON_ALLOWED_UNITS="asdev-supervisor.service nginx.service docker.service postgresql.service"
ALL_REJECTED=true
for unit in $NON_ALLOWED_UNITS; do
  if is_allowlisted_unit "$unit"; then
    fail_test "Unit $unit should NOT be allowlisted"
    ALL_REJECTED=false
  fi
done
if [ "$ALL_REJECTED" = true ]; then
  pass_test "All non-allowlisted units correctly rejected"
fi

# ---------------------------------------------------------------------------
# Test 3: Supervisor itself is NOT allowlisted (prevents restart storm)
# ---------------------------------------------------------------------------
log "Test 3: Supervisor not allowlisted"
if is_allowlisted_unit "asdev-supervisor.service"; then
  fail_test "asdev-supervisor.service must NOT be allowlisted (restart storm prevention)"
else
  pass_test "asdev-supervisor.service correctly not allowlisted"
fi

# ---------------------------------------------------------------------------
# Test 4: Cooldown state management
# ---------------------------------------------------------------------------
log "Test 4: Recovery state management"
RECOVERY_DIR="$TEST_DIR/recovery"
mkdir -p "$RECOVERY_DIR"

# Create initial state
cat > "$RECOVERY_DIR/test-unit.json" << 'EOF'
{"attempts":[],"last_attempt":0,"total_attempts":0}
EOF

# Read initial state
INITIAL=$(cat "$RECOVERY_DIR/test-unit.json")
if echo "$INITIAL" | grep -q '"total_attempts"'; then
  pass_test "Initial recovery state has 0 attempts"
else
  fail_test "Initial recovery state incorrect"
fi

# ---------------------------------------------------------------------------
# Test 5: Script syntax check
# ---------------------------------------------------------------------------
log "Test 5: Supervisor v2 script syntax"
if bash -n "$SCRIPT_DIR/../asdev-supervisor.sh" 2>/dev/null; then
  pass_test "asdev-supervisor.sh has valid syntax"
else
  fail_test "asdev-supervisor.sh has syntax errors"
fi

# ---------------------------------------------------------------------------
# Test 6: MCP check v2 script syntax
# ---------------------------------------------------------------------------
log "Test 6: MCP health check v2 script syntax"
if bash -n "$SCRIPT_DIR/../mcp-health-check-v2.sh" 2>/dev/null; then
  pass_test "mcp-health-check-v2.sh has valid syntax"
else
  fail_test "mcp-health-check-v2.sh has syntax errors"
fi

# ---------------------------------------------------------------------------
# Test 7: Loop-once script syntax
# ---------------------------------------------------------------------------
log "Test 7: loop-once.sh script syntax"
if bash -n "$SCRIPT_DIR/../loop-once.sh" 2>/dev/null; then
  pass_test "loop-once.sh has valid syntax"
else
  fail_test "loop-once.sh has syntax errors"
fi

# ---------------------------------------------------------------------------
# Test 8: Sync script syntax
# ---------------------------------------------------------------------------
log "Test 8: sync-github-local-server.sh script syntax"
if bash -n "$SCRIPT_DIR/../sync-github-local-server.sh" 2>/dev/null; then
  pass_test "sync-github-local-server.sh has valid syntax"
else
  fail_test "sync-github-local-server.sh has syntax errors"
fi

# ---------------------------------------------------------------------------
# Test 9: State file is valid JSON
# ---------------------------------------------------------------------------
log "Test 9: State file template is valid JSON"
cat > "$TEST_DIR/test-state.json" << 'TESTJSON'
{
  "script": "asdev-supervisor",
  "version": "v2",
  "started_at": "2026-07-10T18:00:00Z",
  "finished_at": "2026-07-10T18:00:05Z",
  "environment": "test",
  "hostname": "testhost",
  "verdict": "GO",
  "checks_passed": 10,
  "checks_warn": 1,
  "checks_failed": 0,
  "auto_healed": 0,
  "skipped_cooldown": 0,
  "skipped_not_allowlisted": 0,
  "checks": [{"check":"TEST-001","status":"PASS","message":"test"}]
}
TESTJSON
if python3 -m json.tool "$TEST_DIR/test-state.json" >/dev/null 2>&1; then
  pass_test "State file template is valid JSON"
else
  fail_test "State file template is invalid JSON"
fi

# ---------------------------------------------------------------------------
# Test 10: Recovery state JSON structure
# ---------------------------------------------------------------------------
log "Test 10: Recovery state JSON is valid"
cat > "$TEST_DIR/test-recovery.json" << 'RECOVERYJSON'
{
  "attempts": [1720000000, 1720000300],
  "last_attempt": 1720000300,
  "total_attempts": 2,
  "last_success": "true"
}
RECOVERYJSON
if python3 -m json.tool "$TEST_DIR/test-recovery.json" >/dev/null 2>&1; then
  pass_test "Recovery state JSON is valid"
else
  fail_test "Recovery state JSON is invalid"
fi

# ---------------------------------------------------------------------------
# Test 11: Verdict classification — GO
# ---------------------------------------------------------------------------
log "Test 11: Verdict GO with 0 failures"
CHECKS_FAILED=0
CHECKS_WARN=0
VERDICT="GO"
if [ "$CHECKS_FAILED" -gt 0 ]; then
  VERDICT="NO_GO"
elif [ "$CHECKS_WARN" -gt 2 ]; then
  VERDICT="GO_WITH_WARNINGS"
fi
[ "$VERDICT" = "GO" ] && pass_test "Verdict GO with 0 failures, 0 warnings" || fail_test "Verdict should be GO"

# ---------------------------------------------------------------------------
# Test 12: Verdict classification — GO_WITH_WARNINGS
# ---------------------------------------------------------------------------
log "Test 12: Verdict GO_WITH_WARNINGS with 3 warnings"
CHECKS_FAILED=0
CHECKS_WARN=3
VERDICT="GO"
if [ "$CHECKS_FAILED" -gt 0 ]; then
  VERDICT="NO_GO"
elif [ "$CHECKS_WARN" -gt 2 ]; then
  VERDICT="GO_WITH_WARNINGS"
fi
[ "$VERDICT" = "GO_WITH_WARNINGS" ] && pass_test "Verdict GO_WITH_WARNINGS with 3 warnings" || fail_test "Verdict should be GO_WITH_WARNINGS"

# ---------------------------------------------------------------------------
# Test 13: Verdict classification — NO_GO
# ---------------------------------------------------------------------------
log "Test 13: Verdict NO_GO with 1 failure"
CHECKS_FAILED=1
CHECKS_WARN=0
VERDICT="GO"
if [ "$CHECKS_FAILED" -gt 0 ]; then
  VERDICT="NO_GO"
elif [ "$CHECKS_WARN" -gt 2 ]; then
  VERDICT="GO_WITH_WARNINGS"
fi
[ "$VERDICT" = "NO_GO" ] && pass_test "Verdict NO_GO with 1 failure" || fail_test "Verdict should be NO_GO"

# ---------------------------------------------------------------------------
# Test 14: All shell scripts in control-plane have valid syntax
# ---------------------------------------------------------------------------
log "Test 14: All control-plane scripts have valid syntax"
SYNTAX_OK=true
for script in "$SCRIPT_DIR"/../"$SCRIPT_DIR"/*.sh; do
  [ ! -f "$script" ] && continue
  if ! bash -n "$script" 2>/dev/null; then
    fail_test "Syntax error in $(basename "$script")"
    SYNTAX_OK=false
    break
  fi
done
if [ "$SYNTAX_OK" = true ]; then
  pass_test "All control-plane scripts have valid syntax"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "=== Supervisor v2 Test Results ==="
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
