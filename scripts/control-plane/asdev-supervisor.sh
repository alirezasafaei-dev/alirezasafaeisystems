#!/usr/bin/env bash
# ASDEV Self-Healing Supervisor v2 — bounded allowlisted service recovery.
# Pre-loop health check: git state, timers, MCP, connectivity, disk/memory/network.
# Attempts auto-heal for known failure modes with cooldowns and max retries.
# Reports go/no-go with evidence. HTTP 000 is NEVER treated as healthy.
set -Euo pipefail

SCRIPT_NAME="asdev-supervisor"
ASDEV_ENVIRONMENT="${ASDEV_ENVIRONMENT:-UNKNOWN}"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO_DIR="${ASDEV_REPO_DIR:-$ASDEV_ROOT}"
REMOTE_NAME="${ASDEV_REMOTE_NAME:-origin}"
REMOTE_BRANCH="${ASDEV_REMOTE_BRANCH:-main}"
STATE_DIR="${ASDEV_STATE_DIR:-$REPO_DIR/.state/asdev-supervisor}"
REPORT_DIR="${ASDEV_REPORT_DIR:-$REPO_DIR/docs/reports/automation-server}"
RECOVERY_STATE_DIR="$REPO_DIR/.state/asdev-recovery"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTNAME_FQDN="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"

# Recovery policy
COOLDOWN_SECONDS="${ASDEV_RECOVERY_COOLDOWN:-300}"  # 5 minutes
MAX_RECOVERY_ATTEMPTS="${ASDEV_RECOVERY_MAX_ATTEMPTS:-3}"  # per rolling window
ROLLING_WINDOW_SECONDS="${ASDEV_RECOVERY_WINDOW:-3600}"  # 1 hour

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARN=0
RESULTS=()
HEALED=()
SKIPPED_COOLDOWN=()
SKIPPED_NOT_ALLOWLISTED=()

mkdir -p "$STATE_DIR" "$REPORT_DIR" "$RECOVERY_STATE_DIR"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
now_epoch() { date +%s; }
log() { echo "[$(ts)] $*" >&2; }

pass() { CHECKS_PASSED=$((CHECKS_PASSED+1)); RESULTS+=("PASS:$1:$2"); }
warn() { CHECKS_WARN=$((CHECKS_WARN+1)); RESULTS+=("WARN:$1:$2"); }
fail() { CHECKS_FAILED=$((CHECKS_FAILED+1)); RESULTS+=("FAIL:$1:$2"); }
healed() { HEALED+=("$1"); }
skipped_cooldown() { SKIPPED_COOLDOWN+=("$1"); }
skipped_not_allowlisted() { SKIPPED_NOT_ALLOWLISTED+=("$1"); }

# ---------------------------------------------------------------------------
# Allowlist — units the supervisor is permitted to restart
# ---------------------------------------------------------------------------
# Timers and their associated services. The supervisor must NOT restart itself
# (asdev-supervisor.service) to prevent recursive restart storms.
is_allowlisted_unit() {
  local unit="$1"
  case "$unit" in
    asdev-github-sync.timer|asdev-github-sync.service) return 0 ;;
    asdev-agent-loop.timer|asdev-agent-loop.service) return 0 ;;
    asdev-health-monitor.timer|asdev-health-monitor.service) return 0 ;;
    asdev-mcp-monitor.timer|asdev-mcp-monitor.service) return 0 ;;
    asdev-bot.service) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Recovery state management (persisted in .state/, not in Git)
# ---------------------------------------------------------------------------
get_recovery_state() {
  local unit="$1"
  local state_file="$RECOVERY_STATE_DIR/${unit}.json"
  if [ -f "$state_file" ]; then
    cat "$state_file"
  else
    echo '{"attempts":[],"last_attempt":0,"total_attempts":0}'
  fi
}

save_recovery_state() {
  local unit="$1" state="$2"
  echo "$state" > "$RECOVERY_STATE_DIR/${unit}.json"
}

can_attempt_recovery() {
  local unit="$1"
  local now
  now=$(now_epoch)
  local state
  state=$(get_recovery_state "$unit")

  # Parse current state
  local total_attempts last_attempt
  total_attempts=$(echo "$state" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total_attempts',0))" 2>/dev/null || echo 0)
  last_attempt=$(echo "$state" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('last_attempt',0))" 2>/dev/null || echo 0)

  # Check cooldown
  local elapsed=$(( now - last_attempt ))
  if [ "$elapsed" -lt "$COOLDOWN_SECONDS" ]; then
    return 1  # still in cooldown
  fi

  # Check rolling window max attempts
  # Count attempts within the rolling window
  local window_start=$(( now - ROLLING_WINDOW_SECONDS ))
  local recent_attempts
  recent_attempts=$(echo "$state" | python3 -c "
import sys, json
d = json.load(sys.stdin)
attempts = d.get('attempts', [])
window_start = $window_start
count = sum(1 for a in attempts if a >= window_start)
print(count)
" 2>/dev/null || echo 0)

  if [ "$recent_attempts" -ge "$MAX_RECOVERY_ATTEMPTS" ]; then
    return 1  # max attempts in window
  fi

  return 0
}

record_recovery_attempt() {
  local unit="$1" success="$2"
  local now
  now=$(now_epoch)
  local state
  state=$(get_recovery_state "$unit")

  echo "$state" | python3 -c "
import sys, json
d = json.load(sys.stdin)
attempts = d.get('attempts', [])
window_start = $now - $ROLLING_WINDOW_SECONDS
# Prune old attempts
attempts = [a for a in attempts if a >= window_start]
attempts.append($now)
d['attempts'] = attempts
d['last_attempt'] = $now
d['total_attempts'] = d.get('total_attempts', 0) + 1
d['last_success'] = $success
json.dump(d, sys.stdout)
" > "$RECOVERY_STATE_DIR/${unit}.json" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Check 1: Git state
# ---------------------------------------------------------------------------
check_git_state() {
  if [ ! -d "$REPO_DIR/.git" ]; then
    fail "GIT-001" "Not a git repo: $REPO_DIR"
    return
  fi
  cd "$REPO_DIR"

  # Rebase in progress?
  if [ -f ".git/rebase-merge/onto" ]; then
    local onto
    onto=$(cat ".git/rebase-merge/onto" 2>/dev/null || echo "unknown")
    log "Healing: aborting stale rebase (onto $onto)"
    if git rebase --abort 2>/dev/null; then
      healed "Aborted stale rebase (onto $onto)"
      pass "GIT-002" "Stale rebase auto-healed"
    else
      fail "GIT-002" "Could not abort rebase (onto $onto)"
      return
    fi
  fi

  # Cherry-pick in progress?
  if [ -f ".git/CHERRY_PICK_HEAD" ]; then
    log "Healing: aborting stale cherry-pick"
    if git cherry-pick --abort 2>/dev/null; then
      healed "Aborted stale cherry-pick"
      pass "GIT-003" "Stale cherry-pick auto-healed"
    else
      fail "GIT-003" "Could not abort cherry-pick"
      return
    fi
  fi

  # Detached HEAD?
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")"
  if [ "$branch" = "HEAD" ] || echo "$branch" | grep -q '^[0-9a-f]\{7,\}$' 2>/dev/null; then
    log "Healing: detached HEAD -> checking out $REMOTE_BRANCH"
    if git fetch "$REMOTE_NAME" "$REMOTE_BRANCH" --prune 2>/dev/null && git checkout "$REMOTE_BRANCH" 2>/dev/null; then
      healed "Checked out $REMOTE_BRANCH (was detached)"
      pass "GIT-004" "Detached HEAD auto-healed -> $REMOTE_BRANCH"
    else
      if git checkout main 2>/dev/null; then
        healed "Checked out main (local, detached fix)"
        pass "GIT-004" "Detached HEAD auto-healed -> main (local)"
      else
        fail "GIT-004" "Detached HEAD could not be healed"
        return
      fi
    fi
  else
    pass "GIT-005" "On branch: $branch"
  fi

  # Origin reachable?
  if git fetch "$REMOTE_NAME" "$REMOTE_BRANCH" --prune 2>/dev/null; then
    pass "GIT-006" "Remote $REMOTE_NAME reachable"
  else
    fail "GIT-006" "Remote $REMOTE_NAME not reachable"
    return
  fi

  # Divergence — classify before acting (Phase 3 integration)
  local ahead behind
  ahead="$(git rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"
  behind="$(git rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
  if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ]; then
    # Divergence detected — classify local commits
    local has_code=false
    local has_generated=false
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
    done < <(git diff --name-only "$REMOTE_NAME/$REMOTE_BRANCH"...HEAD 2>/dev/null || true)

    if [ "$has_code" = true ]; then
      fail "GIT-007" "Code-bearing divergence detected (ahead=$ahead behind=$behind) — NO_GO"
    else
      # Generated-only divergence — safe to reconcile
      local recovery_branch="recovery/supervisor-$(date -u +%Y%m%dT%H%M%S)"
      git branch -f "$recovery_branch" HEAD 2>/dev/null
      if git reset --hard "$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null; then
        healed "Generated-only divergence reconciled: ahead=$ahead behind=$behind (recovery: $recovery_branch)"
        pass "GIT-007" "Generated-only divergence auto-healed"
      else
        fail "GIT-007" "Divergence could not be healed (ahead=$ahead behind=$behind)"
      fi
    fi
  else
    pass "GIT-008" "No divergence (ahead=$ahead behind=$behind)"
  fi

  # Sync up
  behind="$(git rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
  if [ "${behind:-0}" -gt 0 ]; then
    if git pull --ff-only "$REMOTE_NAME" "$REMOTE_BRANCH" 2>/dev/null; then
      healed "Fast-forward $behind commits"
      pass "GIT-009" "Fast-forward sync OK"
    else
      warn "GIT-009" "Fast-forward failed"
    fi
  else
    pass "GIT-009" "Already up to date"
  fi
}

# ---------------------------------------------------------------------------
# Check 2: Systemd timer and service health with bounded recovery
# ---------------------------------------------------------------------------
check_systemd_health() {
  local timers
  timers=$(systemctl --user list-timers --no-pager 2>/dev/null || true)

  # Check timers
  for svc in asdev-github-sync asdev-agent-loop asdev-health-monitor asdev-mcp-monitor asdev-supervisor; do
    if echo "$timers" | grep -q "$svc"; then
      pass "SVC-${svc}.timer" "Timer active"
    else
      warn "SVC-${svc}.timer" "Timer not found"
    fi
  done

  # Check services with recovery
  local critical_units=(asdev-bot.service)
  local recoverable_units=(asdev-github-sync.service asdev-agent-loop.service asdev-health-monitor.service asdev-mcp-monitor.service)

  # Critical units: check running, but do NOT auto-restart
  for unit in "${critical_units[@]}"; do
    local state
    state=$(systemctl --user show "$unit" --property=ActiveState --value 2>/dev/null || echo "unknown")
    if [ "$state" = "active" ]; then
      pass "SVC-$unit" "Service running"
    else
      fail "SVC-$unit" "Critical service not running (state=$state)"
    fi
  done

  # Recoverable units: check and attempt bounded recovery
  for unit in "${recoverable_units[@]}"; do
    local state result
    state=$(systemctl --user show "$unit" --property=ActiveState --value 2>/dev/null || echo "unknown")
    result=$(systemctl --user show "$unit" --property=Result --value 2>/dev/null || echo "unknown")

    # For oneshot services triggered by timers: "inactive" is normal resting state.
    # Only flag as needing recovery if: state=failed OR (state=inactive AND result=failed)
    # "inactive" with result=success or result=none (never ran, timer will trigger) is OK.
    if [ "$state" = "active" ]; then
      pass "SVC-$unit" "Service running"
      continue
    fi

    if [ "$state" = "inactive" ] && [ "$result" = "success" ]; then
      pass "SVC-$unit" "Oneshot service completed successfully (inactive, result=success)"
      continue
    fi

    if [ "$state" = "inactive" ] && [ "$result" = "none" ]; then
      pass "SVC-$unit" "Oneshot service idle (inactive, awaiting timer trigger)"
      continue
    fi

    if [ "$state" = "activating" ] || [ "$state" = "reloading" ]; then
      pass "SVC-$unit" "Service transitioning (state=$state)"
      continue
    fi

    # If we get here, the service is in a problematic state (failed, or inactive with failed result)
    # Not running — check if allowlisted
    if ! is_allowlisted_unit "$unit"; then
      skipped_not_allowlisted "$unit"
      warn "SVC-$unit" "Not running but not allowlisted for recovery (state=$state result=$result)"
      continue
    fi

    # Check cooldown and max attempts
    if ! can_attempt_recovery "$unit"; then
      skipped_cooldown "$unit"
      warn "SVC-$unit" "Recovery skipped: cooldown/max-attempts (state=$state result=$result)"
      continue
    fi

    # Attempt recovery
    log "Attempting recovery: $unit (current state=$state result=$result)"
    if systemctl --user restart "$unit" 2>/dev/null; then
      # Re-check after restart
      sleep 2
      local new_state new_result
      new_state=$(systemctl --user show "$unit" --property=ActiveState --value 2>/dev/null || echo "unknown")
      new_result=$(systemctl --user show "$unit" --property=Result --value 2>/dev/null || echo "unknown")
      if [ "$new_state" = "active" ] || { [ "$new_state" = "inactive" ] && [ "$new_result" = "success" ]; }; then
        healed "Restarted $unit successfully"
        pass "SVC-$unit" "Service recovered (state=$new_state result=$new_result)"
        record_recovery_attempt "$unit" "true"
      else
        fail "SVC-$unit" "Restart attempted but still not running (state=$new_state result=$new_result)"
        record_recovery_attempt "$unit" "false"
      fi
    else
      fail "SVC-$unit" "Restart command failed"
      record_recovery_attempt "$unit" "false"
    fi
  done
}

# ---------------------------------------------------------------------------
# Check 3: MCP health (using v2 validator)
# ---------------------------------------------------------------------------
check_mcp_health() {
  local mcp_check="$REPO_DIR/scripts/control-plane/mcp-health-check-v2.sh"
  if [ -x "$mcp_check" ]; then
    if bash "$mcp_check" 2>/dev/null; then
      local mcp_state="$REPO_DIR/.state/asdev-mcp/latest.json"
      if [ -f "$mcp_state" ]; then
        local verdict http_code
        verdict=$(python3 -c "import json; d=json.load(open('$mcp_state')); print(d.get('verdict','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
        http_code=$(python3 -c "import json; d=json.load(open('$mcp_state')); print(d.get('http_code','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
        pass "MCP-001" "MCP endpoint healthy (HTTP $http_code, verdict=$verdict)"
      else
        pass "MCP-001" "MCP check passed (no state file)"
      fi
    else
      local mcp_state="$REPO_DIR/.state/asdev-mcp/latest.json"
      if [ -f "$mcp_state" ]; then
        local verdict failure_class
        verdict=$(python3 -c "import json; d=json.load(open('$mcp_state')); print(d.get('verdict','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
        failure_class=$(python3 -c "import json; d=json.load(open('$mcp_state')); print(d.get('failure_class','unknown'))" 2>/dev/null || echo "unknown")
        fail "MCP-001" "MCP endpoint unhealthy (verdict=$verdict failure=$failure_class)"
      else
        fail "MCP-001" "MCP check failed (no state file)"
      fi
    fi
  else
    # Fallback to legacy check
    local mcp_url="${ASDEV_MCP_URL:-https://mcp.alirezasafaeisystems.ir/sse/}"
    if command -v curl >/dev/null 2>&1; then
      local http_code
      http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$mcp_url" 2>/dev/null || echo "000")
      if [ "$http_code" = "200" ]; then
        pass "MCP-001" "MCP endpoint reachable (HTTP $http_code)"
      elif [ "$http_code" = "307" ]; then
        pass "MCP-001" "MCP endpoint reachable (HTTP $http_code redirect)"
      elif [ "$http_code" = "000" ]; then
        fail "MCP-001" "MCP endpoint unreachable (HTTP 000)"
      else
        warn "MCP-001" "MCP endpoint returned HTTP $http_code"
      fi
    else
      warn "MCP-001" "curl not available, skipping MCP check"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Check 4: System resources
# ---------------------------------------------------------------------------
check_system_resources() {
  # Disk
  local disk_pct
  disk_pct=$(df -h "$REPO_DIR" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%' || echo "0")
  if [ "${disk_pct:-0}" -gt 90 ]; then
    fail "SYS-001" "Disk usage critical: ${disk_pct}%"
  elif [ "${disk_pct:-0}" -gt 80 ]; then
    warn "SYS-001" "Disk usage high: ${disk_pct}%"
  else
    pass "SYS-001" "Disk usage: ${disk_pct}%"
  fi

  # Memory
  if command -v free >/dev/null 2>&1; then
    local mem_pct
    mem_pct=$(free -m 2>/dev/null | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}' || echo "0")
    if [ "${mem_pct:-0}" -gt 90 ]; then
      fail "SYS-002" "Memory usage critical: ${mem_pct}%"
    elif [ "${mem_pct:-0}" -gt 80 ]; then
      warn "SYS-002" "Memory usage high: ${mem_pct}%"
    else
      pass "SYS-002" "Memory usage: ${mem_pct}%"
    fi
  else
    warn "SYS-002" "free not available"
  fi

  # Network
  if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 3 github.com >/dev/null 2>&1; then
      pass "SYS-003" "Network reachable (github.com)"
    else
      warn "SYS-003" "Network issue (github.com unreachable)"
    fi
  else
    warn "SYS-003" "ping not available"
  fi
}

# ---------------------------------------------------------------------------
# Check 5: Provider health (if state exists)
# ---------------------------------------------------------------------------
check_provider_health() {
  local provider_state="$REPO_DIR/.state/ai-router/latest.json"
  if [ -f "$provider_state" ]; then
    if command -v jq >/dev/null 2>&1; then
      local opencode_status
      opencode_status=$(jq -r '.providers.opencode // "UNKNOWN"' "$provider_state" 2>/dev/null || echo "UNKNOWN")
      if [ "$opencode_status" = "AVAILABLE" ]; then
        pass "PROV-001" "OpenCode available"
      else
        warn "PROV-001" "OpenCode status: $opencode_status"
      fi
    else
      warn "PROV-001" "jq not available"
    fi
  else
    warn "PROV-001" "No provider health state"
  fi
}

# ===========================================================================
# Main
# ===========================================================================
log "=== ASDEV Supervisor v2 ==="
log "environment=$ASDEV_ENVIRONMENT host=$HOSTNAME_FQDN repo=$REPO_DIR"

check_git_state
check_systemd_health
check_mcp_health
check_system_resources
check_provider_health

FINISHED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Determine verdict
VERDICT="GO"
if [ "$CHECKS_FAILED" -gt 0 ]; then
  VERDICT="NO_GO"
elif [ "$CHECKS_WARN" -gt 2 ]; then
  VERDICT="GO_WITH_WARNINGS"
fi

# Report
REPORT_FILE="$REPORT_DIR/latest-supervisor.md"
{
  echo "# ASDEV Supervisor Report"
  echo
  echo "| Item | Value |"
  echo "|---|---|"
  echo "| Started | $STARTED_AT |"
  echo "| Finished | $FINISHED_AT |"
  echo "| Environment | $ASDEV_ENVIRONMENT |"
  echo "| Hostname | $HOSTNAME_FQDN |"
  echo "| Verdict | $VERDICT |"
  echo "| Passed | $CHECKS_PASSED |"
  echo "| Warnings | $CHECKS_WARN |"
  echo "| Failed | $CHECKS_FAILED |"
  echo "| Auto-healed | ${#HEALED[@]} |"
  echo "| Skipped (cooldown) | ${#SKIPPED_COOLDOWN[@]} |"
  echo "| Skipped (not allowlisted) | ${#SKIPPED_NOT_ALLOWLISTED[@]} |"
  echo
  echo "## Checks"
  for r in "${RESULTS[@]}"; do
    IFS=':' read -r status code msg <<< "$r"
    echo "- $status [$code] $msg"
  done
  echo
  if [ "${#HEALED[@]}" -gt 0 ]; then
    echo "## Auto-heal actions"
    for h in "${HEALED[@]}"; do
      echo "- $h"
    done
    echo
  fi
  if [ "${#SKIPPED_COOLDOWN[@]}" -gt 0 ]; then
    echo "## Skipped (cooldown)"
    for s in "${SKIPPED_COOLDOWN[@]}"; do
      echo "- $s"
    done
    echo
  fi
  if [ "${#SKIPPED_NOT_ALLOWLISTED[@]}" -gt 0 ]; then
    echo "## Skipped (not allowlisted)"
    for s in "${SKIPPED_NOT_ALLOWLISTED[@]}"; do
      echo "- $s"
    done
    echo
  fi
  echo "## Verdict"
  case "$VERDICT" in
    GO) echo "All critical checks passed. Loop may proceed." ;;
    GO_WITH_WARNINGS) echo "All critical checks passed (non-critical warnings). Loop may proceed with caution." ;;
    NO_GO) echo "Critical failures detected. Loop must not proceed until resolved." ;;
  esac
} > "$REPORT_FILE"

# JSON state
STATE_FILE="$STATE_DIR/latest.json"
json_checks=()
for r in "${RESULTS[@]}"; do
  IFS=':' read -r status code msg <<< "$r"
  # Escape messages for JSON
  msg_escaped=$(printf '%s' "$msg" | python3 -c "import sys; print(sys.stdin.read().strip().replace('\"','\\\\\"').replace('\n',' '))" 2>/dev/null || echo "$msg")
  json_checks+=("{\"check\":\"$code\",\"status\":\"$status\",\"message\":\"$msg_escaped\"}")
done
joined_checks=$(IFS=,; echo "${json_checks[*]}")

cat > "$STATE_FILE" <<JSON
{
  "script": "$SCRIPT_NAME",
  "version": "v2",
  "started_at": "$STARTED_AT",
  "finished_at": "$FINISHED_AT",
  "environment": "$ASDEV_ENVIRONMENT",
  "hostname": "$HOSTNAME_FQDN",
  "verdict": "$VERDICT",
  "checks_passed": $CHECKS_PASSED,
  "checks_warn": $CHECKS_WARN,
  "checks_failed": $CHECKS_FAILED,
  "auto_healed": ${#HEALED[@]},
  "skipped_cooldown": ${#SKIPPED_COOLDOWN[@]},
  "skipped_not_allowlisted": ${#SKIPPED_NOT_ALLOWLISTED[@]},
  "checks": [$joined_checks]
}
JSON

log "=== Supervisor verdict: $VERDICT (passed=$CHECKS_PASSED warn=$CHECKS_WARN failed=$CHECKS_FAILED healed=${#HEALED[@]}) ==="

case "$VERDICT" in
  NO_GO) exit 1 ;;
  *) exit 0 ;;
esac
