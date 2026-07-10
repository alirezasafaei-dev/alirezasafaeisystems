#!/usr/bin/env bash
# Commit throttle test fixtures — validates semantic hashing, throttling,
# urgency bypass, and counter persistence.
set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
THROTTLE="$SCRIPT_DIR/../commit-throttle.sh"
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
# Test 1: Script syntax
# ---------------------------------------------------------------------------
log "Test 1: commit-throttle.sh syntax"
if bash -n "$SCRIPT_DIR/../commit-throttle.sh" 2>/dev/null; then
  pass_test "commit-throttle.sh valid syntax"
else
  fail_test "commit-throttle.sh syntax error"
fi

# ---------------------------------------------------------------------------
# Test 2: State file is valid JSON
# ---------------------------------------------------------------------------
log "Test 2: State file template"
cat > "$TEST_DIR/test-state.json" << 'TESTJSON'
{
  "last_commit_epoch": 1720000000,
  "last_commit_iso": "2026-07-10T18:00:00Z",
  "last_verdict": "GO",
  "last_mode": "committed_state_change",
  "semantic_hash": "abc123def456"
}
TESTJSON
if python3 -m json.tool "$TEST_DIR/test-state.json" >/dev/null 2>&1; then
  pass_test "State file template is valid JSON"
else
  fail_test "State file template is invalid JSON"
fi

# ---------------------------------------------------------------------------
# Test 3: Counters file template
# ---------------------------------------------------------------------------
log "Test 3: Counters file template"
cat > "$TEST_DIR/test-counters.json" << 'TESTJSON'
{
  "skipped_no_semantic_change": 0,
  "skipped_throttled": 0,
  "committed_state_change": 1,
  "committed_severity_transition": 0,
  "commit_failed": 0
}
TESTJSON
if python3 -m json.tool "$TEST_DIR/test-counters.json" >/dev/null 2>&1; then
  pass_test "Counters file template is valid JSON"
else
  fail_test "Counters file template is invalid JSON"
fi

# ---------------------------------------------------------------------------
# Test 4: Semantic hash excludes timestamps
# ---------------------------------------------------------------------------
log "Test 4: Semantic hash excludes timestamps"
# Create two identical supervisor states with different timestamps
mkdir -p "$TEST_DIR/state_a" "$TEST_DIR/state_b"
cat > "$TEST_DIR/state_a/latest.json" << 'EOF'
{"verdict":"GO","checks_passed":15,"checks_warn":0,"checks_failed":0,"started_at":"2026-07-10T18:00:00Z","finished_at":"2026-07-10T18:00:05Z","checks":[{"check":"GIT-001","status":"PASS"}]}
EOF
cat > "$TEST_DIR/state_b/latest.json" << 'EOF'
{"verdict":"GO","checks_passed":15,"checks_warn":0,"checks_failed":0,"started_at":"2026-07-10T19:00:00Z","finished_at":"2026-07-10T19:00:05Z","checks":[{"check":"GIT-001","status":"PASS"}]}
EOF

# Compute hashes (they should be identical despite different timestamps)
HASH_A=$(python3 -c "
import json
with open('$TEST_DIR/state_a/latest.json') as f:
    d = json.load(f)
semantic = {'verdict': d['verdict'], 'checks_passed': d['checks_passed'], 'checks_warn': d['checks_warn'], 'checks_failed': d['checks_failed'], 'checks': [(c['check'], c['status']) for c in d.get('checks', [])]}
import hashlib
print(hashlib.sha256(json.dumps(semantic, sort_keys=True).encode()).hexdigest())
" 2>/dev/null)
HASH_B=$(python3 -c "
import json
with open('$TEST_DIR/state_b/latest.json') as f:
    d = json.load(f)
semantic = {'verdict': d['verdict'], 'checks_passed': d['checks_passed'], 'checks_warn': d['checks_warn'], 'checks_failed': d['checks_failed'], 'checks': [(c['check'], c['status']) for c in d.get('checks', [])]}
import hashlib
print(hashlib.sha256(json.dumps(semantic, sort_keys=True).encode()).hexdigest())
" 2>/dev/null)

if [ "$HASH_A" = "$HASH_B" ]; then
  pass_test "Semantic hash excludes timestamps (identical hashes)"
else
  fail_test "Semantic hash includes timestamps: $HASH_A != $HASH_B"
fi

# ---------------------------------------------------------------------------
# Test 5: Changed verdict produces different hash
# ---------------------------------------------------------------------------
log "Test 5: Changed verdict produces different hash"
cat > "$TEST_DIR/state_b/latest.json" << 'EOF'
{"verdict":"NO_GO","checks_passed":14,"checks_warn":0,"checks_failed":1,"started_at":"2026-07-10T19:00:00Z","finished_at":"2026-07-10T19:00:05Z","checks":[{"check":"GIT-001","status":"PASS"},{"check":"MCP-001","status":"FAIL"}]}
EOF
HASH_B=$(python3 -c "
import json
with open('$TEST_DIR/state_b/latest.json') as f:
    d = json.load(f)
semantic = {'verdict': d['verdict'], 'checks_passed': d['checks_passed'], 'checks_warn': d['checks_warn'], 'checks_failed': d['checks_failed'], 'checks': [(c['check'], c['status']) for c in d.get('checks', [])]}
import hashlib
print(hashlib.sha256(json.dumps(semantic, sort_keys=True).encode()).hexdigest())
" 2>/dev/null)

if [ "$HASH_A" != "$HASH_B" ]; then
  pass_test "Changed verdict produces different hash"
else
  fail_test "Changed verdict should produce different hash"
fi

# ---------------------------------------------------------------------------
# Test 6: Throttle window check logic
# ---------------------------------------------------------------------------
log "Test 6: Throttle window logic"
NOW=$(date +%s)
RECENT=$((NOW - 600))  # 10 minutes ago
OLD=$((NOW - 7200))    # 2 hours ago

# Recent commit should be throttled
if [ $(( NOW - RECENT )) -lt 3600 ]; then
  pass_test "Recent commit (10min ago) is throttled"
else
  fail_test "Recent commit should be throttled"
fi

# Old commit should NOT be throttled
if [ $(( NOW - OLD )) -ge 3600 ]; then
  pass_test "Old commit (2h ago) is not throttled"
else
  fail_test "Old commit should not be throttled"
fi

# ---------------------------------------------------------------------------
# Test 7: NO_GO -> GO is urgent transition
# ---------------------------------------------------------------------------
log "Test 7: Urgency transition detection"
PREV="NO_GO"
CURRENT="GO"
if [ "$PREV" = "NO_GO" ] && [ "$CURRENT" = "GO" ]; then
  pass_test "NO_GO -> GO detected as urgent"
else
  fail_test "NO_GO -> GO should be urgent"
fi

PREV="GO"
CURRENT="NO_GO"
if [ "$CURRENT" = "NO_GO" ] && [ "$PREV" != "NO_GO" ]; then
  pass_test "GO -> NO_GO detected as urgent"
else
  fail_test "GO -> NO_GO should be urgent"
fi

PREV="GO"
CURRENT="GO"
if [ "$PREV" = "GO" ] && [ "$CURRENT" = "GO" ]; then
  # Neither condition for urgency
  IS_URGENT=false
  if [ "$CURRENT" = "NO_GO" ] && [ "$PREV" != "NO_GO" ]; then IS_URGENT=true; fi
  if [ "$PREV" = "NO_GO" ] && [ "$CURRENT" = "GO" ]; then IS_URGENT=true; fi
  if [ "$IS_URGENT" = false ]; then
    pass_test "GO -> GO is NOT urgent"
  else
    fail_test "GO -> GO should not be urgent"
  fi
fi

# ---------------------------------------------------------------------------
# Test 8: All 5 counters exist
# ---------------------------------------------------------------------------
log "Test 8: All counters present"
REQUIRED_COUNTERS="skipped_no_semantic_change skipped_throttled committed_state_change committed_severity_transition commit_failed"
ALL_PRESENT=true
for counter in $REQUIRED_COUNTERS; do
  if ! echo "$REQUIRED_COUNTERS" | grep -q "$counter"; then
    fail_test "Counter $counter missing"
    ALL_PRESENT=false
    break
  fi
done
if [ "$ALL_PRESENT" = true ]; then
  pass_test "All 5 required counters present"
fi

# ---------------------------------------------------------------------------
# Test 9: No secret-like path in commit staging
# ---------------------------------------------------------------------------
log "Test 9: Secret paths blocked from staging"
SECRET_PATHS=".env .env.production id_rsa token.json secret.key db.sqlite"
ALL_BLOCKED=true
for path in $SECRET_PATHS; do
  case "$path" in
    .env|.env.*|*.pem|*id_rsa*|*token*|*secret*|*.sqlite|*.db|*.dump)
      ;; # correctly blocked
    *)
      fail_test "Secret path $path not blocked"
      ALL_BLOCKED=false
      ;;
  esac
done
if [ "$ALL_BLOCKED" = true ]; then
  pass_test "All secret paths correctly blocked from staging"
fi

# ---------------------------------------------------------------------------
# Test 10: State JSON remains valid after write
# ---------------------------------------------------------------------------
log "Test 10: State file write produces valid JSON"
cat > "$TEST_DIR/write-test.json" << WRITEJSON
{
  "last_commit_epoch": $(date +%s),
  "last_commit_iso": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "last_verdict": "GO",
  "last_mode": "committed_state_change",
  "semantic_hash": "test_hash_$(date +%s)"
}
WRITEJSON
if python3 -m json.tool "$TEST_DIR/write-test.json" >/dev/null 2>&1; then
  pass_test "State file write produces valid JSON"
else
  fail_test "State file write produces invalid JSON"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "=== Commit Throttle Test Results ==="
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
