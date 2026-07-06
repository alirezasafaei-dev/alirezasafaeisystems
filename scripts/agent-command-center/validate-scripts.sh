#!/usr/bin/env bash
# ASDEV Agent Command Center — Validate all scripts
# Checks syntax, permissions, and basic functionality
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0

echo "ASDEV Script Validation"
echo "======================="
echo ""

# Check syntax
echo "--- Syntax Check ---"
for script in "${SCRIPT_DIR}"/*.sh; do
  if bash -n "$script" 2>/dev/null; then
    echo "✅ $(basename "$script")"
  else
    echo "❌ $(basename "$script") — SYNTAX ERROR"
    ERRORS=$((ERRORS + 1))
  fi
done
echo ""

# Check permissions
echo "--- Permission Check ---"
for script in "${SCRIPT_DIR}"/*.sh; do
  if [[ -x "$script" ]]; then
    echo "✅ $(basename "$script") — executable"
  else
    echo "⚠️ $(basename "$script") — not executable"
    chmod +x "$script"
    echo "  → fixed"
  fi
done
echo ""

# Check secrets
echo "--- Secrets Check ---"
SECRET_COUNT=$(grep -r "sk-\|ghp_\|API_KEY=.*[A-Za-z0-9]\{12,\}" "${SCRIPT_DIR}"/*.sh 2>/dev/null | grep -v "env.example" | grep -v "grep -qiE" | grep -v "grep -niE" | grep -v "SECRET_COUNT" | wc -l | tr -d '[:space:]')
SECRET_COUNT=${SECRET_COUNT:-0}
if [[ "$SECRET_COUNT" -eq 0 ]]; then
  echo "✅ No secrets found"
else
  echo "❌ Found ${SECRET_COUNT} potential secret(s)"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# Summary
echo "======================="
if [[ $ERRORS -eq 0 ]]; then
  echo "✅ All checks passed"
else
  echo "❌ ${ERRORS} error(s) found"
fi

exit $ERRORS
