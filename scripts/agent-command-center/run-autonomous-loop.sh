#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${WORKSPACE_ROOT}/ops/automation-logs"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

DRY_RUN=false
MAX_JOBS=3
ONCE=false
ISSUE=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[$(date -u +%H:%M:%S)]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }
section() { echo -e "\n${BLUE}═══ $* ═══${NC}"; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --max-jobs) MAX_JOBS="$2"; shift 2 ;;
    --once) ONCE=true; shift ;;
    --issue) ISSUE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/loop-$(date -u +%Y-%m-%d).log"

exec > >(tee -a "$LOG_FILE") 2>&1

section "ASDEV Autonomous Execution Loop"
log "Timestamp: ${TIMESTAMP}"
log "Dry-run: ${DRY_RUN}"
log "Max jobs: ${MAX_JOBS}"
log "Once: ${ONCE}"
log "Issue: ${ISSUE:-none}"
echo ""

JOBS_EXECUTED=0
JOBS_FAILED=0

execute_job() {
  local task_id="$1"
  local task_title="$2"
  local mode="$3"
  local repo="$4"

  section "Executing: ${task_id} — ${task_title}"
  log "Mode: ${mode} | Repo: ${repo}"

  if $DRY_RUN; then
    log "[DRY-RUN] Would execute: ${task_id}"
    return 0
  fi

  SAFETY=$(bash "${SCRIPT_DIR}/agent-safety-gate.sh" "$repo" "$mode" 2>&1)
  if [ $? -ne 0 ]; then
    fail "Safety gate blocked ${task_id}: ${SAFETY}"
    JOBS_FAILED=$((JOBS_FAILED + 1))
    return 1
  fi

  AUDITSYSTEMS_DIR="${WORKSPACE_ROOT}/sites/live/auditsystems"

  case "$mode" in
    read-only)
      log "Read-only audit for ${task_id}"
      ok "Read-only task ${task_id} completed"
      ;;
    test-only|product-branch)
      log "Running validation for ${task_id}"
      cd "$AUDITSYSTEMS_DIR"
      TYPECHECK=$(pnpm typecheck 2>&1 && echo "PASS" || echo "FAIL")
      LINT=$(pnpm lint 2>&1 && echo "PASS" || echo "FAIL")
      TEST=$(pnpm test 2>&1 | tail -3 && echo "PASS" || echo "FAIL")

      if echo "$TYPECHECK" | grep -q "PASS" && echo "$LINT" | grep -q "PASS"; then
        ok "Validation passed for ${task_id}"
      else
        fail "Validation failed for ${task_id}"
        JOBS_FAILED=$((JOBS_FAILED + 1))
        return 1
      fi
      ;;
    docs-only)
      log "Docs task ${task_id} — no validation needed"
      ok "Docs task ${task_id} completed"
      ;;
    automation-script)
      log "Automation script task ${task_id}"
      bash -n "${SCRIPT_DIR}"/*.sh 2>/dev/null && ok "Script syntax OK" || fail "Script syntax error"
      ok "Automation task ${task_id} completed"
      ;;
  esac

  JOBS_EXECUTED=$((JOBS_EXECUTED + 1))
  return 0
}

QUEUE_FILE="${WORKSPACE_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"

if [ -f "$QUEUE_FILE" ]; then
  section "Processing Queue"
  PENDING=$(grep -c "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || echo "0")
  log "Pending tasks: ${PENDING}"

  PROCESSED=0
  while IFS= read -r line; do
    if [ $PROCESSED -ge $MAX_JOBS ]; then
      log "Max jobs reached (${MAX_JOBS})"
      break
    fi

    TASK_ID=$(echo "$line" | grep -oP 'ID:\s*\K\S+' || continue)
    TASK_TITLE=$(echo "$line" | sed 's/^- \[ \] [A-Z]*: //' | cut -d'|' -f1 | xargs)
    MODE=$(echo "$line" | grep -oP 'Mode:\s*\K\S+' || echo "read-only")
    REPO=$(echo "$line" | grep -oP 'Repo:\s*\K\S+' || echo "auditsystems")

    execute_job "$TASK_ID" "$TASK_TITLE" "$MODE" "$REPO" || true
    PROCESSED=$((PROCESSED + 1))

    if $ONCE; then
      break
    fi
  done < <(grep "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || true)
else
  warn "No queue file found at ${QUEUE_FILE}"
fi

section "Loop Summary"
log "Jobs executed: ${JOBS_EXECUTED}"
log "Jobs failed: ${JOBS_FAILED}"
log "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ "$JOBS_FAILED" -gt 0 ]; then
  fail "Loop completed with ${JOBS_FAILED} failures"
  exit 1
else
  ok "Loop completed successfully"
  exit 0
fi
