#!/usr/bin/env bash
# ASDEV Self-Tasking: selects highest-value safe next task when queue is empty
set -euo pipefail

ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
QUEUE_FILE="${ASDEV_QUEUE_FILE:-${ASDEV_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md}"
STATE_FILE="${ASDEV_ROOT}/.state/asdev-agent-loop/self-task-state.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

# Check if queue has pending tasks
if [ -f "$QUEUE_FILE" ]; then
  PENDING=$(grep -c "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || true)
  PENDING=${PENDING:-0}
  if [ "$PENDING" -gt 0 ] 2>/dev/null; then
    log "Queue has ${PENDING} pending tasks — skipping self-tasking"
    exit 0
  fi
fi

log "Queue empty — selecting highest-value safe next task"

# Define safe tasks that can run without approval
SAFE_TASKS=(
  "docs:memory-refresh:Update ASDEV_CURRENT_STATE.md with latest system status"
  "docs:queue-archive:Archive completed tasks from queue to history"
  "docs:health-check:Run health check on all production sites"
  "docs:security-audit:Scan for secrets, tokens, .env files in repo"
  "docs:control-plane-maturity:Improve control-plane scripts and docs"
  "docs:memory-sync:Sync memory files between GitHub and server"
)

# Load last task state
LAST_TASK=""
if [ -f "$STATE_FILE" ]; then
  LAST_TASK=$(grep -o '"last_task":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
fi

# Select next task (simple round-robin for now)
NEXT_TASK=""
for task in "${SAFE_TASKS[@]}"; do
  TASK_ID=$(echo "$task" | cut -d: -f1-2)
  if [ "$TASK_ID" != "$LAST_TASK" ]; then
    NEXT_TASK="$task"
    break
  fi
done

# If all tasks done, start from beginning
if [ -z "$NEXT_TASK" ]; then
  NEXT_TASK="${SAFE_TASKS[0]}"
fi

TASK_ID=$(echo "$NEXT_TASK" | cut -d: -f1-2)
TASK_DESC=$(echo "$NEXT_TASK" | cut -d: -f3-)

log "Selected task: ${TASK_ID} — ${TASK_DESC}"

# Execute based on task type
case "$TASK_ID" in
  docs:memory-refresh)
    log "Updating ASDEV_CURRENT_STATE.md..."
    cd "$ASDEV_ROOT"
    if [ -f "docs/memory/ASDEV_CURRENT_STATE.md" ]; then
      sed -i "s/\\*\\*Updated:.*\\*\\*/\\*\\*Updated: ${TIMESTAMP}\\*\\*/" docs/memory/ASDEV_CURRENT_STATE.md 2>/dev/null || true
      log "Memory updated"
    fi
    ;;
  docs:queue-archive)
    log "Archiving completed tasks..."
    if [ -f "$QUEUE_FILE" ]; then
      ARCHIVE_DIR="${ASDEV_ROOT}/docs/automation/queue-archive"
      mkdir -p "$ARCHIVE_DIR"
      ARCHIVE_FILE="${ARCHIVE_DIR}/archive-$(date -u +%Y%m%dT%H%M%SZ).md"
      grep "^\- \[x\]" "$QUEUE_FILE" > "$ARCHIVE_FILE" 2>/dev/null || true
      log "Archived to ${ARCHIVE_FILE}"
    fi
    ;;
  docs:health-check)
    log "Running health check..."
    for site in "persiantoolbox.ir" "alirezasafaeisystems.ir" "audit.alirezasafaeisystems.ir"; do
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${site}/" 2>/dev/null || echo "000")
      log "  ${site}: HTTP ${STATUS}"
    done
    ;;
  docs:security-audit)
    log "Scanning for secrets..."
    cd "$ASDEV_ROOT"
    FOUND=$(grep -r "PRIVATE_KEY\|API_KEY\|SECRET\|PASSWORD" --include="*.env" --include="*.env.*" . 2>/dev/null | grep -v ".example" | grep -v "node_modules" | head -5 || true)
    if [ -n "$FOUND" ]; then
      log "WARNING: Potential secrets found:"
      echo "$FOUND"
    else
      log "No secrets found in env files"
    fi
    ;;
  docs:control-plane-maturity)
    log "Checking control-plane health..."
    if [ -f "${ASDEV_ROOT}/control-plane/queue/queue.json" ]; then
      TASKS=$(cat "${ASDEV_ROOT}/control-plane/queue/queue.json" 2>/dev/null | grep -c '"id"' || echo "0")
      log "Control plane queue has ${TASKS} tasks"
    fi
    ;;
  docs:memory-sync)
    log "Syncing memory files..."
    cd "$ASDEV_ROOT"
    git pull --rebase 2>/dev/null && log "Repo synced" || log "Sync failed"
    ;;
esac

# Save state
mkdir -p "$(dirname "$STATE_FILE")"
cat > "$STATE_FILE" <<EOF
{
  "last_task": "${TASK_ID}",
  "last_run_at": "${TIMESTAMP}",
  "status": "completed"
}
EOF

log "Self-task completed: ${TASK_ID}"
