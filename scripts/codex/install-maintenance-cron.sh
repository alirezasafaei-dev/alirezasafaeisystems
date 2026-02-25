#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CRON_SCHEDULE="${1:-17 3 * * *}"
CRON_TAG="# codex-cli-maintain"

mkdir -p "${REPO_ROOT}/artifacts"

CRON_JOB="${CRON_SCHEDULE} /usr/bin/env bash -lc 'cd \"${REPO_ROOT}\" && bash scripts/codex/maintain-codex-cli.sh --push >> artifacts/codex-cli-maintain.log 2>&1' ${CRON_TAG}"
CURRENT_CRONTAB="$(crontab -l 2>/dev/null || true)"
FILTERED_CRONTAB="$(printf '%s\n' "$CURRENT_CRONTAB" | rg -v --fixed-strings "$CRON_TAG" || true)"

if [[ -n "$FILTERED_CRONTAB" ]]; then
  {
    printf '%s\n' "$FILTERED_CRONTAB"
    printf '%s\n' "$CRON_JOB"
  } | crontab -
else
  printf '%s\n' "$CRON_JOB" | crontab -
fi

echo "Installed cron entry:"
echo "$CRON_JOB"
