#!/usr/bin/env bash
# ASDEV AI provider health checker — local-first MVP
# Reads provider config from JSON, checks availability, writes reports.
# Safe: No external API calls. No secrets printed.
set -Eeuo pipefail

ROOT_DIR="${ASDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Config priority: local.json > example.json
if [ -f "$ROOT_DIR/config/ai-providers.local.json" ]; then
  CONFIG_FILE="$ROOT_DIR/config/ai-providers.local.json"
else
  CONFIG_FILE="${ASDEV_AI_PROVIDERS_CONFIG:-$ROOT_DIR/config/ai-providers.example.json}"
fi

REPORT_DIR="${ASDEV_AI_REPORT_DIR:-$ROOT_DIR/docs/reports/ai-router}"
STATE_DIR="${ASDEV_AI_STATE_DIR:-$ROOT_DIR/.state/ai-router}"
REPORT_FILE="$REPORT_DIR/latest-provider-status.md"
STATE_FILE="$STATE_DIR/latest.json"
ENVIRONMENT_NAME="${ASDEV_ENVIRONMENT:-LOCAL_PC}"
STARTED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTNAME_VALUE="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"

mkdir -p "$REPORT_DIR" "$STATE_DIR"

check_cmd() {
  command -v "$1" >/dev/null 2>&1 && echo "AVAILABLE" || echo "CONFIG_MISSING"
}

# Default statuses per ASDEV_AI_GATEWAY_POLICY.md vocabulary
mimo_status="UNKNOWN_NOT_TESTED"
opencode_status="UNKNOWN_NOT_TESTED"
deepseek_status="CONFIG_MISSING"
hermes_status="UNKNOWN_NOT_TESTED"
openclaw_status="UNKNOWN_NOT_TESTED"
local_model_status="DISABLED_BY_POLICY"

# Parse provider config with jq
if command -v jq >/dev/null 2>&1 && [ -f "$CONFIG_FILE" ]; then
  PROVIDERS=$(jq -c '.providers[]' "$CONFIG_FILE" 2>/dev/null || true)
  if [ -n "$PROVIDERS" ]; then
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      id=$(echo "$p" | jq -r '.id // ""' 2>/dev/null || echo "")
      enabled=$(echo "$p" | jq -r '.enabled // false' 2>/dev/null || echo "false")
      cmd=$(echo "$p" | jq -r '.invocation.command // ""' 2>/dev/null || echo "")
      requires_vpn=$(echo "$p" | jq -r '.requires_vpn // "unknown"' 2>/dev/null || echo "unknown")
      env_vars=$(echo "$p" | jq -r '.invocation.env // [] | .[]' 2>/dev/null || echo "")

      case "$id" in
        mimo)
          if [ "$enabled" != "true" ]; then
            mimo_status="DISABLED_BY_POLICY"
          elif [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
            mimo_status="AVAILABLE"
            [ "$requires_vpn" = "true" ] && mimo_status="AVAILABLE_WITH_VPN"
          else
            mimo_status="CONFIG_MISSING"
          fi
          ;;
        opencode)
          if [ "$enabled" != "true" ]; then
            opencode_status="DISABLED_BY_POLICY"
          elif [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
            opencode_status="AVAILABLE"
          else
            opencode_status="CONFIG_MISSING"
          fi
          ;;
        deepseek)
          if [ "$enabled" != "true" ]; then
            deepseek_status="DISABLED_BY_POLICY"
          elif [ -n "$env_vars" ]; then
            all_set=true
            while IFS= read -r e; do
              [ -z "$e" ] && continue
              [ -z "${!e:-}" ] && all_set=false
            done <<< "$env_vars"
            if $all_set; then
              deepseek_status="CONFIGURED_NOT_CALLED"
            fi
          fi
          ;;
        hermes)
          if [ "$enabled" != "true" ]; then
            hermes_status="DISABLED_BY_POLICY"
          elif [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
            hermes_status="AVAILABLE"
          else
            hermes_status="CONFIG_MISSING"
          fi
          ;;
        openclaw)
          if [ "$enabled" != "true" ]; then
            openclaw_status="DISABLED_BY_POLICY"
          elif [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
            openclaw_status="AVAILABLE"
          else
            openclaw_status="CONFIG_MISSING"
          fi
          ;;
        local-small-model)
          local_model_status="DISABLED_BY_POLICY"
          ;;
      esac
    done <<< "$PROVIDERS"
  fi
else
  # Fallback: direct command checks without config JSON
  mimo_status=$(check_cmd mimo)
  opencode_status=$(check_cmd opencode)
  hermes_status=$(check_cmd hermes)
  openclaw_status=$(check_cmd openclaw)
  if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
    deepseek_status="CONFIGURED_NOT_CALLED"
  fi
fi

FINISHED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$REPORT_FILE" <<MD
# ASDEV AI Provider Status

| Item | Value |
|---|---|
| Started | $STARTED_AT |
| Finished | $FINISHED_AT |
| Environment | $ENVIRONMENT_NAME |
| Hostname | $HOSTNAME_VALUE |
| Config source | $CONFIG_FILE |

## Provider Status

| Provider | Status | Notes |
|---|---|---|
| MiMo | $mimo_status | long-context planning; may need VPN |
| OpenCode | $opencode_status | implementation/patch agent; MVP executor |
| DeepSeek | $deepseek_status | low-cost reasoning fallback; no API call |
| Hermes | $hermes_status | reporting & provider inventory |
| OpenClaw | $openclaw_status | gateway/diagnostic; Telegram disabled by policy |
| Local small model | $local_model_status | offline fallback; research only |

## Status Legend

| Status | Meaning |
|---|---|
| \`AVAILABLE\` | command found or config verified |
| \`AVAILABLE_WITH_VPN\` | available but VPN may be required |
| \`CONFIG_MISSING\` | command not found or env not set |
| \`CONFIGURED_NOT_CALLED\` | configured but no API call made |
| \`DISABLED_BY_POLICY\` | intentionally disabled per ASDEV policy |
| \`UNKNOWN_NOT_TESTED\` | not yet tested |

## Safety

This check does not call external APIs, print secrets, or execute provider commands.
MD

cat > "$STATE_FILE" <<JSON
{
  "started_at": "$STARTED_AT",
  "finished_at": "$FINISHED_AT",
  "environment": "$ENVIRONMENT_NAME",
  "hostname": "$HOSTNAME_VALUE",
  "config_file": "$CONFIG_FILE",
  "report_file": "$REPORT_FILE",
  "providers": {
    "mimo": "$mimo_status",
    "opencode": "$opencode_status",
    "deepseek": "$deepseek_status",
    "hermes": "$hermes_status",
    "openclaw": "$openclaw_status",
    "local-small-model": "$local_model_status"
  }
}
JSON

echo "$REPORT_FILE"
