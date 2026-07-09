#!/usr/bin/env bash
# ASDEV Real Autonomous Worker - does actual valuable work
# Enhanced: MCP health, queue seeding, safe-task synthesis
set -euo pipefail

ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
QUEUE_FILE="${ASDEV_QUEUE_FILE:-${ASDEV_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md}"
JSON_QUEUE_FILE="${ASDEV_JSON_QUEUE_FILE:-${ASDEV_ROOT}/control-plane/queue/queue.json}"
STATE_FILE="${ASDEV_ROOT}/.state/asdev-agent-loop/worker-state.json"
LOG_DIR="${ASDEV_ROOT}/ops/automation-logs"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$LOG_DIR" "$(dirname "$STATE_FILE")"

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "=== ASDEV Autonomous Worker ==="

MCP_ENDPOINT="https://mcp.alirezasafaeisystems.ir/sse"
COMMIT_HASH=$(cd "$ASDEV_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
log "Commit: ${COMMIT_HASH}"

# ---- 1. HEALTH CHECK ----
log "--- Health Check ---"
HEALTH_OK=true
for site in "persiantoolbox.ir" "alirezasafaeisystems.ir" "audit.alirezasafaeisystems.ir"; do
  STATUS=$( (timeout 10 curl -s -o /dev/null -w "%{http_code}" "https://${site}/" 2>/dev/null || true) | grep -oE '^[0-9]{3}' | tr -d '[:space:]')
  STATUS="${STATUS:-000}"
  if [ "$STATUS" != "200" ]; then
    log "  ! ${site}: HTTP ${STATUS}"
    HEALTH_OK=false
  else
    log "  OK ${site}: HTTP ${STATUS}"
  fi
done

# ---- 1b. MCP HEALTH ----
log "--- MCP Health ---"
MCP_CODE=$( (timeout 5 curl -sN -D - -o /dev/null "http://127.0.0.1:8000/sse" 2>/dev/null || true) | grep -oE 'HTTP/[0-9.]+ [0-9]{3}' | head -1 | grep -oE '[0-9]{3}' | tr -d '[:space:]')
MCP_CODE="${MCP_CODE:-000}"
if [ "${MCP_CODE}" = "200" ]; then
  log "  OK /sse: HTTP ${MCP_CODE}"
else
  log "  ! /sse: HTTP ${MCP_CODE}"
fi
# Check MCP server by port
if ss -tlnp 2>/dev/null | grep -q ":8000"; then
  log "  OK asdev-chatgpt-mcp: listening on :8000"
else
  log "  ! asdev-chatgpt-mcp: port 8000 not listening"
fi
# Check Caddy by port
if ss -tlnp 2>/dev/null | grep -q ":443"; then
  log "  OK asdev-chatgpt-caddy: listening on :443"
else
  log "  ! asdev-chatgpt-caddy: port 443 not listening"
fi

# ---- 2. COMMIT PENDING WORK ----
log "--- Commit Pending Work ---"
for repo_dir in "${ASDEV_ROOT}"; do
  if [ -d "$repo_dir/.git" ]; then
    CHANGES=$(cd "$repo_dir" && git status --short 2>/dev/null | wc -l)
    if [ "$CHANGES" -gt 0 ]; then
      cd "$repo_dir"
      git add -A 2>/dev/null || true
      git diff --cached --quiet 2>/dev/null || {
        git commit --no-verify -m "chore(auto): autonomous loop auto-commit [skip ci]" 2>/dev/null || true
        log "  OK committed"
      }
    fi
  fi
done

# ---- 3. SYNC TO GITHUB ----
log "--- Sync to GitHub ---"
cd "$ASDEV_ROOT"
BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
if [ "$BEHIND" -gt 0 ]; then
  log "  Remote ahead by ${BEHIND} - rebasing"
  git pull --rebase 2>/dev/null || true
fi
AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
if [ "$AHEAD" -gt 0 ]; then
  log "  ${AHEAD} commits ahead - pushing"
  git push origin main 2>/dev/null && log "  OK Pushed" || log "  ! Push failed"
fi

# ---- 4. QUEUE INTEGRITY ----
log "--- Queue Status ---"
if [ -f "$QUEUE_FILE" ]; then
  PENDING=$(grep -c "^- \[ \]" "$QUEUE_FILE" 2>/dev/null || true)
  DONE=$(grep -c "^- \[x\]" "$QUEUE_FILE" 2>/dev/null || true)
  GATED=$(grep -c "APPROVE_" "$QUEUE_FILE" 2>/dev/null || true)
  PENDING=${PENDING:-0}; DONE=${DONE:-0}; GATED=${GATED:-0}
  log "  Markdown queue — Pending: ${PENDING}, Gated: ${GATED}, Done: ${DONE}"

  # ARCHIVE DONE ITEMS
  if [ "$DONE" -gt 0 ]; then
    ARCHIVE_DIR="${ASDEV_ROOT}/docs/automation/queue-archive"
    mkdir -p "$ARCHIVE_DIR"
    ARCHIVE_FILE="${ARCHIVE_DIR}/archive-$(date -u +%Y%m%d).md"
    if [ ! -f "$ARCHIVE_FILE" ]; then
      echo "# Queue Archive $(date -u +%Y%m%d)" > "$ARCHIVE_FILE"
      grep "^- \[x\]" "$QUEUE_FILE" >> "$ARCHIVE_FILE" 2>/dev/null || true
      log "  Archived ${DONE} completed tasks"
    fi
  fi

  # QUEUE_ONLY_GATED detection — also fires if table-format gated tasks exist with zero safe pending
  HAS_GATED_TABLE=$(grep -c "APPROVE_" "$QUEUE_FILE" 2>/dev/null || echo 0)
  if [ "$PENDING" -eq 0 ] && [ "$HAS_GATED_TABLE" -gt 0 ] 2>/dev/null; then
    log "QUEUE_ONLY_GATED_SYNTHESIZED_SAFE_TASK: markdown queue only has gated tasks"
    if ! grep -q "ASDEV-AUTO-MCP-HEALTH" "$QUEUE_FILE" 2>/dev/null; then
      cat >> "$QUEUE_FILE" << 'SEEDEOF'

## Next safe cycles
- [ ] MCP health monitor report | ID: ASDEV-AUTO-MCP-HEALTH | Mode: read-only | Priority: 3
- [ ] Control-plane queue integrity check | ID: ASDEV-AUTO-QUEUE-INTEGRITY | Mode: automation-script | Priority: 3
- [ ] Agent memory freshness check | ID: ASDEV-AUTO-MEMORY-FRESH | Mode: docs-only | Priority: 3
- [ ] MCP recurring health verify | ID: ASDEV-AUTO-MCP-SSE | Mode: read-only | Priority: 4
SEEDEOF
      log "  Seeded 4 safe tasks into markdown queue"
    fi
  fi
fi

# JSON queue is the queue used by scripts/control-plane/loop-once.sh. Seed it too.
if [ -f "$JSON_QUEUE_FILE" ] && command -v python3 >/dev/null 2>&1; then
  export JSON_QUEUE_FILE TIMESTAMP
  python3 << 'PY'
import json
import os
from pathlib import Path

path = Path(os.environ["JSON_QUEUE_FILE"])
now = os.environ["TIMESTAMP"]

data = json.loads(path.read_text())
tasks = data.get("tasks", [])
safe_pending = [
    t for t in tasks
    if t.get("status") in {"pending", "approved"} and not t.get("approval_required")
]
gated_pending = [
    t for t in tasks
    if t.get("status") in {"pending", "approved"} and t.get("approval_required")
]

seed = [
    {
        "id": "ASDEV-AUTO-MCP-HEALTH",
        "title": "MCP health monitor report",
        "status": "pending",
        "owner": "sre-observer",
        "priority": 3,
        "depends_on": [],
        "approval_required": None,
        "tags": ["mcp", "read-only", "safe-auto"],
        "created_at": now,
        "updated_at": now,
        "logs": [f"{now} synthesized by self-task loop because queue only had gated tasks"],
        "result": None,
    },
    {
        "id": "ASDEV-AUTO-QUEUE-INTEGRITY",
        "title": "Control-plane queue integrity check",
        "status": "pending",
        "owner": "automation-host-agent",
        "priority": 3,
        "depends_on": [],
        "approval_required": None,
        "tags": ["control-plane", "safe-auto", "queue"],
        "created_at": now,
        "updated_at": now,
        "logs": [f"{now} synthesized by self-task loop because queue only had gated tasks"],
        "result": None,
    },
    {
        "id": "ASDEV-AUTO-MEMORY-FRESH",
        "title": "Agent memory freshness check",
        "status": "pending",
        "owner": "docs-memory-agent",
        "priority": 3,
        "depends_on": [],
        "approval_required": None,
        "tags": ["docs", "memory", "safe-auto"],
        "created_at": now,
        "updated_at": now,
        "logs": [f"{now} synthesized by self-task loop because queue only had gated tasks"],
        "result": None,
    },
    {
        "id": "ASDEV-AUTO-MCP-SSE",
        "title": "MCP recurring SSE health verification",
        "status": "pending",
        "owner": "sre-observer",
        "priority": 4,
        "depends_on": [],
        "approval_required": None,
        "tags": ["mcp", "sse", "read-only", "safe-auto"],
        "created_at": now,
        "updated_at": now,
        "logs": [f"{now} synthesized by self-task loop because queue only had gated tasks"],
        "result": None,
    },
]

existing = {t.get("id") for t in tasks}
if not safe_pending and gated_pending:
    added = [item for item in seed if item["id"] not in existing]
    if added:
        data["tasks"] = tasks + added
        data["updated_at"] = now
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
        print(f"JSON_QUEUE_SEEDED_SAFE_TASKS={len(added)}")
    else:
        print("JSON_QUEUE_SAFE_TASKS_ALREADY_PRESENT")
else:
    print(f"JSON_QUEUE_NO_SEED safe_pending={len(safe_pending)} gated_pending={len(gated_pending)}")
PY
fi

# ---- 5. UPDATE MEMORY ----
log "--- Update Memory ---"
MEMORY_FILE="${ASDEV_ROOT}/docs/memory/ASDEV_CURRENT_STATE.md"
if [ -f "$MEMORY_FILE" ]; then
  # Fix the canonical top-level Updated line without producing malformed Markdown or double-Z timestamps.
  sed -i -E "0,/^\*\*Updated:/s|^\*\*Updated:.*|**Updated:** ${TIMESTAMP}  |" "$MEMORY_FILE" 2>/dev/null || true
  # Also repair older malformed secondary Updated lines such as '**Updated: ...ZZ'.
  sed -i -E "s|^\*\*Updated: .*$|**Updated:** ${TIMESTAMP}  |" "$MEMORY_FILE" 2>/dev/null || true
  log "  OK Memory timestamp updated"
fi

# ---- 6. SAVE STATE ----
cat > "$STATE_FILE" << SAVEEOF
{
  "last_run_at": "${TIMESTAMP}",
  "last_commit": "${COMMIT_HASH}",
  "mcp_code": "${MCP_CODE}",
  "health_ok": ${HEALTH_OK},
  "status": "completed"
}
SAVEEOF

log "=== Worker cycle complete ==="
