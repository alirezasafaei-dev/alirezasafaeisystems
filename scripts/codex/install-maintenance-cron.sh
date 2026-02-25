#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CRON_SCHEDULE="${1:-17 3 * * *}"
KEEP_DAYS="${2:-30}"
HEALTH_SCHEDULE="${3:-47 3 * * *}"
CRON_TAG_MAIN="# codex-cli-maintain"
CRON_TAG_HEALTH="# codex-cli-health"

mkdir -p "${REPO_ROOT}/artifacts"

if [[ ! "$KEEP_DAYS" =~ ^[0-9]+$ ]]; then
  echo "keep-days must be a non-negative integer" >&2
  exit 1
fi

CRON_JOB_MAIN="${CRON_SCHEDULE} /usr/bin/env bash -lc 'cd \"${REPO_ROOT}\" && bash scripts/codex/maintain-codex-cli.sh --push --keep-days ${KEEP_DAYS} >> artifacts/codex-cli-maintain.log 2>&1' ${CRON_TAG_MAIN}"
CRON_JOB_HEALTH="${HEALTH_SCHEDULE} /usr/bin/env bash -lc 'cd \"${REPO_ROOT}\" && bash scripts/codex/check-maintenance-health.sh --max-age-hours 48 --repair-cron --auto-heal --keep-days ${KEEP_DAYS} >> artifacts/codex-cli-health.log 2>&1' ${CRON_TAG_HEALTH}"
CURRENT_CRONTAB="$(crontab -l 2>/dev/null || true)"
FILTERED_CRONTAB="$(printf '%s\n' "$CURRENT_CRONTAB" | rg -v --fixed-strings "$CRON_TAG_MAIN" | rg -v --fixed-strings "$CRON_TAG_HEALTH" || true)"

if [[ -n "$FILTERED_CRONTAB" ]]; then
  {
    printf '%s\n' "$FILTERED_CRONTAB"
    printf '%s\n' "$CRON_JOB_MAIN"
    printf '%s\n' "$CRON_JOB_HEALTH"
  } | crontab -
else
  {
    printf '%s\n' "$CRON_JOB_MAIN"
    printf '%s\n' "$CRON_JOB_HEALTH"
  } | crontab -
fi

echo "Installed cron entries:"
echo "$CRON_JOB_MAIN"
echo "$CRON_JOB_HEALTH"
