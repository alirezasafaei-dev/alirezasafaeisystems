#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PUSH_CHANGES=false
COMMIT_CHANGES=true

for arg in "$@"; do
  case "$arg" in
    --)
      ;;
    --push)
      PUSH_CHANGES=true
      ;;
    --no-commit)
      COMMIT_CHANGES=false
      ;;
    *)
      echo "Unknown argument: ${arg}" >&2
      echo "Usage: bash scripts/codex/maintain-codex-cli.sh [--push] [--no-commit]" >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

bash scripts/codex/bootstrap-codex-cli.sh
bash scripts/codex/report-codex-cli-state.sh

REPORT_DATE_UTC="$(date -u +%F)"
DATED_REPORT="docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_${REPORT_DATE_UTC}.md"
LATEST_REPORT="docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_LATEST.md"

if [[ ! -f "$DATED_REPORT" ]]; then
  echo "Expected report file not found: ${DATED_REPORT}" >&2
  exit 1
fi

if [[ "$COMMIT_CHANGES" == "false" ]]; then
  echo "Maintenance run completed without git commit."
  exit 0
fi

git add -A -- "$DATED_REPORT" "$LATEST_REPORT"

if git diff --cached --quiet; then
  echo "No runtime evidence changes to commit."
  exit 0
fi

COMMIT_MSG="chore(codex): refresh auto-compact runtime status ${REPORT_DATE_UTC}"
git commit -m "$COMMIT_MSG"

if [[ "$PUSH_CHANGES" == "true" ]]; then
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  git push origin "$CURRENT_BRANCH"
fi

echo "Maintenance complete."
