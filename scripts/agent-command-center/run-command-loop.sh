#!/usr/bin/env bash
# ASDEV Agent Command Center — Run command loop
# Unified entry point for the command loop
# Usage: ./run-command-loop.sh [--issue N] [--pr N] [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
ISSUE=""
PR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --issue) ISSUE="$2"; shift 2 ;;
    --pr) PR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Validate numeric args
if [[ -n "$ISSUE" ]] && ! [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
  echo "Error: --issue must be numeric, got: $ISSUE"
  exit 1
fi
if [[ -n "$PR" ]] && ! [[ "$PR" =~ ^[0-9]+$ ]]; then
  echo "Error: --pr must be numeric, got: $PR"
  exit 1
fi

echo "=========================================="
echo "ASDEV Command Loop"
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Dry-run: ${DRY_RUN}"
echo "=========================================="
echo ""

# Step 1: Monitor
echo "--- Step 1: Monitor Thread ---"
MONITOR_ARGS=()
[[ -n "$ISSUE" ]] && MONITOR_ARGS+=(--issue "$ISSUE")
[[ -n "$PR" ]] && MONITOR_ARGS+=(--pr "$PR")
$DRY_RUN && MONITOR_ARGS+=(--dry-run)

set +e
MONITOR_OUTPUT=$("${SCRIPT_DIR}/monitor-command-thread.sh" "${MONITOR_ARGS[@]}" 2>&1)
MONITOR_EXIT=$?
set -e
echo "${MONITOR_OUTPUT}"
echo ""

# Step 2: Check status
STATUS=$(echo "${MONITOR_OUTPUT}" | grep "^STATUS:" | awk '{print $2}')
echo "Status: ${STATUS:-unknown}"

if [[ "$STATUS" == "PROMPT_PENDING" ]]; then
  PROMPT_ID=$(echo "${MONITOR_OUTPUT}" | grep "^PROMPT_COMMENT_ID:" | awk '{print $2}')
  echo "Prompt ID: ${PROMPT_ID}"
  echo ""
  echo "To execute: ./dispatch-next-task.sh"
  echo "To sync: ./sync-github-to-kanban.sh"
elif [[ "$STATUS" == "IDLE_WAITING" ]]; then
  echo "No pending prompts. Waiting for owner."
elif [[ "$STATUS" == "BLOCKED_AWAITING_APPROVAL" ]]; then
  echo "Command center blocked. Owner must approve."
elif [[ "$STATUS" == "NO_PROMPT" ]]; then
  echo "No actionable prompt found."
fi

echo ""
echo "=========================================="
echo "Loop complete."
echo "=========================================="
