#!/usr/bin/env bash
# ASDEV Self-Healing Supervisor
# Pre-loop health check: git state, timers, MCP, connectivity, disk/memory/network.
# Attempts auto-heal for known failure modes. Reports go/no-go.
set -Euo pipefail

SCRIPT_NAME="asdev-supervisor"
ASDEV_ENVIRONMENT="${ASDEV_ENVIRONMENT:-UNKNOWN}"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO_DIR="${ASDEV_REPO_DIR:-$ASDEV_ROOT}"
REMOTE_NAME="${ASDEV_REMOTE_NAME:-origin}"
REMOTE_BRANCH="${ASDEV_REMOTE_BRANCH:-main}"
STATE_DIR="${ASDEV_STATE_DIR:-$REPO_DIR/.state/asdev-supervisor}"
REPORT_DIR="${ASDEV_REPORT_DIR:-$REPO_DIR/docs/reports/automation-server}"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTNAME_FQDN="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARN=0
RESULTS=()
HEALED=()

mkdir -p "$STATE_DIR" "$REPORT_DIR"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "[$(ts)] $*"; }

pass() { CHECKS_PASSED=$((CHECKS_PASSED+1)); RESULTS+=("PASS:$1:$2"); }
warn() { CHECKS_WARN=$((CHECKS_WARN+1)); RESULTS+=("WARN:$1:$2"); }
fail() { CHECKS_FAILED=$((CHECKS_FAILED+1)); RESULTS+=("FAIL:$1:$2"); }
healed() { HEALED+=("$1"); }

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
      # Try local main as fallback
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

  # Diverged?
  local ahead behind
  ahead="$(git rev-list --count "$REMOTE_NAME/$REMOTE_BRANCH"..HEAD 2>/dev/null || echo 0)"
  behind="$(git rev-list --count HEAD.."$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null || echo 0)"
  if [ "${ahead:-0}" -gt 0 ] && [ "${behind:-0}" -gt 0 ]; then
    local recovered="recovery/supervisor-$(date -u +%Y%m%dT%H%M%S)"
    git branch -f "$recovered" HEAD 2>/dev/null
    if git reset --hard "$REMOTE_NAME/$REMOTE_BRANCH" 2>/dev/null; then
      healed "Divergence auto-healed: ahead=$ahead behind=$behind (recovery: $recovered)"
      pass "GIT-007" "Divergence auto-healed"
    else
      fail "GIT-007" "Divergence could not be healed (ahead=$ahead behind=$behind)"
    fi
  else
    pass "GIT-008" "No divergence (ahead=$ahead behind=$behind)"
  fi

  # Sync up
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
# Check 2: Systemd timer and service health
# ---------------------------------------------------------------------------
check_systemd_health() {
  local timers
  timers=$(systemctl --user list-timers --no-pager 2>/dev/null || true)
  for svc in asdev-github-sync asdev-agent-loop asdev-health-monitor asdev-mcp-monitor; do
    if echo "$timers" | grep -q "$svc"; then
      pass "SVC-${svc}" "Timer active"
    else
      warn "SVC-${svc}" "Timer not found"
    fi
  done
  local units
  units=$(systemctl --user list-units --no-pager 'asdev-*' 2>/dev/null || true)
  for svc in asdev-bot; do
    if echo "$units" | grep -q "$svc.*active.*running"; then
      pass "SVC-${svc}" "Service running"
    else
      warn "SVC-${svc}" "Service not running"
    fi
  done
}

# ---------------------------------------------------------------------------
# Check 3: MCP health
# ---------------------------------------------------------------------------
check_mcp_health() {
  local mcp_url="${ASDEV_MCP_URL:-https://mcp.alirezasafaeisystems.ir/sse/}"
  if command -v curl >/dev/null 2>&1; then
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$mcp_url" 2>/dev/null || echo "000")
    if [ "$http_code" = "200" ] || [ "$http_code" = "000" ]; then
      pass "MCP-001" "MCP endpoint reachable (HTTP $http_code)"
    else
      warn "MCP-001" "MCP endpoint returned HTTP $http_code"
    fi
  else
    warn "MCP-001" "curl not available, skipping MCP check"
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

  # Memory (approximate via free)
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

  # Network (default gateway)
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
    warn "PROV-001" "No provider health state (expected if provider-health.sh never ran)"
  fi
}

# ===========================================================================
# Main
# ===========================================================================
log "=== ASDEV Supervisor v1 ==="
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
  json_checks+=("{\"check\":\"$code\",\"status\":\"$status\",\"message\":\"$msg\"}")
done
joined_checks=$(IFS=,; echo "${json_checks[*]}")
cat > "$STATE_FILE" <<JSON
{
  "script": "$SCRIPT_NAME",
  "started_at": "$STARTED_AT",
  "finished_at": "$FINISHED_AT",
  "environment": "$ASDEV_ENVIRONMENT",
  "hostname": "$HOSTNAME_FQDN",
  "verdict": "$VERDICT",
  "checks_passed": $CHECKS_PASSED,
  "checks_warn": $CHECKS_WARN,
  "checks_failed": $CHECKS_FAILED,
  "auto_healed": ${#HEALED[@]},
  "checks": [$joined_checks]
}
JSON

log "=== Supervisor verdict: $VERDICT (passed=$CHECKS_PASSED warn=$CHECKS_WARN failed=$CHECKS_FAILED healed=${#HEALED[@]}) ==="

case "$VERDICT" in
  NO_GO) exit 1 ;;
  *) exit 0 ;;
esac
