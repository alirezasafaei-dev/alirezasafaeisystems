#!/usr/bin/env bash
# AUTOMATION_HOST self-health for control plane.
# Safe: read-only. No docker rm, no pm2 delete, no production mutation.
set -euo pipefail

PROJECT_ROOT="${ASDEV_ROOT:-/home/dev13/ASDEV}"
CP_ROOT="${ASDEV_CONTROL_PLANE:-$PROJECT_ROOT/control-plane}"
OUT_JSON="${ASDEV_HEALTH_JSON:-$CP_ROOT/health/last-health.json}"
DRY_RUN=false
ERRORS=0
WARNINGS=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--json-out <path>]

Control-plane health: disk, memory, load, docker, pm2, gateways, queue, tools.
EOF
}

log()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
ok()   { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] OK: $*"; }
warn() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: $*"; WARNINGS=$((WARNINGS + 1)); }
err()  { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*"; ERRORS=$((ERRORS + 1)); }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --json-out) OUT_JSON="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown: $1"; exit 1 ;;
  esac
done

echo "========================================"
echo "  AUTOMATION_HOST CONTROL PLANE HEALTH"
echo "========================================"

if [[ "$DRY_RUN" == "true" ]]; then
  log "[DRY RUN] Would check disk/mem/docker/pm2/gateways/queue/tools"
  exit 0
fi

# tools
for c in git bash ssh node pnpm curl rsync docker; do
  command -v "$c" >/dev/null 2>&1 && ok "tool:$c" || err "missing:$c"
done
command -v pm2 >/dev/null 2>&1 && ok "tool:pm2" || warn "pm2 missing"
command -v jq >/dev/null 2>&1 && ok "tool:jq" || warn "jq missing"

# disk / mem / load
disk_pct=$(df -P / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
disk_avail=$(df -k / | awk 'NR==2{print int($4/1024)}')
if (( disk_pct >= 90 )); then err "disk ${disk_pct}% used"; elif (( disk_pct >= 80 )); then warn "disk ${disk_pct}% used"; else ok "disk ${disk_pct}% used avail=${disk_avail}MB"; fi

mem_avail=$(free -m | awk '/^Mem:/{print $7}')
if (( mem_avail < 512 )); then err "mem_avail ${mem_avail}MB"; elif (( mem_avail < 2048 )); then warn "mem_avail ${mem_avail}MB"; else ok "mem_avail ${mem_avail}MB"; fi

load1=$(awk '{print $1}' /proc/loadavg)
ok "load1=$load1"

# docker
if command -v docker >/dev/null 2>&1; then
  running=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
  unhealthy=$(docker ps --filter health=unhealthy -q 2>/dev/null | wc -l | tr -d ' ')
  stopped=$(docker ps -aq -f status=exited 2>/dev/null | wc -l | tr -d ' ')
  ok "docker running=$running unhealthy=$unhealthy exited=$stopped"
  if (( unhealthy > 0 )); then err "unhealthy containers=$unhealthy"; fi
  if (( stopped > 0 )); then warn "exited containers=$stopped (see container-inventory)"; fi
else
  warn "docker not available"
fi

# pm2
if command -v pm2 >/dev/null 2>&1; then
  pm2_n=$(pm2 jlist 2>/dev/null | jq 'length' 2>/dev/null || echo 0)
  if [[ "${pm2_n:-0}" == "0" ]]; then
    warn "pm2 apps=0 (idle OK if gateways external)"
  else
    ok "pm2 apps=$pm2_n"
  fi
fi

# gateways (informational)
if pgrep -f 'hermes_cli.main gateway' >/dev/null 2>&1; then ok "gateway:hermes running"; else warn "gateway:hermes not running"; fi
if pgrep -f 'openclaw.*gateway' >/dev/null 2>&1; then ok "gateway:openclaw running"; else warn "gateway:openclaw not running"; fi

# repo / control plane
if [[ -d "$PROJECT_ROOT/deploy" ]]; then ok "asdev repo layout"; else err "asdev repo missing deploy/"; fi
if [[ -d "$CP_ROOT" ]]; then ok "control-plane root $CP_ROOT"; else warn "control-plane root missing"; fi

queue_file="$CP_ROOT/queue/queue.json"
stale_jobs=0
if [[ -f "$queue_file" ]] && command -v jq >/dev/null 2>&1; then
  pending=$(jq '[.tasks[]? | select(.status=="pending" or .status=="approved")] | length' "$queue_file" 2>/dev/null || echo 0)
  inprog=$(jq '[.tasks[]? | select(.status=="in_progress")] | length' "$queue_file" 2>/dev/null || echo 0)
  # stale: in_progress updated_at older than 24h
  stale_jobs=$(jq --argjson now "$(date +%s)" '
    [.tasks[]? | select(.status=="in_progress") |
      (try ((.updated_at|fromdateiso8601)) catch 0) as $u |
      select($now - $u > 86400)] | length' "$queue_file" 2>/dev/null || echo 0)
  ok "queue pending+approved=$pending in_progress=$inprog"
  if [[ "${stale_jobs:-0}" != "0" ]]; then warn "stale in_progress jobs=$stale_jobs"; fi
else
  warn "queue.json missing or jq unavailable"
fi

# ssh key presence (no path leak of other secrets)
if [[ -f "${HOME}/.ssh/asdev_vps_ed25519" ]]; then ok "iran_ssh_key present"; else warn "iran_ssh_key missing"; fi

class="READY"
if (( ERRORS > 0 )); then class="NOT_READY"; elif (( WARNINGS > 0 )); then class="DEGRADED_NON_BLOCKING"; fi

echo "========================================"
echo "CLASSIFICATION=$class ERRORS=$ERRORS WARNINGS=$WARNINGS"
echo "========================================"

# write json snapshot if possible
mkdir -p "$(dirname "$OUT_JSON")" 2>/dev/null || true
if [[ -w "$(dirname "$OUT_JSON")" ]] || mkdir -p "$(dirname "$OUT_JSON")" 2>/dev/null; then
  cat >"$OUT_JSON" <<EOF
{
  "checked_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "host_alias": "AUTOMATION_HOST",
  "classification": "$class",
  "errors": $ERRORS,
  "warnings": $WARNINGS,
  "disk_pct": $disk_pct,
  "mem_avail_mb": $mem_avail,
  "load1": "$load1",
  "stale_jobs": ${stale_jobs:-0}
}
EOF
  log "json_out=$OUT_JSON"
fi

[[ "$class" == "NOT_READY" ]] && exit 2
[[ "$class" == "DEGRADED_NON_BLOCKING" ]] && exit 0
exit 0
