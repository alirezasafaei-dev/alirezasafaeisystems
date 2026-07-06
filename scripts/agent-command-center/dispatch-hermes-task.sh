#!/usr/bin/env bash
# ASDEV Agent Command Center — Dispatch Hermes task
# Usage: ./dispatch-hermes-task.sh <task_id> [prompt_text]
# Requires: hermes CLI, kanban board asdev-audit
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOARD="${HERMES_KANBAN_BOARD:-asdev-audit}"
WORKSPACE="${ASDEV_WORKSPACE:-/home/dev13/my-project/sites/live/alirezasafaeisystems}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <task_id> [prompt_text]"
  echo "Example: $0 t_abc123 'Read docs and produce status report'"
  exit 1
fi

TASK_ID="$1"
PROMPT_TEXT="${2:-Read command center docs and produce a status report. Do not edit any files.}"

echo "Dispatching task: ${TASK_ID}"
echo "Board: ${BOARD}"
echo "Prompt: ${PROMPT_TEXT}"
echo ""

# Switch to the correct board
hermes kanban boards use "${BOARD}" 2>/dev/null || true

# Show task details
echo "--- Task Details ---"
hermes kanban show "${TASK_ID}" 2>/dev/null || echo "Could not show task details"
echo ""

# Execute via hermes -z (oneshot)
echo "--- Execution ---"
OUTPUT_FILE="/tmp/asdev-kanban-output-${TASK_ID}.md"

hermes -m deepseek/deepseek-chat -z "${PROMPT_TEXT}" 2>&1 | tee "${OUTPUT_FILE}"
EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "--- Result ---"
if [[ $EXIT_CODE -eq 0 ]]; then
  echo "✅ Task executed successfully"
  echo "Output saved to: ${OUTPUT_FILE}"
else
  echo "❌ Task execution failed (exit code: ${EXIT_CODE})"
fi

# Mark task complete
echo ""
echo "--- Completion ---"
hermes kanban complete "${TASK_ID}" 2>/dev/null && echo "✅ Task marked complete" || echo "⚠️ Could not mark task complete"

exit $EXIT_CODE
