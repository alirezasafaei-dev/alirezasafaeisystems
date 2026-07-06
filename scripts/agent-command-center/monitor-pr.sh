#!/usr/bin/env bash
# ASDEV Agent Command Center — PR #42 monitor
# Detects unhandled agent prompts vs execution reports.
set -euo pipefail

REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-42}"
STATE_FILE="${ASDEV_COMMAND_STATE:-$(dirname "$0")/../../docs/agent-command-center/STATE.json}"

fetch_comments() {
  gh api "repos/${REPO}/issues/${PR_NUMBER}/comments?per_page=100" \
    --jq 'sort_by(.created_at) | .[] | {id, created_at, first_line: (.body | split("\n")[0])}'
}

latest_prompt_id() {
  fetch_comments | jq -s 'map(select(.first_line | startswith("# Next Agent Prompt"))) | last | .id // empty'
}

latest_report_id() {
  fetch_comments | jq -s 'map(select(.first_line | startswith("# Agent Execution Report"))) | last | .id // empty'
}

latest_prompt_created() {
  fetch_comments | jq -s 'map(select(.first_line | startswith("# Next Agent Prompt"))) | last | .created_at // empty'
}

latest_report_created() {
  fetch_comments | jq -s 'map(select(.first_line | startswith("# Agent Execution Report"))) | last | .created_at // empty'
}

last_handled_prompt() {
  if [[ -f "$STATE_FILE" ]]; then
    jq -r '.lastHandledPromptCommentId // empty' "$STATE_FILE" 2>/dev/null || true
  fi
}

mark_handled() {
  local prompt_id="$1"
  local report_id="$2"
  mkdir -p "$(dirname "$STATE_FILE")"
  local now
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  jq -n \
    --arg prompt "$prompt_id" \
    --arg report "$report_id" \
    --arg checked "$now" \
    '{lastCheckedAt: $checked, lastHandledPromptCommentId: $prompt, lastReportCommentId: $report}' \
    > "$STATE_FILE"
}

main() {
  echo "ASDEV Agent Command Center Monitor"
  echo "Repo: ${REPO} | PR: #${PR_NUMBER}"
  echo "Checked at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""

  local prompt_id report_id prompt_at report_at handled
  prompt_id="$(latest_prompt_id)"
  report_id="$(latest_report_id)"
  prompt_at="$(latest_prompt_created)"
  report_at="$(latest_report_created)"
  handled="$(last_handled_prompt)"

  echo "Latest prompt comment: ${prompt_id:-none} (${prompt_at:-n/a})"
  echo "Latest report comment: ${report_id:-none} (${report_at:-n/a})"
  echo "Last handled prompt id: ${handled:-none}"
  echo ""

  if [[ -z "$prompt_id" ]]; then
    echo "STATUS: NO_PROMPT"
    echo "Action: Owner should post a comment starting with '# Next Agent Prompt — ...'"
    exit 0
  fi

  if [[ -z "$report_id" ]] || [[ "$report_at" < "$prompt_at" ]]; then
    echo "STATUS: PROMPT_PENDING"
    echo "Action: Agent must execute latest prompt and post '# Agent Execution Report — ...'"
    exit 2
  fi

  if [[ "$prompt_id" != "$handled" ]]; then
    echo "STATUS: PROMPT_HANDLED_NEW"
    echo "Action: Prompt has a report; update STATE and wait for next prompt."
    mark_handled "$prompt_id" "$report_id"
    exit 0
  fi

  echo "STATUS: IDLE_WAITING"
  echo "Action: No new prompt since last handled report. Monitor again later."
  exit 0
}

main "$@"