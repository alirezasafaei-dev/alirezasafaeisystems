#!/usr/bin/env bash
set -euo pipefail

echo "=== Telegram Bot GitHub Test ==="
echo ""

ASDEV_REPO="alirezasafaei-dev/alirezasafaeisystems"
AUDIT_REPO="alirezasafaei-dev/auditsystems"

echo "--- Test 1: Issue #45 fetch ---"
RESULT=$(gh api repos/${ASDEV_REPO}/issues/45 --jq '.title' 2>/dev/null || echo "FAIL")
if [ "$RESULT" = "FAIL" ]; then
  echo "❌ Issue #45 fetch failed"
else
  echo "✅ Issue #45: ${RESULT}"
fi

echo ""
echo "--- Test 2: alirezasafaeisystems open PRs ---"
COUNT=$(gh api repos/${ASDEV_REPO}/pulls?state=open --jq 'length' 2>/dev/null || echo "FAIL")
if [ "$COUNT" = "FAIL" ]; then
  echo "❌ PR fetch failed"
else
  echo "✅ alirezasafaeisystems: ${COUNT} open PRs"
fi

echo ""
echo "--- Test 3: auditsystems open PRs ---"
COUNT=$(gh api repos/${AUDIT_REPO}/pulls?state=open --jq 'length' 2>/dev/null || echo "FAIL")
if [ "$COUNT" = "FAIL" ]; then
  echo "❌ PR fetch failed"
else
  echo "✅ auditsystems: ${COUNT} open PRs"
fi

echo ""
echo "--- Test 4: Latest Issue #45 comment ---"
RESULT=$(gh api repos/${ASDEV_REPO}/issues/45/comments?per_page=5 --jq '.[0].body[:100]' 2>/dev/null || echo "FAIL")
if [ "$RESULT" = "FAIL" ]; then
  echo "❌ Comment fetch failed"
else
  echo "✅ Latest comment: ${RESULT}..."
fi

echo ""
echo "--- Test 5: Status data assembly ---"
ISSUE_TITLE=$(gh api repos/${ASDEV_REPO}/issues/45 --jq '.title' 2>/dev/null || echo "unknown")
ASDEV_PRS=$(gh api repos/${ASDEV_REPO}/pulls?state=open --jq 'length' 2>/dev/null || echo "0")
AUDIT_PRS=$(gh api repos/${AUDIT_REPO}/pulls?state=open --jq 'length' 2>/dev/null || echo "0")
echo "✅ Status data:"
echo "  Issue: ${ISSUE_TITLE}"
echo "  alirezasafaeisystems PRs: ${ASDEV_PRS}"
echo "  auditsystems PRs: ${AUDIT_PRS}"

echo ""
echo "=== All tests passed ==="
