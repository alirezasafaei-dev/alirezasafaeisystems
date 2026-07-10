#!/usr/bin/env bash
# ASDEV AI local-first task routing scaffold.
# This script intentionally avoids calling paid/secret APIs by default.
set -Eeuo pipefail

ROOT_DIR="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPORT_DIR="${ASDEV_AI_REPORT_DIR:-$ROOT_DIR/docs/reports/ai-router}"
STATE_DIR="${ASDEV_AI_STATE_DIR:-$ROOT_DIR/.state/ai-router}"
ENVIRONMENT_NAME="${ASDEV_ENVIRONMENT:-LOCAL_PC}"
TASK_CLASS="${1:-}"
TASK_FILE="${2:-}"
PROVIDER="${ASDEV_AI_PROVIDER:-auto}"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
RUN_ID="$(date -u +"%Y%m%d-%H%M%S")"
REPORT_FILE="$REPORT_DIR/task-$RUN_ID.md"
STATE_FILE="$STATE_DIR/task-$RUN_ID.json"

mkdir -p "$REPORT_DIR" "$STATE_DIR"

usage() {
  cat <<'USAGE'
Usage:
  scripts/ai-router/run-task.sh <task-class> <task-file>

Task classes:
  repo-audit
  code-patch
  text-reasoning
  provider-health
  report

Environment:
  ASDEV_AI_PROVIDER=auto|mimo|opencode|deepseek|hermes|openclaw
USAGE
}

if [ -z "$TASK_CLASS" ] || [ -z "$TASK_FILE" ]; then
  usage
  exit 2
fi

if [ ! -f "$TASK_FILE" ]; then
  echo "Task file not found: $TASK_FILE" >&2
  exit 2
fi

select_provider() {
  if [ "$PROVIDER" != "auto" ]; then
    echo "$PROVIDER"
    return
  fi
  case "$TASK_CLASS" in
    repo-audit) echo "mimo" ;;
    code-patch) echo "opencode" ;;
    text-reasoning) echo "deepseek" ;;
    provider-health) echo "local" ;;
    report) echo "hermes" ;;
    *) echo "opencode" ;;
  esac
}

SELECTED_PROVIDER="$(select_provider)"
STATUS="PLANNED_NOT_EXECUTED"
COMMAND=""
NOTES=""

case "$SELECTED_PROVIDER" in
  opencode)
    if command -v opencode >/dev/null 2>&1; then
      COMMAND="opencode < $TASK_FILE"
      STATUS="READY_MANUAL_EXECUTION"
      NOTES="Run manually after reviewing task file. This scaffold does not auto-execute by default."
    else
      STATUS="PROVIDER_UNAVAILABLE"
      NOTES="opencode command not found"
    fi
    ;;
  mimo)
    if command -v mimo >/dev/null 2>&1; then
      COMMAND="mimo < $TASK_FILE"
      STATUS="READY_MANUAL_EXECUTION"
      NOTES="MiMo may require VPN depending on network."
    else
      STATUS="PROVIDER_UNAVAILABLE"
      NOTES="mimo command not found"
    fi
    ;;
  deepseek)
    if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
      STATUS="CONFIGURED_NOT_IMPLEMENTED"
      COMMAND="deepseek provider adapter pending"
      NOTES="API adapter intentionally not implemented in scaffold."
    else
      STATUS="CONFIG_MISSING"
      NOTES="DEEPSEEK_API_KEY not set"
    fi
    ;;
  hermes)
    if command -v hermes >/dev/null 2>&1; then
      COMMAND="hermes < $TASK_FILE"
      STATUS="READY_MANUAL_EXECUTION"
      NOTES="Hermes is reporting/provider-inventory layer."
    else
      STATUS="PROVIDER_UNAVAILABLE"
      NOTES="hermes command not found"
    fi
    ;;
  local)
    COMMAND="scripts/ai-router/provider-health.sh"
    STATUS="READY_MANUAL_EXECUTION"
    NOTES="Local shell task only."
    ;;
  *)
    STATUS="UNKNOWN_PROVIDER"
    NOTES="Provider $SELECTED_PROVIDER is not recognized"
    ;;
esac

cat > "$REPORT_FILE" <<MD
# ASDEV AI Router Task Plan

| Item | Value |
|---|---|
| Started | $STARTED_AT |
| Environment | $ENVIRONMENT_NAME |
| Task class | $TASK_CLASS |
| Task file | $TASK_FILE |
| Selected provider | $SELECTED_PROVIDER |
| Status | $STATUS |
| Command | \`$COMMAND\` |

## Notes

$NOTES

## Safety

This scaffold records routing decisions only. It does not call external APIs or execute agent commands automatically.
MD

cat > "$STATE_FILE" <<JSON
{
  "started_at": "$STARTED_AT",
  "environment": "$ENVIRONMENT_NAME",
  "task_class": "$TASK_CLASS",
  "task_file": "$TASK_FILE",
  "selected_provider": "$SELECTED_PROVIDER",
  "status": "$STATUS",
  "command": "$COMMAND",
  "report_file": "$REPORT_FILE"
}
JSON

echo "$REPORT_FILE"
