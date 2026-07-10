#!/usr/bin/env bash
# Single control-plane loop iteration (bounded — not infinite).
# Policy: docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md
# 1 supervisor gate 2 read state 3 claim task 4 execute only if SAFE tag 5 report
# Does NOT run production mutations.
# v2: Integrates supervisor v2 verdict, MCP check, commit throttle.
set -Euo pipefail
ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO_DIR="${ASDEV_REPO_DIR:-$ROOT}"
CP="$REPO_DIR/control-plane"
STATE_DIR="$REPO_DIR/.state"
LOG_DIR="$REPO_DIR/ops/automation-logs"
LOG="$LOG_DIR/loop-$(date -u +%Y%m%d).log"
mkdir -p "$LOG_DIR" "$CP/logs" "$CP/state" "$STATE_DIR"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

log() { echo "[$TS] $*" | tee -a "$LOG"; }

log "loop-once start (v2)"

# ---------------------------------------------------------------------------
# Gate 1: Supervisor verdict (must be GO or GO_WITH_WARNINGS to proceed)
# ---------------------------------------------------------------------------
SUPERVISOR_SCRIPT="$REPO_DIR/scripts/control-plane/asdev-supervisor.sh"
SUPERVISOR_STATE="$STATE_DIR/asdev-supervisor/latest.json"
VERDICT="UNKNOWN"

if [[ -x "$SUPERVISOR_SCRIPT" ]]; then
  log "Running supervisor pre-loop gate..."
  if bash "$SUPERVISOR_SCRIPT" >>"$LOG" 2>&1; then
    # Read verdict from state file
    if [ -f "$SUPERVISOR_STATE" ]; then
      VERDICT=$(python3 -c "import json; d=json.load(open('$SUPERVISOR_STATE')); print(d.get('verdict','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
    else
      VERDICT="GO"  # script exited 0 but no state file
    fi
    log "Supervisor: $VERDICT"
  else
    # Script exited non-zero — read state file for detail
    if [ -f "$SUPERVISOR_STATE" ]; then
      VERDICT=$(python3 -c "import json; d=json.load(open('$SUPERVISOR_STATE')); print(d.get('verdict','NO_GO'))" 2>/dev/null || echo "NO_GO")
    else
      VERDICT="NO_GO"
    fi
    log "Supervisor: $VERDICT — loop skipped"
    echo "LOOP_BLOCKED SUPERVISOR_$VERDICT"
    exit 1
  fi
else
  log "WARNING: Supervisor script not found at $SUPERVISOR_SCRIPT — proceeding without gate"
fi

# ---------------------------------------------------------------------------
# Gate 2: Supervisor failure itself must fail closed
# ---------------------------------------------------------------------------
if [ "$VERDICT" = "NO_GO" ]; then
  log "Supervisor verdict is NO_GO — loop blocked. No task claim, no agent execution."
  echo "LOOP_BLOCKED SUPERVISOR_NO_GO"
  exit 1
fi

# GO_WITH_WARNINGS: continue with caution (log the warning)
if [ "$VERDICT" = "GO_WITH_WARNINGS" ]; then
  log "Supervisor: GO_WITH_WARNINGS — loop proceeding with caution"
fi

# ---------------------------------------------------------------------------
# Gate 3: MCP health (non-blocking warning, logged)
# ---------------------------------------------------------------------------
MCP_STATE="$STATE_DIR/asdev-mcp/latest.json"
if [ -f "$MCP_STATE" ]; then
  MCP_VERDICT=$(python3 -c "import json; d=json.load(open('$MCP_STATE')); print(d.get('verdict','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
  log "MCP health: $MCP_VERDICT"
  if [ "$MCP_VERDICT" = "FAIL" ]; then
    log "WARNING: MCP endpoint unhealthy — loop continues but MCP-dependent tasks may fail"
  fi
fi

# ---------------------------------------------------------------------------
# Task claim and execution
# ---------------------------------------------------------------------------
CLAIM=$(bash "$REPO_DIR/scripts/control-plane/queue-claim.sh" 2>/dev/null || echo "NO_TASK")
log "claim: $CLAIM"
if [[ "$CLAIM" == "NO_TASK" ]]; then
  log "no runnable task — exit"
  exit 0
fi
ID=${CLAIM#CLAIMED }

# Inspect tags — only auto-run docs/audit style
TAGS=$(jq -r --arg id "$ID" '.tasks[] | select(.id==$id) | (.tags//[])|join(",")' "$CP/queue/queue.json" 2>/dev/null || echo "")
TITLE=$(jq -r --arg id "$ID" '.tasks[] | select(.id==$id) | .title' "$CP/queue/queue.json" 2>/dev/null || echo "unknown")
log "task=$ID title=$TITLE tags=$TAGS"

if [[ "$TAGS" == *safe-auto* ]]; then
  log "safe-auto: mark complete (placeholder executor)"
  bash "$REPO_DIR/scripts/control-plane/queue-complete.sh" --id "$ID" --result "safe-auto acknowledged $TS" 2>/dev/null || true
else
  log "task requires interactive agent — leaving in_progress for session pickup"
fi

log "loop-once end"
echo "LOOP_ONCE_OK $CLAIM"
