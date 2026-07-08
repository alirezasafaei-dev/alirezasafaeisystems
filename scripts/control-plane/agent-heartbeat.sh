#!/usr/bin/env bash
# Record agent heartbeat (ownership proof). Safe local write under control-plane.
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
AGENT="${ASDEV_AGENT_ID:-automation-host-agent}"
DIR="$ROOT/control-plane/state/heartbeats"
mkdir -p "$DIR"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
FILE="$DIR/${AGENT}.json"
cat >"$FILE" <<EOF
{
  "agent_id": "$AGENT",
  "heartbeat_at": "$TS",
  "host_alias": "AUTOMATION_HOST",
  "pid": $$,
  "status": "alive"
}
EOF
echo "HEARTBEAT $AGENT $TS"
