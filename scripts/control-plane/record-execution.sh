#!/usr/bin/env bash
# Append execution history event (local JSONL under control-plane/history).
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
HIST="$ROOT/control-plane/history/executions.jsonl"
mkdir -p "$(dirname "$HIST")"
TASK_ID="${1:-unknown}"
RESULT="${2:-ok}"
AGENT="${ASDEV_AGENT_ID:-automation-host-agent}"
DETAIL="${3:-}"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# single line JSON
printf '{"ts":"%s","agent":"%s","task_id":"%s","result":"%s","detail":%s}\n' \
  "$TS" "$AGENT" "$TASK_ID" "$RESULT" "$(printf '%s' "$DETAIL" | jq -Rs .)" >>"$HIST"
echo "RECORDED $TASK_ID $RESULT"
