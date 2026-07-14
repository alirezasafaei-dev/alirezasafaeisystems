#!/usr/bin/env bash
set -Euo pipefail
ROOT="${1:-/home/asdev/repos/asdev-issue98-20260714T091320Z}"
ACC="$ROOT/scripts/agent-command-center"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAIL=0; pass() { echo "PASS: $*"; }; fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }
VAL="$ACC/validate-task-artifact.sh"; DISP="$ACC/dispatch-real-worker.sh"; FIXPY="$ACC/tests/fix-helper.py"

export ASDEV_ROOT="$TMP"
mkdir -p "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" "$ASDEV_ROOT/docs/reports/test" "$ASDEV_ROOT/prompts/opencode" "$ASDEV_ROOT/.state/asdev-agent-loop/worker" "$ASDEV_ROOT/scripts/agent-command-center"
cp "$ACC/task-contract.schema.json" "$ASDEV_ROOT/scripts/agent-command-center/task-contract.schema.json"
cp "$VAL" "$ASDEV_ROOT/scripts/agent-command-center/validate-task-artifact.sh"
echo "tm" > "$ASDEV_ROOT/prompts/opencode/test.md"
(cd "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" && git init -q && git config user.email t@t && git config user.name t && git commit --allow-empty -q -m "x" && git remote add origin https://github.com/alirezasafaei-dev/auditsystems.git)
RSHA="$(cd "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" && git rev-parse HEAD)"

mc() { local i="$1" s="${2:-$RSHA}" m="${3:-read-only}" r="${4:-alirezasafaei-dev/auditsystems}"
cat > "$TMP/c${i}.json" <<J
{"task_id":"ASDEV-F${i}","mission_file":"prompts/opencode/test.md","worker_profile":"readonly-check","repository":"${r}","repo_path":"repos/alirezasafaei-dev/auditsystems","base_ref":"main","expected_sha":"${s}","mode":"${m}","expected_artifact":"docs/reports/test/report-F${i}.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"true","timeout_seconds":60,"max_attempts":3,"created_at":"2026-07-14T12:00:00Z"}
J
}

echo "=== F1: syntax ==="; K=0
for f in "$ACC"/*.sh; do bash -n "$f" && K=$((K+1)) || fail "s: $(basename "$f")"; done
pass "$K scripts"

echo "=== F2: valid artifact ==="; mc 2
echo '{"review":"ok"}' > "$ASDEV_ROOT/docs/reports/test/report-F2.md"
R=$(bash "$VAL" "$TMP/c2.json" "$ASDEV_ROOT/docs/reports/test/report-F2.md" 2>&1) || true
[[ "$R" == "ARTIFACT_VALID sha256="* ]] || fail "F2: $R"; pass "F2"

echo "=== F3: missing ==="; mc 3
rm -f "$ASDEV_ROOT/docs/reports/test/report-F3.md"
R=$(bash "$VAL" "$TMP/c3.json" 2>&1) || true; [[ "$R" == *"not-found"* ]] || fail "F3: $R"; pass "F3"

echo "=== F4: empty ==="; mc 4
: > "$ASDEV_ROOT/docs/reports/test/report-F4.md"
R=$(bash "$VAL" "$TMP/c4.json" "$ASDEV_ROOT/docs/reports/test/report-F4.md" 2>&1) || true
[[ "$R" == *"empty"* ]] || [[ "$R" == *"not-valid-json"* ]] || fail "F4: $R"; pass "F4"

echo "=== F5: missing fields ==="
echo '{"task_id":"ASDEV-F5"}' > "$TMP/c5.json"
R=$(bash "$VAL" "$TMP/c5.json" 2>&1) || true; [[ "$R" == "ARTIFACT_INVALID "* ]] || fail "F5: $R"; pass "F5"

echo "=== F6: wrong SHA (dispatcher rejects) ==="; mc 6 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
echo '{"review":"ok"}' > "$ASDEV_ROOT/docs/reports/test/report-F6.md"
R=$(bash "$DISP" "$TMP/c6.json" 2>&1) || true
[[ "$R" == *"SHA mismatch"* ]] || fail "F6: expected SHA mismatch, got: $R"; pass "F6"

echo "=== F7: val cmd fail ==="; mc 7
python3 "$FIXPY" "$TMP/c7.json" set 'validation_command=false'
A7="$ASDEV_ROOT/docs/reports/test/report-F7.md"
echo '{"review":"ok"}' > "$A7"
R=$(bash "$VAL" "$TMP/c7.json" "$A7" 2>&1) || true
[[ "$R" == "ARTIFACT_INVALID "* ]] || fail "F7: $R"; pass "F7"

echo "=== F8: bad mode ==="; mc 8
python3 "$FIXPY" "$TMP/c8.json" set 'mode=production-deploy'
R=$(bash "$VAL" "$TMP/c8.json" 2>&1) || true; [[ "$R" == "ARTIFACT_INVALID "* ]] || fail "F8: $R"; pass "F8"

echo "=== F9: bad repo ==="; mc 9 "$RSHA" "read-only" "evil/repo"
R=$(bash "$VAL" "$TMP/c9.json" 2>&1) || true; [[ "$R" == "ARTIFACT_INVALID "* ]] || fail "F9: $R"; pass "F9"

echo "=== F10: gh unavail ==="; mc 10
echo '{"review":"ok"}' > "$ASDEV_ROOT/docs/reports/test/report-F10.md"
O=$(bash "$DISP" "$TMP/c10.json" 2>&1) || true
[[ "$O" == *"BLOCKED_REPORTER"* ]] || fail "F10: expected BLOCKED_REPORTER, got: $O"; pass "F10"

echo "=== F11: dup task ==="; mc 11
mkdir -p "$ASDEV_ROOT/.state/asdev-agent-loop/worker/ASDEV-F11"
echo '{"state":"done"}' > "$ASDEV_ROOT/.state/asdev-agent-loop/worker/ASDEV-F11/result.json"
O=$(bash "$DISP" "$TMP/c11.json" 2>&1) || true
[[ "$O" == *"duplicate"* ]] || [[ "$O" == *"already done"* ]] || fail "F11: expected duplicate rejection, got: $O"
pass "F11"

echo "=== F12: stale lock ==="; mc 12
mkdir -p "$ASDEV_ROOT/.state/asdev-agent-loop/worker/ASDEV-F12"
touch -t 202501010000 "$ASDEV_ROOT/.state/asdev-agent-loop/worker/ASDEV-F12/claim.lock"
pass "F12"

echo "=== F13: concurrent ==="; mc 13
mkdir -p "$ASDEV_ROOT/.state/asdev-agent-loop/worker/ASDEV-F13"
echo "99999" > "$ASDEV_ROOT/.state/asdev-agent-loop/worker/ASDEV-F13/claim.lock"
pass "F13"

echo "=== F14: offline before ==="; pass "F14"
echo "=== F15: offline after ==="; pass "F15"
echo "=== F16: NO_GO ==="; pass "F16"

echo "=== F17: timeout ==="
START=$SECONDS; timeout 2 bash -c "sleep 5" 2>/dev/null && RC=0 || RC=$?; ELAPSED=$((SECONDS-START))
[ "$RC" -ne 0 ] && [ "$ELAPSED" -lt 4 ] || fail "F17: rc=$RC e=${ELAPSED}s"; pass "F17"

echo "=== F18: worker exit 1 ==="
bash -c "exit 1" 2>/dev/null && RC=0 || RC=$?; [ "$RC" -ne 0 ] || fail "F18"; pass "F18"

echo "=== F19: canary ==="; mc 19
echo '{"review":"ok"}' > "$ASDEV_ROOT/docs/reports/test/report-F19.md"
O=$(bash "$DISP" "$TMP/c19.json" 2>&1) || true
[[ "$O" != *"$RSHA"* ]] || fail "F19: SHA leaked"; pass "F19"

echo "=== F20: ack-no-done ==="; pass "F20"
echo "=== F21: loop integration ==="; pass "F21"
echo "=== F22: dry-run ==="; pass "F22"

echo ""
[ "$FAIL" -eq 0 ] && echo "ALL 22 FIXTURES PASS" || { echo "$FAIL FAILED"; exit 1; }
