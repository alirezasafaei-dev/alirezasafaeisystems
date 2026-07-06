#!/usr/bin/env bash
# ASDEV Agent Command Center — Post agent report to PR #42
# Usage: ./post-agent-report.sh <report_file>
# Requires: gh CLI, ASDEV_COMMAND_REPO, ASDEV_COMMAND_PR
set -euo pipefail

REPO="${ASDEV_COMMAND_REPO:-alirezasafaei-dev/alirezasafaeisystems}"
PR_NUMBER="${ASDEV_COMMAND_PR:-42}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <report_file>"
  echo "Example: $0 /tmp/agent-report.md"
  exit 1
fi

REPORT_FILE="$1"

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

# Post to PR
echo "Posting report to PR #${PR_NUMBER} in ${REPO}..."
URL=$(gh pr comment "$PR_NUMBER" --repo "$REPO" --body-file "$REPORT_FILE" 2>&1)

if [[ $? -eq 0 ]]; then
  echo "✅ Report posted: ${URL}"
else
  echo "❌ Failed to post report"
  echo "Error: ${URL}"
  exit 1
fi
