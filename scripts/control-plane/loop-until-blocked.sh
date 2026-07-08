#!/usr/bin/env bash
# Bounded autonomous productivity loop (max N iterations).
# Never executes gated production mutations.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
MAX="${ASDEV_LOOP_MAX:-5}"
LOG="$ROOT/control-plane/logs/loop-until-$(date -u +%Y%m%d).log"
mkdir -p "$ROOT/control-plane/logs"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] start max=$MAX" | tee -a "$LOG"
for ((i=1; i<=MAX; i++)); do
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] iteration $i" | tee -a "$LOG"
  bash "$ROOT/scripts/ops/automation-health-check.sh" >>"$LOG" 2>&1 || true
  out=$(bash "$ROOT/scripts/control-plane/queue-claim.sh")
  echo "$out" | tee -a "$LOG"
  if [[ "$out" == "NO_TASK" ]]; then
    echo "no safe runnable task — stop loop" | tee -a "$LOG"
    break
  fi
  id=${out#CLAIMED }
  tags=$(jq -r --arg id "$id" '.tasks[]|select(.id==$id)|(.tags//[])|join(",")' "$ROOT/control-plane/queue/queue.json")
  if [[ "$tags" == *safe-auto* ]]; then
    bash "$ROOT/scripts/control-plane/queue-complete.sh" --id "$id" --result "loop-until auto $i"
  else
    echo "interactive/gated task claimed — leave in_progress and stop" | tee -a "$LOG"
    break
  fi
done
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] end" | tee -a "$LOG"
