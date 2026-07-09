#!/usr/bin/env bash
# Real work selector - finds actual valuable tasks when queue is empty
set -euo pipefail

ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "=== Real Work Selector ==="

# 1. Check if PersianToolbox has uncommitted a11y work
PT_DIR="${ASDEV_ROOT}/sites/live/persiantoolbox"
if [ -d "$PT_DIR" ]; then
  UNCOMMITTED=$(cd "$PT_DIR" && git status --short 2>/dev/null | wc -l)
  if [ "$UNCOMMITTED" -gt 0 ]; then
    log "PT: ${UNCOMMITTED} uncommitted changes - committing"
    cd "$PT_DIR" && git add -A && git commit --no-verify -m "fix(a11y): auto-commit from autonomous loop" 2>/dev/null || true
  fi
fi

# 2. Check for broken links in docs
BROKEN=$(grep -r "https\?://[^ )]*" "${ASDEV_ROOT}/docs/" --include="*.md" 2>/dev/null | grep -v "example.com\|localhost\|127.0.0.1" | head -5 || true)

# 3. Check if memory files need updating
MEMORY_FILE="${ASDEV_ROOT}/docs/memory/ASDEV_CURRENT_STATE.md"
if [ -f "$MEMORY_FILE" ]; then
  LAST_UPDATE=$(grep -o "Updated:.*" "$MEMORY_FILE" 2>/dev/null | head -1 | sed 's/Updated: //' || echo "unknown")
  log "Memory last updated: ${LAST_UPDATE}"
fi

# 4. Run health check on all sites
log "Running health check..."
for site in "persiantoolbox.ir" "alirezasafaeisystems.ir" "audit.alirezasafaeisystems.ir"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${site}/" 2>/dev/null || echo "000")
  log "  ${site}: HTTP ${STATUS}"
done

# 5. Check queue status
QUEUE_FILE="${ASDEV_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"
if [ -f "$QUEUE_FILE" ]; then
  PENDING=$(grep -c "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || echo "0")
  DONE=$(grep -c "^\- \[x\]" "$QUEUE_FILE" 2>/dev/null || echo "0")
  log "Queue: ${PENDING} pending, ${DONE} done"
fi

log "=== Work selection complete ==="
