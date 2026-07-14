#!/usr/bin/env bash
set -Euo pipefail

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
ACC="$REPO_ROOT/scripts/agent-command-center"
DISPATCHER="$ACC/dispatch-real-worker.sh"
VALIDATOR="$ACC/validate-task-artifact.sh"
LOOP="$ACC/run-autonomous-loop.sh"
COMMAND_BUS="$ACC/issue45-command-bus.sh"
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
  [ "${GH_MOCK_COMMENT_FAIL:-0}" != "1" ] || exit 1
  printf 'https://github.com/alirezasafaei-dev/alirezasafaeisystems/issues/98#issuecomment-test\n'
  exit 0
fi
printf '%s\n' "$*" >> "${GH_CALL_LOG:?}"
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
  unset ASDEV_SOURCE_COMMENT_ID ASDEV_COMMAND_BUS_DEPTH ASDEV_OPENCODE_BIN
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

# 1. Shell syntax and the no-eval invariant.
reset_mock
SYNTAX_OK=1
for script in "$DISPATCHER" "$VALIDATOR" "$LOOP" "$COMMAND_BUS" "$ACC/tests/test-real-worker-contract.sh"; do
  bash -n "$script" || SYNTAX_OK=0
done
if [ "$SYNTAX_OK" -eq 1 ] && ! rg -n '\beval\b' "$DISPATCHER" "$VALIDATOR" >/dev/null; then
  pass 1 "shell syntax valid and no eval"
else
  fail_fixture 1 "syntax failure or eval present"
fi

# 2. Real fixture worker success, valid artifact, report receipt, done.
reset_mock
make_contract 2
write_success_mission 2
dispatch_capture "$TMP/c2.json" env
if [ "$STATUS" -eq 0 ] &&
  grep -q '"state":"done"' "$ASDEV_ROOT/.state/worker/ASDEV-F2/result.json" &&
  grep -Eq '"artifact_hash":"[a-f0-9]{64}"' "$ASDEV_ROOT/.state/worker/ASDEV-F2/result.json" &&
  grep -q '^https://github.com/' "$ASDEV_ROOT/.state/worker/ASDEV-F2/report-receipt.txt"; then
  pass 2 "real fixture worker produces validated artifact and receipt"
else
  fail_fixture 2 "success contract failed: $OUTPUT"
fi

# 3. Missing worker.
reset_mock
make_contract 3
set_json "$TMP/c3.json" worker_profile opencode
printf 'Review only.\n' > "$ASDEV_ROOT/prompts/opencode/f3.md"
dispatch_capture "$TMP/c3.json" env ASDEV_OPENCODE_BIN=/definitely/missing/opencode
if [ "$STATUS" -ne 0 ] &&
  grep -q '"worker_exit":127' "$ASDEV_ROOT/.state/worker/ASDEV-F3/result.json"; then
  pass 3 "missing worker records 127 and cannot become done"
else
  fail_fixture 3 "missing worker handling failed: $OUTPUT"
fi

# 4. Non-zero worker exit.
reset_mock
make_contract 4
cat > "$ASDEV_ROOT/prompts/opencode/f4.md" <<'SH'
#!/usr/bin/env bash
exit 7
SH
dispatch_capture "$TMP/c4.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"worker_exit":7' "$ASDEV_ROOT/.state/worker/ASDEV-F4/result.json"; then
  pass 4 "non-zero worker exit prevents done"
else
  fail_fixture 4 "worker failure not recorded: $OUTPUT"
fi

# 5. Dispatcher timeout.
reset_mock
make_contract 5
cat > "$ASDEV_ROOT/prompts/opencode/f5.md" <<'SH'
#!/usr/bin/env bash
exec sleep 5
SH
START_SECONDS=$SECONDS
dispatch_capture "$TMP/c5.json" env ASDEV_TEST_TIMEOUT_SECONDS=1
ELAPSED=$((SECONDS - START_SECONDS))
if [ "$STATUS" -ne 0 ] && [ "$ELAPSED" -lt 4 ] &&
  grep -q '"worker_exit":124' "$ASDEV_ROOT/.state/worker/ASDEV-F5/result.json"; then
  pass 5 "dispatcher timeout terminates worker and records 124"
else
  fail_fixture 5 "timeout failed: elapsed=$ELAPSED $OUTPUT"
fi

# 6. Missing artifact.
reset_mock
make_contract 6
printf '#!/usr/bin/env bash\nexit 0\n' > "$ASDEV_ROOT/prompts/opencode/f6.md"
dispatch_capture "$TMP/c6.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"artifact_valid":0' "$ASDEV_ROOT/.state/worker/ASDEV-F6/result.json" &&
  ! grep -q . "$GH_CALL_LOG"; then
  pass 6 "missing artifact fails closed without reporting"
else
  fail_fixture 6 "missing artifact accepted: $OUTPUT"
fi

# 7. Empty artifact.
reset_mock
make_contract 7
cat > "$ASDEV_ROOT/prompts/opencode/f7.md" <<'SH'
#!/usr/bin/env bash
: > "$ASDEV_ROOT/docs/reports/test/report-F7.md"
SH
dispatch_capture "$TMP/c7.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"validator_exit":1' "$ASDEV_ROOT/.state/worker/ASDEV-F7/result.json"; then
  pass 7 "empty artifact rejected"
else
  fail_fixture 7 "empty artifact accepted: $OUTPUT"
fi

# 8. Invalid artifact schema.
reset_mock
make_contract 8 "$REPO_SHA" json-object
cat > "$ASDEV_ROOT/prompts/opencode/f8.md" <<'SH'
#!/usr/bin/env bash
printf '{not-json}\n' > "$ASDEV_ROOT/docs/reports/test/report-F8.md"
SH
dispatch_capture "$TMP/c8.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"validator_exit":1' "$ASDEV_ROOT/.state/worker/ASDEV-F8/result.json"; then
  pass 8 "invalid artifact schema rejected"
else
  fail_fixture 8 "invalid artifact schema accepted: $OUTPUT"
fi

# 9. Wrong repository, base ref, and exact SHA.
reset_mock
make_contract 9
write_success_mission 9
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" remote set-url origin \
  https://github.com/evil/alirezasafaei-dev/auditsystems.git
dispatch_capture "$TMP/c9.json" env
REMOTE_REJECTED=0
[[ "$OUTPUT" == *"remote-not-allowlisted"* ]] && REMOTE_REJECTED=1
git -C "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" remote set-url origin \
  https://github.com/alirezasafaei-dev/auditsystems.git
set_json "$TMP/c9.json" base_ref no-such-ref
dispatch_capture "$TMP/c9.json" env
REF_REJECTED=0
[[ "$OUTPUT" == *"base-ref-not-found"* ]] && REF_REJECTED=1
set_json "$TMP/c9.json" base_ref main
set_json "$TMP/c9.json" expected_sha aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
dispatch_capture "$TMP/c9.json" env
SHA_REJECTED=0
[[ "$OUTPUT" == *"sha-mismatch"* ]] && SHA_REJECTED=1
if [ "$REMOTE_REJECTED" -eq 1 ] && [ "$REF_REJECTED" -eq 1 ] && [ "$SHA_REJECTED" -eq 1 ]; then
  pass 9 "wrong repository/ref/SHA all rejected before worker"
else
  fail_fixture 9 "repository/ref/SHA checks incomplete: remote=$REMOTE_REJECTED ref=$REF_REJECTED sha=$SHA_REJECTED last=$OUTPUT"
fi

# 10. Allowlisted validation ID fails.
reset_mock
make_contract 10 "$REPO_SHA" markdown-report
cat > "$ASDEV_ROOT/prompts/opencode/f10.md" <<'SH'
#!/usr/bin/env bash
printf '{"review":"not markdown"}\n' > "$ASDEV_ROOT/docs/reports/test/report-F10.md"
SH
dispatch_capture "$TMP/c10.json" env
if [ "$STATUS" -ne 0 ] &&
  grep -q '"validator_exit":1' "$ASDEV_ROOT/.state/worker/ASDEV-F10/result.json"; then
  pass 10 "validation failure prevents done"
else
  fail_fixture 10 "validation failure not enforced: $OUTPUT"
fi

# 11. Report publication failure after valid artifact.
reset_mock
make_contract 11
write_success_mission 11
export GH_MOCK_COMMENT_FAIL=1
dispatch_capture "$TMP/c11.json" env
unset GH_MOCK_COMMENT_FAIL
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"BLOCKED_REPORTER"* ]] &&
  grep -q '"reason":"report-publish-failed"' "$ASDEV_ROOT/.state/worker/ASDEV-F11/result.json"; then
  pass 11 "report publication failure blocks done"
else
  fail_fixture 11 "report failure did not block done: $OUTPUT"
fi

# 12. Duplicate task and duplicate source-comment claims.
reset_mock
make_contract 12
cat > "$ASDEV_ROOT/prompts/opencode/f12.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f12-worker-ran"
SH
mkdir -p "$ASDEV_ROOT/.state/worker/ASDEV-F12"
printf '{"state":"done"}\n' > "$ASDEV_ROOT/.state/worker/ASDEV-F12/state.json"
printf '{"state":"done"}\n' > "$ASDEV_ROOT/.state/worker/ASDEV-F12/result.json"
dispatch_capture "$TMP/c12.json" env ASDEV_SOURCE_COMMENT_ID=1200
TASK_REJECTED=0
[[ "$OUTPUT" == *"duplicate-task"* ]] && TASK_REJECTED=1
cp "$TMP/c12.json" "$TMP/c12b.json"
set_json "$TMP/c12b.json" task_id ASDEV-F12B
dispatch_capture "$TMP/c12b.json" env ASDEV_SOURCE_COMMENT_ID=1200
COMMENT_REJECTED=0
[[ "$OUTPUT" == *"duplicate-comment-claim"* ]] && COMMENT_REJECTED=1
if [ "$TASK_REJECTED" -eq 1 ] && [ "$COMMENT_REJECTED" -eq 1 ] &&
  [ ! -e "$ASDEV_ROOT/f12-worker-ran" ]; then
  pass 12 "duplicate task and comment claims refused"
else
  fail_fixture 12 "duplicate refusal incomplete"
fi

# 13. Nested command-bus recursion/claim refusal.
reset_mock
make_contract 13
cat > "$ASDEV_ROOT/prompts/opencode/f13.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f13-worker-ran"
SH
dispatch_capture "$TMP/c13.json" env ASDEV_COMMAND_BUS_DEPTH=1
DISPATCH_REJECTED=0
[[ "$OUTPUT" == *"nested-command-bus-claim"* ]] && DISPATCH_REJECTED=1
set +e
BUS_OUTPUT="$(ASDEV_COMMAND_BUS_DEPTH=1 bash "$COMMAND_BUS" 45 2>&1)"
BUS_STATUS=$?
set -e
if [ "$DISPATCH_REJECTED" -eq 1 ] && [ "$BUS_STATUS" -ne 0 ] &&
  [[ "$BUS_OUTPUT" == *"nested command-bus invocation refused"* ]] &&
  [ ! -e "$ASDEV_ROOT/f13-worker-ran" ]; then
  pass 13 "nested command-bus invocation and claim refused"
else
  fail_fixture 13 "nested command-bus guard failed"
fi

# 14. Stale claim recovery.
reset_mock
make_contract 14
write_success_mission 14
mkdir -p "$ASDEV_ROOT/.state/worker/ASDEV-F14/claim.lock"
printf '999999\n' > "$ASDEV_ROOT/.state/worker/ASDEV-F14/claim.lock/pid"
touch -d '2 hours ago' "$ASDEV_ROOT/.state/worker/ASDEV-F14/claim.lock"
dispatch_capture "$TMP/c14.json" env
if [ "$STATUS" -eq 0 ] && [ ! -e "$ASDEV_ROOT/.state/worker/ASDEV-F14/claim.lock" ]; then
  pass 14 "old dead claim recovered and cleaned"
else
  fail_fixture 14 "stale claim recovery failed: $OUTPUT"
fi

# 15. Concurrent claim refusal against the actual dispatcher.
reset_mock
make_contract 15
cat > "$ASDEV_ROOT/prompts/opencode/f15.md" <<'SH'
#!/usr/bin/env bash
sleep 2
printf '# Concurrent review\n' > "$ASDEV_ROOT/docs/reports/test/report-F15.md"
SH
(
  set +e
  bash "$DISPATCHER" "$TMP/c15.json" > "$TMP/f15-first.out" 2>&1
  printf '%s\n' "$?" > "$TMP/f15-first.rc"
) &
FIRST_PID=$!
for _ in $(seq 1 50); do
  [ -d "$ASDEV_ROOT/.state/worker/ASDEV-F15/claim.lock" ] && break
  sleep 0.05
done
dispatch_capture "$TMP/c15.json" env
SECOND_OUTPUT="$OUTPUT"
SECOND_STATUS="$STATUS"
wait "$FIRST_PID"
FIRST_STATUS="$(cat "$TMP/f15-first.rc")"
if [ "$FIRST_STATUS" -eq 0 ] && [ "$SECOND_STATUS" -ne 0 ] &&
  [[ "$SECOND_OUTPUT" == *"concurrent-claim"* ]]; then
  pass 15 "atomic claim admits one worker and rejects the other"
else
  fail_fixture 15 "concurrent claim invariant failed: first=$FIRST_STATUS second=$SECOND_STATUS"
fi

# 16. Offline before claim.
reset_mock
make_contract 16
cat > "$ASDEV_ROOT/prompts/opencode/f16.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f16-worker-ran"
SH
dispatch_capture "$TMP/c16.json" env ASDEV_OFFLINE_STAGE=before
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"offline-before-worker"* ]] &&
  [ ! -e "$ASDEV_ROOT/f16-worker-ran" ] &&
  [ ! -e "$ASDEV_ROOT/.state/worker/ASDEV-F16" ]; then
  pass 16 "offline-before fails before claim and worker"
else
  fail_fixture 16 "offline-before handling failed: $OUTPUT"
fi

# 17. Offline after worker success and before reporting.
reset_mock
make_contract 17
write_success_mission 17
dispatch_capture "$TMP/c17.json" env ASDEV_OFFLINE_STAGE=after
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"offline-after-worker"* ]] &&
  grep -q '"state":"failed"' "$ASDEV_ROOT/.state/worker/ASDEV-F17/result.json" &&
  ! grep -q . "$GH_CALL_LOG"; then
  pass 17 "offline-after preserves failed evidence and blocks done"
else
  fail_fixture 17 "offline-after handling failed: $OUTPUT"
fi

# 18. Supervisor NO_GO.
reset_mock
make_contract 18
cat > "$ASDEV_ROOT/prompts/opencode/f18.md" <<'SH'
#!/usr/bin/env bash
touch "$ASDEV_ROOT/f18-worker-ran"
SH
mkdir -p "$ASDEV_ROOT/.state/supervisor"
printf 'NO_GO\n' > "$ASDEV_ROOT/.state/supervisor/verdict"
dispatch_capture "$TMP/c18.json" env
rm -f "$ASDEV_ROOT/.state/supervisor/verdict"
if [ "$STATUS" -ne 0 ] && [[ "$OUTPUT" == *"supervisor-no-go"* ]] &&
  [ ! -e "$ASDEV_ROOT/f18-worker-ran" ]; then
  pass 18 "supervisor NO_GO blocks worker"
else
  fail_fixture 18 "NO_GO not enforced: $OUTPUT"
fi

# 19. Disallowed mode and command string.
reset_mock
make_contract 19
set_json "$TMP/c19.json" mode production-deploy
set +e
MODE_OUTPUT="$(bash "$VALIDATOR" "$TMP/c19.json" 2>&1)"
MODE_STATUS=$?
set -e
make_contract 19
set_json "$TMP/c19.json" validation_command 'rm -rf /'
set +e
COMMAND_OUTPUT="$(bash "$VALIDATOR" "$TMP/c19.json" 2>&1)"
COMMAND_STATUS=$?
set -e
if [ "$MODE_STATUS" -ne 0 ] && [ "$COMMAND_STATUS" -ne 0 ] &&
  [[ "$MODE_OUTPUT" == ARTIFACT_INVALID* ]] && [[ "$COMMAND_OUTPUT" == ARTIFACT_INVALID* ]]; then
  pass 19 "disallowed mode and command rejected by schema allowlist"
else
  fail_fixture 19 "mode/command allowlist failed"
fi

# 20. Secret redaction canary.
reset_mock
make_contract 20
export ASDEV_SECRET_CANARY='ghp_ASDEV_SUPER_SECRET_12345678901234567890'
cat > "$ASDEV_ROOT/prompts/opencode/f20.md" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$ASDEV_SECRET_CANARY"
printf '# Redacted review\n' > "$ASDEV_ROOT/docs/reports/test/report-F20.md"
SH
dispatch_capture "$TMP/c20.json" env
if [ "$STATUS" -eq 0 ] &&
  ! grep -R -F "$ASDEV_SECRET_CANARY" "$ASDEV_ROOT/.state/worker/ASDEV-F20" "$GH_CALL_LOG" >/dev/null; then
  pass 20 "secret canary redacted from state, output, and report"
else
  fail_fixture 20 "secret canary leaked or dispatch failed: $OUTPUT"
fi
unset ASDEV_SECRET_CANARY

# 21. Loop delegates to dispatcher; missing contract cannot become acknowledgement-only done.
reset_mock
make_contract 21 "$REPO_SHA" markdown-report "$TMP/contracts/ASDEV-F21.json"
write_success_mission 21
cat > "$TMP/q21-valid.md" <<'EOF'
- [ ] Integrated task | ID: ASDEV-F21 | Mode: read-only | Repo: auditsystems | Target: vps
EOF
set +e
VALID_LOOP_OUTPUT="$(ASDEV_QUEUE_FILE="$TMP/q21-valid.md" ASDEV_CONTRACTS_DIR="$TMP/contracts" \
  ASDEV_AGENT_LOG_DIR="$TMP/log21-valid" ASDEV_AGENT_STATE_DIR="$TMP/state21-valid" \
  ASDEV_SAFETY_GATE="$TMP/bin/safety-gate" bash "$LOOP" --once --max-jobs 1 2>&1)"
VALID_LOOP_STATUS=$?
set -e
cat > "$TMP/q21-missing.md" <<'EOF'
- [ ] Missing contract | ID: ASDEV-F21-MISSING | Mode: read-only | Repo: auditsystems | Target: vps
EOF
set +e
MISSING_LOOP_OUTPUT="$(ASDEV_QUEUE_FILE="$TMP/q21-missing.md" ASDEV_CONTRACTS_DIR="$TMP/empty-contracts" \
  ASDEV_AGENT_LOG_DIR="$TMP/log21-missing" ASDEV_AGENT_STATE_DIR="$TMP/state21-missing" \
  bash "$LOOP" --dry-run --once --max-jobs 1 2>&1)"
MISSING_LOOP_STATUS=$?
set -e
if [ "$VALID_LOOP_STATUS" -eq 0 ] &&
  grep -q '"state":"done"' "$ASDEV_ROOT/.state/worker/ASDEV-F21/result.json" &&
  [ "$MISSING_LOOP_STATUS" -ne 0 ] &&
  [[ "$MISSING_LOOP_OUTPUT" == *"Missing required contract"* ]] &&
  [[ "$MISSING_LOOP_OUTPUT" != *"completed (legacy)"* ]]; then
  pass 21 "loop uses dispatcher and acknowledgement cannot become done"
else
  fail_fixture 21 "loop integration or no-ack invariant failed: $VALID_LOOP_OUTPUT / $MISSING_LOOP_OUTPUT"
fi

# 22. Issue #45 dry-run validates contract and performs no GitHub mutation.
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
  bash "$LOOP" --dry-run --once --max-jobs 1 --issue 45 2>&1)"
STATUS=$?
set -e
if [ "$STATUS" -eq 0 ] &&
  [[ "$OUTPUT" == *"contract validated; would dispatch"* ]] &&
  [[ "$OUTPUT" == *"command bus skipped; no GitHub reads or writes"* ]] &&
  [ ! -e "$ASDEV_ROOT/f22-worker-ran" ] &&
  [ ! -e "$ASDEV_ROOT/.state/worker/ASDEV-F22" ] &&
  ! grep -q . "$GH_CALL_LOG"; then
  pass 22 "Issue #45 dry-run has no worker, state, or GitHub mutation"
else
  fail_fixture 22 "Issue #45 dry-run mutated state or GitHub: $OUTPUT"
fi

printf '\nFixtures passed: %s/22\n' "$PASSES"
if [ "$FAILURES" -ne 0 ] || [ "$PASSES" -ne 22 ]; then
  printf 'Fixtures failed: %s\n' "$FAILURES"
  exit 1
fi
printf 'ALL 22 REQUIRED REAL FIXTURES PASS\n'
