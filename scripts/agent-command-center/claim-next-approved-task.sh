#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
QUEUE_FILE="${WORKSPACE_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"

log() { echo -e "[CLAIM] $*"; }

if [ ! -f "$QUEUE_FILE" ]; then
  log "No queue file found at $QUEUE_FILE"
  exit 1
fi

TASK_LINE=$(grep -m1 "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || true)

if [ -z "$TASK_LINE" ]; then
  log "No pending tasks in queue"
  exit 1
fi

TASK_ID=$(echo "$TASK_LINE" | grep -oP 'ID:\s*\K\S+' || echo "")
TASK_TITLE=$(echo "$TASK_LINE" | sed 's/^- \[ \] [A-Z]*: //' | cut -d' ' -f2-)

if [ -z "$TASK_ID" ]; then
  log "Could not parse task ID from: $TASK_LINE"
  exit 1
fi

log "Claiming task: $TASK_ID — $TASK_TITLE"
sed -i "0,/^- \[ \] .*${TASK_ID}/s/^- \[ \]/- [~]/" "$QUEUE_FILE"
log "Task $TASK_ID marked as in-progress"
echo "${TASK_ID}|${TASK_TITLE}"
