#!/usr/bin/env bash
# ASDEV AI local-first task router — improved MVP
# Default: --dry-run (show plan, no execution).
# --execute: only for safe local commands.
# Never executes production mutation commands.
set -Eeuo pipefail

ROOT_DIR="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPORT_DIR="${ASDEV_AI_REPORT_DIR:-$ROOT_DIR/docs/reports/ai-router}"
STATE_DIR="${ASDEV_AI_STATE_DIR:-$ROOT_DIR/.state/ai-router}"
ENVIRONMENT_NAME="${ASDEV_ENVIRONMENT:-LOCAL_PC}"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
RUN_ID="$(date -u +"%Y%m%d-%H%M%S")"
REPORT_FILE="$REPORT_DIR/task-$RUN_ID.md"
STATE_FILE="$STATE_DIR/task-$RUN_ID.json"
PROVIDER_OVERRIDE="${ASDEV_AI_PROVIDER:-auto}"

MODE="dry-run"
TASK_CLASS=""
TASK_FILE=""

mkdir -p "$REPORT_DIR" "$STATE_DIR"

usage() {
  cat <<'USAGE'
Usage:
  scripts/ai-router/run-task.sh [--dry-run|--execute] <task-class> <task-file>

Modes:
  --dry-run (default)   Show routing plan, no execution.
  --execute             Execute only safe local commands.

Task classes:
  repo-audit           High-context repository audit
  code-patch           Code implementation/patch
  text-reasoning       Simple reasoning/text generation
  provider-health      Provider availability check
  report               Automation report generation

Environment:
  ASDEV_AI_PROVIDER=auto|mimo|opencode|deepseek|hermes|openclaw
  ASDEV_ENVIRONMENT=LOCAL_PC|AUTOMATION_SERVER|IRAN_PROD_SERVER

Examples:
  scripts/ai-router/run-task.sh --dry-run provider-health prompts/ai-router/sample-provider-health.md
  scripts/ai-router/run-task.sh --execute provider-health prompts/ai-router/sample-provider-health.md
USAGE
}

# Parse arguments
parse_args() {
  MODE="dry-run"
  local args=()
  for arg in "$@"; do
    case "$arg" in
      --dry-run) MODE="dry-run" ;;
      --execute) MODE="execute" ;;
      --help|-h) usage; exit 0 ;;
      *) args+=("$arg") ;;
    esac
  done
  TASK_CLASS="${args[0]:-}"
  TASK_FILE="${args[1]:-}"
}

parse_args "$@"

if [ -z "$TASK_CLASS" ] || [ -z "$TASK_FILE" ]; then
  echo "Error: Missing arguments. Expected: <task-class> <task-file>" >&2
  usage
  exit 2
fi

# Resolve relative path to task file
if [ ! -f "$TASK_FILE" ]; then
  resolved="$ROOT_DIR/$TASK_FILE"
  if [ -f "$resolved" ]; then
    TASK_FILE="$resolved"
  else
    echo "Error: Task file not found: $TASK_FILE" >&2
    echo "  (resolved: $resolved)" >&2
    echo "  Usage: $(basename "$0") [--dry-run|--execute] <task-class> <task-file>" >&2
    exit 2
  fi
fi

# ---------------------------------------------------------------------------
# Provider health helper: read status from latest state if available
# ---------------------------------------------------------------------------
get_provider_status() {
  local pid="$1"
  local state_file="$STATE_DIR/latest.json"
  if [ -f "$state_file" ]; then
    if command -v jq >/dev/null 2>&1; then
      jq -r ".providers.\"$pid\" // \"UNKNOWN_NOT_TESTED\"" "$state_file" 2>/dev/null || echo "UNKNOWN_NOT_TESTED"
    else
      echo "UNKNOWN_NOT_TESTED"
    fi
  else
    echo "UNKNOWN_NOT_TESTED"
  fi
}

is_provider_available() {
  local status
  status=$(get_provider_status "$1")
  case "$status" in
    AVAILABLE|AVAILABLE_WITH_VPN) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Provider selection with fallback chain
# ---------------------------------------------------------------------------
select_provider() {
  if [ "$PROVIDER_OVERRIDE" != "auto" ]; then
    echo "$PROVIDER_OVERRIDE"
    return
  fi
  case "$TASK_CLASS" in
    repo-audit)
      if is_provider_available "mimo"; then echo "mimo"
      elif is_provider_available "opencode"; then echo "opencode"
      else echo "mimo"
      fi
      ;;
    code-patch)
      if is_provider_available "opencode"; then echo "opencode"
      elif is_provider_available "mimo"; then echo "mimo"
      else echo "opencode"
      fi
      ;;
    text-reasoning)
      if is_provider_available "deepseek"; then echo "deepseek"
      elif is_provider_available "opencode"; then echo "opencode"
      else echo "deepseek"
      fi
      ;;
    provider-health)
      echo "local"
      ;;
    report)
      if is_provider_available "hermes"; then echo "hermes"
      else echo "local"
      fi
      ;;
    *)
      echo "opencode"
      ;;
  esac
}

SELECTED_PROVIDER="$(select_provider)"
FALLBACK_CHAIN=""
STATUS="PLANNED_NOT_EXECUTED"
COMMAND=""
NOTES=""

case "$SELECTED_PROVIDER" in
  opencode)
    if command -v opencode >/dev/null 2>&1; then
      COMMAND="opencode < $TASK_FILE"
      STATUS="READY_MANUAL_EXECUTION"
      NOTES="Provider: OpenCode. Run manually in dry-run mode. Use --execute only after review."
    else
      STATUS="PROVIDER_UNAVAILABLE"
      NOTES="opencode command not found on $ENVIRONMENT_NAME."
      # Fallback suggestion
      if is_provider_available "mimo"; then
        FALLBACK_CHAIN="mimo"
        NOTES="${NOTES} Suggested fallback: MiMo."
      fi
    fi
    ;;
  mimo)
    if command -v mimo >/dev/null 2>&1; then
      COMMAND="mimo < $TASK_FILE"
      STATUS="READY_MANUAL_EXECUTION"
      NOTES="Provider: MiMo. May require VPN. Verify availability before execution."
    else
      STATUS="PROVIDER_UNAVAILABLE"
      NOTES="mimo command not found on $ENVIRONMENT_NAME."
      if is_provider_available "opencode"; then
        FALLBACK_CHAIN="opencode"
        NOTES="${NOTES} Suggested fallback: OpenCode."
      fi
    fi
    ;;
  deepseek)
    if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
      STATUS="CONFIGURED_NOT_IMPLEMENTED"
      COMMAND="deepseek provider adapter pending"
      NOTES="API adapter not implemented. DeepSeek requires a safe adapter before execution."
    else
      STATUS="CONFIG_MISSING"
      NOTES="DEEPSEEK_API_KEY not set. Cannot route to DeepSeek."
      if is_provider_available "opencode"; then
        FALLBACK_CHAIN="opencode"
        NOTES="${NOTES} Suggested fallback: OpenCode."
      fi
    fi
    ;;
  hermes)
    if command -v hermes >/dev/null 2>&1; then
      COMMAND="hermes < $TASK_FILE"
      STATUS="READY_MANUAL_EXECUTION"
      NOTES="Provider: Hermes. Reporting and provider inventory layer."
    else
      STATUS="PROVIDER_UNAVAILABLE"
      NOTES="hermes command not found on $ENVIRONMENT_NAME."
      FALLBACK_CHAIN="local"
      NOTES="${NOTES} Falling back to local report generation."
    fi
    ;;
  local)
    COMMAND="scripts/ai-router/provider-health.sh"
    STATUS="READY_LOCAL_SAFE"
    NOTES="Local shell task. Safe for --execute."
    ;;
  *)
    STATUS="UNKNOWN_PROVIDER"
    NOTES="Provider $SELECTED_PROVIDER is not recognized."
    ;;
esac

# ---------------------------------------------------------------------------
# Execute mode: only for safe local commands
# ---------------------------------------------------------------------------
EXECUTION_OUTPUT=""
EXECUTION_EXIT_CODE=""

if [ "$MODE" = "execute" ]; then
  if [ "$STATUS" = "READY_LOCAL_SAFE" ]; then
    echo "Executing: $COMMAND"
    echo ""
    set +e
    EXECUTION_OUTPUT=$(ASDEV_ENVIRONMENT="$ENVIRONMENT_NAME" bash "$ROOT_DIR/$COMMAND" 2>&1)
    EXECUTION_EXIT_CODE=$?
    set -e
    if [ $EXECUTION_EXIT_CODE -eq 0 ]; then
      STATUS="EXECUTED_SUCCESS"
    else
      STATUS="EXECUTED_FAILURE"
    fi
  else
    echo "Error: --execute is only allowed for safe local commands." >&2
    echo "Provider: $SELECTED_PROVIDER, Status: $STATUS" >&2
    echo "Use --dry-run to preview the plan without execution." >&2
    STATUS="EXECUTION_REFUSED_SAFETY"
    EXECUTION_EXIT_CODE=99
  fi
fi

FINISHED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# ---------------------------------------------------------------------------
# Write Markdown report
# ---------------------------------------------------------------------------
cat > "$REPORT_FILE" <<MD
# ASDEV AI Router Task Report

| Item | Value |
|---|---|
| Started | $STARTED_AT |
| Finished | $FINISHED_AT |
| Environment | $ENVIRONMENT_NAME |
| Mode | $MODE |
| Task class | $TASK_CLASS |
| Task file | $TASK_FILE |
| Selected provider | $SELECTED_PROVIDER |
| Fallback chain | ${FALLBACK_CHAIN:-none} |
| Status | $STATUS |
| Command | \`$COMMAND\` |
MD

if [ -n "$EXECUTION_OUTPUT" ]; then
cat >> "$REPORT_FILE" <<MD

## Execution output

\`\`\`
$EXECUTION_OUTPUT
\`\`\`

Exit code: $EXECUTION_EXIT_CODE
MD
fi

cat >> "$REPORT_FILE" <<MD

## Notes

$NOTES

## Safety

This script does not call external APIs or execute agent commands by default.
Use --dry-run to review the plan. Use --execute only for local safe commands.
MD

# ---------------------------------------------------------------------------
# Write JSON state
# ---------------------------------------------------------------------------
cat > "$STATE_FILE" <<JSON
{
  "started_at": "$STARTED_AT",
  "finished_at": "$FINISHED_AT",
  "environment": "$ENVIRONMENT_NAME",
  "mode": "$MODE",
  "task_class": "$TASK_CLASS",
  "task_file": "$TASK_FILE",
  "selected_provider": "$SELECTED_PROVIDER",
  "fallback_chain": "$FALLBACK_CHAIN",
  "status": "$STATUS",
  "command": "$COMMAND",
  "execution_exit_code": ${EXECUTION_EXIT_CODE:-null},
  "report_file": "$REPORT_FILE"
}
JSON

echo ""
echo "Report: $REPORT_FILE"
echo "State:  $STATE_FILE"
echo "Status: $STATUS"

if [ "$MODE" = "dry-run" ] && [ "$STATUS" = "READY_LOCAL_SAFE" ]; then
  echo ""
  echo "Safe local task. To execute:"
  echo "  scripts/ai-router/run-task.sh --execute $TASK_CLASS $TASK_FILE"
fi
