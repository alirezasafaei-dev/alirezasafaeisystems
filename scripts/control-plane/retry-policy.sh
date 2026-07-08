#!/usr/bin/env bash
# Document and apply simple retry counters on tasks (safe metadata only).
# Usage: retry-policy.sh --id ID --fail "reason" | --clear
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
QUEUE="${ASDEV_QUEUE_FILE:-$ROOT/control-plane/queue/queue.json}"
MAX_RETRY="${ASDEV_MAX_RETRY:-3}"
ID=""
MODE=""
REASON=""
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --fail) MODE=fail; REASON="$2"; shift 2 ;;
    --clear) MODE=clear; shift ;;
    --max) MAX_RETRY="$2"; shift 2 ;;
    *) echo "Unknown $1" >&2; exit 1 ;;
  esac
done
[[ -n "$ID" && -n "$MODE" ]] || { echo "Usage: $0 --id ID --fail reason | --clear" >&2; exit 1; }

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP=$(mktemp)

if [[ "$MODE" == "clear" ]]; then
  jq --arg id "$ID" --arg ts "$TS" '
    .tasks = [.tasks[] |
      if .id==$id then
        .retry_count = 0
        | .updated_at = $ts
        | .logs += [($ts + " retry counter cleared")]
      else . end]
  ' "$QUEUE" >"$TMP"
  mv "$TMP" "$QUEUE"
  echo "CLEARED $ID"
  exit 0
fi

# fail path
jq --arg id "$ID" --arg ts "$TS" --arg reason "$REASON" --argjson max "$MAX_RETRY" '
  .tasks = [.tasks[] |
    if .id==$id then
      .retry_count = ((.retry_count // 0) + 1)
      | .updated_at = $ts
      | .logs += [($ts + " fail attempt " + (.retry_count|tostring) + ": " + $reason)]
      | if .retry_count >= $max then
          .status = "blocked"
          | .result = ("max retries: " + $reason)
          | .logs += [($ts + " blocked after max retries")]
        else
          .status = "approved"
        end
    else . end]
' "$QUEUE" >"$TMP"
mv "$TMP" "$QUEUE"
echo "RECORDED_FAIL $ID"
