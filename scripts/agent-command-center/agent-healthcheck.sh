#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[HEALTH]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }

ISSUES=0

log "=== ASDEV Agent Health Check ==="
echo ""

log "--- Timer Status ---"
if systemctl --user is-active asdev-agent-loop.timer >/dev/null 2>&1; then
  ok "Timer active"
  systemctl --user status asdev-agent-loop.timer 2>&1 | grep -E "Active:|Trigger:" | head -2
else
  fail "Timer not active"
  ISSUES=$((ISSUES + 1))
fi
echo ""

log "--- Service Last Run ---"
LAST_RUN=$(journalctl --user -u asdev-agent-loop.service -n 1 --no-pager 2>/dev/null | tail -1 || echo "no logs")
echo "  Last log: ${LAST_RUN}"
echo ""

log "--- Linger Status ---"
LINGER=$(loginctl show-user "$USER" -p Linger 2>/dev/null || echo "unknown")
if echo "$LINGER" | grep -q "yes"; then
  ok "Linger enabled"
else
  warn "Linger not enabled — timer may not survive reboot"
  ISSUES=$((ISSUES + 1))
fi
echo ""

log "--- Network Status ---"
if getent hosts github.com >/dev/null 2>&1; then
  ok "DNS resolving"
else
  fail "DNS not resolving"
  ISSUES=$((ISSUES + 1))
fi

if curl -fsS --max-time 5 https://api.github.com/rate_limit >/dev/null 2>&1; then
  ok "GitHub API reachable"
else
  warn "GitHub API unreachable"
fi
echo ""

log "--- gh auth ---"
if gh auth status >/dev/null 2>&1; then
  ok "gh authenticated"
else
  warn "gh not authenticated"
fi
echo ""

log "--- Tools ---"
for tool in node pnpm git hermes; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool: $(command -v "$tool")"
  else
    warn "$tool: not found"
  fi
done
echo ""

log "--- Repo Paths ---"
for dir in /home/dev13/my-project/sites/live/auditsystems /home/dev13/my-project/sites/live/alirezasafaeisystems /home/dev13/my-project/sites/live/persiantoolbox; do
  if [ -d "$dir" ]; then
    ok "$dir"
  else
    fail "$dir not found"
    ISSUES=$((ISSUES + 1))
  fi
done
echo ""

log "--- Queue Status ---"
QUEUE="/home/dev13/my-project/docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md"
if [ -f "$QUEUE" ]; then
  PENDING=$(grep -c "^\- \[ \]" "$QUEUE" 2>/dev/null || echo "0")
  DONE=$(grep -c "^\- \[x\]" "$QUEUE" 2>/dev/null || echo "0")
  ok "Queue: ${PENDING} pending, ${DONE} done"
else
  warn "Queue file not found"
fi
echo ""

log "--- State ---"
STATE_DIR="/home/dev13/my-project/.state/asdev-agent-loop"
if [ -f "${STATE_DIR}/state.json" ]; then
  FAILURES=$(cat "${STATE_DIR}/state.json" 2>/dev/null | grep -o '"consecutive_failures":[0-9]*' | cut -d: -f2 || echo "0")
  ok "State file exists (consecutive failures: ${FAILURES})"
else
  warn "State file not found"
fi
echo ""

log "--- Lock ---"
LOCK="/tmp/asdev-agent-loop/asdev-agent-loop.lock"
if [ -f "$LOCK" ]; then
  LOCK_PID=$(cat "$LOCK" 2>/dev/null || echo "")
  if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
    warn "Lock held by PID ${LOCK_PID}"
  else
    ok "Lock exists but stale (safe to override)"
  fi
else
  ok "No lock (loop not running)"
fi
echo ""

log "=== Summary ==="
if [ "$ISSUES" -gt 0 ]; then
  fail "Issues found: ${ISSUES}"
  exit 1
else
  ok "All checks passed"
  exit 0
fi
