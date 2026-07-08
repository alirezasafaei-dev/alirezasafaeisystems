#!/usr/bin/env bash
# Add a task to local queue.json (no SaaS).
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
QUEUE="${ASDEV_QUEUE_FILE:-$ROOT/control-plane/queue/queue.json}"
TITLE=""
PRIORITY=3
OWNER="automation-host-agent"
APPROVAL=""
TAGS="ops"

usage() {
  cat <<EOF
Usage: $(basename "$0") --title "..." [--priority N] [--owner id] [--approval PHRASE] [--tags a,b]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --priority) PRIORITY="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --approval) APPROVAL="$2"; shift 2 ;;
    --tags) TAGS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$TITLE" ]] || { usage; exit 1; }
[[ -f "$QUEUE" ]] || { echo "missing $QUEUE" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DAY=$(date -u +%Y%m%d)
N=$(jq --arg p "ASDEV-$DAY" '[.tasks[]?.id | select(startswith($p))] | length' "$QUEUE")
ID=$(printf 'ASDEV-%s-%03d' "$DAY" "$((N + 1))")

TMP=$(mktemp)
jq --arg id "$ID" --arg title "$TITLE" --arg owner "$OWNER" --argjson pri "$PRIORITY" \
  --arg ts "$TS" --arg appr "$APPROVAL" --arg tags "$TAGS" '
  .tasks += [{
    id: $id,
    title: $title,
    status: (if $appr == "" then "approved" else "pending" end),
    owner: $owner,
    priority: $pri,
    depends_on: [],
    approval_required: (if $appr == "" then null else $appr end),
    tags: ($tags | split(",")),
    created_at: $ts,
    updated_at: $ts,
    logs: [($ts + " created")],
    result: null
  }]
' "$QUEUE" >"$TMP"
mv "$TMP" "$QUEUE"
echo "ADDED $ID"
