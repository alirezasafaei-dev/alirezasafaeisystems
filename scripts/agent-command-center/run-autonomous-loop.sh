#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ASDEV_ROOT="${ASDEV_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ASDEV_SYSTEMS_DIR="${ASDEV_SYSTEMS_DIR:-${ASDEV_ROOT}/sites/live/alirezasafaeisystems}"
AUDITSYSTEMS_DIR="${AUDITSYSTEMS_DIR:-${ASDEV_SYSTEMS_DIR}/../auditsystems}"
ASDEV_AGENT_LOG_DIR="${ASDEV_AGENT_LOG_DIR:-${ASDEV_ROOT}/ops/automation-logs}"
ASDEV_AGENT_STATE_DIR="${ASDEV_AGENT_STATE_DIR:-${ASDEV_ROOT}/.state/asdev-agent-loop}"
ASDEV_QUEUE_FILE="${ASDEV_QUEUE_FILE:-${ASDEV_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md}"
ASDEV_ALLOWED_MODES="${ASDEV_ALLOWED_MODES:-read-only,docs-only,automation-script}"
ASDEV_BLOCK_PRODUCT_VALIDATION="${ASDEV_BLOCK_PRODUCT_VALIDATION:-false}"

LOCK_DIR="/tmp/asdev-agent-loop"
LOCK_FILE="${LOCK_DIR}/asdev-agent-loop.lock"
STATE_FILE="${ASDEV_AGENT_STATE_DIR}/state.json"
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

mkdir -p "$ASDEV_AGENT_LOG_DIR" "$ASDEV_AGENT_STATE_DIR" "$LOCK_DIR"
LOG_FILE="${ASDEV_AGENT_LOG_DIR}/loop-$(date -u +%Y-%m-%d).log"
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
  local success_at=""
  if [ "$failures" -eq 0 ]; then
    success_at="${TIMESTAMP}"
  fi
  cat > "$STATE_FILE" <<EOF
{
  "last_run_at": "${TIMESTAMP}",
  "last_success_at": "${success_at}",
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
  curl -fsS --max-time 5 https://api.github.com/rate_limit >/dev/null 2>&1
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

is_mode_allowed() {
  local mode="$1"
  IFS=',' read -ra ALLOWED <<< "$ASDEV_ALLOWED_MODES"
  for am in "${ALLOWED[@]}"; do
    if [ "$am" = "$mode" ]; then
      return 0
    fi
  done
  return 1
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
      if [ "$ASDEV_BLOCK_PRODUCT_VALIDATION" = "true" ]; then
        warn "Product validation blocked by ASDEV_BLOCK_PRODUCT_VALIDATION — skipping"
        return 0
      fi
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
log "Root: ${ASDEV_ROOT}"
log "Queue: ${ASDEV_QUEUE_FILE}"
log "Allowed modes: ${ASDEV_ALLOWED_MODES}"
log "Block product validation: ${ASDEV_BLOCK_PRODUCT_VALIDATION}"
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
JOBS_SKIPPED=0

if [ -f "$ASDEV_QUEUE_FILE" ]; then
  section "Processing Queue"
  PENDING=$(grep -c "^\- \[ \]" "$ASDEV_QUEUE_FILE" 2>/dev/null || echo "0")
  log "Pending tasks: ${PENDING}"

  PROCESSED=0
  while IFS= read -r line; do
    if [ $PROCESSED -ge $MAX_JOBS ]; then
      log "Max jobs reached (${MAX_JOBS})"
      break
    fi

    TASK_ID=$(echo "$line" | grep -oP 'ID:\s*\K\S+' || continue)
    TASK_TITLE=$(echo "$line" | sed 's/^- \[.\] //' | sed 's/|.*//' | xargs)
    MODE=$(echo "$line" | grep -oP 'Mode:\s*\K\S+' || echo "read-only")
    REPO=$(echo "$line" | grep -oP 'Repo:\s*\K\S+' || echo "auditsystems")
    EXEC_TARGET=$(echo "$line" | grep -oP 'Target:\s*\K\S+' || echo "vps")

    if [ "$EXEC_TARGET" = "local-heavy" ]; then
      warn "Task ${TASK_ID} requires local execution — skipping"
      PROCESSED=$((PROCESSED + 1))
      JOBS_SKIPPED=$((JOBS_SKIPPED + 1))
      continue
    fi

    if ! is_mode_allowed "$MODE"; then
      warn "Task ${TASK_ID} mode '${MODE}' not in allowed modes (${ASDEV_ALLOWED_MODES}) — deferred"
      PROCESSED=$((PROCESSED + 1))
      JOBS_SKIPPED=$((JOBS_SKIPPED + 1))
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
  done < <(grep "^\- \[ \]" "$ASDEV_QUEUE_FILE" 2>/dev/null || true)
else
  warn "No queue file found at ${ASDEV_QUEUE_FILE}"
fi

section "Loop Summary"
log "Jobs executed: ${JOBS_EXECUTED}"
log "Jobs failed: ${JOBS_FAILED}"
log "Jobs skipped: ${JOBS_SKIPPED}"
log "Consecutive failures: ${CONSECUTIVE_FAILURES}"

save_state "$CONSECUTIVE_FAILURES"

if [ "$JOBS_FAILED" -gt 0 ]; then
  fail "Loop completed with ${JOBS_FAILED} failures"
  exit 1
else
  ok "Loop completed successfully"
  exit 0
fi
