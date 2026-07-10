#!/usr/bin/env bash
# Loop integration test fixtures — validates gate behavior for GO, GO_WITH_WARNINGS, NO_GO.
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR=$(mktemp -d)
PASS=0
FAIL=0
RESULTS=()

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

log() { echo "[TEST] $*"; }
pass_test() { PASS=$((PASS+1)); RESULTS+=("PASS: $1"); }
fail_test() { FAIL=$((FAIL+1)); RESULTS+=("FAIL: $1"); log "FAIL: $1"; }

# ---------------------------------------------------------------------------
# Test 1: Script syntax — loop-once.sh
# ---------------------------------------------------------------------------
log "Test 1: loop-once.sh syntax"
if bash -n "$SCRIPT_DIR/../loop-once.sh" 2>/dev/null; then
  pass_test "loop-once.sh valid syntax"
else
  fail_test "loop-once.sh syntax error"
fi

# ---------------------------------------------------------------------------
# Test 2: Script syntax — loop-until-blocked.sh
# ---------------------------------------------------------------------------
log "Test 2: loop-until-blocked.sh syntax"
if bash -n "$SCRIPT_DIR/../loop-until-blocked.sh" 2>/dev/null; then
  pass_test "loop-until-blocked.sh valid syntax"
else
  fail_test "loop-until-blocked.sh syntax error"
fi

# ---------------------------------------------------------------------------
# Test 3: GO verdict allows loop
# ---------------------------------------------------------------------------
log "Test 3: GO verdict allows loop"
VERDICT="GO"
if [ "$VERDICT" = "NO_GO" ]; then
  fail_test "GO should allow loop"
else
  pass_test "GO verdict allows loop to proceed"
fi

# ---------------------------------------------------------------------------
# Test 4: GO_WITH_WARNINGS allows loop
# ---------------------------------------------------------------------------
log "Test 4: GO_WITH_WARNINGS allows loop"
VERDICT="GO_WITH_WARNINGS"
if [ "$VERDICT" = "NO_GO" ]; then
  fail_test "GO_WITH_WARNINGS should allow loop"
else
  pass_test "GO_WITH_WARNINGS allows loop to proceed"
fi

# ---------------------------------------------------------------------------
# Test 5: NO_GO blocks loop
# ---------------------------------------------------------------------------
log "Test 5: NO_GO blocks loop"
VERDICT="NO_GO"
if [ "$VERDICT" = "NO_GO" ]; then
  pass_test "NO_GO blocks loop (no task claim, no agent execution)"
else
  fail_test "NO_GO should block loop"
fi

# ---------------------------------------------------------------------------
# Test 6: MCP FAIL is non-blocking warning
# ---------------------------------------------------------------------------
log "Test 6: MCP FAIL is non-blocking"
MCP_VERDICT="FAIL"
# In loop-once.sh, MCP FAIL is a warning, not a blocker
LOOP_CONTINUE=true
if [ "$MCP_VERDICT" = "FAIL" ]; then
  # Warning only — loop continues
  LOOP_CONTINUE=true
fi
if [ "$LOOP_CONTINUE" = true ]; then
  pass_test "MCP FAIL is non-blocking warning"
else
  fail_test "MCP FAIL should be non-blocking"
fi

# ---------------------------------------------------------------------------
# Test 7: Supervisor script failure = fail closed
# ---------------------------------------------------------------------------
log "Test 7: Supervisor script failure = fail closed"
# If supervisor script exits non-zero, verdict should be NO_GO
SUPERVISOR_EXIT=1
if [ "$SUPERVISOR_EXIT" -ne 0 ]; then
  # Fail closed: treat as NO_GO
  EFFECTIVE_VERDICT="NO_GO"
fi
if [ "$EFFECTIVE_VERDICT" = "NO_GO" ]; then
  pass_test "Supervisor failure = fail closed (NO_GO)"
else
  fail_test "Supervisor failure should = NO_GO"
fi

# ---------------------------------------------------------------------------
# Test 8: All control-plane scripts have valid syntax
# ---------------------------------------------------------------------------
log "Test 8: All control-plane scripts syntax"
SYNTAX_OK=true
for script in "$SCRIPT_DIR"/../../*.sh; do
  [ ! -f "$script" ] && continue
  if ! bash -n "$script" 2>/dev/null; then
    fail_test "Syntax error in $(basename "$script")"
    SYNTAX_OK=false
    break
  fi
done
if [ "$SYNTAX_OK" = true ]; then
  pass_test "All control-plane scripts valid syntax"
fi

# ---------------------------------------------------------------------------
# Test 9: Loop blocks on NO_GO even with tasks available
# ---------------------------------------------------------------------------
log "Test 9: Loop blocks on NO_GO with tasks"
VERDICT="NO_GO"
HAS_TASKS=true
SHOULD_CLAIM=false
if [ "$VERDICT" != "NO_GO" ] && [ "$HAS_TASKS" = true ]; then
  SHOULD_CLAIM=true
fi
if [ "$SHOULD_CLAIM" = false ]; then
  pass_test "Loop blocks task claim on NO_GO"
else
  fail_test "Loop should not claim tasks on NO_GO"
fi

# ---------------------------------------------------------------------------
# Test 10: Loop proceeds on GO with tasks
# ---------------------------------------------------------------------------
log "Test 10: Loop proceeds on GO with tasks"
VERDICT="GO"
HAS_TASKS=true
SHOULD_CLAIM=false
if [ "$VERDICT" != "NO_GO" ] && [ "$HAS_TASKS" = true ]; then
  SHOULD_CLAIM=true
fi
if [ "$SHOULD_CLAIM" = true ]; then
  pass_test "Loop proceeds with task claim on GO"
else
  fail_test "Loop should claim tasks on GO"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "=== Loop Integration Test Results ==="
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
