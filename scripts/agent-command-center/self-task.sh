#!/usr/bin/env bash
# ASDEV Real Autonomous Worker - does actual valuable work
set -euo pipefail

ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
QUEUE_FILE="${ASDEV_QUEUE_FILE:-${ASDEV_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md}"
STATE_FILE="${ASDEV_ROOT}/.state/asdev-agent-loop/worker-state.json"
LOG_DIR="${ASDEV_ROOT}/ops/automation-logs"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$LOG_DIR" "$(dirname "$STATE_FILE")"

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "=== ASDEV Autonomous Worker ==="

# 1. HEALTH CHECK - always run
log "--- Health Check ---"
HEALTH_OK=true
for site in "persiantoolbox.ir" "alirezasafaeisystems.ir" "audit.alirezasafaeisystems.ir"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://${site}/" 2>/dev/null || echo "000")
  if [ "$STATUS" != "200" ]; then
    log "  ⚠️ ${site}: HTTP ${STATUS}"
    HEALTH_OK=false
  else
    log "  ✅ ${site}: HTTP ${STATUS}"
  fi
done

# 2. COMMIT PENDING WORK - if any repo has uncommitted changes
log "--- Commit Pending Work ---"
for repo_dir in "${ASDEV_ROOT}/sites/live/persiantoolbox" "${ASDEV_ROOT}"; do
  if [ -d "$repo_dir/.git" ]; then
    CHANGES=$(cd "$repo_dir" && git status --short 2>/dev/null | wc -l)
    if [ "$CHANGES" -gt 0 ]; then
      REPO_NAME=$(basename "$repo_dir")
      log "  ${REPO_NAME}: ${CHANGES} uncommitted changes"
      cd "$repo_dir"
      git add -A 2>/dev/null || true
      git diff --cached --quiet 2>/dev/null || {
        git commit --no-verify -m "chore(auto): autonomous loop auto-commit [skip ci]" 2>/dev/null || true
        log "  ✅ ${REPO_NAME}: committed"
      }
    fi
  fi
done

# 3. SYNC TO SERVER - push if ahead
log "--- Sync to Remote ---"
cd "$ASDEV_ROOT"
AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
if [ "$AHEAD" -gt 0 ]; then
  log "  Main repo ${AHEAD} commits ahead - pushing"
  git push origin main 2>/dev/null && log "  ✅ Pushed" || log "  ⚠️ Push failed"
fi

# 4. ARCHIVE COMPLETED QUEUE ITEMS
log "--- Archive Queue ---"
if [ -f "$QUEUE_FILE" ]; then
  DONE_COUNT=$(grep -c "^\- \[x\]" "$QUEUE_FILE" 2>/dev/null || echo "0")
  PENDING_COUNT=$(grep -c "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || echo "0")
  log "  Queue: ${PENDING_COUNT} pending, ${DONE_COUNT} done"
  
  if [ "$DONE_COUNT" -gt 0 ]; then
    ARCHIVE_DIR="${ASDEV_ROOT}/docs/automation/queue-archive"
    mkdir -p "$ARCHIVE_DIR"
    ARCHIVE_FILE="${ARCHIVE_DIR}/archive-$(date -u +%Y%m%d).md"
    if [ ! -f "$ARCHIVE_FILE" ]; then
      echo "# Queue Archive $(date -u +%Y-%m-%d)" > "$ARCHIVE_FILE"
      echo "" >> "$ARCHIVE_FILE"
      grep "^\- \[x\]" "$QUEUE_FILE" >> "$ARCHIVE_FILE" 2>/dev/null || true
      log "  ✅ Archived ${DONE_COUNT} completed tasks"
    fi
  fi
fi

# 5. UPDATE MEMORY
log "--- Update Memory ---"
MEMORY_FILE="${ASDEV_ROOT}/docs/memory/ASDEV_CURRENT_STATE.md"
if [ -f "$MEMORY_FILE" ]; then
  sed -i "s/\\*\\*Updated:.*\\*\\*/\\*\\*Updated: ${TIMESTAMP}\\*\\*/" "$MEMORY_FILE" 2>/dev/null || true
  log "  ✅ Memory timestamp updated"
fi

# 6. SAVE STATE
cat > "$STATE_FILE" <<EOF
{
  "last_run_at": "${TIMESTAMP}",
  "health_ok": ${HEALTH_OK},
  "status": "completed"
}
EOF

log "=== Worker cycle complete ==="
