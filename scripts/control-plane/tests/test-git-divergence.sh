#!/usr/bin/env bash
# Git divergence policy test fixtures — validates classification logic
# for local vs remote divergence scenarios.
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR=$(mktemp -d)
PASS=0
FAIL=0
RESULTS=()

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

log() { echo "[TEST] $*"; }
pass_test() { PASS=$((PASS+1)); RESULTS+=("PASS: $1"); }
fail_test() { FAIL=$((FAIL+1)); RESULTS+=("FAIL: $1"); log "FAIL: $1"; }

# ---------------------------------------------------------------------------
# Classification function (mirrors sync-github-local-server.sh)
# ---------------------------------------------------------------------------
classify_file() {
  local file="$1"
  case "$file" in
    docs/reports/*|reports/*|docs/memory/*|docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md|control-plane/queue/queue.json)
      echo "generated" ;;
    ops/automation-logs/*.summary.md)
      echo "generated" ;;
    .env|.env.*|*.pem|*id_rsa*|*token*|*secret*|*.sqlite|*.db|*.dump|*.trace.zip|*.har)
      echo "secret" ;;
    *)
      echo "code" ;;
  esac
}

classify_divergence() {
  local files="$1"
  local has_code=false has_generated=false has_secret=false
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    local cls
    cls=$(classify_file "$file")
    case "$cls" in
      code) has_code=true ;;
      generated) has_generated=true ;;
      secret) has_secret=true ;;
    esac
  done <<< "$files"

  if [ "$has_secret" = true ]; then
    echo "SECRET_DIVERGENCE"
  elif [ "$has_code" = true ]; then
    echo "CODE_DIVERGENCE"
  elif [ "$has_generated" = true ]; then
    echo "GENERATED_DIVERGENCE"
  else
    echo "NO_DIVERGENCE"
  fi
}

# ---------------------------------------------------------------------------
# Test 1: Generated-only files classify as GENERATED
# ---------------------------------------------------------------------------
log "Test 1: Generated-only files"
R=$(classify_file "docs/reports/automation-server/latest.md")
[ "$R" = "generated" ] && pass_test "docs/reports/ = generated" || fail_test "docs/reports/ = $R"

R=$(classify_file "docs/memory/ASDEV_CURRENT_STATE.md")
[ "$R" = "generated" ] && pass_test "docs/memory/ = generated" || fail_test "docs/memory/ = $R"

R=$(classify_file "control-plane/queue/queue.json")
[ "$R" = "generated" ] && pass_test "queue.json = generated" || fail_test "queue.json = $R"

R=$(classify_file "ops/automation-logs/sync.summary.md")
[ "$R" = "generated" ] && pass_test "*.summary.md = generated" || fail_test "*.summary.md = $R"

# ---------------------------------------------------------------------------
# Test 2: Code-bearing files classify as CODE
# ---------------------------------------------------------------------------
log "Test 2: Code-bearing files"
R=$(classify_file "scripts/control-plane/asdev-supervisor.sh")
[ "$R" = "code" ] && pass_test "scripts/ = code" || fail_test "scripts/ = $R"

R=$(classify_file "src/app/page.tsx")
[ "$R" = "code" ] && pass_test "src/ = code" || fail_test "src/ = $R"

R=$(classify_file "docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md")
[ "$R" = "code" ] && pass_test "docs/governance/ = code" || fail_test "docs/governance/ = $R"

R=$(classify_file "prisma/schema.prisma")
[ "$R" = "code" ] && pass_test "prisma/ = code" || fail_test "prisma/ = $R"

# ---------------------------------------------------------------------------
# Test 3: Secret-like files classify as SECRET
# ---------------------------------------------------------------------------
log "Test 3: Secret files"
R=$(classify_file ".env")
[ "$R" = "secret" ] && pass_test ".env = secret" || fail_test ".env = $R"

R=$(classify_file ".env.production")
[ "$R" = "secret" ] && pass_test ".env.production = secret" || fail_test ".env.production = $R"

R=$(classify_file "id_rsa")
[ "$R" = "secret" ] && pass_test "id_rsa = secret" || fail_test "id_rsa = $R"

# ---------------------------------------------------------------------------
# Test 4: Generated-only divergence
# ---------------------------------------------------------------------------
log "Test 4: Generated-only divergence"
FILES="docs/reports/automation-server/latest.md
control-plane/queue/queue.json"
R=$(classify_divergence "$FILES")
[ "$R" = "GENERATED_DIVERGENCE" ] && pass_test "Generated-only divergence correctly classified" || fail_test "Generated-only: $R"

# ---------------------------------------------------------------------------
# Test 5: Code-bearing divergence
# ---------------------------------------------------------------------------
log "Test 5: Code-bearing divergence"
FILES="docs/reports/automation-server/latest.md
scripts/control-plane/asdev-supervisor.sh"
R=$(classify_divergence "$FILES")
[ "$R" = "CODE_DIVERGENCE" ] && pass_test "Code-bearing divergence correctly classified" || fail_test "Code-bearing: $R"

# ---------------------------------------------------------------------------
# Test 6: Secret divergence
# ---------------------------------------------------------------------------
log "Test 6: Secret divergence"
FILES=".env
docs/reports/automation-server/latest.md"
R=$(classify_divergence "$FILES")
[ "$R" = "SECRET_DIVERGENCE" ] && pass_test "Secret divergence correctly classified" || fail_test "Secret: $R"

# ---------------------------------------------------------------------------
# Test 7: No divergence
# ---------------------------------------------------------------------------
log "Test 7: Empty file list"
R=$(classify_divergence "")
[ "$R" = "NO_DIVERGENCE" ] && pass_test "Empty list = NO_DIVERGENCE" || fail_test "Empty: $R"

# ---------------------------------------------------------------------------
# Test 8: Mixed code + generated = CODE_DIVERGENCE
# ---------------------------------------------------------------------------
log "Test 8: Mixed code + generated"
FILES="docs/reports/automation-server/latest.md
src/lib/db.ts
control-plane/queue/queue.json"
R=$(classify_divergence "$FILES")
[ "$R" = "CODE_DIVERGENCE" ] && pass_test "Mixed code+generated = CODE_DIVERGENCE" || fail_test "Mixed: $R"

# ---------------------------------------------------------------------------
# Test 9: Sync script syntax
# ---------------------------------------------------------------------------
log "Test 9: sync-github-local-server.sh syntax"
if bash -n "$SCRIPT_DIR/../sync-github-local-server.sh" 2>/dev/null; then
  pass_test "sync-github-local-server.sh valid syntax"
else
  fail_test "sync-github-local-server.sh syntax error"
fi

# ---------------------------------------------------------------------------
# Test 10: Supervisor script syntax
# ---------------------------------------------------------------------------
log "Test 10: asdev-supervisor.sh syntax"
if bash -n "$SCRIPT_DIR/../asdev-supervisor.sh" 2>/dev/null; then
  pass_test "asdev-supervisor.sh valid syntax"
else
  fail_test "asdev-supervisor.sh syntax error"
fi

# ---------------------------------------------------------------------------
# Test 11: Divergence policy — generated-only is safe to reconcile
# ---------------------------------------------------------------------------
log "Test 11: Generated-only divergence is safe"
FILES="docs/reports/automation-server/FINAL_RELIABILITY_HARDENING.md
docs/memory/ASDEV_CURRENT_STATE.md
ops/automation-logs/github-sync.summary.md"
R=$(classify_divergence "$FILES")
[ "$R" = "GENERATED_DIVERGENCE" ] && pass_test "Multiple generated files = safe reconciliation" || fail_test "Multiple generated: $R"

# ---------------------------------------------------------------------------
# Test 12: Policy doc changes are CODE (not generated)
# ---------------------------------------------------------------------------
log "Test 12: Policy docs are CODE"
R=$(classify_file "docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md")
[ "$R" = "code" ] && pass_test "Policy docs = code (not generated)" || fail_test "Policy docs: $R"

R=$(classify_file "AGENTS.md")
[ "$R" = "code" ] && pass_test "AGENTS.md = code" || fail_test "AGENTS.md: $R"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "=== Git Divergence Policy Test Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
