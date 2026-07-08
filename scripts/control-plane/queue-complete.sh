#!/usr/bin/env bash
# Mark task done with result string.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
QUEUE="${ASDEV_QUEUE_FILE:-$ROOT/control-plane/queue/queue.json}"
ID=""
RESULT="ok"
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --result) RESULT="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$ID" ]] || { echo "Usage: $0 --id ID [--result text]" >&2; exit 1; }

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP=$(mktemp)
jq --arg id "$ID" --arg ts "$TS" --arg res "$RESULT" '
  .tasks = [.tasks[] |
    if .id == $id then
      .status = "done"
      | .updated_at = $ts
      | .result = $res
      | .logs += [($ts + " completed: " + $res)]
    else . end]
' "$QUEUE" >"$TMP"
mv "$TMP" "$QUEUE"
echo "DONE $ID"
