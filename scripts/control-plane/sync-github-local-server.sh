#!/usr/bin/env bash
# ASDEV GitHub / Local / Server sync script
# Keeps LOCAL_PC or AUTOMATION_SERVER aligned with GitHub main without destructive resets.
set -Eeuo pipefail

SCRIPT_NAME="asdev-sync"
ASDEV_ENVIRONMENT="${ASDEV_ENVIRONMENT:-UNKNOWN}"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO_DIR="${ASDEV_REPO_DIR:-$ASDEV_ROOT}"
REMOTE_NAME="${ASDEV_REMOTE_NAME:-origin}"
REMOTE_BRANCH="${ASDEV_REMOTE_BRANCH:-main}"
LOCK_FILE="${ASDEV_SYNC_LOCK:-/tmp/asdev-github-sync.lock}"
LOG_DIR="${ASDEV_LOG_DIR:-$REPO_DIR/ops/automation-logs}"
STATE_DIR="${ASDEV_STATE_DIR:-$REPO_DIR/.state/asdev-sync}"
REPORT_DIR="${ASDEV_REPORT_DIR:-$REPO_DIR/docs/reports/automation-server}"
LOG_FILE="$LOG_DIR/github-sync-latest.log"
STATE_FILE="$STATE_DIR/latest.json"
REPORT_FILE="$REPORT_DIR/latest-github-sync.md"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTNAME_FQDN="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"
USER_NAME="$(id -un 2>/dev/null || echo unknown)"
STATUS="ok"
ACTIONS=()
BLOCKERS=()
WARNINGS=()

mkdir -p "$LOG_DIR" "$STATE_DIR" "$REPORT_DIR"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[$(date -u +%H:%M:%S)] another sync is already running" | tee -a "$LOG_FILE"
  exit 0
fi

exec > >(tee -a "$LOG_FILE") 2>&1

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "[$(ts)] $*"; }
add_action() { ACTIONS+=("$*"); }
add_warning() { WARNINGS+=("$*"); STATUS="warning"; }
add_blocker() { BLOCKERS+=("$*"); STATUS="blocked"; }

json_escape() {
  python3 - <<'PY' "$1" 2>/dev/null || printf '%s' "$1"
import json, sys
print(json.dumps(sys.argv[1]))
PY
}

classify_dirty_paths() {
  local unsafe=0
  local safe=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local path="${line:3}"
    path="${path#\"}"; path="${path%\"}"
    case "$path" in
      docs/reports/*|reports/*|docs/memory/*|docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md|control-plane/queue/queue.json)
        safe=$((safe + 1))
        ;;
      ops/automation-logs/*.summary.md)
        safe=$((safe + 1))
        ;;
      .env|.env.*|*.pem|*id_rsa*|*token*|*secret*|*.sqlite|*.db|*.dump|*.trace.zip|*.har)
        unsafe=$((unsafe + 1))
        ;;
      *)
        unsafe=$((unsafe + 1))
        ;;
    esac
  done < <(git -C "$REPO_DIR" status --short 2>/dev/null || true)
  echo "$safe $unsafe"
}

write_outputs() {
  local finished_at branch local_head origin_head dirty ahead behind diverged prompt_count opencode_count local_prompt_count queue_json_ok
  finished_at="$(ts)"
  branch="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  local_head="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  origin_head="$(git -C "$REPO_DIR" rev-parse --short "$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo unknown)"
  dirty="$(git -C "$REPO_DIR" status --short 2>/dev/null | wc -l | tr -d ' ')"
  ahead="$(git -C "$REPO_DIR" rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"
  behind="$(git -C "$REPO_DIR" rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
  diverged="no"; [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ] && diverged="yes"
  opencode_count="$(find "$REPO_DIR/prompts/opencode" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  local_prompt_count="$(find "$REPO_DIR/prompts/local" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  prompt_count=$((opencode_count + local_prompt_count))
  queue_json_ok="unknown"
  if [ -f "$REPO_DIR/control-plane/queue/queue.json" ]; then
    if python3 -m json.tool "$REPO_DIR/control-plane/queue/queue.json" >/dev/null 2>&1; then queue_json_ok="yes"; else queue_json_ok="no"; STATUS="warning"; fi
  fi

  {
    echo "# ASDEV GitHub Sync Report"
    echo
    echo "| Item | Value |"
    echo "|---|---|"
    echo "| Started | $STARTED_AT |"
    echo "| Finished | $finished_at |"
    echo "| Environment | $ASDEV_ENVIRONMENT |"
    echo "| Hostname | $HOSTNAME_FQDN |"
    echo "| User | $USER_NAME |"
    echo "| Repo | $REPO_DIR |"
    echo "| Branch | $branch |"
    echo "| Local HEAD | $local_head |"
    echo "| Origin HEAD | $origin_head |"
    echo "| Dirty count | $dirty |"
    echo "| Ahead | $ahead |"
    echo "| Behind | $behind |"
    echo "| Diverged | $diverged |"
    echo "| Prompt files | $prompt_count |"
    echo "| Queue JSON valid | $queue_json_ok |"
    echo "| Status | $STATUS |"
    echo
    echo "## Actions"
    if [ "${#ACTIONS[@]}" -eq 0 ]; then echo "- none"; else printf -- '- %s\n' "${ACTIONS[@]}"; fi
    echo
    echo "## Warnings"
    if [ "${#WARNINGS[@]}" -eq 0 ]; then echo "- none"; else printf -- '- %s\n' "${WARNINGS[@]}"; fi
    echo
    echo "## Blockers"
    if [ "${#BLOCKERS[@]}" -eq 0 ]; then echo "- none"; else printf -- '- %s\n' "${BLOCKERS[@]}"; fi
  } > "$REPORT_FILE"

  cat > "$STATE_FILE" <<JSON
{
  "script": "$SCRIPT_NAME",
  "started_at": "$STARTED_AT",
  "finished_at": "$finished_at",
  "environment": "$ASDEV_ENVIRONMENT",
  "hostname": "$HOSTNAME_FQDN",
  "user": "$USER_NAME",
  "repo_dir": "$REPO_DIR",
  "branch": "$branch",
  "local_head": "$local_head",
  "origin_head": "$origin_head",
  "dirty_count": $dirty,
  "ahead": $ahead,
  "behind": $behind,
  "diverged": "$diverged",
  "prompt_count": $prompt_count,
  "queue_json_valid": "$queue_json_ok",
  "status": "$STATUS",
  "report_file": "$REPORT_FILE",
  "log_file": "$LOG_FILE"
}
JSON
}

trap write_outputs EXIT

log "=== ASDEV sync start ==="
log "environment=$ASDEV_ENVIRONMENT repo=$REPO_DIR host=$HOSTNAME_FQDN user=$USER_NAME"

if [ "$ASDEV_ENVIRONMENT" = "UNKNOWN" ]; then
  add_warning "ASDEV_ENVIRONMENT not set; set LOCAL_PC, AUTOMATION_SERVER, or IRAN_PROD_SERVER"
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  add_blocker "Repo directory is not a git repo: $REPO_DIR"
  exit 0
fi

cd "$REPO_DIR"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
if [ "$branch" != "$REMOTE_BRANCH" ]; then
  add_warning "Current branch is $branch, expected $REMOTE_BRANCH"
fi

log "Fetching $REMOTE_NAME/$REMOTE_BRANCH"
if git fetch "$REMOTE_NAME" "$REMOTE_BRANCH" --prune; then
  add_action "Fetched $REMOTE_NAME/$REMOTE_BRANCH"
else
  add_blocker "Git fetch failed; continuing with local checks only"
fi

dirty_count="$(git status --short | wc -l | tr -d ' ')"
if [ "$dirty_count" -gt 0 ]; then
  read -r safe_count unsafe_count < <(classify_dirty_paths)
  log "Dirty repo: safe=$safe_count unsafe=$unsafe_count total=$dirty_count"
  if [ "$unsafe_count" -eq 0 ] && [ "$safe_count" -gt 0 ]; then
    git add docs/reports reports docs/memory docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md control-plane/queue/queue.json ops/automation-logs/*.summary.md 2>/dev/null || true
    if git diff --cached --quiet; then
      add_warning "Dirty files existed but nothing safe was staged"
    else
      if git commit -m "chore(sync): auto-commit safe sync state [skip ci]"; then
        add_action "Committed safe generated state/report changes"
      else
        add_warning "Safe generated state commit failed"
      fi
    fi
  else
    add_blocker "Dirty repo contains unsafe or unknown changes; not pulling with rebase and not resetting"
  fi
fi

behind="$(git rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
ahead="$(git rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"

if [ "${behind:-0}" -gt 0 ]; then
  dirty_after="$(git status --short | wc -l | tr -d ' ')"
  if [ "$dirty_after" -eq 0 ]; then
    log "Remote ahead by $behind; pulling with rebase"
    if git pull --rebase "$REMOTE_NAME" "$REMOTE_BRANCH"; then
      add_action "Pulled/rebased $behind remote commit(s)"
    else
      add_blocker "git pull --rebase failed"
    fi
  else
    add_blocker "Remote ahead by $behind but repo is dirty; pull skipped"
  fi
else
  add_action "Repo not behind origin/main"
fi

# Push safe local commits only if ahead and not diverged.
behind_after="$(git rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
ahead_after="$(git rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"
if [ "${ahead_after:-0}" -gt 0 ] && [ "${behind_after:-0}" -eq 0 ]; then
  log "Local ahead by $ahead_after; attempting push"
  if git push "$REMOTE_NAME" HEAD:"$REMOTE_BRANCH"; then
    add_action "Pushed $ahead_after local commit(s)"
  else
    add_warning "Push failed"
  fi
fi

# Prompt and policy discovery checks.
for path in \
  "docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md" \
  "docs/ops/GITHUB_LOCAL_SERVER_SYNC.md" \
  "docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md" \
  "docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"; do
  if [ -f "$path" ]; then
    add_action "Found $path"
  else
    add_warning "Missing expected file: $path"
  fi
done

if [ -d prompts/opencode ]; then
  op_count="$(find prompts/opencode -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
  add_action "Found $op_count opencode prompt(s)"
else
  add_warning "Missing prompts/opencode directory"
fi

if [ -f control-plane/queue/queue.json ]; then
  if python3 -m json.tool control-plane/queue/queue.json >/dev/null 2>&1; then
    add_action "Queue JSON is valid"
  else
    add_warning "Queue JSON is invalid"
  fi
fi

log "=== ASDEV sync complete status=$STATUS ==="
