#!/usr/bin/env bash
# ASDEV Commit Throttle — prevents timestamp-only commit storms.
# Computes semantic state hash, excludes timestamps, and only commits when
# health state meaningfully changes. Max 1 automated state commit per hour.
# Urgent severity transitions may bypass throttle.
set -Euo pipefail

SCRIPT_NAME="asdev-commit-throttle"
ASDEV_ROOT="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO_DIR="${ASDEV_REPO_DIR:-$ASDEV_ROOT}"
STATE_DIR="${ASDEV_STATE_DIR:-$REPO_DIR/.state/asdev-commit-throttle}"
THROTTLE_WINDOW="${ASDEV_COMMIT_THROTTLE_WINDOW:-3600}"  # 1 hour default

mkdir -p "$STATE_DIR"

ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "[$(ts)] $*"; }

# ---------------------------------------------------------------------------
# Compute semantic state hash — excludes timestamps and volatile fields
# ---------------------------------------------------------------------------
compute_semantic_hash() {
  local supervisor_state="$REPO_DIR/.state/asdev-supervisor/latest.json"
  local mcp_state="$REPO_DIR/.state/asdev-mcp/latest.json"

  local hash_input=""

  # Supervisor verdict + check statuses (excluding timestamps)
  if [ -f "$supervisor_state" ]; then
    hash_input+=$(python3 -c "
import json, hashlib
with open('$supervisor_state') as f:
    d = json.load(f)
# Extract only semantic fields
semantic = {
    'verdict': d.get('verdict', 'UNKNOWN'),
    'checks_passed': d.get('checks_passed', 0),
    'checks_warn': d.get('checks_warn', 0),
    'checks_failed': d.get('checks_failed', 0),
    'auto_healed': d.get('auto_healed', 0),
    'checks': [(c.get('check',''), c.get('status','')) for c in d.get('checks', [])]
}
print(json.dumps(semantic, sort_keys=True))
" 2>/dev/null || echo "SUPERVISOR_MISSING")
  else
    hash_input+="SUPERVISOR_MISSING"
  fi

  # MCP verdict (excluding timestamps)
  if [ -f "$mcp_state" ]; then
    hash_input+=$(python3 -c "
import json
with open('$mcp_state') as f:
    d = json.load(f)
semantic = {
    'verdict': d.get('verdict', 'UNKNOWN'),
    'http_code': d.get('http_code', 'UNKNOWN'),
    'failure_class': d.get('failure_class', 'unknown')
}
print(json.dumps(semantic, sort_keys=True))
" 2>/dev/null || echo "MCP_MISSING")
  else
    hash_input+="MCP_MISSING"
  fi

  # Git state (branch, ahead/behind — exclude timestamps)
  local branch ahead behind dirty
  branch=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
  ahead=$(git -C "$REPO_DIR" rev-list --count "origin/main..HEAD" 2>/dev/null || echo 0)
  behind=$(git -C "$REPO_DIR" rev-list --count "HEAD..origin/main" 2>/dev/null || echo 0)
  dirty=$(git -C "$REPO_DIR" status --short 2>/dev/null | wc -l | tr -d ' ')
  hash_input+="{\"branch\":\"$branch\",\"ahead\":$ahead,\"behind\":$behind,\"dirty\":$dirty}"

  # Compute hash
  printf '%s' "$hash_input" | sha256sum | cut -d' ' -f1
}

# ---------------------------------------------------------------------------
# Check if commit is throttled
# ---------------------------------------------------------------------------
is_throttled() {
  local throttle_file="$STATE_DIR/throttle.json"
  if [ ! -f "$throttle_file" ]; then
    return 1  # not throttled
  fi

  local last_commit_epoch
  last_commit_epoch=$(python3 -c "
import json
with open('$throttle_file') as f:
    d = json.load(f)
print(d.get('last_commit_epoch', 0))
" 2>/dev/null || echo 0)

  local now
  now=$(date +%s)
  local elapsed=$(( now - last_commit_epoch ))

  if [ "$elapsed" -lt "$THROTTLE_WINDOW" ]; then
    return 0  # throttled
  fi
  return 1  # not throttled
}

# ---------------------------------------------------------------------------
# Check if severity transition warrants bypass
# ---------------------------------------------------------------------------
is_urgent_severity_transition() {
  local throttle_file="$STATE_DIR/throttle.json"
  if [ ! -f "$throttle_file" ]; then
    return 1  # no previous state, not a transition
  fi

  local prev_verdict
  prev_verdict=$(python3 -c "
import json
with open('$throttle_file') as f:
    d = json.load(f)
print(d.get('last_verdict', 'UNKNOWN'))
" 2>/dev/null || echo "UNKNOWN")

  local current_verdict
  local supervisor_state="$REPO_DIR/.state/asdev-supervisor/latest.json"
  if [ -f "$supervisor_state" ]; then
    current_verdict=$(python3 -c "
import json
with open('$supervisor_state') as f:
    d = json.load(f)
print(d.get('verdict', 'UNKNOWN'))
" 2>/dev/null || echo "UNKNOWN")
  else
    current_verdict="UNKNOWN"
  fi

  # Urgent: any transition TO NO_GO, or FROM NO_GO to GO
  if [ "$current_verdict" = "NO_GO" ] && [ "$prev_verdict" != "NO_GO" ]; then
    return 0  # urgent: entering NO_GO
  fi
  if [ "$prev_verdict" = "NO_GO" ] && [ "$current_verdict" = "GO" ]; then
    return 0  # urgent: recovering from NO_GO
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Record commit
# ---------------------------------------------------------------------------
record_commit() {
  local verdict="$1" mode="$2"  # mode: "committed" or "skipped"
  local now
  now=$(date +%s)
  local semantic_hash
  semantic_hash=$(compute_semantic_hash)

  cat > "$STATE_DIR/throttle.json" <<JSON
{
  "last_commit_epoch": $now,
  "last_commit_iso": "$(ts)",
  "last_verdict": "$verdict",
  "last_mode": "$mode",
  "semantic_hash": "$semantic_hash"
}
JSON
}

# ---------------------------------------------------------------------------
# Check semantic change
# ---------------------------------------------------------------------------
has_semantic_change() {
  local throttle_file="$STATE_DIR/throttle.json"
  if [ ! -f "$throttle_file" ]; then
    return 0  # first run, always commit
  fi

  local prev_hash
  prev_hash=$(python3 -c "
import json
with open('$throttle_file') as f:
    d = json.load(f)
print(d.get('semantic_hash', ''))
" 2>/dev/null || echo "")

  local current_hash
  current_hash=$(compute_semantic_hash)

  if [ "$prev_hash" = "$current_hash" ]; then
    return 1  # no semantic change
  fi
  return 0  # semantic change detected
}

# ---------------------------------------------------------------------------
# Should commit? Main decision logic
# ---------------------------------------------------------------------------
should_commit() {
  local counters_file="$STATE_DIR/counters.json"

  # Load or initialize counters
  local skipped_no_change=0 skipped_throttled=0 committed_change=0 committed_urgent=0 commit_failed=0
  if [ -f "$counters_file" ]; then
    skipped_no_change=$(python3 -c "import json; d=json.load(open('$counters_file')); print(d.get('skipped_no_semantic_change',0))" 2>/dev/null || echo 0)
    skipped_throttled=$(python3 -c "import json; d=json.load(open('$counters_file')); print(d.get('skipped_throttled',0))" 2>/dev/null || echo 0)
    committed_change=$(python3 -c "import json; d=json.load(open('$counters_file')); print(d.get('committed_state_change',0))" 2>/dev/null || echo 0)
    committed_urgent=$(python3 -c "import json; d=json.load(open('$counters_file')); print(d.get('committed_severity_transition',0))" 2>/dev/null || echo 0)
    commit_failed=$(python3 -c "import json; d=json.load(open('$counters_file')); print(d.get('commit_failed',0))" 2>/dev/null || echo 0)
  fi

  # Get current verdict
  local supervisor_state="$REPO_DIR/.state/asdev-supervisor/latest.json"
  local verdict="UNKNOWN"
  if [ -f "$supervisor_state" ]; then
    verdict=$(python3 -c "import json; d=json.load(open('$supervisor_state')); print(d.get('verdict','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
  fi

  # Check 1: Semantic change?
  if ! has_semantic_change; then
    skipped_no_change=$((skipped_no_change + 1))
    cat > "$counters_file" <<JSON
{
  "skipped_no_semantic_change": $skipped_no_change,
  "skipped_throttled": $skipped_throttled,
  "committed_state_change": $committed_change,
  "committed_severity_transition": $committed_urgent,
  "commit_failed": $commit_failed
}
JSON
    log "SKIP: No semantic change (counter: $skipped_no_change)"
    echo "SKIP_NO_CHANGE"
    return 1
  fi

  # Check 2: Urgent severity transition bypasses throttle
  if is_urgent_severity_transition; then
    committed_urgent=$((committed_urgent + 1))
    record_commit "$verdict" "committed_severity_transition"
    cat > "$counters_file" <<JSON
{
  "skipped_no_semantic_change": $skipped_no_change,
  "skipped_throttled": $skipped_throttled,
  "committed_state_change": $committed_change,
  "committed_severity_transition": $committed_urgent,
  "commit_failed": $commit_failed
}
JSON
    log "COMMIT: Urgent severity transition (counter: $committed_urgent)"
    echo "COMMIT_URGENT"
    return 0
  fi

  # Check 3: Throttled?
  if is_throttled; then
    skipped_throttled=$((skipped_throttled + 1))
    cat > "$counters_file" <<JSON
{
  "skipped_no_semantic_change": $skipped_no_change,
  "skipped_throttled": $skipped_throttled,
  "committed_state_change": $committed_change,
  "committed_severity_transition": $committed_urgent,
  "commit_failed": $commit_failed
}
JSON
    log "SKIP: Throttled (counter: $skipped_throttled)"
    echo "SKIP_THROTTLED"
    return 1
  fi

  # All checks passed — commit
  committed_change=$((committed_change + 1))
  record_commit "$verdict" "committed_state_change"
  cat > "$counters_file" <<JSON
{
  "skipped_no_semantic_change": $skipped_no_change,
  "skipped_throttled": $skipped_throttled,
  "committed_state_change": $committed_change,
  "committed_severity_transition": $committed_urgent,
  "commit_failed": $commit_failed
}
JSON
  log "COMMIT: Semantic state change (counter: $committed_change)"
  echo "COMMIT_STATE_CHANGE"
  return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "=== ASDEV Commit Throttle ==="

DECISION=$(should_commit)
log "Decision: $DECISION"

# Output the decision for caller
echo "$DECISION"
