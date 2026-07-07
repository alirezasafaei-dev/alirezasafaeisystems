#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
QUEUE_FILE="${WORKSPACE_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"
AUDITSYSTEMS_DIR="${WORKSPACE_ROOT}/sites/live/auditsystems"

TASK_ID="${1:-}"

log() { echo -e "[LOCAL-HEAVY] $*"; }
ok() { echo -e "[OK] $*"; }
fail() { echo -e "[FAIL] $*"; }

if [ -z "$TASK_ID" ]; then
  log "Usage: local-heavy-runner.sh <task-id>"
  log ""
  log "Available local-heavy tasks:"
  grep "execution_target: local-heavy" "$QUEUE_FILE" 2>/dev/null | sed 's/.*ID: /  /' | cut -d'|' -f1 || echo "  (none)"
  exit 1
fi

TASK_LINE=$(grep "ID: ${TASK_ID}" "$QUEUE_FILE" 2>/dev/null || true)
if [ -z "$TASK_LINE" ]; then
  fail "Task ${TASK_ID} not found in queue"
  exit 1
fi

TASK_TITLE=$(echo "$TASK_LINE" | sed 's/^- \[.\] //' | sed 's/|.*//' | xargs)
MODE=$(echo "$TASK_LINE" | grep -oP 'Mode:\s*\K\S+' || echo "product-branch")
EXEC_TARGET=$(echo "$TASK_LINE" | grep -oP 'execution_target:\s*\K\S+' || echo "")

if [ "$EXEC_TARGET" != "local-heavy" ]; then
  log "Task ${TASK_ID} is not marked as local-heavy (target: ${EXEC_TARGET:-unknown})"
  log "Use the VPS autonomous loop instead."
  exit 1
fi

log "=== Executing Local Heavy Task ==="
log "Task: ${TASK_ID} — ${TASK_TITLE}"
log "Mode: ${MODE}"
echo ""

case "$MODE" in
  product-branch|test-only)
    log "Running full validation..."
    cd "$AUDITSYSTEMS_DIR"
    log "Typecheck..."
    pnpm typecheck
    ok "Typecheck pass"

    log "Lint..."
    pnpm lint
    ok "Lint pass"

    log "Test..."
    pnpm test
    ok "Test pass"

    log "Build..."
    pnpm build
    ok "Build pass"
    ;;
  docs-only)
    log "Docs task — no heavy validation needed"
    ;;
  automation-script)
    log "Script task — checking syntax..."
    bash -n "${SCRIPT_DIR}"/*.sh
    ok "Script syntax OK"
    ;;
  *)
    log "Unknown mode: ${MODE}"
    exit 1
    ;;
esac

echo ""
ok "Task ${TASK_ID} completed locally"
log "Report result to Issue #45 or update queue."
