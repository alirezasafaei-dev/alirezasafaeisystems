#!/usr/bin/env bash
# ASDEV Agent Command Center — Create kanban task from monitor output
# Usage: ./create-kanban-task.sh <prompt_comment_id> <prompt_title>
# Requires: hermes CLI, kanban board asdev-audit
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-42}"
BOARD="${HERMES_KANBAN_BOARD:-asdev-audit}"
WORKSPACE="${ASDEV_WORKSPACE:-/home/dev13/my-project/sites/live/alirezasafaeisystems}"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <prompt_comment_id> <prompt_title>"
  echo "Example: $0 4896439275 'Phase P2 command loop'"
  exit 1
fi

PROMPT_ID="$1"
PROMPT_TITLE="$2"

echo "Creating kanban task for prompt: ${PROMPT_TITLE}"
echo "Prompt comment ID: ${PROMPT_ID}"
echo "Board: ${BOARD}"
echo ""

# Switch to the correct board
hermes kanban boards use "${BOARD}" 2>/dev/null || true

# Create the task
TASK_BODY="github_prompt_comment_id: \"${PROMPT_ID}\"
title: \"${PROMPT_TITLE}\"
product_goal: \"lower audit cost, support cost, or execution time\"
repo_scope: [\"alirezasafaeisystems\"]
protected_repos: [\"persiantoolbox\"]
agent_candidates: [\"hermes-asdev-docs\", \"hermes-asdev-ops\"]
selected_agent: \"hermes-asdev-docs\"
autonomy_level: \"docs-only\"
approval_required: false
owner_approved: false
validation_commands: []
report_target: \"pr:${PR_NUMBER}\"
out_of_scope: [\"billing\", \"deploy\", \"persiantoolbox runtime\", \"auditsystems code\"]"

TASK_ID=$(hermes kanban create "${PROMPT_TITLE}" \
  --body "${TASK_BODY}" \
  --assignee hermes-asdev-docs \
  --workspace "dir:${WORKSPACE}" \
  --json 2>/dev/null | jq -r '.id // empty' || echo "")

if [[ -z "$TASK_ID" ]]; then
  # Fallback: try without --json
  OUTPUT=$(hermes kanban create "${PROMPT_TITLE}" \
    --body "${TASK_BODY}" \
    --assignee hermes-asdev-docs \
    --workspace "dir:${WORKSPACE}" 2>&1)
  TASK_ID=$(echo "$OUTPUT" | grep -oP 't_[a-f0-9]+' || echo "")
fi

if [[ -n "$TASK_ID" ]]; then
  echo "✅ Task created: ${TASK_ID}"
  echo "TASK_ID=${TASK_ID}"
else
  echo "❌ Failed to create task"
  echo "Output: ${OUTPUT:-no output}"
  exit 1
fi
