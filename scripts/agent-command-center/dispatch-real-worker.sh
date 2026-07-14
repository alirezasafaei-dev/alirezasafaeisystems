#!/usr/bin/env bash
set -Euo pipefail

ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
ACC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER_LOG="${ROOT}/ops/automation-logs/worker-$(date -u +%Y%m%d).log"
mkdir -p "$(dirname "$WORKER_LOG")"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
log() { echo "[$TS] $*" | tee -a "$WORKER_LOG"; }

CONTRACT_FILE="${1:?usage: dispatch-real-worker.sh <contract.json>}"
test -f "$CONTRACT_FILE" || { log "FATAL: contract not found"; exit 1; }
CONTRACT_RAW="$(cat "$CONTRACT_FILE")"

###############################################################################
# 1. Deep contract validation (before any field is used)
###############################################################################
VALIDATOR="${ACC_DIR}/validate-task-artifact.sh"
SCHEMA_FILE="${ACC_DIR}/task-contract.schema.json"
VALIDATION_OUTPUT=""
VALIDATION_EXIT=""
if [ -x "$VALIDATOR" ] && [ -f "$SCHEMA_FILE" ]; then
  set +e
  VALIDATION_OUTPUT=$(bash "$VALIDATOR" "$CONTRACT_FILE" 2>&1)
  VALIDATION_EXIT=$?
  set -e
  log "Contract validation: exit=$VALIDATION_EXIT $VALIDATION_OUTPUT"
  if [ "$VALIDATION_EXIT" -ne 0 ]; then
    echo "DISPATCH_FAILED contract-validation $VALIDATION_OUTPUT"
    log "DISPATCH_FAILED contract-validation $VALIDATION_OUTPUT"
    exit 1
  fi
else
  log "FATAL: validator or schema missing"
  exit 1
fi

###############################################################################
# 2. Parse contract fields (safe after validation)
###############################################################################
extract_json_str() {
  local key="$1"
  echo "$CONTRACT_RAW" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',''))" 2>/dev/null || echo ""
}
extract_json_int() {
  local key="$1"
  echo "$CONTRACT_RAW" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key',0))" 2>/dev/null || echo "0"
}

TASK_ID="$(extract_json_str task_id)"
MISSION_FILE="$(extract_json_str mission_file)"
WORKER_PROFILE="$(extract_json_str worker_profile)"
REPOSITORY="$(extract_json_str repository)"
REPO_PATH="$(extract_json_str repo_path)"
BASE_REF="$(extract_json_str base_ref)"
EXPECTED_SHA="$(extract_json_str expected_sha)"
MODE="$(extract_json_str mode)"
EXPECTED_ARTIFACT="$(extract_json_str expected_artifact)"
ARTIFACT_VALIDATOR="$(extract_json_str artifact_validator)"
VALIDATION_COMMAND="$(extract_json_str validation_command)"
TIMEOUT_SECONDS="$(extract_json_int timeout_seconds)"
MAX_ATTEMPTS="$(extract_json_int max_attempts)"

log "task=$TASK_ID worker=$WORKER_PROFILE repo=$REPOSITORY sha=$EXPECTED_SHA mode=$MODE"

###############################################################################
# 3. Repository verification
###############################################################################
REPO_DIR="$ROOT/$REPO_PATH"
if [ ! -d "$REPO_DIR/.git" ]; then
  log "FATAL: repo_path is not a git repository: $REPO_DIR"
  exit 1
fi
REMOTE_URL="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")"
ALLOWED="alirezasafaei-dev/alirezasafaeisystems alirezasafaei-dev/auditsystems"
MATCH=0
for r in $ALLOWED; do
  case "$REMOTE_URL" in
    *"$r"*) MATCH=1 ;;
  esac
done
if [ "$MATCH" -ne 1 ]; then
  log "FATAL: remote $REMOTE_URL not in allowlist"
  exit 1
fi
log "Remote verified: $REMOTE_URL"

# Enforce detached or clean worktree
IS_DETACHED="$(git -C "$REPO_PATH" symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")"
if [ "$IS_DETACHED" != "DETACHED" ]; then
  BRANCH_CLEAN="$(git -C "$REPO_DIR" status --porcelain 2>/dev/null || echo "dirty")"
  if [ -n "$BRANCH_CLEAN" ]; then
    log "FATAL: non-detached and dirty worktree not allowed"
    exit 1
  fi
fi
ACTUAL_SHA="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")"
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  log "FATAL: SHA mismatch expected=$EXPECTED_SHA actual=$ACTUAL_SHA"
  exit 1
fi
log "SHA verified: $ACTUAL_SHA"

###############################################################################
# 4. State machine paths
###############################################################################
STATE_DIR="${ROOT}/.state/worker/${TASK_ID}"
LOCK_FILE="${STATE_DIR}/claim.lock"
STATE_FILE="${STATE_DIR}/state.json"
RESULT_FILE="${STATE_DIR}/result.json"
ARTIFACT_PATH="${ROOT}/${EXPECTED_ARTIFACT}"
RETRY_FILE="${STATE_DIR}/attempt"

mkdir -p "$STATE_DIR" "$(dirname "$ARTIFACT_PATH")"

###############################################################################
# 5. Atomic claim lock with duplicate/concurrent/stale refusal
###############################################################################
if [ -f "$LOCK_FILE" ]; then
  LOCK_PID="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"
  if kill -0 "$LOCK_PID" 2>/dev/null; then
    log "FATAL: claim lock held by PID $LOCK_PID"
    echo "DISPATCH_FAILED concurrent-claim pid=$LOCK_PID"
    exit 1
  fi
  # Stale lock: check age
  LOCK_AGE="$(($(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo "0")))"
  if [ "$LOCK_AGE" -lt 3600 ]; then
    log "FATAL: stale lock younger than 1h (${LOCK_AGE}s), refusing auto-recovery"
    echo "DISPATCH_FAILED stale-lock age=${LOCK_AGE}s"
    exit 1
  fi
  log "WARN: reclaiming stale lock (age=${LOCK_AGE}s)"
fi
echo "$$" > "$LOCK_FILE"
log "Claim lock acquired (PID=$$)"

# Retry accounting
ATTEMPT=1
if [ -f "$RETRY_FILE" ]; then
  ATTEMPT="$(cat "$RETRY_FILE")"
  ATTEMPT=$((ATTEMPT + 1))
fi
echo "$ATTEMPT" > "$RETRY_FILE"
if [ "$ATTEMPT" -gt "$MAX_ATTEMPTS" ] && [ "$MAX_ATTEMPTS" -gt 0 ]; then
  log "FATAL: max attempts ($MAX_ATTEMPTS) exceeded"
  echo "DISPATCH_FAILED max-attempts"
  exit 1
fi
log "Attempt $ATTEMPT/$MAX_ATTEMPTS"

# Duplicate task refusal
if [ -f "$STATE_FILE" ] && [ -f "$RESULT_FILE" ]; then
  PREV_STATE="$(python3 -c "import json,sys; d=json.load(open('$STATE_FILE','r')); print(d.get('state',''))" 2>/dev/null || echo "")"
  if [ "$PREV_STATE" = "done" ]; then
    log "FATAL: task $TASK_ID already done"
    echo "DISPATCH_FAILED duplicate-task"
    exit 1
  fi
fi

###############################################################################
# 6. Write claimed state atomically
###############################################################################
atom_write() {
  local tmp="$1.tmp.$$"
  cat > "$tmp"
  mv "$tmp" "$1"
}

atom_write "$STATE_FILE" << STATEOF
{"task_id":"$TASK_ID","state":"claimed","attempt":$ATTEMPT,"started_at":"$TS","repository":"$REPOSITORY","expected_sha":"$EXPECTED_SHA","mode":"$MODE"}
STATEOF
log "State: claimed"

###############################################################################
# 7. Run worker
###############################################################################
EXIT_CODE=""
CAPTURED_OUTPUT=""
WORKER_VERSION=""
RUNNING_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
atom_write "$STATE_FILE" << STATEOF
{"task_id":"$TASK_ID","state":"running","attempt":$ATTEMPT,"started_at":"$RUNNING_TS","repository":"$REPOSITORY","expected_sha":"$EXPECTED_SHA","mode":"$MODE"}
STATEOF
log "State: running"

case "$WORKER_PROFILE" in
  opencode)
    OPENCODE_BIN=""
    for p in /home/asdev/.opencode/bin/opencode /usr/local/bin/opencode /usr/bin/opencode; do
      [ -x "$p" ] && OPENCODE_BIN="$p" && break
    done
    if [ -z "$OPENCODE_BIN" ]; then
      OPENCODE_BIN="$(command -v opencode 2>/dev/null || echo "")"
    fi
    if [ -z "$OPENCODE_BIN" ]; then
      log "ERROR: opencode not found"
      EXIT_CODE=127
    else
      WORKER_VERSION="$($OPENCODE_BIN --version 2>&1 | head -1 || echo "unknown")"
      MISSION_TEXT=""
      if [ -f "$ROOT/$MISSION_FILE" ]; then
        MISSION_TEXT="$(cat "$ROOT/$MISSION_FILE" | head -20)"
      fi
      if [ -z "$MISSION_TEXT" ]; then
        MISSION_TEXT="Review repository at $REPO_PATH SHA $EXPECTED_SHA. Write review report to $ARTIFACT_PATH."
      fi
      log "OpenCode: $OPENCODE_BIN v$WORKER_VERSION"
      set +e
      CAPTURED_OUTPUT=$(timeout "$TIMEOUT_SECONDS" "$OPENCODE_BIN" run --dir "$REPO_DIR" --auto "$MISSION_TEXT" 2>&1)
      EXIT_CODE=$?
      set -e
      log "OpenCode exit=$EXIT_CODE"
    fi
    ;;
  readonly-check)
    MISSION_SCRIPT="$ROOT/$MISSION_FILE"
    if [ -f "$MISSION_SCRIPT" ]; then
      set +e
      CAPTURED_OUTPUT=$(timeout "$TIMEOUT_SECONDS" bash "$MISSION_SCRIPT" 2>&1)
      EXIT_CODE=$?
      set -e
    else
      log "ERROR: mission file not found: $MISSION_SCRIPT"
      EXIT_CODE=2
    fi
    ;;
  *)
    log "ERROR: unknown worker_profile: $WORKER_PROFILE"
    EXIT_CODE=22
    ;;
esac

END_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "$CAPTURED_OUTPUT" > "$STATE_DIR/output.log" 2>/dev/null || true

###############################################################################
# 8. Validation phase
###############################################################################
atom_write "$STATE_FILE" << STATEOF
{"task_id":"$TASK_ID","state":"validation","attempt":$ATTEMPT,"worker_exit":${EXIT_CODE:- -1},"started_at":"$RUNNING_TS","ended_at":"$END_TS","repository":"$REPOSITORY","expected_sha":"$EXPECTED_SHA","mode":"$MODE"}
STATEOF
log "State: validation"

ARTIFACT_VALID=0
ARTIFACT_HASH=""
VALIDATOR_EXIT=""
VALIDATOR_OUTPUT=""
VALIDATION_EXIT=""
VALIDATION_OUTPUT=""

# Check artifact exists and non-empty
if [ -f "$ARTIFACT_PATH" ] && [ -s "$ARTIFACT_PATH" ]; then
  ARTIFACT_HASH="$(sha256sum "$ARTIFACT_PATH" | cut -d" " -f1)"
  log "Artifact: $ARTIFACT_PATH ($ARTIFACT_HASH)"

  # Execute artifact_validator
  if [ -n "$ARTIFACT_VALIDATOR" ] && [ -x "$ROOT/$ARTIFACT_VALIDATOR" ]; then
    set +e
    VALIDATOR_OUTPUT=$(bash "$ROOT/$ARTIFACT_VALIDATOR" "$CONTRACT_FILE" "$ARTIFACT_PATH" 2>&1)
    VALIDATOR_EXIT=$?
    set -e
    log "Validator exit=$VALIDATOR_EXIT $VALIDATOR_OUTPUT"
  fi

  # Execute validation_command
  if [ -n "$VALIDATION_COMMAND" ]; then
    set +e
    VALIDATION_OUTPUT=$(eval "$VALIDATION_COMMAND" 2>&1)
    VALIDATION_EXIT=$?
    set -e
    log "Validation command exit=$VALIDATION_EXIT"
  fi

  # All checks pass
  if [ "${EXIT_CODE:-0}" -eq 0 ] && \
     [ "${VALIDATOR_EXIT:-0}" -eq 0 ] && \
     [ "${VALIDATION_EXIT:-0}" -eq 0 ]; then
    ARTIFACT_VALID=1
  else
    log "VALIDATION FAILED: worker_exit=${EXIT_CODE:-0} validator=${VALIDATOR_EXIT:-0} validation=${VALIDATION_EXIT:-0}"
  fi
else
  log "Artifact missing or empty: $ARTIFACT_PATH"
fi

###############################################################################
# 9. Reporting phase
###############################################################################
atom_write "$STATE_FILE" << STATEOF
{"task_id":"$TASK_ID","state":"reporting","attempt":$ATTEMPT,"worker_exit":${EXIT_CODE:-0},"artifact_valid":$ARTIFACT_VALID,"artifact_hash":"${ARTIFACT_HASH:-null}","validator_exit":${VALIDATOR_EXIT:--1},"validation_exit":${VALIDATION_EXIT:--1},"started_at":"$RUNNING_TS","ended_at":"$END_TS"}
STATEOF
log "State: reporting"

REPORT_PUBLISHED="no"
if [ "$ARTIFACT_VALID" -eq 1 ]; then
  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    set +e
    gh issue comment 98 --repo alirezasafaei-dev/alirezasafaeisystems \
      --body "## Acceptance task complete

**Task**: ${TASK_ID}
**Worker**: ${WORKER_PROFILE}
**Worker version**: ${WORKER_VERSION:-unknown}
**Repository**: ${REPOSITORY}
**SHA**: ${EXPECTED_SHA}
**Artifact**: ${EXPECTED_ARTIFACT}
**Artifact SHA256**: ${ARTIFACT_HASH}
**Validated**: yes
**Exit code**: ${EXIT_CODE:-0}
**Validator**: ${VALIDATOR_EXIT:--1}
**Validation command**: ${VALIDATION_EXIT:--1}
" 2>&1 || REPORT_PUBLISHED="no"
    set -e
    if [ "$REPORT_PUBLISHED" != "no" ]; then
      REPORT_PUBLISHED="yes"
    fi
  else
    log "BLOCKED_REPORTER: gh not available"
    atom_write "$STATE_FILE" << STATEOF2
{"task_id":"$TASK_ID","state":"failed","reason":"blocked-reporter","attempt":$ATTEMPT,"worker_exit":${EXIT_CODE:-0},"artifact_valid":$ARTIFACT_VALID,"artifact_hash":"${ARTIFACT_HASH:-null}","validator_exit":${VALIDATOR_EXIT:--1},"validation_exit":${VALIDATION_EXIT:--1},"started_at":"$RUNNING_TS","ended_at":"$END_TS"}
STATEOF2
    > "$STATE_DIR/report-blocked-marker"
    log "State: failed (blocked-reporter)"
    echo "DISPATCH_FAILED blocked-reporter artifact=$ARTIFACT_HASH"
    exit 1
  fi
fi

###############################################################################
# 10. Final state
###############################################################################
if [ "$ARTIFACT_VALID" -eq 1 ] && [ "$REPORT_PUBLISHED" = "yes" ]; then
  FINAL_STATE="done"
else
  FINAL_STATE="failed"
fi

atom_write "$STATE_FILE" << STATEOF3
{"task_id":"$TASK_ID","state":"$FINAL_STATE","attempt":$ATTEMPT,"worker_exit":${EXIT_CODE:-0},"artifact_valid":$ARTIFACT_VALID,"artifact_hash":"${ARTIFACT_HASH:-null}","validator_exit":${VALIDATOR_EXIT:--1},"validation_exit":${VALIDATION_EXIT:--1},"report_published":"$REPORT_PUBLISHED","started_at":"$RUNNING_TS","ended_at":"$END_TS"}
STATEOF3

atom_write "$RESULT_FILE" << STATEOF4
{"task_id":"$TASK_ID","state":"$FINAL_STATE","attempt":$ATTEMPT,"worker_profile":"$WORKER_PROFILE","worker_version":"${WORKER_VERSION:-unknown}","worker_exit":${EXIT_CODE:-0},"artifact_path":"$ARTIFACT_PATH","artifact_hash":"${ARTIFACT_HASH:-null}","artifact_valid":$ARTIFACT_VALID,"validator_exit":${VALIDATOR_EXIT:--1},"validation_exit":${VALIDATION_EXIT:--1},"report_published":"$REPORT_PUBLISHED","repository":"$REPOSITORY","expected_sha":"$EXPECTED_SHA","mode":"$MODE","started_at":"$RUNNING_TS","ended_at":"$END_TS"}
STATEOF4

rm -f "$LOCK_FILE"
log "State: $FINAL_STATE (report=${REPORT_PUBLISHED})"

if [ "$FINAL_STATE" = "done" ]; then
  echo "DISPATCH_OK ${TASK_ID} artifact=${ARTIFACT_HASH}"
else
  echo "DISPATCH_FAILED ${FINAL_STATE} exit=${EXIT_CODE:-0} artifact=${ARTIFACT_VALID} report=${REPORT_PUBLISHED}"
  exit 1
fi
