#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ASDEV_AGENT_STATE_DIR="${ASDEV_AGENT_STATE_DIR:-${ASDEV_ROOT}/.state/asdev-agent-loop}"
STATE_FILE="${ASDEV_AGENT_STATE_DIR}/state.json"
COMMAND_BUS_STATE="${ASDEV_AGENT_STATE_DIR}/command-bus.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[CMD-BUS]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }

ISSUE_NUMBER="${1:-45}"
REPO="${2:-alirezasafaei-dev/alirezasafaeisystems}"

mkdir -p "$ASDEV_AGENT_STATE_DIR"

load_bus_state() {
  if [ -f "$COMMAND_BUS_STATE" ]; then
    LAST_COMMENT_ID=$(grep -o '"last_comment_id":"[^"]*"' "$COMMAND_BUS_STATE" 2>/dev/null | cut -d'"' -f4 || echo "0")
    LAST_REPORT_AT=$(grep -o '"last_report_at":"[^"]*"' "$COMMAND_BUS_STATE" 2>/dev/null | cut -d'"' -f4 || echo "")
    LAST_COMMAND=$(grep -o '"last_command":"[^"]*"' "$COMMAND_BUS_STATE" 2>/dev/null | cut -d'"' -f4 || echo "")
  else
    LAST_COMMENT_ID="0"
    LAST_REPORT_AT=""
    LAST_COMMAND=""
  fi
}

save_bus_state() {
  local comment_id="$1"
  local command="$2"
  cat > "$COMMAND_BUS_STATE" <<EOF
{
  "last_comment_id": "${comment_id}",
  "last_report_at": "${TIMESTAMP}",
  "last_command": "${command}"
}
EOF
}

fetch_new_commands() {
  local since_id="$1"
  gh api "repos/${REPO}/issues/${ISSUE_NUMBER}/comments" --paginate --jq ".[] | select(.id > ${since_id}) | \"\(.id)|\(.user.login)|\(.body)\"" 2>/dev/null || echo ""
}

parse_command() {
  local body="$1"
  local cmd=""
  local arg=""

  if echo "$body" | grep -qiE '^\[ASDEV RUN\]'; then
    cmd="RUN"
    arg=$(echo "$body" | sed 's/^\[ASDEV RUN\]\s*//' | head -1)
  elif echo "$body" | grep -qiE '^\[ASDEV STATUS\]'; then
    cmd="STATUS"
  elif echo "$body" | grep -qiE '^\[ASDEV STOP\]'; then
    cmd="STOP"
  elif echo "$body" | grep -qiE '^\[ASDEV SAFE-MODE\]'; then
    cmd="SAFE-MODE"
  elif echo "$body" | grep -qiE '^\[ASDEV REPORT\]'; then
    cmd="REPORT"
  fi

  echo "${cmd}|${arg}"
}

execute_command() {
  local cmd="$1"
  local arg="$2"
  local comment_id="$3"
  local author="$4"

  log "Executing command: ${cmd} (by ${author})"

  case "$cmd" in
    STATUS)
      post_status_report
      ;;
    STOP)
      log "Stop command received — disabling timer"
      systemctl --user stop asdev-agent-loop.timer 2>/dev/null || true
      systemctl --user disable asdev-agent-loop.timer 2>/dev/null || true
      post_to_issue "ASDEV stopped by ${author}. Timer disabled. Run [ASDEV SAFE-MODE] to re-enable."
      ;;
    SAFE-MODE)
      log "Safe-mode command received — enabling timer"
      systemctl --user enable --now asdev-agent-loop.timer 2>/dev/null || true
      post_to_issue "ASDEV safe-mode timer re-enabled by ${author}."
      ;;
    RUN)
      log "Run command received: ${arg}"
      bash "${SCRIPT_DIR}/run-autonomous-loop.sh" --issue "$ISSUE_NUMBER" --max-jobs 2 --once 2>&1 | tail -5
      post_to_issue "ASDEV run completed: ${arg}"
      ;;
    REPORT)
      post_status_report
      ;;
    *)
      warn "Unknown command: ${cmd}"
      ;;
  esac
}

post_status_report() {
  local timer_status="inactive"
  if systemctl --user is-active asdev-agent-loop.timer >/dev/null 2>&1; then
    timer_status="active"
  fi

  local linger="unknown"
  linger=$(loginctl show-user "$USER" -p Linger 2>/dev/null | cut -d= -f2 || echo "unknown")

  local network="down"
  if getent hosts github.com >/dev/null 2>&1; then
    network="ok"
  fi

  local gh_auth="no"
  if gh auth status >/dev/null 2>&1; then
    gh_auth="yes"
  fi

  local failures="0"
  if [ -f "$STATE_FILE" ]; then
    failures=$(grep -o '"consecutive_failures":[0-9]*' "$STATE_FILE" 2>/dev/null | cut -d: -f2 || echo "0")
  fi

  local queue_pending="0"
  local queue_done="0"
  local QUEUE_FILE="${ASDEV_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"
  if [ -f "$QUEUE_FILE" ]; then
    queue_pending=$(grep -c "^\- \[ \]" "$QUEUE_FILE" 2>/dev/null || echo "0")
    queue_done=$(grep -c "^\- \[x\]" "$QUEUE_FILE" 2>/dev/null || echo "0")
  fi

  local report="**ASDEV Status Report** — ${TIMESTAMP}

| Component | Status |
|---|---|
| Timer | ${timer_status} |
| Linger | ${linger} |
| Network | ${network} |
| GitHub auth | ${gh_auth} |
| Consecutive failures | ${failures} |
| Queue pending | ${queue_pending} |
| Queue done | ${queue_done} |
| Last report | ${LAST_REPORT_AT:-never} |

Commands: \`[ASDEV STATUS]\` \`[ASDEV STOP]\` \`[ASDEV SAFE-MODE]\` \`[ASDEV RUN <task>]\`"

  post_to_issue "$report"
}

post_to_issue() {
  local body="$1"
  gh issue comment "$ISSUE_NUMBER" --repo "$REPO" --body "$body" 2>/dev/null || warn "Failed to post to Issue #${ISSUE_NUMBER}"
}

log "=== ASDEV Command Bus ==="
log "Issue: #${ISSUE_NUMBER}"
log "Repo: ${REPO}"
log "Timestamp: ${TIMESTAMP}"
echo ""

load_bus_state
log "Last processed comment: ${LAST_COMMENT_ID}"

NEW_COMMANDS=$(fetch_new_commands "$LAST_COMMENT_ID")

if [ -z "$NEW_COMMANDS" ]; then
  log "No new commands"
  save_bus_state "$LAST_COMMENT_ID" ""
  exit 0
fi

log "New commands found"
MAX_COMMENT_ID="$LAST_COMMENT_ID"

while IFS='|' read -r comment_id author body; do
  [ -z "$comment_id" ] && continue

  PARSED=$(parse_command "$body")
  CMD=$(echo "$PARSED" | cut -d'|' -f1)
  ARG=$(echo "$PARSED" | cut -d'|' -f2)

  if [ -n "$CMD" ]; then
    execute_command "$CMD" "$ARG" "$comment_id" "$author"
    save_bus_state "$comment_id" "$CMD"
  fi

  if [ "$comment_id" -gt "$MAX_COMMENT_ID" ] 2>/dev/null; then
    MAX_COMMENT_ID="$comment_id"
  fi
done <<< "$NEW_COMMANDS"

save_bus_state "$MAX_COMMENT_ID" ""
log "Command bus cycle complete"
