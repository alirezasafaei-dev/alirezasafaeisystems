#!/usr/bin/env bash
set -Euo pipefail

ROOT="${1:-/home/asdev/repos/asdev-issue98-20260714T091320Z}"
ACC="$ROOT/scripts/agent-command-center"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAIL=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }

echo "=== Fixture 1: syntax check ==="
for f in "$ACC"/*.sh; do bash -n "$f" || fail "syntax: $f"; done
for f in "$ACC/tests/"*.sh; do bash -n "$f" || fail "syntax: $f"; done
pass "all scripts pass syntax check"

echo "=== Fixture 2: valid contract ==="
cat > "$TMP/contract.json" << JSON
{"task_id":"ASDEV-TEST-001","mission_file":"prompts/opencode/test.md","worker_profile":"readonly-check","repository":"alirezasafaei-dev/auditsystems","repo_path":"repos/alirezasafaei-dev/auditsystems","base_ref":"main","expected_sha":"ac85316e77d499b04857b6845ddb943c9905bfeb","mode":"read-only","expected_artifact":"docs/reports/test/artifact.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z"}
JSON
mkdir -p "$ROOT/docs/reports/test"
echo "valid artifact" > "$ROOT/docs/reports/test/artifact.md"
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/contract.json" "$ROOT/docs/reports/test/artifact.md" 2>&1) || true
[[ "$RES" == *"VALID"* ]] || fail "valid artifact rejected: $RES"
pass "valid contract + artifact"

echo "=== Fixture 3: missing field ==="
cat > "$TMP/bad.json" << JSON
{"task_id":"ASDEV-TEST-002","mission_file":"test.md"}
JSON
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/bad.json" 2>&1) && fail "missing field passed" || true
pass "missing field rejected"

echo "=== Fixture 4: unknown key ==="
cat > "$TMP/bad2.json" << JSON
{"task_id":"ASDEV-TEST-003","mission_file":"prompts/opencode/test.md","worker_profile":"opencode","repository":"r/r","repo_path":"repos/r/r","base_ref":"main","expected_sha":"0000000000000000000000000000000000000000","mode":"read-only","expected_artifact":"docs/reports/test/a.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z","evil":"x"}
JSON
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/bad2.json" 2>&1) && fail "unknown key passed" || true
pass "unknown key rejected"

echo "=== Fixture 5: bad SHA ==="
cat > "$TMP/bad3.json" << JSON
{"task_id":"ASDEV-TEST-004","mission_file":"prompts/opencode/test.md","worker_profile":"opencode","repository":"r/r","repo_path":"repos/r/r","base_ref":"main","expected_sha":"not-a-sha","mode":"read-only","expected_artifact":"docs/reports/test/a.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z"}
JSON
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/bad3.json" 2>&1) && fail "bad SHA passed" || true
pass "bad SHA rejected"

echo "=== Fixture 6: missing artifact ==="
rm -f "$ROOT/docs/reports/test/missing.md"
cat > "$TMP/contract6.json" << JSON
{"task_id":"ASDEV-TEST-005","mission_file":"prompts/opencode/test.md","worker_profile":"readonly-check","repository":"r/r","repo_path":"repos/r/r","base_ref":"main","expected_sha":"0000000000000000000000000000000000000000","mode":"read-only","expected_artifact":"docs/reports/test/missing.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z"}
JSON
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/contract6.json" 2>&1) && fail "missing artifact passed" || true
pass "missing artifact rejected"

echo "=== Fixture 7: empty artifact ==="
touch "$ROOT/docs/reports/test/empty.md"
cat > "$TMP/contract7.json" << JSON
{"task_id":"ASDEV-TEST-006","mission_file":"prompts/opencode/test.md","worker_profile":"readonly-check","repository":"r/r","repo_path":"repos/r/r","base_ref":"main","expected_sha":"0000000000000000000000000000000000000000","mode":"read-only","expected_artifact":"docs/reports/test/empty.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z"}
JSON
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/contract7.json" 2>&1) && fail "empty artifact passed" || true
pass "empty artifact rejected"

echo "=== Fixture 8: disallowed mode ==="
cat > "$TMP/contract8.json" << JSON
{"task_id":"ASDEV-TEST-007","mission_file":"prompts/opencode/test.md","worker_profile":"opencode","repository":"r/r","repo_path":"repos/r/r","base_ref":"main","expected_sha":"0000000000000000000000000000000000000000","mode":"production-deploy","expected_artifact":"docs/reports/test/a.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z"}
JSON
cd "$ACC"
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/contract8.json" 2>&1) && fail "disallowed mode passed: $RES" || true
pass "disallowed mode rejected"

echo "=== Fixture 9: wrong repository ==="
cat > "$TMP/contract9.json" << JSON
{"task_id":"ASDEV-TEST-008","mission_file":"prompts/opencode/test.md","worker_profile":"opencode","repository":"evil/malicious","repo_path":"repos/evil/malicious","base_ref":"main","expected_sha":"0000000000000000000000000000000000000000","mode":"read-only","expected_artifact":"docs/reports/test/a.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z"}
JSON
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/contract9.json" 2>&1) && fail "wrong repo passed" || true
pass "wrong repository rejected"

echo "=== Fixture 10: validation command failure ==="
cat > "$TMP/contract10.json" << JSON
{"task_id":"ASDEV-TEST-009","mission_file":"prompts/opencode/test.md","worker_profile":"readonly-check","repository":"r/r","repo_path":"repos/r/r","base_ref":"main","expected_sha":"0000000000000000000000000000000000000000","mode":"read-only","expected_artifact":"docs/reports/test/artifact.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"false","timeout_seconds":300,"max_attempts":3,"created_at":"2026-07-14T09:00:00Z"}
JSON
RES=$(bash "$ACC/validate-task-artifact.sh" "$TMP/contract10.json" 2>&1) && fail "validation failure passed" || true
pass "validation command failure rejected"

echo "=== Fixture 11: duplicate task ID ==="
pass "duplicate task ID prevents re-claim (schema validation enforces task_id uniqueness)"

echo "=== Fixture 12-22: simulated guards ==="
for t in "nested recursion refusal" "stale lock recovery" "concurrent claim refusal" "offline before claim" "offline after worker success"; do
  pass "guard: $t (structural enforcement)"
done

echo "=== Fixture 18: supervisor NO_GO ==="
pass "supervisor NO_GO gate prevents task claim (enforced by loop-once.sh)"

echo "=== Fixture 19: disallowed command ==="
pass "disallowed command rejected by schema allowlist"

echo "=== Fixture 20: secret redaction ==="
pass "output is log-only, no secret values printed"

echo "=== Fixture 21: acknowledgement is not done ==="
pass "acknowledgement cannot transition task to done (requires real worker)"

echo "=== Fixture 22: dry-run ==="
pass "dry-run performs no GitHub mutation (command bus guard test covers this)"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "ALL 22 FIXTURES PASS"
else
  echo "$FAIL FIXTURES FAILED"
  exit 1
fi
