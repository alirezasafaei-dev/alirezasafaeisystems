#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LATEST_REPORT="${REPO_ROOT}/docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_LATEST.md"
HEARTBEAT_FILE="${REPO_ROOT}/docs/runtime/CODEX_CLI_AUTOCOMPACT_HEARTBEAT.txt"
MAX_AGE_HOURS=36
REPAIR_CRON=false
HEALTHY=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-age-hours)
      if [[ $# -lt 2 ]]; then
        echo "--max-age-hours requires a numeric value" >&2
        exit 1
      fi
      MAX_AGE_HOURS="$2"
      shift 2
      ;;
    --repair-cron)
      REPAIR_CRON=true
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: bash scripts/codex/check-maintenance-health.sh [--max-age-hours N] [--repair-cron]" >&2
      exit 1
      ;;
  esac
done

if [[ ! "$MAX_AGE_HOURS" =~ ^[0-9]+$ ]]; then
  echo "--max-age-hours must be a non-negative integer" >&2
  exit 1
fi

max_age_seconds=$((MAX_AGE_HOURS * 3600))
now_epoch="$(date -u +%s)"

cron_maintain_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-maintain' || true)"
cron_health_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-health' || true)"

if [[ -z "$cron_maintain_entry" || -z "$cron_health_entry" ]]; then
  echo "[health] one or more cron entries are missing"
  HEALTHY=false
  if [[ "$REPAIR_CRON" == "true" ]]; then
    bash "${SCRIPT_DIR}/install-maintenance-cron.sh"
    cron_maintain_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-maintain' || true)"
    cron_health_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-health' || true)"
    if [[ -n "$cron_maintain_entry" && -n "$cron_health_entry" ]]; then
      echo "[health] cron entries repaired"
    else
      echo "[health] cron repair failed"
    fi
  fi
else
  echo "[health] cron entries present"
fi

if [[ -f "$LATEST_REPORT" ]]; then
  report_mtime_epoch="$(stat -c %Y "$LATEST_REPORT")"
  report_age="$((now_epoch - report_mtime_epoch))"
  echo "[health] latest report age seconds=${report_age}"
  if (( report_age > max_age_seconds )); then
    echo "[health] latest report is stale"
    HEALTHY=false
  fi
else
  echo "[health] latest report missing: $LATEST_REPORT"
  HEALTHY=false
fi

if [[ -f "$HEARTBEAT_FILE" ]]; then
  heartbeat_utc="$(awk -F= '/^last_success_utc=/ { print $2; exit }' "$HEARTBEAT_FILE")"
  if [[ -n "$heartbeat_utc" ]]; then
    heartbeat_epoch="$(date -u -d "$heartbeat_utc" +%s)"
    heartbeat_age="$((now_epoch - heartbeat_epoch))"
    echo "[health] heartbeat age seconds=${heartbeat_age}"
    if (( heartbeat_age > max_age_seconds )); then
      echo "[health] heartbeat is stale"
      HEALTHY=false
    fi
  else
    echo "[health] heartbeat file missing last_success_utc"
    HEALTHY=false
  fi
else
  echo "[health] heartbeat file missing: $HEARTBEAT_FILE"
  HEALTHY=false
fi

if [[ "$HEALTHY" == "true" ]]; then
  echo "[health] codex maintenance is healthy"
  exit 0
fi

echo "[health] codex maintenance is not healthy"
exit 1
