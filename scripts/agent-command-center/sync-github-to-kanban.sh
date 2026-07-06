#!/usr/bin/env bash
# ASDEV Agent Command Center — Sync GitHub prompts to kanban
# Reads PR/issue comments, creates kanban tasks for unhandled prompts
# Usage: ./sync-github-to-kanban.sh [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-42}"
BOARD="${HERMES_KANBAN_BOARD:-asdev-audit}"
STATE_FILE="${ASDEV_COMMAND_STATE:-$(dirname "$0")/../../docs/agent-command-center/STATE.json}"
WORKSPACE="${ASDEV_WORKSPACE:-/home/dev13/my-project/sites/live/alirezasafaeisystems}"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

echo "ASDEV Sync GitHub → Kanban"
echo "Repo: ${REPO} | PR: #${PR_NUMBER} | Dry-run: ${DRY_RUN}"
echo ""

# Run monitor to get status
MONITOR_OUTPUT=$("${SCRIPT_DIR}/monitor-pr.sh" 2>&1)
STATUS=$(echo "${MONITOR_OUTPUT}" | grep "^STATUS:" | awk '{print $2}')
PROMPT_ID=$(echo "${MONITOR_OUTPUT}" | grep "^PROMPT_COMMENT_ID:" | awk '{print $2}')

echo "Monitor status: ${STATUS}"
echo "Prompt ID: ${PROMPT_ID:-none}"
echo ""

if [[ "$STATUS" != "PROMPT_PENDING" ]]; then
  echo "No pending prompt. Nothing to sync."
  exit 0
fi

# Extract prompt title from monitor output
PROMPT_TITLE=$(echo "${MONITOR_OUTPUT}" | grep "title:" | head -1 | sed 's/.*title: //')
echo "Prompt title: ${PROMPT_TITLE}"

if $DRY_RUN; then
  echo ""
  echo "[DRY-RUN] Would create kanban task:"
  echo "  Title: ${PROMPT_TITLE}"
  echo "  Prompt ID: ${PROMPT_ID}"
  echo "  Board: ${BOARD}"
  echo "  Assignee: hermes-asdev-docs"
  exit 0
fi

# Switch to board
hermes kanban boards use "${BOARD}" 2>/dev/null || true

# Create task
TASK_OUTPUT=$(hermes kanban create "${PROMPT_TITLE}" \
  --body "github_prompt_comment_id: \"${PROMPT_ID}\"
title: \"${PROMPT_TITLE}\"
product_goal: \"lower audit cost, support cost, or execution time\"
repo_scope: [\"alirezasafaeisystems\"]
protected_repos: [\"persiantoolbox\"]
agent_candidates: [\"hermes-asdev-docs\", \"hermes-asdev-ops\"]
selected_agent: \"hermes-asdev-docs\"
autonomy_level: \"docs-only\"
approval_required: false
owner_approved: false
report_target: \"pr:${PR_NUMBER}\"" \
  --assignee hermes-asdev-docs \
  --workspace "dir:${WORKSPACE}" 2>&1)

TASK_ID=$(echo "${TASK_OUTPUT}" | grep -oP 't_[a-f0-9]+' || echo "")

if [[ -n "$TASK_ID" ]]; then
  echo "✅ Kanban task created: ${TASK_ID}"
else
  echo "❌ Failed to create kanban task"
  echo "${TASK_OUTPUT}"
  exit 1
fi
