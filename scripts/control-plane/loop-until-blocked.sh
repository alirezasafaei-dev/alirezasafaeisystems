#!/usr/bin/env bash
# Bounded autonomous productivity loop (max N iterations).
# Never executes gated production mutations.
# v2: Uses supervisor v2, correct repo paths, proper verdict handling.
set -euo pipefail
ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO_DIR="${ASDEV_REPO_DIR:-$ROOT}"
MAX="${ASDEV_LOOP_MAX:-5}"
LOG_DIR="$REPO_DIR/ops/automation-logs"
LOG="$LOG_DIR/loop-until-$(date -u +%Y%m%d).log"
mkdir -p "$LOG_DIR"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] start max=$MAX" | tee -a "$LOG"

for ((i=1; i<=MAX; i++)); do
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] iteration $i" | tee -a "$LOG"

  # Run supervisor gate
  SUPERVISOR_SCRIPT="$REPO_DIR/scripts/control-plane/asdev-supervisor.sh"
  if [[ -x "$SUPERVISOR_SCRIPT" ]]; then
    if ! bash "$SUPERVISOR_SCRIPT" >>"$LOG" 2>&1; then
      echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] supervisor NO_GO — loop stopped" | tee -a "$LOG"
      echo "LOOP_BLOCKED SUPERVISOR_NO_GO"
      break
    fi
  fi

  out=$(bash "$REPO_DIR/scripts/control-plane/queue-claim.sh" 2>/dev/null || echo "NO_TASK")
  echo "$out" | tee -a "$LOG"
  if [[ "$out" == "NO_TASK" ]]; then
    echo "no safe runnable task — stop loop" | tee -a "$LOG"
    break
  fi
  id=${out#CLAIMED }
  tags=$(jq -r --arg id "$id" '.tasks[]|select(.id==$id)|(.tags//[])|join(",")' "$REPO_DIR/control-plane/queue/queue.json" 2>/dev/null || echo "")
  if [[ "$tags" == *safe-auto* ]]; then
    bash "$REPO_DIR/scripts/control-plane/queue-complete.sh" --id "$id" --result "loop-until auto $i" 2>/dev/null || true
  else
    echo "interactive/gated task claimed — leave in_progress and stop" | tee -a "$LOG"
    break
  fi
done
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] end" | tee -a "$LOG"
