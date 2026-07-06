#!/usr/bin/env bash
# ASDEV Agent Command Center — Dispatch next kanban task
# Claims the next ready task and executes it
# Usage: ./dispatch-next-task.sh [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOARD="${HERMES_KANBAN_BOARD:-asdev-audit}"
WORKSPACE="${ASDEV_WORKSPACE:-/home/dev13/my-project/sites/live/alirezasafaeisystems}"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

echo "ASDEV Dispatch Next Task"
echo "Board: ${BOARD} | Dry-run: ${DRY_RUN}"
echo ""

# Switch to board
hermes kanban boards use "${BOARD}" 2>/dev/null || true

# List ready tasks
READY_TASKS=$(hermes kanban list --status ready 2>/dev/null || echo "")

if [[ -z "$READY_TASKS" ]] || echo "$READY_TASKS" | grep -q "no matching tasks"; then
  echo "No ready tasks to dispatch."
  exit 0
fi

echo "Ready tasks:"
echo "${READY_TASKS}"
echo ""

# Get first ready task ID
TASK_ID=$(echo "${READY_TASKS}" | grep -oP 't_[a-f0-9]+' | head -1 || echo "")

if [[ -z "$TASK_ID" ]]; then
  echo "Could not extract task ID."
  exit 1
fi

echo "Dispatching task: ${TASK_ID}"

if $DRY_RUN; then
  echo "[DRY-RUN] Would dispatch task ${TASK_ID} via hermes -z"
  hermes kanban show "${TASK_ID}" 2>/dev/null || echo "Could not show task"
  exit 0
fi

# Show task details
hermes kanban show "${TASK_ID}" 2>/dev/null || echo "Could not show task details"

# Execute via hermes -z
echo ""
echo "--- Execution ---"
OUTPUT_FILE="/tmp/asdev-dispatch-${TASK_ID}.md"
hermes -m deepseek/deepseek-chat -z "Execute the task described in the kanban task body. Read-only mode. Produce a report." 2>&1 | tee "${OUTPUT_FILE}"
EXEC_EXIT=${PIPESTATUS[0]}

# Mark complete
hermes kanban complete "${TASK_ID}" 2>/dev/null && echo "✅ Task complete" || echo "⚠️ Could not mark complete"

exit $EXEC_EXIT
