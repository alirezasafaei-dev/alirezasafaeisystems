#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AUDITSYSTEMS_DIR="${WORKSPACE_ROOT}/sites/live/auditsystems"
LOG_DIR="${WORKSPACE_ROOT}/ops/automation-logs"
STATE_DIR="${WORKSPACE_ROOT}/.state/asdev-agent-loop"
LOCK_DIR="/tmp/asdev-agent-loop"
LOCK_FILE="${LOCK_DIR}/asdev-agent-loop.lock"
STATE_FILE="${STATE_DIR}/state.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

DRY_RUN=false
MAX_JOBS=3
ONCE=false
ISSUE=""
SIMULATE_OFFLINE=false

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
    --simulate-offline) SIMULATE_OFFLINE=true; shift ;;
    *) shift ;;
  esac
done

mkdir -p "$LOG_DIR" "$STATE_DIR" "$LOCK_DIR"
LOG_FILE="${LOG_DIR}/loop-$(date -u +%Y-%m-%d).log"
exec > >(tee -a "$LOG_FILE") 2>&1

acquire_lock() {
  if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
      log "Another loop is running (PID ${OLD_PID}). Exiting."
      exit 0
    else
      warn "Stale lock found (PID ${OLD_PID}). Removing."
      rm -f "$LOCK_FILE"
    fi
  fi
  echo $$ > "$LOCK_FILE"
  trap 'rm -f "$LOCK_FILE"' EXIT
}

load_state() {
  if [ -f "$STATE_FILE" ]; then
    CONSECUTIVE_FAILURES=$(grep -o '"consecutive_failures":[0-9]*' "$STATE_FILE" 2>/dev/null | cut -d: -f2 || echo "0")
    CONSECUTIVE_FAILURES=${CONSECUTIVE_FAILURES:-0}
  else
    CONSECUTIVE_FAILURES=0
  fi
}

save_state() {
  local failures="$1"
  cat > "$STATE_FILE" <<EOF
{
  "last_run_at": "${TIMESTAMP}",
  "last_success_at": "${failures}" == "0" && "${TIMESTAMP}" || "",
  "consecutive_failures": ${failures}
}
EOF
}

check_network() {
  if $SIMULATE_OFFLINE; then
    warn "Simulating offline mode"
    return 1
  fi
  getent hosts github.com >/dev/null 2>&1 && \
  curl -fsS --max-time 5 https://api.github.com/rate_limit >/dev/null 2>&1 && \
  gh auth status >/dev/null 2>&1
}

circuit_breaker_check() {
  if [ "$CONSECUTIVE_FAILURES" -ge 5 ]; then
    fail "Circuit breaker: 5 consecutive failures. Stopping loop."
    fail "Owner review required."
    save_state "$CONSECUTIVE_FAILURES"
    exit 1
  fi
  if [ "$CONSECUTIVE_FAILURES" -ge 3 ]; then
    warn "Circuit breaker: 3 consecutive failures. Only read-only/docs-only tasks."
    return 1
  fi
  return 0
}

execute_job() {
  local task_id="$1"
  local task_title="$2"
  local mode="$3"
  local repo="$4"

  section "Executing: ${task_id} — ${task_title}"

  if ! $DRY_RUN; then
    SAFETY=$(bash "${SCRIPT_DIR}/agent-safety-gate.sh" "$repo" "$mode" 2>&1)
    if [ $? -ne 0 ]; then
      fail "Safety gate blocked ${task_id}"
      return 1
    fi
  fi

  case "$mode" in
    read-only)
      log "Read-only task ${task_id}"
      ;;
    test-only|product-branch)
      if [ -d "$AUDITSYSTEMS_DIR/node_modules" ] && command -v pnpm >/dev/null 2>&1; then
        cd "$AUDITSYSTEMS_DIR"
        TYPECHECK=$(pnpm typecheck 2>&1 && echo "PASS" || echo "FAIL")
        LINT=$(pnpm lint 2>&1 && echo "PASS" || echo "FAIL")
        if echo "$TYPECHECK" | grep -q "PASS" && echo "$LINT" | grep -q "PASS"; then
          ok "Validation passed for ${task_id}"
        else
          fail "Validation failed for ${task_id}"
          return 1
        fi
      else
        warn "Skipping validation (no node_modules or pnpm)"
      fi
      ;;
    docs-only|automation-script)
      log "Task ${task_id} — no heavy validation needed"
      ;;
  esac

  ok "Task ${task_id} completed"
  return 0
}

section "ASDEV Autonomous Execution Loop"
log "Timestamp: ${TIMESTAMP}"
log "Dry-run: ${DRY_RUN}"
log "Max jobs: ${MAX_JOBS}"
log "Once: ${ONCE}"
log "Issue: ${ISSUE:-none}"
log "Simulate-offline: ${SIMULATE_OFFLINE}"
echo ""

acquire_lock
load_state
circuit_breaker_check || true

if ! check_network; then
  warn "Network unavailable. Skipping this cycle."
  save_state "$CONSECUTIVE_FAILURES"
  exit 0
fi

ok "Network OK"

JOBS_EXECUTED=0
JOBS_FAILED=0

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
    TASK_TITLE=$(echo "$line" | sed 's/^- \[ \] //' | sed 's/|.*//' | xargs)
    MODE=$(echo "$line" | grep -oP 'Mode:\s*\K\S+' || echo "read-only")
    REPO=$(echo "$line" | grep -oP 'Repo:\s*\K\S+' || echo "auditsystems")
    EXEC_TARGET=$(echo "$line" | grep -oP 'Target:\s*\K\S+' || echo "vps")

    if [ "$EXEC_TARGET" = "local-heavy" ]; then
      warn "Task ${TASK_ID} requires local execution — skipping on VPS"
      warn "Run locally: ./scripts/agent-command-center/local-heavy-runner.sh ${TASK_ID}"
      PROCESSED=$((PROCESSED + 1))
      continue
    fi

    if ! circuit_breaker_check 2>/dev/null && [ "$MODE" = "product-branch" ]; then
      warn "Circuit breaker active — skipping product-branch task ${TASK_ID}"
      continue
    fi

    execute_job "$TASK_ID" "$TASK_TITLE" "$MODE" "$REPO" && {
      JOBS_EXECUTED=$((JOBS_EXECUTED + 1))
      CONSECUTIVE_FAILURES=0
    } || {
      JOBS_FAILED=$((JOBS_FAILED + 1))
      CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    }

    PROCESSED=$((PROCESSED + 1))
    if $ONCE; then break; fi
  done < <(grep "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || true)
else
  warn "No queue file found at ${QUEUE_FILE}"
fi

section "Loop Summary"
log "Jobs executed: ${JOBS_EXECUTED}"
log "Jobs failed: ${JOBS_FAILED}"
log "Consecutive failures: ${CONSECUTIVE_FAILURES}"

save_state "$CONSECUTIVE_FAILURES"

if [ "$JOBS_FAILED" -gt 0 ]; then
  fail "Loop completed with ${JOBS_FAILED} failures"
  exit 1
else
  ok "Loop completed successfully"
  exit 0
fi
