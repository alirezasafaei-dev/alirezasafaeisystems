#!/usr/bin/env bash
# ASDEV Agent Command Center — Post agent report to PR or Issue
# Requires: gh CLI, ASDEV_COMMAND_REPO
set -euo pipefail

REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-42}"
ISSUE_NUMBER=""

while [[ $# -gt 1 ]]; do
  case $1 in
    --issue) ISSUE_NUMBER="$2"; shift 2 ;;
    *) break ;;
  esac
done

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [--issue N] <report_file>"
  echo "Example: $0 /tmp/agent-report.md"
  echo "         $0 --issue 45 /tmp/agent-report.md"
  exit 1
fi

REPORT_FILE="$1"

TARGET_TYPE="pr"
TARGET_NUMBER="$PR_NUMBER"
if [[ -n "$ISSUE_NUMBER" ]]; then
  TARGET_TYPE="issue"
  TARGET_NUMBER="$ISSUE_NUMBER"
fi

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "❌ Report file not found: ${REPORT_FILE}"
  exit 1
fi

# Validate report has required heading
if ! head -5 "$REPORT_FILE" | grep -q "# Agent Execution Report"; then
  echo "❌ Report missing required heading: # Agent Execution Report"
  echo "First 5 lines:"
  head -5 "$REPORT_FILE"
  exit 1
fi

# Check for secrets (basic grep)
if grep -qiE "(password|secret|api_key|token|sk-)" "$REPORT_FILE"; then
  echo "⚠️ Warning: Report may contain sensitive data. Review before posting."
  echo "Matches:"
  grep -niE "(password|secret|api_key|token|sk-)" "$REPORT_FILE" || true
  echo ""
  read -p "Post anyway? (y/N): " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Post to PR or Issue
echo "Posting report to ${TARGET_TYPE} #${TARGET_NUMBER} in ${REPO}..."
if [[ "$TARGET_TYPE" == "issue" ]]; then
  URL=$(gh issue comment "$TARGET_NUMBER" --repo "$REPO" --body-file "$REPORT_FILE" 2>&1)
else
  URL=$(gh pr comment "$TARGET_NUMBER" --repo "$REPO" --body-file "$REPORT_FILE" 2>&1)
fi

if [[ $? -eq 0 ]]; then
  echo "✅ Report posted: ${URL}"
else
  echo "❌ Failed to post report"
  echo "Error: ${URL}"
  exit 1
fi
