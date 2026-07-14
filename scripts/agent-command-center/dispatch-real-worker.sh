#!/usr/bin/env bash
set -Euo pipefail

ACC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${ASDEV_ROOT:-$(cd "${ACC_DIR}/../.." && pwd)}"
VALIDATOR="${ACC_DIR}/validate-task-artifact.sh"
WORKER_LOG="${ROOT}/ops/automation-logs/worker-$(date -u +%Y%m%d).log"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$WORKER_LOG")"
log() {
  printf '[%s] %s\n' "$TS" "$*" | tee -a "$WORKER_LOG"
}

fail() {
  local reason="$1"
  log "FATAL: $reason"
  printf 'DISPATCH_FAILED %s\n' "$reason"
  exit 1
}

CONTRACT_FILE="${1:?usage: dispatch-real-worker.sh <contract.json>}"
[ -f "$CONTRACT_FILE" ] || fail "contract-not-found"
[ -x "$VALIDATOR" ] || fail "validator-not-executable"

set +e
CONTRACT_VALIDATION_OUTPUT="$(bash "$VALIDATOR" "$CONTRACT_FILE" 2>&1)"
CONTRACT_VALIDATION_EXIT=$?
set -e
if [ "$CONTRACT_VALIDATION_EXIT" -ne 0 ]; then
  fail "contract-validation $CONTRACT_VALIDATION_OUTPUT"
fi
log "Contract validation: $CONTRACT_VALIDATION_OUTPUT"

read_contract() {
  python3 - "$CONTRACT_FILE" "$1" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)[sys.argv[2]]
print(value)
PY
}

TASK_ID="$(read_contract task_id)"
MISSION_FILE="$(read_contract mission_file)"
WORKER_PROFILE="$(read_contract worker_profile)"
REPOSITORY="$(read_contract repository)"
REPO_PATH="$(read_contract repo_path)"
BASE_REF="$(read_contract base_ref)"
EXPECTED_SHA="$(read_contract expected_sha)"
MODE="$(read_contract mode)"
EXPECTED_ARTIFACT="$(read_contract expected_artifact)"
ARTIFACT_VALIDATOR="$(read_contract artifact_validator)"
VALIDATION_ID="$(read_contract validation_command)"
TIMEOUT_SECONDS="$(read_contract timeout_seconds)"
MAX_ATTEMPTS="$(read_contract max_attempts)"

path_within_root() {
  local candidate="$1"
  local resolved
  resolved="$(realpath -m "$candidate")"
  case "$resolved" in
    "$ROOT"|"$ROOT"/*) printf '%s\n' "$resolved" ;;
    *) return 1 ;;
  esac
}

REPO_DIR="$(path_within_root "$ROOT/$REPO_PATH")" || fail "repo-path-escape"
MISSION_PATH="$(path_within_root "$ROOT/$MISSION_FILE")" || fail "mission-path-escape"
ARTIFACT_PATH="$(path_within_root "$ROOT/$EXPECTED_ARTIFACT")" || fail "artifact-path-escape"
ARTIFACT_VALIDATOR_PATH="$(path_within_root "$ROOT/$ARTIFACT_VALIDATOR")" || fail "validator-path-escape"

if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "repo-not-git:$REPO_DIR"
fi

normalize_remote() {
  local url="$1"
  local slug=""
  case "$url" in
    https://github.com/*|http://github.com/*)
      slug="${url#*://github.com/}"
      ;;
    git@github.com:*)
      slug="${url#git@github.com:}"
      ;;
    ssh://git@github.com/*)
      slug="${url#ssh://git@github.com/}"
      ;;
    *)
      return 1
      ;;
  esac
  slug="${slug%/}"
  slug="${slug%.git}"
  printf '%s\n' "$slug"
}

REMOTE_URL="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)"
REMOTE_SLUG="$(normalize_remote "$REMOTE_URL" 2>/dev/null || true)"
case "$REMOTE_SLUG" in
  alirezasafaei-dev/alirezasafaeisystems|alirezasafaei-dev/auditsystems) ;;
  *) fail "remote-not-allowlisted:$REMOTE_URL" ;;
esac
[ "$REMOTE_SLUG" = "$REPOSITORY" ] || fail "remote-contract-mismatch:$REMOTE_SLUG"

ACTUAL_SHA="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || true)"
[ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || fail "sha-mismatch expected=$EXPECTED_SHA actual=$ACTUAL_SHA"
BASE_SHA="$(git -C "$REPO_DIR" rev-parse "${BASE_REF}^{commit}" 2>/dev/null || true)"
[ -n "$BASE_SHA" ] || fail "base-ref-not-found:$BASE_REF"
git -C "$REPO_DIR" merge-base --is-ancestor "$BASE_SHA" "$ACTUAL_SHA" >/dev/null 2>&1 || \
  fail "base-ref-not-ancestor:$BASE_REF"

BRANCH_NAME="$(git -C "$REPO_DIR" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [ -n "$BRANCH_NAME" ] && [ -n "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" ]; then
  fail "dirty-worktree:$BRANCH_NAME"
fi

if [ "${ASDEV_OFFLINE_STAGE:-}" = "before" ]; then
  fail "offline-before-worker"
fi

SUPERVISOR_GATE_FILE="${ASDEV_SUPERVISOR_GATE_FILE:-$ROOT/.state/supervisor/verdict}"
if [ -f "$SUPERVISOR_GATE_FILE" ] && grep -Eq '^[[:space:]]*NO_GO[[:space:]]*$' "$SUPERVISOR_GATE_FILE"; then
  fail "supervisor-no-go"
fi

STATE_DIR="$ROOT/.state/worker/$TASK_ID"
CLAIM_DIR="$STATE_DIR/claim.lock"
STATE_FILE="$STATE_DIR/state.json"
RESULT_FILE="$STATE_DIR/result.json"
RETRY_FILE="$STATE_DIR/attempt"
REPORT_RECEIPT="$STATE_DIR/report-receipt.txt"
LOCK_ACQUIRED=0
FINALIZED=0

mkdir -p "$STATE_DIR" "$(dirname "$ARTIFACT_PATH")"

is_done() {
  [ -s "$STATE_FILE" ] && [ -s "$RESULT_FILE" ] &&
    python3 - "$STATE_FILE" "$RESULT_FILE" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as state_file:
    state = json.load(state_file)
with open(sys.argv[2], encoding="utf-8") as result_file:
    result = json.load(result_file)
raise SystemExit(0 if state.get("state") == "done" and result.get("state") == "done" else 1)
PY
}

if is_done; then
  fail "duplicate-task:$TASK_ID"
fi

if ! mkdir "$CLAIM_DIR" 2>/dev/null; then
  LOCK_AGE="$(( $(date +%s) - $(stat -c %Y "$CLAIM_DIR" 2>/dev/null || printf '0') ))"
  if [ "$LOCK_AGE" -lt 3600 ]; then
    fail "concurrent-claim age=${LOCK_AGE}s"
  fi
  LOCK_PID="$(cat "$CLAIM_DIR/pid" 2>/dev/null || true)"
  if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
    fail "concurrent-claim pid=$LOCK_PID"
  fi
  rm -f "$CLAIM_DIR/pid"
  rmdir "$CLAIM_DIR" 2>/dev/null || fail "stale-claim-not-empty"
  mkdir "$CLAIM_DIR" 2>/dev/null || fail "claim-race-lost"
  log "Reclaimed stale claim age=${LOCK_AGE}s"
fi
LOCK_ACQUIRED=1
printf '%s\n' "$$" > "$CLAIM_DIR/pid"

atom_write() {
  local target="$1"
  local tmp="${target}.tmp.$$"
  cat > "$tmp"
  mv -f "$tmp" "$target"
}

cleanup() {
  local rc=$?
  trap - EXIT INT TERM HUP
  if [ "$LOCK_ACQUIRED" -eq 1 ]; then
    rm -f "$CLAIM_DIR/pid"
    rmdir "$CLAIM_DIR" 2>/dev/null || true
  fi
  if [ "$rc" -ne 0 ] && [ "$FINALIZED" -eq 0 ] && [ -d "$STATE_DIR" ]; then
    atom_write "$STATE_FILE" <<EOF || true
{"task_id":"$TASK_ID","state":"failed","reason":"unexpected-exit","ended_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF
  fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

if is_done; then
  fail "duplicate-task-after-claim:$TASK_ID"
fi

ATTEMPT=1
if [ -s "$RETRY_FILE" ]; then
  PREVIOUS_ATTEMPT="$(cat "$RETRY_FILE")"
  [[ "$PREVIOUS_ATTEMPT" =~ ^[0-9]+$ ]] || fail "invalid-attempt-state"
  ATTEMPT="$((PREVIOUS_ATTEMPT + 1))"
fi
if [ "$ATTEMPT" -gt "$MAX_ATTEMPTS" ]; then
  fail "max-attempts:$MAX_ATTEMPTS"
fi

printf '%s\n' "$ATTEMPT" > "$RETRY_FILE.tmp.$$"
mv -f "$RETRY_FILE.tmp.$$" "$RETRY_FILE"

atom_write "$STATE_FILE" <<EOF
{"task_id":"$TASK_ID","state":"claimed","attempt":$ATTEMPT,"repository":"$REPOSITORY","expected_sha":"$EXPECTED_SHA","mode":"$MODE","started_at":"$TS"}
EOF

RUNNING_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
atom_write "$STATE_FILE" <<EOF
{"task_id":"$TASK_ID","state":"running","attempt":$ATTEMPT,"repository":"$REPOSITORY","expected_sha":"$EXPECTED_SHA","mode":"$MODE","started_at":"$RUNNING_TS"}
EOF

EFFECTIVE_TIMEOUT="$TIMEOUT_SECONDS"
if [ "${ASDEV_TEST_MODE:-0}" = "1" ] && [[ "${ASDEV_TEST_TIMEOUT_SECONDS:-}" =~ ^[1-9][0-9]*$ ]]; then
  EFFECTIVE_TIMEOUT="$ASDEV_TEST_TIMEOUT_SECONDS"
fi

EXIT_CODE=0
CAPTURED_OUTPUT=""
WORKER_VERSION="unknown"
case "$WORKER_PROFILE" in
  opencode)
    OPENCODE_BIN=""
    for candidate in /home/asdev/.opencode/bin/opencode /usr/local/bin/opencode /usr/bin/opencode; do
      if [ -x "$candidate" ]; then
        OPENCODE_BIN="$candidate"
        break
      fi
    done
    if [ -z "$OPENCODE_BIN" ]; then
      OPENCODE_BIN="$(command -v opencode 2>/dev/null || true)"
    fi
    if [ -z "$OPENCODE_BIN" ]; then
      EXIT_CODE=127
      CAPTURED_OUTPUT="opencode not found"
    else
      WORKER_VERSION="$("$OPENCODE_BIN" --version 2>&1 | head -n 1 | tr -cd 'A-Za-z0-9._ -')"
      [ -f "$MISSION_PATH" ] || fail "mission-not-found:$MISSION_FILE"
      MISSION_TEXT="$(cat "$MISSION_PATH")

Required output artifact: $ARTIFACT_PATH
Repository: $REPOSITORY
Expected commit: $EXPECTED_SHA
Mode: $MODE"
      set +e
      CAPTURED_OUTPUT="$(timeout "$EFFECTIVE_TIMEOUT" "$OPENCODE_BIN" run --dir "$REPO_DIR" --auto "$MISSION_TEXT" 2>&1)"
      EXIT_CODE=$?
      set -e
    fi
    ;;
  readonly-check)
    [ -f "$MISSION_PATH" ] || fail "mission-not-found:$MISSION_FILE"
    set +e
    CAPTURED_OUTPUT="$(timeout "$EFFECTIVE_TIMEOUT" bash "$MISSION_PATH" 2>&1)"
    EXIT_CODE=$?
    set -e
    ;;
  *)
    EXIT_CODE=22
    CAPTURED_OUTPUT="unknown worker profile"
    ;;
esac

SANITIZED_OUTPUT="$(printf '%s' "$CAPTURED_OUTPUT" | python3 -c '
import os
import re
import sys
text = sys.stdin.read()
canary = os.environ.get("ASDEV_SECRET_CANARY", "")
if canary:
    text = text.replace(canary, "[REDACTED]")
patterns = [
    r"ghp_[A-Za-z0-9]{20,}",
    r"github_pat_[A-Za-z0-9_]{20,}",
    r"sk-[A-Za-z0-9_-]{20,}",
]
for pattern in patterns:
    text = re.sub(pattern, "[REDACTED]", text)
sys.stdout.write(text)
')"
printf '%s\n' "$SANITIZED_OUTPUT" > "$STATE_DIR/output.log.tmp.$$"
mv -f "$STATE_DIR/output.log.tmp.$$" "$STATE_DIR/output.log"

END_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
atom_write "$STATE_FILE" <<EOF
{"task_id":"$TASK_ID","state":"validation","attempt":$ATTEMPT,"worker_exit":$EXIT_CODE,"started_at":"$RUNNING_TS","ended_at":"$END_TS"}
EOF

ARTIFACT_VALID=0
ARTIFACT_HASH=""
VALIDATOR_EXIT=-1
VALIDATION_OUTPUT=""
if [ "$EXIT_CODE" -eq 0 ] && [ -x "$ARTIFACT_VALIDATOR_PATH" ]; then
  set +e
  VALIDATION_OUTPUT="$(ASDEV_ROOT="$ROOT" bash "$ARTIFACT_VALIDATOR_PATH" "$CONTRACT_FILE" "$ARTIFACT_PATH" 2>&1)"
  VALIDATOR_EXIT=$?
  set -e
  if [ "$VALIDATOR_EXIT" -eq 0 ]; then
    ARTIFACT_HASH="$(sha256sum "$ARTIFACT_PATH" | awk '{print $1}')"
    ARTIFACT_VALID=1
  fi
fi

REPORT_PUBLISHED="no"
REPORT_REASON=""
REPORT_URL=""
atom_write "$STATE_FILE" <<EOF
{"task_id":"$TASK_ID","state":"reporting","attempt":$ATTEMPT,"worker_exit":$EXIT_CODE,"artifact_valid":$ARTIFACT_VALID,"artifact_hash":"$ARTIFACT_HASH","validator_exit":$VALIDATOR_EXIT,"started_at":"$RUNNING_TS","ended_at":"$END_TS"}
EOF

if [ "$ARTIFACT_VALID" -eq 1 ]; then
  if [ "${ASDEV_OFFLINE_STAGE:-}" = "after" ]; then
    REPORT_REASON="offline-after-worker"
  elif ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
    REPORT_REASON="blocked-reporter"
  else
    set +e
    REPORT_URL="$(gh issue comment 98 --repo alirezasafaei-dev/alirezasafaeisystems --body "Acceptance task complete
Task: $TASK_ID
Worker: $WORKER_PROFILE
Worker version: $WORKER_VERSION
Repository: $REPOSITORY
SHA: $EXPECTED_SHA
Artifact: $EXPECTED_ARTIFACT
Artifact SHA256: $ARTIFACT_HASH
Validated: yes
Worker exit: $EXIT_CODE
Validator exit: $VALIDATOR_EXIT" 2>&1)"
    REPORT_EXIT=$?
    set -e
    if [ "$REPORT_EXIT" -eq 0 ]; then
      REPORT_PUBLISHED="yes"
      printf '%s\n' "$REPORT_URL" > "$REPORT_RECEIPT.tmp.$$"
      mv -f "$REPORT_RECEIPT.tmp.$$" "$REPORT_RECEIPT"
    else
      REPORT_REASON="report-publish-failed"
    fi
  fi
else
  REPORT_REASON="artifact-or-worker-invalid"
fi

if [ "$ARTIFACT_VALID" -eq 1 ] && [ "$REPORT_PUBLISHED" = "yes" ]; then
  FINAL_STATE="done"
else
  FINAL_STATE="failed"
fi

atom_write "$STATE_FILE" <<EOF
{"task_id":"$TASK_ID","state":"$FINAL_STATE","reason":"$REPORT_REASON","attempt":$ATTEMPT,"worker_exit":$EXIT_CODE,"artifact_valid":$ARTIFACT_VALID,"artifact_hash":"$ARTIFACT_HASH","validator_exit":$VALIDATOR_EXIT,"report_published":"$REPORT_PUBLISHED","started_at":"$RUNNING_TS","ended_at":"$END_TS"}
EOF
atom_write "$RESULT_FILE" <<EOF
{"task_id":"$TASK_ID","state":"$FINAL_STATE","reason":"$REPORT_REASON","attempt":$ATTEMPT,"worker_profile":"$WORKER_PROFILE","worker_version":"$WORKER_VERSION","worker_exit":$EXIT_CODE,"artifact_path":"$ARTIFACT_PATH","artifact_hash":"$ARTIFACT_HASH","artifact_valid":$ARTIFACT_VALID,"validator_exit":$VALIDATOR_EXIT,"validation_id":"$VALIDATION_ID","report_published":"$REPORT_PUBLISHED","repository":"$REPOSITORY","expected_sha":"$EXPECTED_SHA","mode":"$MODE","started_at":"$RUNNING_TS","ended_at":"$END_TS"}
EOF

FINALIZED=1
rm -f "$CLAIM_DIR/pid"
rmdir "$CLAIM_DIR"
LOCK_ACQUIRED=0

if [ "$FINAL_STATE" = "done" ]; then
  printf 'DISPATCH_OK %s artifact=%s\n' "$TASK_ID" "$ARTIFACT_HASH"
  exit 0
fi

if [ "$REPORT_REASON" = "blocked-reporter" ] || [ "$REPORT_REASON" = "offline-after-worker" ] || [ "$REPORT_REASON" = "report-publish-failed" ]; then
  printf 'BLOCKED_REPORTER %s artifact=%s\n' "$REPORT_REASON" "$ARTIFACT_HASH"
fi
printf 'DISPATCH_FAILED %s worker=%s validator=%s artifact=%s report=%s\n' \
  "$REPORT_REASON" "$EXIT_CODE" "$VALIDATOR_EXIT" "$ARTIFACT_VALID" "$REPORT_PUBLISHED"
exit 1
