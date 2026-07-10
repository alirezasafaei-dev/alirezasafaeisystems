#!/usr/bin/env bash
# ASDEV AI provider health scaffold. Safe local-first script.
set -Eeuo pipefail

ROOT_DIR="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CONFIG_FILE="${ASDEV_AI_PROVIDERS_CONFIG:-$ROOT_DIR/config/ai-providers.example.json}"
REPORT_DIR="${ASDEV_AI_REPORT_DIR:-$ROOT_DIR/docs/reports/ai-router}"
STATE_DIR="${ASDEV_AI_STATE_DIR:-$ROOT_DIR/.state/ai-router}"
REPORT_FILE="$REPORT_DIR/latest-provider-status.md"
STATE_FILE="$STATE_DIR/latest.json"
ENVIRONMENT_NAME="${ASDEV_ENVIRONMENT:-LOCAL_PC}"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTNAME_VALUE="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"

mkdir -p "$REPORT_DIR" "$STATE_DIR"

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "AVAILABLE"
  else
    echo "CONFIG_MISSING"
  fi
}

mimo_status="$(check_cmd mimo)"
opencode_status="$(check_cmd opencode)"
hermes_status="$(check_cmd hermes)"
openclaw_status="$(check_cmd openclaw)"
deepseek_status="CONFIG_MISSING"
if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
  deepseek_status="AVAILABLE_CONFIGURED_NOT_CALLED"
fi

cat > "$REPORT_FILE" <<MD
# ASDEV AI Provider Status

| Item | Value |
|---|---|
| Started | $STARTED_AT |
| Environment | $ENVIRONMENT_NAME |
| Hostname | $HOSTNAME_VALUE |
| Config | $CONFIG_FILE |

## Providers

| Provider | Status | Notes |
|---|---|---|
| MiMo | $mimo_status | command check only |
| OpenCode | $opencode_status | command check only; first local MVP executor |
| DeepSeek | $deepseek_status | env-only check; no API call |
| Hermes | $hermes_status | command check only |
| OpenClaw | $openclaw_status | command check only; Telegram must remain disabled if Hermes owns Telegram |

## Verdict

This is a scaffold health check. It does not prove provider quality, token limits, or commercial suitability.
MD

cat > "$STATE_FILE" <<JSON
{
  "started_at": "$STARTED_AT",
  "environment": "$ENVIRONMENT_NAME",
  "hostname": "$HOSTNAME_VALUE",
  "config_file": "$CONFIG_FILE",
  "providers": {
    "mimo": "$mimo_status",
    "opencode": "$opencode_status",
    "deepseek": "$deepseek_status",
    "hermes": "$hermes_status",
    "openclaw": "$openclaw_status"
  },
  "report_file": "$REPORT_FILE"
}
JSON

echo "$REPORT_FILE"
