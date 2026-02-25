#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
REPORT_DIR="${REPO_ROOT}/docs/runtime"
KEEP_DAYS=30

while [[ $# -gt 0 ]]; do
  case "$1" in
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
      echo "Usage: bash scripts/codex/prune-status-reports.sh [--keep-days N]" >&2
      exit 1
      ;;
  esac
done

if [[ ! "$KEEP_DAYS" =~ ^[0-9]+$ ]]; then
  echo "--keep-days must be a non-negative integer" >&2
  exit 1
fi

if [[ ! -d "$REPORT_DIR" ]]; then
  echo "Report directory not found: $REPORT_DIR" >&2
  exit 0
fi

CUTOFF_EPOCH="$(date -u -d "${KEEP_DAYS} days ago" +%s)"
REMOVED=0

for file in "$REPORT_DIR"/CODEX_CLI_AUTOCOMPACT_STATUS_*.md; do
  [[ -e "$file" ]] || break

  basename_file="$(basename "$file")"

  if [[ "$basename_file" == "CODEX_CLI_AUTOCOMPACT_STATUS_LATEST.md" ]]; then
    continue
  fi

  if [[ "$basename_file" =~ ^CODEX_CLI_AUTOCOMPACT_STATUS_([0-9]{4}-[0-9]{2}-[0-9]{2})\.md$ ]]; then
    report_date="${BASH_REMATCH[1]}"
    report_epoch="$(date -u -d "${report_date} 00:00:00" +%s)"

    if (( report_epoch < CUTOFF_EPOCH )); then
      rm -f "$file"
      REMOVED=$((REMOVED + 1))
      echo "Pruned $basename_file"
    fi
  fi
done

echo "Prune complete. keep_days=${KEEP_DAYS}; removed=${REMOVED}."
