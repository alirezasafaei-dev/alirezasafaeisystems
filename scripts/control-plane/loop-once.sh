#!/usr/bin/env bash
# Single control-plane loop iteration (bounded — not infinite).
# 1 read state 2 claim task 3 execute only if SAFE tag 4 report 5 memory hint
# Does NOT run production mutations.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
CP="$ROOT/control-plane"
LOG="$CP/logs/loop-$(date -u +%Y%m%d).log"
mkdir -p "$CP/logs" "$CP/state"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

log() { echo "[$TS] $*" | tee -a "$LOG"; }

log "loop-once start"
# health
if [[ -x "$ROOT/scripts/ops/automation-health-check.sh" ]]; then
  bash "$ROOT/scripts/ops/automation-health-check.sh" >>"$LOG" 2>&1 || true
fi

CLAIM=$(bash "$ROOT/scripts/control-plane/queue-claim.sh")
log "claim: $CLAIM"
if [[ "$CLAIM" == "NO_TASK" ]]; then
  log "no runnable task — exit"
  exit 0
fi
ID=${CLAIM#CLAIMED }

# Inspect tags — only auto-run docs/audit style
TAGS=$(jq -r --arg id "$ID" '.tasks[] | select(.id==$id) | (.tags//[])|join(",")' "$CP/queue/queue.json")
TITLE=$(jq -r --arg id "$ID" '.tasks[] | select(.id==$id) | .title' "$CP/queue/queue.json")
log "task=$ID title=$TITLE tags=$TAGS"

if [[ "$TAGS" == *safe-auto* ]]; then
  log "safe-auto: mark complete (placeholder executor — real work done by human/agent session)"
  bash "$ROOT/scripts/control-plane/queue-complete.sh" --id "$ID" --result "safe-auto acknowledged $TS"
else
  log "task requires interactive agent — leaving in_progress for session pickup"
  # revert to approved so interactive agent can pick, or leave in_progress
  # Prefer leave in_progress for handoff
fi

log "loop-once end"
echo "LOOP_ONCE_OK $CLAIM"
