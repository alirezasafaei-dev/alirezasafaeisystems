#!/usr/bin/env bash
# ASDEV Agent Command Center — Command thread monitor
# Supports both PR and Issue threads
# Usage: ./monitor-command-thread.sh [--issue N] [--pr N] [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-}"
ISSUE_NUMBER="${ASDEV_COMMAND_ISSUE:-}"
STATE_FILE="${ASDEV_COMMAND_STATE:-$(dirname "$0")/../../docs/agent-command-center/STATE.json}"
DRY_RUN=false

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --issue) ISSUE_NUMBER="$2"; shift 2 ;;
    --pr) PR_NUMBER="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Default to Issue #45 if nothing specified
if [[ -z "$PR_NUMBER" && -z "$ISSUE_NUMBER" ]]; then
  ISSUE_NUMBER="${ASDEV_COMMAND_ISSUE:-45}"
fi

# Determine thread type
if [[ -n "$ISSUE_NUMBER" ]]; then
  THREAD_TYPE="issue"
  THREAD_NUMBER="$ISSUE_NUMBER"
  API_PATH="repos/${REPO}/issues/${THREAD_NUMBER}/comments"
else
  THREAD_TYPE="pr"
  THREAD_NUMBER="$PR_NUMBER"
  API_PATH="repos/${REPO}/issues/${THREAD_NUMBER}/comments"
fi

# Actionable prompt patterns
PROMPT_PATTERNS=(
  '^# Next Agent Prompt'
  '^Protected review requested\.'
  '^Hermes-first check requested\.'
  '^# Decision —'
)

# Blocked patterns
BLOCKED_PROMPT_PATTERNS=(
  '^# Next Agent Prompt — Awaiting Owner Approval'
)

# Guard patterns
GUARD_PATTERNS=(
  '^# Critical Guard'
  '^# Monitoring Continues'
)

NEXT_PROMPT_FILE="${ASDEV_NEXT_PROMPT_FILE:-$(dirname "$0")/../../docs/agent-command-center/NEXT_AGENT_PROMPT.md}"

fetch_comments() {
  gh api "${API_PATH}?per_page=100" \
    --jq 'sort_by(.created_at) | .[] | {id, created_at, body, first_line: (.body | split("\n")[0])}'
}

is_blocked_prompt() {
  local first_line="$1"
  for pattern in "${BLOCKED_PROMPT_PATTERNS[@]}"; do
    if [[ "$first_line" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

command_center_has_no_active_prompt() {
  [[ -f "$NEXT_PROMPT_FILE" ]] && grep -q "No active implementation prompt" "$NEXT_PROMPT_FILE"
}

is_actionable_prompt() {
  local first_line="$1"
  if is_blocked_prompt "$first_line"; then
    return 1
  fi
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
    --arg thread "${THREAD_TYPE}:${THREAD_NUMBER}" \
    '{lastCheckedAt: $checked, lastHandledPromptCommentId: $prompt, lastReportCommentId: $report, activeThread: $thread}' \
    > "$STATE_FILE"
}

main() {
  echo "ASDEV Agent Command Center Monitor"
  echo "Thread: ${THREAD_TYPE} #${THREAD_NUMBER} | Repo: ${REPO}"
  echo "Checked at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""

  if $DRY_RUN; then
    echo "[DRY-RUN] Would fetch comments from ${API_PATH}"
    echo ""
    echo "STATUS: SIMULATED_DRY_RUN"
    echo "PROMPT_COMMENT_ID: 9999999999"
    echo "Action: Dry-run — no real API calls made."
    exit 0
  fi

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
    if command_center_has_no_active_prompt; then
      echo "STATUS: BLOCKED_AWAITING_APPROVAL"
      echo "Action: Owner must approve and publish a new prompt."
      exit 0
    fi
    echo "STATUS: NO_PROMPT"
    echo "Action: Post an actionable prompt on ${THREAD_TYPE} #${THREAD_NUMBER}."
    exit 0
  fi

  if command_center_has_no_active_prompt && [[ "$(echo "$prompt_json" | jq -r '.first_line')" =~ ^#\ Next\ Agent\ Prompt ]]; then
    echo "STATUS: BLOCKED_AWAITING_APPROVAL"
    echo "Note: NEXT_AGENT_PROMPT.md has no active prompt."
    exit 0
  fi

  if [[ -z "$report_id" ]] || [[ "$report_at" < "$prompt_at" ]]; then
    echo "STATUS: PROMPT_PENDING"
    echo "PROMPT_COMMENT_ID: ${prompt_id}"
    echo "Action: Execute latest actionable prompt and post report."
    exit 2
  fi

  if [[ "$prompt_id" != "$handled" ]]; then
    echo "STATUS: PROMPT_HANDLED_NEW"
    if ! $DRY_RUN; then
      mark_handled "$prompt_id" "$report_id"
    fi
    exit 0
  fi

  echo "STATUS: IDLE_WAITING"
  echo "Action: No new actionable prompt since last handled report."
  exit 0
}

main "$@"
