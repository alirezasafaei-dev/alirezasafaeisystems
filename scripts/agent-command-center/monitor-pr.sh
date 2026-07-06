#!/usr/bin/env bash
# ASDEV Agent Command Center — PR #42 monitor
# Detects unhandled agent prompts vs execution reports.
set -euo pipefail

REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-42}"
STATE_FILE="${ASDEV_COMMAND_STATE:-$(dirname "$0")/../../docs/agent-command-center/STATE.json}"

# Actionable prompts: agent must execute and report back.
PROMPT_PATTERNS=(
  '^# Next Agent Prompt'
  '^Protected review requested\.'
)

# Informational guards: must be respected; logged but not sole trigger.
GUARD_PATTERNS=(
  '^# Critical Guard'
  '^# Monitoring Continues'
)

fetch_comments() {
  gh api "repos/${REPO}/issues/${PR_NUMBER}/comments?per_page=100" \
    --jq 'sort_by(.created_at) | .[] | {id, created_at, body, first_line: (.body | split("\n")[0])}'
}

is_actionable_prompt() {
  local first_line="$1"
  local pattern
  for pattern in "${PROMPT_PATTERNS[@]}"; do
    if [[ "$first_line" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

latest_actionable_prompt() {
  fetch_comments | jq -s --argjson patterns "$(printf '%s\n' "${PROMPT_PATTERNS[@]}" | jq -R . | jq -s .)" '
    map(select(.first_line as $f | any($patterns[]; . as $p | ($f | test($p)))))
    | last // empty
  '
}

latest_report() {
  fetch_comments | jq -s '
    map(select(.first_line | startswith("# Agent Execution Report")))
    | last // empty
  '
}

latest_guards() {
  fetch_comments | jq -s --argjson patterns "$(printf '%s\n' "${GUARD_PATTERNS[@]}" | jq -R . | jq -s .)" '
    map(select(.first_line as $f | any($patterns[]; . as $p | ($f | test($p)))))
  '
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
  echo "Actionable prompt patterns:"
  printf '  - %s\n' "${PROMPT_PATTERNS[@]}"
  echo ""

  local prompt_json report_json prompt_id report_id prompt_at report_at handled
  prompt_json="$(latest_actionable_prompt)"
  report_json="$(latest_report)"

  prompt_id="$(echo "$prompt_json" | jq -r '.id // empty')"
  report_id="$(echo "$report_json" | jq -r '.id // empty')"
  prompt_at="$(echo "$prompt_json" | jq -r '.created_at // empty')"
  report_at="$(echo "$report_json" | jq -r '.created_at // empty')"
  handled="$(last_handled_prompt)"

  echo "Latest actionable prompt: ${prompt_id:-none} (${prompt_at:-n/a})"
  if [[ -n "$prompt_id" ]]; then
    echo "  title: $(echo "$prompt_json" | jq -r '.first_line')"
  fi
  echo "Latest report comment: ${report_id:-none} (${report_at:-n/a})"
  echo "Last handled prompt id: ${handled:-none}"
  echo ""

  local guard_count
  guard_count="$(latest_guards | jq 'length')"
  if [[ "$guard_count" -gt 0 ]]; then
    echo "Active guards (${guard_count}):"
    latest_guards | jq -r '.[] | "  [\(.id)] \(.first_line)"'
    echo ""
  fi

  if [[ -z "$prompt_id" ]]; then
    echo "STATUS: NO_PROMPT"
    echo "Action: Post '# Next Agent Prompt — ...' or 'Protected review requested.'"
    exit 0
  fi

  if [[ -z "$report_id" ]] || [[ "$report_at" < "$prompt_at" ]]; then
    echo "STATUS: PROMPT_PENDING"
    echo "PROMPT_COMMENT_ID: ${prompt_id}"
    echo "Action: Execute latest actionable prompt and post '# Agent Execution Report — ...'"
    exit 2
  fi

  if [[ "$prompt_id" != "$handled" ]]; then
    echo "STATUS: PROMPT_HANDLED_NEW"
    mark_handled "$prompt_id" "$report_id"
    exit 0
  fi

  echo "STATUS: IDLE_WAITING"
  echo "Action: No new actionable prompt since last handled report."
  exit 0
}

main "$@"