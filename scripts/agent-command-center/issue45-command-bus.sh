#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ASDEV_AGENT_STATE_DIR="${ASDEV_AGENT_STATE_DIR:-${ASDEV_ROOT}/.state/asdev-agent-loop}"
STATE_FILE="${ASDEV_AGENT_STATE_DIR}/state.json"
COMMAND_BUS_STATE="${ASDEV_AGENT_STATE_DIR}/command-bus.json"
WATCHER_STATE="${ASDEV_AGENT_STATE_DIR}/watcher-state.json"
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

load_watcher_state() {
  if [ -f "$WATCHER_STATE" ]; then
    LAST_PR_HASH=$(grep -o '"pr_hash":"[^"]*"' "$WATCHER_STATE" 2>/dev/null | cut -d'"' -f4 || echo "")
    LAST_VPS_TIMER=$(grep -o '"vps_timer":"[^"]*"' "$WATCHER_STATE" 2>/dev/null | cut -d'"' -f4 || echo "")
    LAST_BLOCKER_HASH=$(grep -o '"blocker_hash":"[^"]*"' "$WATCHER_STATE" 2>/dev/null | cut -d'"' -f4 || echo "")
    LAST_SUCCESSFUL_RUN=$(grep -o '"last_successful_run":"[^"]*"' "$WATCHER_STATE" 2>/dev/null | cut -d'"' -f4 || echo "")
  else
    LAST_PR_HASH=""
    LAST_VPS_TIMER=""
    LAST_BLOCKER_HASH=""
    LAST_SUCCESSFUL_RUN=""
  fi
}

save_watcher_state() {
  local pr_hash="$1"
  local vps_timer="$2"
  local blocker_hash="$3"
  local success_run="$4"
  cat > "$WATCHER_STATE" <<EOF
{
  "pr_hash": "${pr_hash}",
  "vps_timer": "${vps_timer}",
  "blocker_hash": "${blocker_hash}",
  "last_successful_run": "${success_run}",
  "last_check": "${TIMESTAMP}"
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

  log "Executing: ${cmd} (by ${author})"

  case "$cmd" in
    STATUS)
      post_status_report
      ;;
    STOP)
      systemctl --user stop asdev-agent-loop.timer 2>/dev/null || true
      systemctl --user disable asdev-agent-loop.timer 2>/dev/null || true
      post_to_issue "**ASDEV stopped** by ${author}. Timer disabled. Run \`[ASDEV SAFE-MODE]\` to re-enable."
      ;;
    SAFE-MODE)
      systemctl --user enable --now asdev-agent-loop.timer 2>/dev/null || true
      post_to_issue "**ASDEV safe-mode timer re-enabled** by ${author}."
      ;;
    RUN)
      log "Run command: ${arg}"
      local queue_file="${ASDEV_ROOT}/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"
      local task_id="CMD-${comment_id}"
      local task_line="- [ ] ${task_id} — ${arg} | Mode: read-only | Repo: alirezasafaei-dev/alirezasafaeisystems | Target: vps"
      if [ -f "$queue_file" ]; then
        echo "$task_line" >> "$queue_file"
        log "Queued task ${task_id} for next loop iteration"
        post_to_issue "**ASDEV task queued** (${task_id}): ${arg}

Task appended to active queue. The next loop iteration (timer-driven) will claim and execute it."
      else
        warn "Queue file not found at ${queue_file} — cannot queue task"
        post_to_issue "**ASDEV run deferred**: ${arg}

Queue file missing. Task not queued."
      fi
      ;;
    REPORT)
      post_status_report
      ;;
    *)
      warn "Unknown command: ${cmd}"
      ;;
  esac
}

check_pr_changes() {
  gh pr list --repo "$REPO" --state open --json number,title,updatedAt --jq '.[:5] | [.[] | "\(.number):\(.updatedAt)"] | join(",")' 2>/dev/null || echo ""
}

check_vps_timer() {
  if systemctl --user is-active asdev-agent-loop.timer >/dev/null 2>&1; then
    echo "active"
  else
    echo "inactive"
  fi
}

check_blockers() {
  local blocker_list=""
  local pr21_state
  pr21_state=$(gh pr view 21 --repo alirezasafaei-dev/auditsystems --json state --jq '.state' 2>/dev/null || echo "unknown")
  if [ "$pr21_state" = "OPEN" ]; then
    blocker_list="PR#21:open"
  fi
  echo "$blocker_list"
}

post_status_report() {
  local timer_status
  timer_status=$(check_vps_timer)

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

  local pr_changes
  pr_changes=$(check_pr_changes)

  local blockers
  blockers=$(check_blockers)

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
| Open PRs | ${pr_changes:-none} |
| Blockers | ${blockers:-none} |
| Last report | ${LAST_REPORT_AT:-never} |

Commands: \`[ASDEV STATUS]\` \`[ASDEV STOP]\` \`[ASDEV SAFE-MODE]\` \`[ASDEV RUN <task>]\`"

  post_to_issue "$report"
}

autonomous_watcher() {
  log "Running autonomous watcher"

  local current_pr_hash
  current_pr_hash=$(check_pr_changes | md5sum | cut -d' ' -f1)

  local current_vps_timer
  current_vps_timer=$(check_vps_timer)

  local current_blockers
  current_blockers=$(check_blockers)
  local current_blocker_hash
  current_blocker_hash=$(echo "$current_blockers" | md5sum | cut -d' ' -f1)

  local current_success_run=""
  if [ -f "$STATE_FILE" ]; then
    current_success_run=$(grep -o '"last_success_at":"[^"]*"' "$STATE_FILE" 2>/dev/null | cut -d'"' -f4 || echo "")
  fi

  local changed=false
  local changes=""

  if [ "$current_pr_hash" != "$LAST_PR_HASH" ] && [ -n "$LAST_PR_HASH" ]; then
    changed=true
    changes="${changes}- PR state changed\n"
  fi

  if [ "$current_vps_timer" != "$LAST_VPS_TIMER" ] && [ -n "$LAST_VPS_TIMER" ]; then
    changed=true
    changes="${changes}- VPS timer: ${LAST_VPS_TIMER} -> ${current_vps_timer}\n"
  fi

  if [ "$current_blocker_hash" != "$LAST_BLOCKER_HASH" ] && [ -n "$LAST_BLOCKER_HASH" ]; then
    changed=true
    changes="${changes}- Blocker status changed\n"
  fi

  if [ "$current_success_run" != "$LAST_SUCCESSFUL_RUN" ] && [ -n "$current_success_run" ]; then
    changed=true
    changes="${changes}- New successful run detected\n"
  fi

  save_watcher_state "$current_pr_hash" "$current_vps_timer" "$current_blocker_hash" "$current_success_run"

  if $changed; then
    log "Changes detected — posting report"
    local change_report="**ASDEV Watcher — Changes Detected** — ${TIMESTAMP}

$(echo -e "$changes")

Run \`[ASDEV STATUS]\` for full status."
    post_to_issue "$change_report"
  else
    log "No changes — staying silent"
  fi
}

post_to_issue() {
  local body="$1"
  gh issue comment "$ISSUE_NUMBER" --repo "$REPO" --body "$body" 2>/dev/null || warn "Failed to post to Issue #${ISSUE_NUMBER}"
}

log "=== ASDEV Command Bus + Watcher ==="
log "Issue: #${ISSUE_NUMBER}"
log "Repo: ${REPO}"
log "Timestamp: ${TIMESTAMP}"
echo ""

load_bus_state
load_watcher_state

log "Last processed comment: ${LAST_COMMENT_ID}"

NEW_COMMANDS=$(fetch_new_commands "$LAST_COMMENT_ID")

if [ -n "$NEW_COMMANDS" ]; then
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
else
  log "No new commands"
fi

autonomous_watcher

log "Command bus cycle complete"
