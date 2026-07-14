#!/usr/bin/env bash
set -Euo pipefail

ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
WORKER_LOG="${ROOT}/ops/automation-logs/worker-$(date -u +%Y%m%d).log"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

log() { echo "[$TS] $*" | tee -a "$WORKER_LOG"; }

CONTRACT_FILE="${1:?usage: dispatch-real-worker.sh <task-contract.json>}"
CONTRACT=$(cat "$CONTRACT_FILE")

task_id=$(echo "$CONTRACT" | jq -r '.task_id')
worker_profile=$(echo "$CONTRACT" | jq -r '.worker_profile')
repository=$(echo "$CONTRACT" | jq -r '.repository')
repo_path=$(echo "$CONTRACT" | jq -r '.repo_path')
expected_sha=$(echo "$CONTRACT" | jq -r '.expected_sha')
mode=$(echo "$CONTRACT" | jq -r '.mode')
expected_artifact=$(echo "$CONTRACT" | jq -r '.expected_artifact')
timeout_seconds=$(echo "$CONTRACT" | jq -r '.timeout_seconds')

log "task_id=$task_id worker=$worker_profile repo=$repository sha=$expected_sha"

STATE_DIR="${ROOT}/.state/worker/${task_id}"
mkdir -p "$STATE_DIR"
echo "$CONTRACT" > "$STATE_DIR/contract.json"

ARTIFACT_PATH="${ROOT}/${expected_artifact}"
EXIT_CODE=""
CAPTURED_OUTPUT=""
WORKER_VERSION=""

case "$worker_profile" in
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
      log "OpenCode binary: $OPENCODE_BIN version=$WORKER_VERSION"
      START_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MISSION_TEXT="Review AuditSystems main for security, privacy, migration safety, lifecycle integrity, CI truth, and release readiness. Do not modify files. Do not access Production."
      set +e
      CAPTURED_OUTPUT=$(timeout "$timeout_seconds" "$OPENCODE_BIN" run --dir "$repo_path" --auto "$MISSION_TEXT" 2>&1)
      EXIT_CODE=$?
      set -e
      END_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      echo "$CAPTURED_OUTPUT" > "$STATE_DIR/output.log"
    fi
    ;;
  readonly-check)
    MISSION_FILE="$ROOT/prompts/opencode/review-mission.md"
    log "Read-only check from $MISSION_FILE"
    START_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MISSION_TEXT="Review AuditSystems main for security, privacy, migration safety, lifecycle integrity, CI truth, and release readiness. Do not modify files. Do not access Production."
    set +e
    CAPTURED_OUTPUT=$(timeout "$timeout_seconds" bash "$MISSION_FILE" 2>&1)
    EXIT_CODE=$?
    set -e
    END_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "$CAPTURED_OUTPUT" > "$STATE_DIR/output.log"
    ;;
  *)
    log "ERROR: unknown worker_profile: $worker_profile"
    EXIT_CODE=22
    ;;
esac

ARTIFACT_VALID=0
ARTIFACT_HASH=""
if [ -f "$ARTIFACT_PATH" ] && [ -s "$ARTIFACT_PATH" ]; then
  ARTIFACT_HASH=$(sha256sum "$ARTIFACT_PATH" | cut -d' ' -f1)
  log "Artifact exists: $ARTIFACT_PATH ($ARTIFACT_HASH)"
  ARTIFACT_VALID=1
else
  log "WARNING: Artifact missing or empty: $ARTIFACT_PATH"
fi

cat > "$STATE_DIR/result.json" << RESTRJ
{
  "task_id": "$task_id",
  "worker_profile": "$worker_profile",
  "worker_version": "${WORKER_VERSION:-unknown}",
  "started_at": "${START_TS:-null}",
  "ended_at": "${END_TS:-null}",
  "exit_code": ${EXIT_CODE:-0},
  "artifact_path": "$ARTIFACT_PATH",
  "artifact_hash": "${ARTIFACT_HASH:-null}",
  "artifact_valid": ${ARTIFACT_VALID},
  "repository": "$repository",
  "expected_sha": "$expected_sha",
  "mode": "$mode"
}
RESTRJ

log "Worker completed: exit=${EXIT_CODE:-0} artifact_valid=$ARTIFACT_VALID"
if [ "${EXIT_CODE:-0}" -ne 0 ] || [ "$ARTIFACT_VALID" -ne 1 ]; then
  echo "WORKER_FAILED exit=${EXIT_CODE:-0} artifact=$ARTIFACT_VALID"
  log "WORKER_FAILED exit=${EXIT_CODE:-0} artifact=$ARTIFACT_VALID"
  exit 1
fi

echo "WORKER_OK $task_id artifact=$ARTIFACT_HASH"
log "WORKER_OK $task_id artifact=$ARTIFACT_HASH"
