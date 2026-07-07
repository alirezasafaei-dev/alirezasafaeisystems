#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${CYAN}[SAFETY]${NC} $*"; }
pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[BLOCK]${NC} $*"; }

REPO="${1:-}"
MODE="${2:-}"
FILES="${3:-}"

VIOLATIONS=0

if [ -z "$REPO" ] || [ -z "$MODE" ]; then
  fail "Usage: agent-safety-gate.sh <repo> <mode> [files]"
  exit 1
fi

check_persiantoolbox() {
  if echo "$REPO" | grep -qi "persiantoolbox"; then
    if [ "$MODE" != "read-only" ]; then
      fail "PersianToolbox only allows read-only mode"
      VIOLATIONS=$((VIOLATIONS + 1))
    else
      pass "PersianToolbox read-only mode OK"
    fi
  fi
}

check_forbidden_patterns() {
  if [ -n "$FILES" ]; then
    for f in $FILES; do
      if echo "$f" | grep -qE "\.env$|credentials|secret"; then
        fail "Forbidden file: $f"
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    done
  fi
}

check_deploy_safety() {
  if [ "$MODE" = "deploy" ]; then
    fail "Auto-deploy is forbidden. Requires owner approval."
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}

check_billing_safety() {
  if [ "$MODE" = "billing" ]; then
    fail "Billing/payment changes require owner approval."
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}

check_frozen_projects() {
  if [ -n "$FILES" ]; then
    for f in $FILES; do
      if echo "$f" | grep -qE "devatlas|creatormembership|microcatalog|rubika-bot|novax|halo"; then
        fail "Frozen project file: $f"
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    done
  fi
}

check_persiantoolbox
check_forbidden_patterns
check_deploy_safety
check_billing_safety
check_frozen_projects

if [ "$VIOLATIONS" -gt 0 ]; then
  fail "Safety gate FAILED with ${VIOLATIONS} violations"
  exit 1
else
  pass "Safety gate PASSED"
  exit 0
fi
