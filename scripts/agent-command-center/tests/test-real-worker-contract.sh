#!/usr/bin/env bash
set -Euo pipefail

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
ACC="$REPO_ROOT/scripts/agent-command-center"
DISPATCHER="$ACC/dispatch-real-worker.sh"
VALIDATOR="$ACC/validate-task-artifact.sh"
LOOP="$ACC/run-autonomous-loop.sh"
TMP="$(mktemp -d)"
ORIGINAL_PATH="$PATH"
FAILURES=0
PASSES=0
trap 'rm -rf "$TMP"' EXIT

pass() {
  PASSES=$((PASSES + 1))
  printf 'PASS F%s: %s\n' "$1" "$2"
}

fail_fixture() {
  FAILURES=$((FAILURES + 1))
  printf 'FAIL F%s: %s\n' "$1" "$2"
}

assert_contains() {
  local fixture="$1" haystack="$2" needle="$3" description="$4"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$fixture" "$description"
  else
    fail_fixture "$fixture" "$description; expected '$needle'; got: $haystack"
  fi
}

export ASDEV_ROOT="$TMP/root"
export ASDEV_TEST_MODE=1
export GH_CALL_LOG="$TMP/gh-calls.log"
mkdir -p \
  "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" \
  "$ASDEV_ROOT/docs/reports/test" \
  "$ASDEV_ROOT/prompts/opencode" \
  "$ASDEV_ROOT/scripts/agent-command-center" \
  "$TMP/bin" "$TMP/contracts" "$TMP/empty-contracts"

cp "$ACC/task-contract.schema.json" "$ASDEV_ROOT/scripts/agent-command-center/task-contract.schema.json"
cp "$VALIDATOR" "$ASDEV_ROOT/scripts/agent-command-center/validate-task-artifact.sh"
chmod +x "$ASDEV_ROOT/scripts/agent-command-center/validate-task-artifact.sh"

git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" init -q -b main
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" config user.email test@example.invalid
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" config user.name test
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" commit --allow-empty -q -m init
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" remote add origin \
  https://github.com/alirezasafaei-dev/auditsystems.git
REPO_SHA="$(git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" rev-parse HEAD)"

cat > "$TMP/bin/gh" <<'SH'
#!/usr/bin/env bash
set -u
if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then
  [ "${GH_MOCK_AUTH_FAIL:-0}" != "1" ]
  exit
fi
if [ "${1:-}" = "issue" ] && [ "${2:-}" = "comment" ]; then
  printf '%s\n' "$*" >> "${GH_CALL_LOG:?}"
  if [ "${GH_MOCK_COMMENT_FAIL:-0}" = "1" ]; then
    exit 1
  fi
  printf 'https://github.com/alirezasafaei-dev/alirezasafaeisystems/issues/98#issuecomment-test\n'
  exit 0
fi
exit 2
SH
cat > "$TMP/bin/getent" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat > "$TMP/bin/curl" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat > "$TMP/bin/safety-gate" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$TMP/bin/gh" "$TMP/bin/getent" "$TMP/bin/curl" "$TMP/bin/safety-gate"
export PATH="$TMP/bin:$ORIGINAL_PATH"

reset_mock() {
  : > "$GH_CALL_LOG"
  unset GH_MOCK_AUTH_FAIL GH_MOCK_COMMENT_FAIL ASDEV_OFFLINE_STAGE
  rm -f "$ASDEV_ROOT/.state/supervisor/verdict"
}

make_contract() {
  local fixture="$1"
  local sha="${2:-$REPO_SHA}"
  local validation_id="${3:-markdown-report}"
  local destination="${4:-$TMP/c${fixture}.json}"
  cat > "$destination" <<EOF
{"task_id":"ASDEV-F${fixture}","mission_file":"prompts/opencode/f${fixture}.md","worker_profile":"readonly-check","repository":"alirezasafaei-dev/auditsystems","repo_path":"repos/alirezasafaei-dev/auditsystems","base_ref":"main","expected_sha":"$sha","mode":"read-only","expected_artifact":"docs/reports/test/report-F${fixture}.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"$validation_id","timeout_seconds":60,"max_attempts":3,"created_at":"2026-07-14T12:00:00Z"}
EOF
}

set_json() {
  python3 - "$1" "$2" "$3" <<'PY'
import json
import sys
path, key, value = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)
data[key] = value
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle)
PY
}

dispatch_capture() {
  local contract="$1"
  shift
  set +e
  OUTPUT="$("$@" bash "$DISPATCHER" "$contract" 2>&1)"
  STATUS=$?
  set -e
}

write_success_mission() {
  local fixture="$1"
  cat > "$ASDEV_ROOT/prompts/opencode/f${fixture}.md" <<EOF
#!/usr/bin/env bash
mkdir -p "\$ASDEV_ROOT/docs/reports/test"
printf '# Review F${fixture}\n\nValidated fixture.\n' > "\$ASDEV_ROOT/docs/reports/test/report-F${fixture}.md"
EOF
}

reset_mock
SYNTAX_OK=1
for script in "$DISPATCHER" "$VALIDATOR" "$LOOP" "$ACC/tests/test-real-worker-contract.sh"; do
  bash -n "$script" || SYNTAX_OK=0
done
if [ "$SYNTAX_OK" -eq 1 ] && ! rg -n '\beval\b' "$DISPATCHER" "$VALIDATOR" >/dev/null; then
  pass 1 "syntax valid and no eval"
else
  fail_fixture 1 "syntax failure or eval present"
fi

reset_mock
make_contract 2
write_success_mission 2
printf '# Rogue\n' > "$TMP/rogue.md"
set +e
MISMATCH_OUTPUT="$(bash "$VALIDATOR" "$TMP/c2.json" "$TMP/rogue.md" 2>&1)"
MISMATCH_STATUS=$?
set -e
dispatch_capture "$TMP/c2.json" env
if [ "$MISMATCH_STATUS" -ne 0 ] && [ "$STATUS" -eq 0 ] &&
  grep -q '"state":"done"' "$ASDEV_ROOT/.state/worker/ASDEV-F2/result.json" &&
  grep -q '^https://github.com/' "$ASDEV_ROOT/.state/worker/ASDEV-F2/report-receipt.txt"; then
  pass 2 "artifact binding, hash, report receipt, and done state"
else
  fail_fixture 2 "valid execution or artifact binding failed: $OUTPUT / $MISMATCH_OUTPUT"
fi

reset_mock
make_contract 3
cat > "$ASDEV_ROOT/prompts/opencode/f3.md" <<'SH'
#!/usr/bin/env bash
exit 0
SH
dispatch_capture "$TMP/c3.json" env
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"artifact-or-worker-invalid"* ]] &&
  ! grep -q . "$GH_CALL_LOG"; then
  pass 3 "missing artifact fails closed without reporting"
else
  fail_fixture 3 "missing artifact path did not fail closed: $OUTPUT"
fi

reset_mock
make_contract 4
cat > "$ASDEV_ROOT/prompts/opencode/f4.md" <<'SH'
#!/usr/bin/env bash
: > "$ASDEV_ROOT/docs/reports/test/report-F4.md"
SH
dispatch_capture "$TMP/c4.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"artifact_valid":0' "$ASDEV_ROOT/.state/worker/ASDEV-F4/result.json"; then
  pass 4 "empty artifact rejected"
else
  fail_fixture 4 "empty artifact accepted: $OUTPUT"
fi

reset_mock
printf '{"task_id":"ASDEV-F5"}\n' > "$TMP/c5.json"
set +e
OUTPUT="$(bash "$VALIDATOR" "$TMP/c5.json" 2>&1)"
STATUS=$?
set -e
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == ARTIFACT_INVALID* ]]; then
  pass 5 "missing required contract fields rejected"
else
  fail_fixture 5 "invalid schema accepted: $OUTPUT"
fi

reset_mock
make_contract 6 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
cat > "$ASDEV_ROOT/prompts/opencode/f6.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f6-worker-ran"
SH
dispatch_capture "$TMP/c6.json" env
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"sha-mismatch"* ]] &&
  [ ! -e "$ASDEV_ROOT/f6-worker-ran" ]; then
  pass 6 "wrong SHA rejected before worker"
else
  fail_fixture 6 "wrong SHA handling failed: $OUTPUT"
fi

reset_mock
make_contract 7 "$REPO_SHA" markdown-report
cat > "$ASDEV_ROOT/prompts/opencode/f7.md" <<'SH'
#!/usr/bin/env bash
printf '{"review":"not markdown"}\n' > "$ASDEV_ROOT/docs/reports/test/report-F7.md"
SH
dispatch_capture "$TMP/c7.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"validator_exit":1' "$ASDEV_ROOT/.state/worker/ASDEV-F7/result.json"; then
  pass 7 "allowlisted validation ID enforces content"
else
  fail_fixture 7 "validation failure not enforced: $OUTPUT"
fi

reset_mock
make_contract 8
set_json "$TMP/c8.json" mode production-deploy
set +e
OUTPUT="$(bash "$VALIDATOR" "$TMP/c8.json" 2>&1)"
STATUS=$?
set -e
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == ARTIFACT_INVALID* ]]; then
  pass 8 "disallowed mode rejected"
else
  fail_fixture 8 "disallowed mode accepted: $OUTPUT"
fi

reset_mock
make_contract 9
write_success_mission 9
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" remote set-url origin \
  https://github.com/evil/alirezasafaei-dev/auditsystems.git
dispatch_capture "$TMP/c9.json" env
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" remote set-url origin \
  https://github.com/alirezasafaei-dev/auditsystems.git
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"remote-not-allowlisted"* ]]; then
  pass 9 "remote URL requires canonical exact match"
else
  fail_fixture 9 "malicious substring remote accepted: $OUTPUT"
fi

reset_mock
make_contract 10
write_success_mission 10
export GH_MOCK_AUTH_FAIL=1
dispatch_capture "$TMP/c10.json" env
unset GH_MOCK_AUTH_FAIL
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"BLOCKED_REPORTER"* ]] &&
  grep -q '"state":"failed"' "$ASDEV_ROOT/.state/worker/ASDEV-F10/result.json"; then
  pass 10 "unavailable reporter blocks done"
else
  fail_fixture 10 "reporter failure did not block done: $OUTPUT"
fi

reset_mock
make_contract 11
cat > "$ASDEV_ROOT/prompts/opencode/f11.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f11-worker-ran"
SH
mkdir -p "$ASDEV_ROOT/.state/worker/ASDEV-F11"
printf '{"state":"done"}\n' > "$ASDEV_ROOT/.state/worker/ASDEV-F11/state.json"
printf '{"state":"done"}\n' > "$ASDEV_ROOT/.state/worker/ASDEV-F11/result.json"
dispatch_capture "$TMP/c11.json" env
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"duplicate-task"* ]] &&
  [ ! -e "$ASDEV_ROOT/f11-worker-ran" ]; then
  pass 11 "completed task cannot execute twice"
else
  fail_fixture 11 "duplicate task not rejected: $OUTPUT"
fi

reset_mock
make_contract 12
write_success_mission 12
mkdir -p "$ASDEV_ROOT/.state/worker/ASDEV-F12/claim.lock"
printf '999999\n' > "$ASDEV_ROOT/.state/worker/ASDEV-F12/claim.lock/pid"
touch -d '2 hours ago' "$ASDEV_ROOT/.state/worker/ASDEV-F12/claim.lock"
dispatch_capture "$TMP/c12.json" env
if [ "$STATUS" -eq 0 ] && [ ! -e "$ASDEV_ROOT/.state/worker/ASDEV-F12/claim.lock" ]; then
  pass 12 "old dead claim reclaimed and cleaned"
else
  fail_fixture 12 "stale lock recovery failed: $OUTPUT"
fi

reset_mock
make_contract 13
cat > "$ASDEV_ROOT/prompts/opencode/f13.md" <<'SH'
#!/usr/bin/env bash
sleep 2
printf '# Concurrent review\n' > "$ASDEV_ROOT/docs/reports/test/report-F13.md"
SH
(
  set +e
  bash "$DISPATCHER" "$TMP/c13.json" > "$TMP/f13-first.out" 2>&1
  printf '%s\n' "$?" > "$TMP/f13-first.rc"
) &
FIRST_PID=$!
for _ in $(seq 1 50); do
  [ -d "$ASDEV_ROOT/.state/worker/ASDEV-F13/claim.lock" ] && break
  sleep 0.05
done
dispatch_capture "$TMP/c13.json" env
SECOND_OUTPUT="$OUTPUT"
SECOND_STATUS="$STATUS"
wait "$FIRST_PID"
FIRST_STATUS="$(cat "$TMP/f13-first.rc")"
if [ "$FIRST_STATUS" -eq 0 ] && [ "$SECOND_STATUS" -ne 0 ] &&
  [[ "$SECOND_OUTPUT" == *"concurrent-claim"* ]]; then
  pass 13 "atomic claim allows one worker and rejects the other"
else
  fail_fixture 13 "concurrent claim invariant failed: first=$FIRST_STATUS second=$SECOND_STATUS $SECOND_OUTPUT"
fi

reset_mock
make_contract 14
cat > "$ASDEV_ROOT/prompts/opencode/f14.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f14-worker-ran"
SH
export ASDEV_OFFLINE_STAGE=before
dispatch_capture "$TMP/c14.json" env
unset ASDEV_OFFLINE_STAGE
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"offline-before-worker"* ]] &&
  [ ! -e "$ASDEV_ROOT/f14-worker-ran" ]; then
  pass 14 "offline-before fails before worker"
else
  fail_fixture 14 "offline-before handling failed: $OUTPUT"
fi

reset_mock
make_contract 15
write_success_mission 15
export ASDEV_OFFLINE_STAGE=after
dispatch_capture "$TMP/c15.json" env
unset ASDEV_OFFLINE_STAGE
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"offline-after-worker"* ]] &&
  ! grep -q . "$GH_CALL_LOG"; then
  pass 15 "offline-after blocks report and done"
else
  fail_fixture 15 "offline-after handling failed: $OUTPUT"
fi

reset_mock
make_contract 16
cat > "$ASDEV_ROOT/prompts/opencode/f16.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f16-worker-ran"
SH
mkdir -p "$ASDEV_ROOT/.state/supervisor"
printf 'NO_GO\n' > "$ASDEV_ROOT/.state/supervisor/verdict"
dispatch_capture "$TMP/c16.json" env
rm -f "$ASDEV_ROOT/.state/supervisor/verdict"
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"supervisor-no-go"* ]] &&
  [ ! -e "$ASDEV_ROOT/f16-worker-ran" ]; then
  pass 16 "supervisor NO_GO blocks worker"
else
  fail_fixture 16 "NO_GO not enforced: $OUTPUT"
fi

reset_mock
make_contract 17
cat > "$ASDEV_ROOT/prompts/opencode/f17.md" <<'SH'
#!/usr/bin/env bash
sleep 3
printf '# too late\n' > "$ASDEV_ROOT/docs/reports/test/report-F17.md"
SH
START_SECONDS=$SECONDS
dispatch_capture "$TMP/c17.json" env ASDEV_TEST_TIMEOUT_SECONDS=1
ELAPSED=$((SECONDS - START_SECONDS))
if [ "$STATUS" -ne 0 ] && [ "$ELAPSED" -lt 3 ] &&
  grep -q '"worker_exit":124' "$ASDEV_ROOT/.state/worker/ASDEV-F17/result.json"; then
  pass 17 "dispatcher timeout kills worker and records exit 124"
else
  fail_fixture 17 "dispatcher timeout failed: elapsed=$ELAPSED $OUTPUT"
fi

reset_mock
make_contract 18
cat > "$ASDEV_ROOT/prompts/opencode/f18.md" <<'SH'
#!/usr/bin/env bash
exit 7
SH
dispatch_capture "$TMP/c18.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"worker_exit":7' "$ASDEV_ROOT/.state/worker/ASDEV-F18/result.json"; then
  pass 18 "worker nonzero exit prevents done"
else
  fail_fixture 18 "worker failure not recorded: $OUTPUT"
fi

reset_mock
make_contract 19
export ASDEV_SECRET_CANARY='ghp_ASDEV_SUPER_SECRET_12345678901234567890'
cat > "$ASDEV_ROOT/prompts/opencode/f19.md" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$ASDEV_SECRET_CANARY"
printf '# Redacted review\n' > "$ASDEV_ROOT/docs/reports/test/report-F19.md"
SH
dispatch_capture "$TMP/c19.json" env
if [ "$STATUS" -eq 0 ] &&
  ! grep -R -F "$ASDEV_SECRET_CANARY" "$ASDEV_ROOT/.state/worker/ASDEV-F19" "$GH_CALL_LOG" >/dev/null; then
  pass 19 "worker secret canary redacted from state, output, and report"
else
  fail_fixture 19 "secret canary leaked or dispatch failed: $OUTPUT"
fi
unset ASDEV_SECRET_CANARY

reset_mock
cat > "$TMP/q20.md" <<'EOF'
- [ ] Missing contract | ID: ASDEV-F20 | Mode: read-only | Repo: auditsystems | Target: vps
EOF
set +e
OUTPUT="$(ASDEV_QUEUE_FILE="$TMP/q20.md" ASDEV_CONTRACTS_DIR="$TMP/empty-contracts" \
  ASDEV_AGENT_LOG_DIR="$TMP/log20" ASDEV_AGENT_STATE_DIR="$TMP/state20" \
  bash "$LOOP" --dry-run --once --max-jobs 1 2>&1)"
STATUS=$?
set -e
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"Missing required contract"* ]] &&
  [[ "$OUTPUT" != *"completed (legacy)"* ]]; then
  pass 20 "missing contract cannot become acknowledgement-only done"
else
  fail_fixture 20 "legacy completion path remains: $OUTPUT"
fi

reset_mock
make_contract 21 "$REPO_SHA" markdown-report "$TMP/contracts/ASDEV-F21.json"
write_success_mission 21
cat > "$TMP/q21.md" <<'EOF'
- [ ] Integrated task | ID: ASDEV-F21 | Mode: read-only | Repo: auditsystems | Target: vps
EOF
set +e
OUTPUT="$(ASDEV_QUEUE_FILE="$TMP/q21.md" ASDEV_CONTRACTS_DIR="$TMP/contracts" \
  ASDEV_AGENT_LOG_DIR="$TMP/log21" ASDEV_AGENT_STATE_DIR="$TMP/state21" \
  ASDEV_SAFETY_GATE="$TMP/bin/safety-gate" bash "$LOOP" --once --max-jobs 1 2>&1)"
STATUS=$?
set -e
if [ "$STATUS" -eq 0 ] &&
  grep -q '"state":"done"' "$ASDEV_ROOT/.state/worker/ASDEV-F21/result.json"; then
  pass 21 "autonomous loop delegates to real dispatcher"
else
  fail_fixture 21 "loop integration failed: $OUTPUT"
fi

reset_mock
make_contract 22 "$REPO_SHA" markdown-report "$TMP/contracts/ASDEV-F22.json"
cat > "$ASDEV_ROOT/prompts/opencode/f22.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f22-worker-ran"
SH
cat > "$TMP/q22.md" <<'EOF'
- [ ] Dry-run task | ID: ASDEV-F22 | Mode: read-only | Repo: auditsystems | Target: vps
EOF
set +e
OUTPUT="$(ASDEV_QUEUE_FILE="$TMP/q22.md" ASDEV_CONTRACTS_DIR="$TMP/contracts" \
  ASDEV_AGENT_LOG_DIR="$TMP/log22" ASDEV_AGENT_STATE_DIR="$TMP/state22" \
  bash "$LOOP" --dry-run --once --max-jobs 1 2>&1)"
STATUS=$?
set -e
if [ "$STATUS" -eq 0 ] && [[ "$OUTPUT" == *"contract validated; would dispatch"* ]] &&
  [ ! -e "$ASDEV_ROOT/f22-worker-ran" ] &&
  [ ! -e "$ASDEV_ROOT/.state/worker/ASDEV-F22" ] &&
  ! grep -q . "$GH_CALL_LOG"; then
  pass 22 "dry-run validates contract without worker, state, or GitHub mutation"
else
  fail_fixture 22 "dry-run mutated state or skipped validation: $OUTPUT"
fi

printf '\nFixtures passed: %s/22\n' "$PASSES"
if [ "$FAILURES" -ne 0 ] || [ "$PASSES" -ne 22 ]; then
  printf 'Fixtures failed: %s\n' "$FAILURES"
  exit 1
fi
printf 'ALL 22 REAL FIXTURES PASS\n'
