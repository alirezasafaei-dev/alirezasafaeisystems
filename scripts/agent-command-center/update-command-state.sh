#!/usr/bin/env bash
# ASDEV Agent Command Center — Update command state
# Updates STATE.json after handling a prompt/report pair
# Usage: ./update-command-state.sh <prompt_id> <report_id> [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="${ASDEV_COMMAND_STATE:-$(dirname "$0")/../../docs/agent-command-center/STATE.json}"
DRY_RUN=false

[[ "${3:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <prompt_id> <report_id> [--dry-run]"
  exit 1
fi

PROMPT_ID="$1"
REPORT_ID="$2"

echo "ASDEV Update Command State"
echo "Prompt: ${PROMPT_ID} | Report: ${REPORT_ID}"
echo ""

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if $DRY_RUN; then
  echo "[DRY-RUN] Would update STATE.json:"
  echo "  lastCheckedAt: ${NOW}"
  echo "  lastHandledPromptCommentId: ${PROMPT_ID}"
  echo "  lastReportCommentId: ${REPORT_ID}"
  exit 0
fi

# Update state file
mkdir -p "$(dirname "$STATE_FILE")"
jq -n \
  --arg prompt "$PROMPT_ID" \
  --arg report "$REPORT_ID" \
  --arg checked "$NOW" \
  '{lastCheckedAt: $checked, lastHandledPromptCommentId: $prompt, lastReportCommentId: $report}' \
  > "$STATE_FILE"

echo "✅ STATE.json updated"
cat "${STATE_FILE}"
