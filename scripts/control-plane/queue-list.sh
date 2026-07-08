#!/usr/bin/env bash
# List control-plane queue tasks (read-only).
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
QUEUE="${ASDEV_QUEUE_FILE:-$ROOT/control-plane/queue/queue.json}"
if [[ ! -f "$QUEUE" ]]; then
  echo "queue missing: $QUEUE" >&2
  exit 1
fi
if command -v jq >/dev/null 2>&1; then
  jq -r '.tasks[]? | [.id, .status, (.priority|tostring), .title] | @tsv' "$QUEUE" | column -t -s $'\t' 2>/dev/null || \
    jq -r '.tasks[]? | "\(.id)\t\(.status)\t\(.priority)\t\(.title)"' "$QUEUE"
else
  cat "$QUEUE"
fi
