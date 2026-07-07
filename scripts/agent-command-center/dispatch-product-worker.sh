#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

log() { echo -e "[DISPATCH] $*"; }

TASK_ID="${1:-}"
TASK_TITLE="${2:-}"
MODE="${3:-product-branch}"
REPO="${4:-auditsystems}"

if [ -z "$TASK_ID" ] || [ -z "$TASK_TITLE" ]; then
  log "Usage: dispatch-product-worker.sh <task-id> <title> [mode] [repo]"
  exit 1
fi

SAFETY_CHECK=$(bash "${SCRIPT_DIR}/agent-safety-gate.sh" "$REPO" "$MODE" 2>&1)
if [ $? -ne 0 ]; then
  log "Safety gate rejected: $SAFETY_CHECK"
  exit 1
fi

BRANCH_NAME="auto/${TASK_ID}-$(date -u +%Y%m%d-%H%M%S)"
AUDITSYSTEMS_DIR="${WORKSPACE_ROOT}/sites/live/auditsystems"

case "$MODE" in
  read-only)
    log "Read-only mode — report only, no branches"
    echo "MODE=read-only TASK=$TASK_ID"
    ;;
  docs-only)
    log "Docs-only mode — will create docs branch"
    echo "MODE=docs-only TASK=$TASK_ID BRANCH=$BRANCH_NAME"
    ;;
  test-only)
    log "Test-only mode — will create test branch"
    cd "$AUDITSYSTEMS_DIR"
    git checkout -b "$BRANCH_NAME" 2>/dev/null || true
    echo "MODE=test-only TASK=$TASK_ID BRANCH=$BRANCH_NAME"
    ;;
  product-branch)
    log "Product branch mode — will create feature branch"
    cd "$AUDITSYSTEMS_DIR"
    git checkout -b "$BRANCH_NAME" 2>/dev/null || true
    echo "MODE=product-branch TASK=$TASK_ID BRANCH=$BRANCH_NAME"
    ;;
  automation-script)
    log "Automation script mode — alirezasafaeisystems branch"
    cd "${WORKSPACE_ROOT}/sites/live/alirezasafaeisystems"
    git checkout -b "$BRANCH_NAME" 2>/dev/null || true
    echo "MODE=automation-script TASK=$TASK_ID BRANCH=$BRANCH_NAME"
    ;;
  *)
    log "Unknown mode: $MODE"
    exit 1
    ;;
esac

log "Worker dispatched for $TASK_ID in $MODE mode"
