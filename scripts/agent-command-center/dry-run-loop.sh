#!/usr/bin/env bash
# ASDEV Agent Command Center — Dry-run end-to-end loop
# Tests: monitor → create task → dispatch → report → verify
# Does NOT edit product repos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-42}"
BOARD="${HERMES_KANBAN_BOARD:-asdev-audit}"
WORKSPACE="${ASDEV_WORKSPACE:-/home/dev13/my-project/sites/live/alirezasafaeisystems}"

echo "=========================================="
echo "ASDEV Command Loop — Dry-Run Test"
echo "=========================================="
echo "Repo: ${REPO}"
echo "PR: #${PR_NUMBER}"
echo "Board: ${BOARD}"
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Step 1: Run monitor
echo "--- Step 1: Monitor PR #42 ---"
set +e
MONITOR_OUTPUT=$("${SCRIPT_DIR}/monitor-pr.sh" 2>&1)
MONITOR_EXIT=$?
set -e
echo "${MONITOR_OUTPUT}"
echo "Monitor exit code: ${MONITOR_EXIT}"
echo ""

# Step 2: Check status
echo "--- Step 2: Check Status ---"
STATUS=$(echo "${MONITOR_OUTPUT}" | grep "^STATUS:" | awk '{print $2}')
echo "Status: ${STATUS:-unknown}"

if [[ "$STATUS" == "BLOCKED_AWAITING_APPROVAL" ]]; then
  echo "ℹ️ Command center is blocked. Creating test task anyway for dry-run."
  echo ""
fi

# Step 3: Create kanban task
echo "--- Step 3: Create Kanban Task ---"
DRY_RUN_TITLE="Dry-run P2: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
DRY_RUN_BODY="github_prompt_comment_id: \"dry-run-p2\"
title: \"${DRY_RUN_TITLE}\"
product_goal: \"lower audit cost, support cost, or execution time\"
repo_scope: [\"alirezasafaeisystems\"]
protected_repos: [\"persiantoolbox\"]
agent_candidates: [\"hermes-asdev-docs\"]
selected_agent: \"hermes-asdev-docs\"
autonomy_level: \"docs-only\"
approval_required: false
owner_approved: false
validation_commands: []
report_target: \"pr:${PR_NUMBER}\"
out_of_scope: [\"billing\", \"deploy\", \"persiantoolbox runtime\", \"auditsystems code\"]"

hermes kanban boards use "${BOARD}" 2>/dev/null || true

TASK_OUTPUT=$(hermes kanban create "${DRY_RUN_TITLE}" \
  --body "${DRY_RUN_BODY}" \
  --assignee hermes-asdev-docs \
  --workspace "dir:${WORKSPACE}" 2>&1)
TASK_ID=$(echo "${TASK_OUTPUT}" | grep -oP 't_[a-f0-9]+' || echo "")

if [[ -n "$TASK_ID" ]]; then
  echo "✅ Task created: ${TASK_ID}"
else
  echo "❌ Failed to create task"
  echo "${TASK_OUTPUT}"
  exit 1
fi
echo ""

# Step 4: Execute dry-run
echo "--- Step 4: Execute Dry-Run ---"
DRY_RUN_PROMPT="Read docs/agent-command-center/README.md from ${WORKSPACE}. Produce a 3-line status summary. Do not edit any files."

OUTPUT_FILE="/tmp/asdev-dry-run-p2-${TASK_ID}.md"
hermes -m deepseek/deepseek-chat -z "${DRY_RUN_PROMPT}" 2>&1 | tee "${OUTPUT_FILE}"
EXEC_EXIT=${PIPESTATUS[0]}

if [[ $EXEC_EXIT -ne 0 ]]; then
  echo "❌ Execution failed (exit code: ${EXEC_EXIT})"
  hermes kanban complete "${TASK_ID}" 2>/dev/null || true
  exit 1
fi
echo ""

# Step 5: Mark complete
echo "--- Step 5: Mark Task Complete ---"
hermes kanban complete "${TASK_ID}" 2>/dev/null && echo "✅ Task marked complete" || echo "⚠️ Could not mark complete"
echo ""

# Step 6: Verify
echo "--- Step 6: Verify ---"
echo "Kanban board status:"
hermes kanban list 2>/dev/null | head -10
echo ""

echo "Output file: ${OUTPUT_FILE}"
if [[ -f "${OUTPUT_FILE}" ]]; then
  echo "Output preview:"
  head -5 "${OUTPUT_FILE}"
fi
echo ""

# Step 7: Summary
echo "=========================================="
echo "Dry-Run Complete"
echo "=========================================="
echo "Task ID: ${TASK_ID}"
echo "Output: ${OUTPUT_FILE}"
echo "Product repos touched: NONE"
echo "PersianToolbox touched: NONE"
echo "Deploy commands: NONE"
echo "Time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "=========================================="
