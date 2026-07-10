#!/usr/bin/env bash
# ASDEV GitHub / Local / Server sync script — hardened v2
# No detached HEAD. No auto-commit on unknown branch. Divergence-safe.
set -Euo pipefail

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
add_warning() { WARNINGS+=("$*"); [ "$STATUS" = "ok" ] && STATUS="warning"; }
add_blocker() { BLOCKERS+=("$*"); STATUS="blocked"; }

classify_dirty_paths() {
  local unsafe=0 safe=0 path
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    path="${line:3}"
    path="${path#\"}"; path="${path%\"}"
    case "$path" in
      docs/reports/*|reports/*|docs/memory/*|docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md|control-plane/queue/queue.json)
        safe=$((safe + 1)) ;;
      ops/automation-logs/*.summary.md)
        safe=$((safe + 1)) ;;
      .env|.env.*|*.pem|*id_rsa*|*token*|*secret*|*.sqlite|*.db|*.dump|*.trace.zip|*.har)
        unsafe=$((unsafe + 1)) ;;
      *)
        unsafe=$((unsafe + 1)) ;;
    esac
  done < <(git -C "$REPO_DIR" status --short 2>/dev/null || true)
  echo "$safe $unsafe"
}

# ---------------------------------------------------------------------------
# Pre-flight: reject unknown environment, missing git repo
# ---------------------------------------------------------------------------
preflight_environment() {
  if [ "$ASDEV_ENVIRONMENT" = "UNKNOWN" ]; then
    add_warning "ASDEV_ENVIRONMENT not set"
  fi
  if [ ! -d "$REPO_DIR/.git" ]; then
    add_blocker "Not a git repo: $REPO_DIR"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Pre-flight: detect stale rebase/merge/cherry-pick and abort if safe
# ---------------------------------------------------------------------------
preflight_git_state() {
  local action_file="$REPO_DIR/.git/rebase-merge/onto"
  if [ -f "$action_file" ]; then
    local onto
    onto=$(cat "$action_file" 2>/dev/null || echo "unknown")
    log "WARNING: Rebase in progress onto $onto — aborting"
    if git rebase --abort 2>/dev/null; then
      add_warning "Stale rebase aborted (onto $onto)"
    else
      add_blocker "Could not abort rebase (onto $onto) — manual fix required"
      return 1
    fi
  fi
  local cherry_file="$REPO_DIR/.git/CHERRY_PICK_HEAD"
  if [ -f "$cherry_file" ]; then
    log "WARNING: Cherry-pick in progress — aborting"
    if git cherry-pick --abort 2>/dev/null; then
      add_warning "Stale cherry-pick aborted"
    else
      add_blocker "Could not abort cherry-pick — manual fix required"
      return 1
    fi
  fi
  local merge_file="$REPO_DIR/.git/MERGE_HEAD"
  if [ -f "$merge_file" ]; then
    log "WARNING: Merge in progress — aborting"
    if git merge --abort 2>/dev/null; then
      add_warning "Stale merge aborted"
    else
      add_blocker "Could not abort merge — manual fix required"
      return 1
    fi
  fi
}

# ---------------------------------------------------------------------------
# Check: is HEAD on the expected branch? Never auto-commit on detached HEAD.
# ---------------------------------------------------------------------------
check_branch() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")"
  if [ "$branch" = "HEAD" ] || echo "$branch" | grep -q '^[0-9a-f]\{7,\}$' 2>/dev/null; then
    add_blocker "Detached HEAD — refusing auto-commit. Check out '$REMOTE_BRANCH' first."
    return 1
  fi
  if [ "$branch" != "$REMOTE_BRANCH" ]; then
    add_warning "On branch '$branch', expected '$REMOTE_BRANCH'"
  fi
  echo "$branch"
}

# ---------------------------------------------------------------------------
# Auto-commit safe generated files — ONLY on main, only if clean.
# ---------------------------------------------------------------------------
auto_commit_safe() {
  local branch="$1"
  if [ "$branch" != "$REMOTE_BRANCH" ]; then
    add_warning "Auto-commit skipped: not on $REMOTE_BRANCH (on $branch)"
    return 1
  fi
  local dirty_count safe_count unsafe_count
  dirty_count="$(git status --short | wc -l | tr -d ' ')"
  [ "$dirty_count" -eq 0 ] && return 0
  read -r safe_count unsafe_count < <(classify_dirty_paths)
  log "Dirty: safe=$safe_count unsafe=$unsafe_count total=$dirty_count"
  if [ "$unsafe_count" -gt 0 ]; then
    add_blocker "Unsafe dirty paths ($unsafe_count) — refusing auto-commit"
    return 1
  fi
  if [ "$safe_count" -eq 0 ]; then
    add_warning "Dirty files exist but none classified as safe"
    return 1
  fi
  local add_targets=()
  for p in docs/reports/ reports/ docs/memory/ docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md control-plane/queue/queue.json; do
    [ -e "$p" ] && add_targets+=("$p")
  done
  for f in ops/automation-logs/*.summary.md; do
    [ -f "$f" ] && add_targets+=("$f")
  done
  if [ "${#add_targets[@]}" -eq 0 ]; then
    add_warning "No safe paths to add"
    return 0
  fi

  # Check commit throttle — skip if no semantic change or throttled
  local throttle_script="$REPO_DIR/scripts/control-plane/commit-throttle.sh"
  if [ -x "$throttle_script" ]; then
    local throttle_decision
    throttle_decision=$(bash "$throttle_script" 2>/dev/null | tail -1)
    case "$throttle_decision" in
      SKIP_NO_CHANGE)
        add_action "Auto-commit skipped: no semantic change"
        return 0
        ;;
      SKIP_THROTTLED)
        add_action "Auto-commit skipped: throttled (max 1/hour)"
        return 0
        ;;
      COMMIT_URGENT|COMMIT_STATE_CHANGE)
        # Proceed with commit
        ;;
      *)
        # Unknown decision, proceed with commit (safe default)
        ;;
    esac
  fi

  git add "${add_targets[@]}" 2>/dev/null || true
  if git diff --cached --quiet; then
    add_warning "Safe paths staged but nothing changed"
    return 0
  fi
  if git commit -m "chore(sync): auto-commit safe sync state [skip ci]"; then
    add_action "Auto-committed safe state on $branch"
    return 0
  else
    add_warning "Auto-commit failed"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Sync: fetch, fast-forward, handle divergence
# ---------------------------------------------------------------------------
sync_from_origin() {
  local branch="$1"
  log "Fetching $REMOTE_NAME/$REMOTE_BRANCH"
  if ! git fetch "$REMOTE_NAME" "$REMOTE_BRANCH" --prune; then
    add_blocker "Git fetch failed"
    return 1
  fi
  add_action "Fetched $REMOTE_NAME/$REMOTE_BRANCH"

  local behind ahead diverged
  behind="$(git rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
  ahead="$(git rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"
  diverged="no"
  [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ] && diverged="yes"

  if [ "$diverged" = "yes" ]; then
    # Phase 3: Classify divergence before acting
    local has_code=false
    local has_generated=false
    local divergent_files
    divergent_files=$(git diff --name-only "$REMOTE_NAME/$REMOTE_BRANCH"...HEAD 2>/dev/null || true)
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      case "$file" in
        docs/reports/*|reports/*|docs/memory/*|docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md|control-plane/queue/queue.json)
          has_generated=true ;;
        ops/automation-logs/*.summary.md)
          has_generated=true ;;
        *)
          has_code=true ;;
      esac
    done <<< "$divergent_files"

    if [ "$has_code" = true ]; then
      # Code-bearing divergence: NO_GO, never auto-reset
      add_blocker "Code-bearing divergence detected: ahead=$ahead behind=$behind. Files: $(echo "$divergent_files" | tr '\n' ' '). NO_GO — manual resolution required."
      return 1
    fi

    # Generated-only divergence: safe to reconcile with recovery branch
    add_warning "Generated-only divergence: ahead=$ahead behind=$behind. Creating recovery branch, then resetting."
    local recovery_branch="recovery/auto-divergence-$(date -u +%Y%m%d)"
    if git branch -f "$recovery_branch" HEAD 2>/dev/null; then
      add_action "Divergence recovery branch: $recovery_branch"
    fi
    if git reset --hard "$REMOTE_NAME/$REMOTE_BRANCH"; then
      add_action "Reset to $REMOTE_NAME/$REMOTE_BRANCH (generated-only divergence resolved)"
    else
      add_blocker "Could not reset to $REMOTE_NAME/$REMOTE_BRANCH"
      return 1
    fi
    return 0
  fi

  if [ "${behind:-0}" -gt 0 ]; then
    local dirty
    dirty="$(git status --short | wc -l | tr -d ' ')"
    if [ "$dirty" -gt 0 ]; then
      add_blocker "Remote ahead by $behind but repo dirty — pull skipped"
      return 1
    fi
    log "Remote ahead by $behind — fast-forward only"
    if git pull --ff-only "$REMOTE_NAME" "$REMOTE_BRANCH"; then
      add_action "Fast-forward $behind commit(s)"
    else
      add_blocker "git pull --ff-only failed (non-fast-forward)"
      return 1
    fi
  else
    add_action "Up to date with $REMOTE_NAME/$REMOTE_BRANCH"
  fi

  # Push local commits only if ahead and not diverged.
  behind="$(git rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
  ahead="$(git rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"
  if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -eq 0 ]; then
    log "Local ahead by $ahead — pushing"
    if git push "$REMOTE_NAME" HEAD:"$REMOTE_BRANCH"; then
      add_action "Pushed $ahead commit(s)"
    else
      add_warning "Push failed"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Policy and prompt discovery
# ---------------------------------------------------------------------------
discover_files() {
  for path in \
    "docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md" \
    "docs/ops/GITHUB_LOCAL_SERVER_SYNC.md" \
    "docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md" \
    "docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"; do
    if [ -f "$path" ]; then
      add_action "Found: $path"
    else
      add_warning "Missing: $path"
    fi
  done
  if [ -d prompts/opencode ]; then
    local op_count
    op_count="$(find prompts/opencode -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
    add_action "Found $op_count opencode prompt(s)"
  else
    add_warning "Missing prompts/opencode"
  fi
  if [ -f control-plane/queue/queue.json ]; then
    if python3 -m json.tool control-plane/queue/queue.json >/dev/null 2>&1; then
      add_action "Queue JSON valid"
    else
      add_warning "Queue JSON invalid"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Write outputs
# ---------------------------------------------------------------------------
write_outputs() {
  local finished_at branch local_head origin_head dirty ahead behind diverged
  local opencode_count local_prompt_count prompt_count queue_json_ok
  finished_at="$(ts)"
  branch="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")"
  local_head="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
  origin_head="$(git -C "$REPO_DIR" rev-parse --short "$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo "unknown")"
  dirty="$(git -C "$REPO_DIR" status --short 2>/dev/null | wc -l | tr -d ' ')"
  ahead="$(git -C "$REPO_DIR" rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"
  behind="$(git -C "$REPO_DIR" rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
  diverged="no"; [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ] && diverged="yes"
  opencode_count="$(find "$REPO_DIR/prompts/opencode" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  local_prompt_count="$(find "$REPO_DIR/prompts/local" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  prompt_count=$((opencode_count + local_prompt_count))
  queue_json_ok="unknown"
  if [ -f "$REPO_DIR/control-plane/queue/queue.json" ]; then
    if python3 -m json.tool "$REPO_DIR/control-plane/queue/queue.json" >/dev/null 2>&1; then
      queue_json_ok="yes"
    else
      queue_json_ok="no"; [ "$STATUS" = "ok" ] && STATUS="warning"
    fi
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

# ===========================================================================
# Main
# ===========================================================================
log "=== ASDEV sync v2 start ==="
log "environment=$ASDEV_ENVIRONMENT repo=$REPO_DIR host=$HOSTNAME_FQDN user=$USER_NAME"

preflight_environment || exit 0
cd "$REPO_DIR"

preflight_git_state || exit 0

BRANCH="$(check_branch)" || exit 0

auto_commit_safe "$BRANCH" || true

sync_from_origin "$BRANCH" || true

discover_files

log "=== ASDEV sync v2 complete status=$STATUS ==="
