#!/usr/bin/env bash
# Claim next runnable task (priority order). Skips approval_required tasks.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
QUEUE="${ASDEV_QUEUE_FILE:-$ROOT/control-plane/queue/queue.json}"
AGENT="${ASDEV_AGENT_ID:-automation-host-agent}"
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }
[[ -f "$QUEUE" ]] || { echo "missing $QUEUE" >&2; exit 1; }

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP=$(mktemp)
# Select first approved/pending without approval_required and not blocked by depends
ID=$(jq -r '
  [.tasks[]
    | select(.status=="approved" or (.status=="pending" and (.approval_required==null)))
    | select((.depends_on|length)==0)
  ]
  | sort_by(.priority, .created_at)
  | .[0].id // empty
' "$QUEUE")

if [[ -z "$ID" ]]; then
  echo "NO_TASK"
  exit 0
fi

jq --arg id "$ID" --arg ts "$TS" --arg agent "$AGENT" '
  .tasks = [.tasks[] |
    if .id == $id then
      .status = "in_progress"
      | .owner = $agent
      | .updated_at = $ts
      | .logs += [($ts + " claimed by " + $agent)]
    else . end]
' "$QUEUE" >"$TMP"
mv "$TMP" "$QUEUE"
echo "CLAIMED $ID"
