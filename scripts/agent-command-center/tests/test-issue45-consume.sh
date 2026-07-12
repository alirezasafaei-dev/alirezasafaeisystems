#!/usr/bin/env bash
# ASDEV Agent Command Center — Issue #45 prompt consumption test
# Deterministic dry-run: validates the full consume flow without real API calls
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo -e "  \033[0;32m[PASS]\033[0m $*"; PASS=$((PASS + 1)); }
fail() { echo -e "  \033[0;31m[FAIL]\033[0m $*"; FAIL=$((FAIL + 1)); }

echo "=== ASDEV Issue #45 Prompt Consumption Test ==="
echo "Script dir: ${SCRIPT_DIR}"
echo ""

# --- Step 1: Syntax validation ---
echo "--- Step 1: Shell syntax ---"
for script in \
  "$SCRIPT_DIR/run-autonomous-loop.sh" \
  "$SCRIPT_DIR/monitor-command-thread.sh" \
  "$SCRIPT_DIR/post-agent-report.sh" \
  "$SCRIPT_DIR/collect-agent-report.sh" \
  "$SCRIPT_DIR/update-command-state.sh" \
  "$SCRIPT_DIR/agent-safety-gate.sh"; do
  if bash -n "$script" 2>/dev/null; then
    pass "$(basename "$script"): syntax OK"
  else
    fail "$(basename "$script"): syntax error"
  fi
done
echo ""

# --- Step 2: consume_issue_prompt function exists ---
echo "--- Step 2: Function definitions ---"
if grep -q "^consume_issue_prompt()" "$SCRIPT_DIR/run-autonomous-loop.sh"; then
  pass "consume_issue_prompt defined in run-autonomous-loop.sh"
else
  fail "consume_issue_prompt not found in run-autonomous-loop.sh"
fi

if grep -q "consume_issue_prompt \"\$ISSUE\" \"\$DRY_RUN\"" "$SCRIPT_DIR/run-autonomous-loop.sh"; then
  pass "consume_issue_prompt invoked in main flow"
else
  fail "consume_issue_prompt not invoked in main flow"
fi
echo ""

# --- Step 3: post-agent-report.sh --issue support ---
echo "--- Step 3: post-agent-report.sh --issue flag ---"
if grep -q "TARGET_TYPE=\"issue\"" "$SCRIPT_DIR/post-agent-report.sh"; then
  pass "post-agent-report.sh supports --issue flag"
else
  fail "post-agent-report.sh missing --issue support"
fi

if grep -q "gh issue comment" "$SCRIPT_DIR/post-agent-report.sh"; then
  pass "post-agent-report.sh uses gh issue comment for issues"
else
  fail "post-agent-report.sh missing gh issue comment"
fi
echo ""

# --- Step 4: Dry-run loop invocation ---
echo "--- Step 4: Dry-run loop invocation ---"

# Check if GH API is reachable (required for monitor to avoid hanging)
NETWORK_OK=false
timeout 5 curl -fsS https://api.github.com/rate_limit >/dev/null 2>&1 && NETWORK_OK=true

if $NETWORK_OK; then
  set +e
  DRY_OUTPUT=$(timeout 30 bash "$SCRIPT_DIR/run-autonomous-loop.sh" --dry-run --issue 45 --once 2>&1)
  DRY_EXIT=$?
  set -e

  if echo "$DRY_OUTPUT" | grep -q "Issue: 45"; then
    pass "Loop parses --issue 45 flag"
  else
    fail "Loop did not display Issue: 45"
  fi

  if echo "$DRY_OUTPUT" | grep -q "Issue #45 status:"; then
    pass "consume_issue_prompt invoked during dry-run"
  else
    fail "consume_issue_prompt not invoked during dry-run"
  fi
else
  echo "  (skipped — no network)"
fi
echo ""

# --- Step 5: collect-agent-report.sh generates valid output ---
echo "--- Step 5: Report generation ---"
TMP_OUTPUT=$(mktemp)
TASK_ID="test-issue45-unit"
echo "Test prompt output" > "$TMP_OUTPUT"

REPORT_RESULT=$(bash "$SCRIPT_DIR/collect-agent-report.sh" "$TASK_ID" "$TMP_OUTPUT" 2>&1 || true)
REPORT_FILE="/tmp/asdev-report-${TASK_ID}.md"

if [ -f "$REPORT_FILE" ]; then
  if grep -q "# Agent Execution Report" "$REPORT_FILE"; then
    pass "Report file generated with correct heading"
  else
    fail "Report file missing heading"
  fi
  rm -f "$REPORT_FILE"
else
  fail "Report file not generated at ${REPORT_FILE}"
fi
rm -f "$TMP_OUTPUT"
echo ""

# --- Step 6: update-command-state.sh dry-run ---
echo "--- Step 6: State update dry-run ---"
STATE_RESULT=$(bash "$SCRIPT_DIR/update-command-state.sh" "9999999999" "8888888888" --dry-run 2>&1 || true)
if echo "$STATE_RESULT" | grep -q "Would update STATE.json"; then
  pass "update-command-state.sh dry-run works"
else
  fail "update-command-state.sh dry-run failed"
fi
echo ""

# --- Summary ---
echo "=== Summary ==="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests FAILED."
  exit 1
else
  echo "All tests PASSED."
  exit 0
fi
