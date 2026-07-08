#!/usr/bin/env bash
# Detect in_progress tasks older than STALE_HOURS (default 24). Read-only unless --reset-stale.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
QUEUE="${ASDEV_QUEUE_FILE:-$ROOT/control-plane/queue/queue.json}"
STALE_HOURS="${STALE_HOURS:-24}"
RESET=false
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }
[[ -f "$QUEUE" ]] || { echo "missing queue" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reset-stale) RESET=true; shift ;;
    --hours) STALE_HOURS="$2"; shift 2 ;;
    *) echo "Unknown $1" >&2; exit 1 ;;
  esac
done

NOW=$(date +%s)
STALE_SEC=$((STALE_HOURS * 3600))

mapfile -t STALE_IDS < <(jq -r --argjson now "$NOW" --argjson max "$STALE_SEC" '
  .tasks[]?
  | select(.status=="in_progress")
  | . as $t
  | ((try ($t.updated_at|fromdateiso8601) catch 0) ) as $u
  | select($now - $u > $max)
  | .id
' "$QUEUE")

if [[ "${#STALE_IDS[@]}" -eq 0 || -z "${STALE_IDS[0]:-}" ]]; then
  echo "STALE_COUNT=0"
  exit 0
fi

echo "STALE_COUNT=${#STALE_IDS[@]}"
printf '%s\n' "${STALE_IDS[@]}"

if [[ "$RESET" != "true" ]]; then
  exit 0
fi

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP=$(mktemp)
jq --arg ts "$TS" --argjson ids "$(printf '%s\n' "${STALE_IDS[@]}" | jq -R . | jq -s .)" '
  .tasks = [.tasks[] |
    if ((.id as $id | $ids | index($id)) != null) and .status=="in_progress" then
      .status = "approved"
      | .updated_at = $ts
      | .logs += [($ts + " reset from stale in_progress")]
    else . end]
' "$QUEUE" >"$TMP"
mv "$TMP" "$QUEUE"
echo "RESET_DONE"
