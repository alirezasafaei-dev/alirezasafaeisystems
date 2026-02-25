#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCK_FILE="${TMPDIR:-/tmp}/codex-cli-maintain.lock"

PUSH_CHANGES=false
COMMIT_CHANGES=true
KEEP_DAYS="${CODEX_CLI_KEEP_DAYS:-30}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      ;;
    --push)
      PUSH_CHANGES=true
      shift
      ;;
    --no-commit)
      COMMIT_CHANGES=false
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
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: bash scripts/codex/maintain-codex-cli.sh [--push] [--no-commit] [--keep-days N]" >&2
      exit 1
      ;;
  esac
done

if [[ ! "$KEEP_DAYS" =~ ^[0-9]+$ ]]; then
  echo "--keep-days must be a non-negative integer" >&2
  exit 1
fi

if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    echo "Another codex maintenance run is already in progress. Exiting."
    exit 0
  fi
fi

cd "$REPO_ROOT"

bash scripts/codex/bootstrap-codex-cli.sh
bash scripts/codex/prune-status-reports.sh --keep-days "$KEEP_DAYS"

REPORT_DATE_UTC="$(date -u +%F)"
DATED_REPORT="docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_${REPORT_DATE_UTC}.md"
HEARTBEAT_FILE="docs/runtime/CODEX_CLI_AUTOCOMPACT_HEARTBEAT.txt"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
CURRENT_HEAD="$(git rev-parse --short HEAD)"
LAST_SUCCESS_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

cat > "$HEARTBEAT_FILE" <<EOF
last_success_utc=${LAST_SUCCESS_UTC}
branch=${CURRENT_BRANCH}
head=${CURRENT_HEAD}
keep_days=${KEEP_DAYS}
EOF

bash scripts/codex/report-codex-cli-state.sh

if [[ ! -f "$DATED_REPORT" ]]; then
  echo "Expected report file not found: ${DATED_REPORT}" >&2
  exit 1
fi

if [[ "$COMMIT_CHANGES" == "false" ]]; then
  echo "Maintenance run completed without git commit."
  exit 0
fi

git add -A -- ':(glob)docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_*.md' "$HEARTBEAT_FILE"

if git diff --cached --quiet; then
  echo "No runtime evidence changes to commit."
  exit 0
fi

COMMIT_MSG="chore(codex): refresh auto-compact runtime status ${REPORT_DATE_UTC}"
git commit -m "$COMMIT_MSG"

if [[ "$PUSH_CHANGES" == "true" ]]; then
  git push origin "$CURRENT_BRANCH"
fi

echo "Maintenance complete."
