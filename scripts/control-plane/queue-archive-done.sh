#!/usr/bin/env bash
# Move done/cancelled tasks from queue.json into archive snapshot.
# Safe local filesystem only.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
QUEUE="${ASDEV_QUEUE_FILE:-$ROOT/control-plane/queue/queue.json}"
ARCHIVE_DIR="${ASDEV_QUEUE_ARCHIVE:-$ROOT/control-plane/queue/archive}"
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }
[[ -f "$QUEUE" ]] || { echo "missing $QUEUE" >&2; exit 1; }
mkdir -p "$ARCHIVE_DIR"
TS=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$ARCHIVE_DIR/done-$TS.json"
TMP=$(mktemp)
jq '{version, updated_at: now|todateiso8601, tasks: [.tasks[]? | select(.status=="done" or .status=="cancelled")]}' "$QUEUE" >"$OUT"
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  .updated_at = $ts
  | .tasks = [.tasks[]? | select(.status!="done" and .status!="cancelled")]
' "$QUEUE" >"$TMP"
mv "$TMP" "$QUEUE"
echo "ARCHIVED $OUT"
jq -r '.tasks | length' "$OUT" | xargs -I{} echo "archived_count={}"
