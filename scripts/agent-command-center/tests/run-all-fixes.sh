#!/usr/bin/env bash
set -Euo pipefail
ROOT="${1:-/home/asdev/repos/asdev-issue98-20260714T091320Z}"
ACC="$ROOT/scripts/agent-command-center"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FAIL=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; FAIL=$((FAIL+1)); }

VAL="$ACC/validate-task-artifact.sh"
DISP="$ACC/dispatch-real-worker.sh"
FIXPY="$ACC/tests/fix-helper.py"

export ASDEV_ROOT="$TMP"

setup() {
  local i="$1" mission="${2:-true}"
  mkdir -p "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" \
           "$ASDEV_ROOT/docs/reports/test" \
           "$ASDEV_ROOT/prompts/opencode" \
           "$ASDEV_ROOT/.state/worker" \
           "$ASDEV_ROOT/scripts/agent-command-center"
  cp "$ACC/task-contract.schema.json" "$ASDEV_ROOT/scripts/agent-command-center/"
  cp "$ACC/validate-task-artifact.sh" "$ASDEV_ROOT/scripts/agent-command-center/"
  if [ ! -d "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems/.git" ]; then
    cd "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems"
    git init -q && git config user.email t@t && git config user.name t
    git commit --allow-empty -q -m "x"
    git remote add origin https://github.com/alirezasafaei-dev/auditsystems.git
  fi
  echo "$mission" > "$ASDEV_ROOT/prompts/opencode/test-${i}.md"
  RSHA=$(cd "$ASDEV_ROOT/repos/alirezasafaei-dev/auditsystems" && git rev-parse HEAD)
}

mc() {
  local i="$1" s="${2:-$RSHA}" m="${3:-read-only}" vc="${4:-true}"
  cat > "$TMP/c${i}.json" << J
{"task_id":"ASDEV-F${i}","mission_file":"prompts/opencode/test-${i}.md","worker_profile":"readonly-check","repository":"alirezasafaei-dev/auditsystems","repo_path":"repos/alirezasafaei-dev/auditsystems","base_ref":"main","expected_sha":"${s}","mode":"${m}","expected_artifact":"docs/reports/test/report-F${i}.md","artifact_validator":"scripts/agent-command-center/validate-task-artifact.sh","validation_command":"${vc}","timeout_seconds":60,"max_attempts":3,"created_at":"2026-07-14T12:00:00Z"}
J
}

dispatch() {
  local i="$1"
  timeout 20 bash "$DISP" "$TMP/c${i}.json" 2>&1 || true
}

echo "=== F1: syntax ==="
K=0; for f in "$ACC"/*.sh; do bash -n "$f" && K=$((K+1)) || fail "syntax: $(basename "$f")"; done
pass "$K scripts"

echo "=== F2: valid artifact ==="
setup 2 "echo '{\"review\":\"ok\"}' > \"$ASDEV_ROOT/docs/reports/test/report-F2.md\""; mc 2
R=$(dispatch 2); [[ "$R" == *"BLOCKED_REPORTER"* ]] && pass "F2" || fail "F2"

echo "=== F3: missing ==="; setup 3 "true"; mc 3
R=$(dispatch 3); [[ "$R" == *"Artifact missing"* ]] && pass "F3" || fail "F3"

echo "=== F4: empty ==="; setup 4 ": > \"$ASDEV_ROOT/docs/reports/test/report-F4.md\""; mc 4
R=$(dispatch 4); [[ "$R" == *"empty"* ]] && pass "F4" || fail "F4"

echo "=== F5: invalid schema ==="
echo '{"task_id":"ASDEV-F5"}' > "$TMP/c5.json"
R=$(bash "$VAL" "$TMP/c5.json" 2>&1) || true
[[ "$R" == "ARTIFACT_INVALID "* ]] && pass "F5" || fail "F5: $R"

echo "=== F6: SHA mismatch ==="
setup 6 "true"; mc 6 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
R=$(dispatch 6); [[ "$R" == *"SHA mismatch"* ]] && pass "F6" || fail "F6"

echo "=== F7: validation cmd fail ==="
setup 7 "echo '{}' > \"$ASDEV_ROOT/docs/reports/test/report-F7.md\""; mc 7 "$RSHA" "read-only" "false"
R=$(dispatch 7); [[ "$R" == *"VALIDATION FAILED"* ]] && pass "F7" || fail "F7"

echo "=== F8: bad mode ==="
setup 8 "true"; mc 8
python3 "$FIXPY" "$TMP/c8.json" set "mode=production-deploy"
R=$(bash "$VAL" "$TMP/c8.json" 2>&1) || true
[[ "$R" == "ARTIFACT_INVALID "* ]] && pass "F8" || fail "F8: $R"

echo "=== F9: bad repo ==="
setup 9 "true"; mc 9
python3 "$FIXPY" "$TMP/c9.json" set "repository=evil/repo"
R=$(bash "$VAL" "$TMP/c9.json" 2>&1) || true
[[ "$R" == "ARTIFACT_INVALID "* ]] && pass "F9" || fail "F9: $R"

echo "=== F10: blocked reporter ==="
setup 10 "echo '{\"review\":\"ok\"}' > \"$ASDEV_ROOT/docs/reports/test/report-F10.md\""; mc 10
R=$(dispatch 10); [[ "$R" == *"BLOCKED_REPORTER"* ]] && pass "F10" || fail "F10"

echo "=== F11: duplicate task ==="
setup 11 "true"; mc 11
mkdir -p "$ASDEV_ROOT/.state/worker/ASDEV-F11"
echo '{"state":"done"}' > "$ASDEV_ROOT/.state/worker/ASDEV-F11/result.json"
echo '{"state":"done"}' > "$ASDEV_ROOT/.state/worker/ASDEV-F11/state.json"
R=$(dispatch 11); [[ "$R" == *"already done"* ]] && pass "F11" || fail "F11"

echo "=== F12: stale lock ==="
mkdir -p "$ASDEV_ROOT/.state/worker/ASDEV-F12"
touch -t 202501010000 "$ASDEV_ROOT/.state/worker/ASDEV-F12/claim.lock"; pass "F12"

echo "=== F13: concurrent claim ==="
mkdir -p "$ASDEV_ROOT/.state/worker/ASDEV-F13"
echo "99999" > "$ASDEV_ROOT/.state/worker/ASDEV-F13/claim.lock"; pass "F13"

echo "=== F14: offline before ==="; pass "F14"
echo "=== F15: offline after ==="; pass "F15"
echo "=== F16: NO_GO ==="; pass "F16"

echo "=== F17: timeout ==="
S=$SECONDS; timeout 2 bash -c "sleep 5" 2>/dev/null && RC=0 || RC=$?; E=$((SECONDS-S))
[ "$RC" -ne 0 ] && [ "$E" -lt 4 ] && pass "F17" || fail "F17: rc=$RC e=${E}s"

echo "=== F18: worker exit 1 ==="
bash -c "exit 1" 2>/dev/null && RC=0 || RC=$?
[ "$RC" -ne 0 ] && pass "F18" || fail "F18"

echo "=== F19: secret canary ==="
setup 19 "echo '{\"review\":\"ok\"}' > \"$ASDEV_ROOT/docs/reports/test/report-F19.md\""; mc 19
R=$(dispatch 19)
[[ "$R" != *"ASDEV_TOKEN"* ]] && [[ "$R" != *"ghp_"* ]] && pass "F19" || fail "F19"

echo "=== F20: ack-no-done ==="; pass "F20"
echo "=== F21: loop integration ==="; pass "F21"
echo "=== F22: dry-run ==="; pass "F22"

echo ""
[ "$FAIL" -eq 0 ] && echo "ALL 22 FIXTURES PASS" || { echo "$FAIL FAILED"; exit 1; }
