#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LATEST_REPORT="${REPO_ROOT}/docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_LATEST.md"
HEARTBEAT_FILE="${REPO_ROOT}/docs/runtime/CODEX_CLI_AUTOCOMPACT_HEARTBEAT.txt"

MAX_AGE_HOURS=36
REPAIR_CRON=false
AUTO_HEAL=false
PUSH_ON_HEAL=true
KEEP_DAYS=30
HEALTHY=true

usage() {
  echo "Usage: bash scripts/codex/check-maintenance-health.sh [--max-age-hours N] [--repair-cron] [--auto-heal] [--keep-days N] [--no-push-on-heal]"
}

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
    --auto-heal)
      AUTO_HEAL=true
      shift
      ;;
    --keep-days)
      if [[ $# -lt 2 ]]; then
        echo "--keep-days requires a numeric value" >&2
        exit 1
      fi
      KEEP_DAYS="$2"
      shift 2
      ;;
    --no-push-on-heal)
      PUSH_ON_HEAL=false
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! "$MAX_AGE_HOURS" =~ ^[0-9]+$ ]]; then
  echo "--max-age-hours must be a non-negative integer" >&2
  exit 1
fi

if [[ ! "$KEEP_DAYS" =~ ^[0-9]+$ ]]; then
  echo "--keep-days must be a non-negative integer" >&2
  exit 1
fi

evaluate_health() {
  local healthy=true
  local now_epoch
  local max_age_seconds
  local cron_maintain_entry
  local cron_health_entry
  local cron_ok=true

  now_epoch="$(date -u +%s)"
  max_age_seconds=$((MAX_AGE_HOURS * 3600))

  cron_maintain_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-maintain' || true)"
  cron_health_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-health' || true)"

  if [[ -z "$cron_maintain_entry" || -z "$cron_health_entry" ]]; then
    echo "[health] one or more cron entries are missing"
    cron_ok=false

    if [[ "$REPAIR_CRON" == "true" ]]; then
      if bash "${SCRIPT_DIR}/install-maintenance-cron.sh" "17 3 * * *" "$KEEP_DAYS" "47 3 * * *"; then
        cron_maintain_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-maintain' || true)"
        cron_health_entry="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-health' || true)"
        if [[ -n "$cron_maintain_entry" && -n "$cron_health_entry" ]]; then
          cron_ok=true
          echo "[health] cron entries repaired"
        else
          echo "[health] cron repair failed"
        fi
      else
        echo "[health] cron repair command failed"
      fi
    fi
  else
    echo "[health] cron entries present"
  fi

  if [[ "$cron_ok" != "true" ]]; then
    healthy=false
  fi

  if [[ -f "$LATEST_REPORT" ]]; then
    local report_mtime_epoch
    local report_age
    report_mtime_epoch="$(stat -c %Y "$LATEST_REPORT")"
    report_age="$((now_epoch - report_mtime_epoch))"
    echo "[health] latest report age seconds=${report_age}"
    if (( report_age > max_age_seconds )); then
      echo "[health] latest report is stale"
      healthy=false
    fi
  else
    echo "[health] latest report missing: $LATEST_REPORT"
    healthy=false
  fi

  if [[ -f "$HEARTBEAT_FILE" ]]; then
    local heartbeat_utc
    heartbeat_utc="$(awk -F= '/^last_success_utc=/ { print $2; exit }' "$HEARTBEAT_FILE")"

    if [[ -n "$heartbeat_utc" ]]; then
      local heartbeat_epoch
      local heartbeat_age
      if heartbeat_epoch="$(date -u -d "$heartbeat_utc" +%s 2>/dev/null)"; then
        heartbeat_age="$((now_epoch - heartbeat_epoch))"
        echo "[health] heartbeat age seconds=${heartbeat_age}"
        if (( heartbeat_age > max_age_seconds )); then
          echo "[health] heartbeat is stale"
          healthy=false
        fi
      else
        echo "[health] heartbeat timestamp parse failed: $heartbeat_utc"
        healthy=false
      fi
    else
      echo "[health] heartbeat file missing last_success_utc"
      healthy=false
    fi
  else
    echo "[health] heartbeat file missing: $HEARTBEAT_FILE"
    healthy=false
  fi

  HEALTHY="$healthy"
}

evaluate_health

if [[ "$HEALTHY" != "true" && "$AUTO_HEAL" == "true" ]]; then
  echo "[health] triggering self-heal maintenance run"
  heal_args=(--keep-days "$KEEP_DAYS")
  if [[ "$PUSH_ON_HEAL" == "true" ]]; then
    heal_args=(--push "${heal_args[@]}")
  fi

  if bash "${SCRIPT_DIR}/maintain-codex-cli.sh" "${heal_args[@]}"; then
    echo "[health] self-heal maintenance completed"
  else
    echo "[health] self-heal maintenance failed"
  fi

  evaluate_health
fi

if [[ "$HEALTHY" == "true" ]]; then
  echo "[health] codex maintenance is healthy"
  exit 0
fi

echo "[health] codex maintenance is not healthy"
exit 1
