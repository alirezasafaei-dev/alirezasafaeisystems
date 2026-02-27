#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT_DIR="${ENTERPRISE_REPORT_DIR:-artifacts}"
REPORT_FILE="${REPORT_DIR}/enterprise-gate-${TIMESTAMP}.md"
mkdir -p "$REPORT_DIR"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

run_gate() {
  local name="$1"
  local cmd="$2"
  echo ""
  echo "[gate] $name"
  if bash -lc "$cmd"; then
    echo "[pass] $name"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "[fail] $name"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

run_optional_gate() {
  local name="$1"
  local cmd="$2"
  local when="$3"
  echo ""
  echo "[gate] $name"
  if [[ "$when" != "1" ]]; then
    echo "[skip] $name"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    return
  fi

  if bash -lc "$cmd"; then
    echo "[pass] $name"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "[fail] $name"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo "=========================================="
echo "Enterprise Gate"
echo "=========================================="

echo "timestamp=$TIMESTAMP"
echo "branch=$(git rev-parse --abbrev-ref HEAD)"
echo "commit=$(git rev-parse --short HEAD)"

run_gate "quality:verify" "pnpm -s run verify"
run_gate "security:audit-high" "pnpm -s run audit:high"
run_gate "security:scan-secrets" "pnpm -s run scan:secrets"
run_gate "governance:ownership" "bash scripts/release/validate-ownership.sh"

SLO_ENABLED=0
if [[ -n "${SITE_URL:-}" ]]; then
  SLO_ENABLED=1
fi
run_optional_gate "reliability:slo" "bash scripts/check-slo.sh" "$SLO_ENABLED"

cat > "$REPORT_FILE" <<REPORT
# Enterprise Gate Report

- Timestamp (UTC): $TIMESTAMP
- Branch: $(git rev-parse --abbrev-ref HEAD)
- Commit: $(git rev-parse --short HEAD)
- SITE_URL: ${SITE_URL:-not-set}

## Gate Summary
- Pass: $PASS_COUNT
- Fail: $FAIL_COUNT
- Skip: $SKIP_COUNT

## Decision
$(if [[ "$FAIL_COUNT" -eq 0 ]]; then
  echo "- Suggested decision: **GO (local gates passed)**"
else
  echo "- Suggested decision: **NO-GO (fix failed gates)**"
fi)
REPORT

echo ""
echo "report=$REPORT_FILE"
echo "pass=$PASS_COUNT fail=$FAIL_COUNT skip=$SKIP_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
