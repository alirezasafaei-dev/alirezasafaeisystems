#!/usr/bin/env bash
# Write a local observability snapshot JSON (no live timers, no SaaS).
set -euo pipefail
ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
OUT="${1:-$ROOT/control-plane/health/observability-snapshot.json}"
mkdir -p "$(dirname "$OUT")"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
disk=$(df -P / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
mem=$(free -m | awk '/^Mem:/{print $7}')
queue_pending=0
if [[ -f "$ROOT/control-plane/queue/queue.json" ]] && command -v jq >/dev/null; then
  queue_pending=$(jq '[.tasks[]?|select(.status=="pending" or .status=="approved")]|length' "$ROOT/control-plane/queue/queue.json")
fi
cat >"$OUT" <<EOF
{
  "ts": "$TS",
  "host_alias": "AUTOMATION_HOST",
  "disk_used_pct": $disk,
  "mem_avail_mb": $mem,
  "queue_pending_or_approved": $queue_pending,
  "notes": "foundation snapshot; not scraped by live timers"
}
EOF
echo "WROTE $OUT"
