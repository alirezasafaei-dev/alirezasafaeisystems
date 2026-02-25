#!/usr/bin/env bash

set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="${CODEX_HOME}/config.toml"
MODELS_CACHE="${CODEX_HOME}/models_cache.json"
REPORT_DATE_UTC="$(date -u +%F)"
OUTPUT_PATH="${1:-docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_${REPORT_DATE_UTC}.md}"
LATEST_PATH="$(dirname "$OUTPUT_PATH")/CODEX_CLI_AUTOCOMPACT_STATUS_LATEST.md"

[[ -f "$CONFIG_FILE" ]] || {
  echo "Codex config not found at ${CONFIG_FILE}" >&2
  exit 1
}

mkdir -p "$(dirname "$OUTPUT_PATH")"

ACTIVE_MODEL="$(awk -F' = ' '/^model = / { gsub(/"/, "", $2); print $2; exit }' "$CONFIG_FILE")"
REASONING_EFFORT="$(awk -F' = ' '/^model_reasoning_effort = / { gsub(/"/, "", $2); print $2; exit }' "$CONFIG_FILE")"
AUTO_COMPACT_LIMIT="$(awk -F' = ' '/^model_auto_compact_token_limit = / { print $2; exit }' "$CONFIG_FILE")"

CACHE_FETCHED_AT=""
CONTEXT_WINDOW=""
EFFECTIVE_PERCENT=""

if [[ -f "$MODELS_CACHE" ]]; then
  CACHE_FETCHED_AT="$(jq -r '.fetched_at // empty' "$MODELS_CACHE")"
  CONTEXT_WINDOW="$(jq -r --arg model "$ACTIVE_MODEL" '.models[]? | select(.slug == $model) | .context_window // empty' "$MODELS_CACHE" | head -n 1)"
  EFFECTIVE_PERCENT="$(jq -r --arg model "$ACTIVE_MODEL" '.models[]? | select(.slug == $model) | .effective_context_window_percent // empty' "$MODELS_CACHE" | head -n 1)"
fi

CODEX_VERSION="$(codex --version 2>/dev/null || true)"
MCP_LIST="$(codex mcp list 2>/dev/null || true)"
MCP_OPENAI_DOCS="$(codex mcp get openaiDeveloperDocs 2>/dev/null || true)"
FEATURES_ACTIVE="$(codex features list 2>/dev/null | rg '^((multi_agent|apps|skill_mcp_dependency_install|use_linux_sandbox_bwrap))[[:space:]]' || true)"
CRON_MAINTAIN_ENTRY="$(crontab -l 2>/dev/null | rg --fixed-strings 'codex-cli-maintain' || true)"

REQUIRED_SKILLS=(
  doc
  gh-fix-ci
  openai-docs
  playwright
  security-best-practices
  security-threat-model
)

{
  echo "# Codex CLI Auto Compact Status (${REPORT_DATE_UTC})"
  echo
  echo "Generated on $(date -u +'%Y-%m-%d %H:%M:%S UTC')."
  echo
  echo "## Effective Configuration"
  echo "- Codex CLI version: \`${CODEX_VERSION:-unknown}\`"
  echo "- Active model: \`${ACTIVE_MODEL:-unknown}\`"
  echo "- Reasoning effort: \`${REASONING_EFFORT:-unknown}\`"
  echo "- model_auto_compact_token_limit: \`${AUTO_COMPACT_LIMIT:-unset}\`"
  echo "- models_cache fetched_at: \`${CACHE_FETCHED_AT:-unknown}\`"
  echo "- model context_window: \`${CONTEXT_WINDOW:-unknown}\`"
  echo "- model effective_context_window_percent: \`${EFFECTIVE_PERCENT:-unknown}\`"
  echo
  echo "## MCP Status"
  echo '```text'
  printf '%s\n' "$MCP_LIST"
  echo ""
  printf '%s\n' "$MCP_OPENAI_DOCS"
  echo '```'
  echo
  echo "## Feature Flags (selected)"
  echo '```text'
  printf '%s\n' "$FEATURES_ACTIVE"
  echo '```'
  echo
  echo "## Required Skills"
  for skill in "${REQUIRED_SKILLS[@]}"; do
    if [[ -d "${CODEX_HOME}/skills/${skill}" ]]; then
      echo "- ${skill}: installed"
    else
      echo "- ${skill}: missing"
    fi
  done
  echo
  echo "## Scheduled Maintenance (cron)"
  if [[ -n "$CRON_MAINTAIN_ENTRY" ]]; then
    echo '```text'
    printf '%s\n' "$CRON_MAINTAIN_ENTRY"
    echo '```'
  else
    echo "- no codex maintenance cron entry found"
  fi
  echo
  echo "## Verification Commands"
  echo '```bash'
  echo "codex --version"
  echo "codex mcp list"
  echo "codex mcp get openaiDeveloperDocs"
  echo "codex features list | rg '^((multi_agent|apps|skill_mcp_dependency_install|use_linux_sandbox_bwrap))[[:space:]]'"
  echo "crontab -l | rg --fixed-strings 'codex-cli-maintain'"
  echo "awk -F' = ' '/^model_auto_compact_token_limit = / { print \$2; exit }' ~/.codex/config.toml"
  echo '```'
} > "$OUTPUT_PATH"

if [[ "$OUTPUT_PATH" != "$LATEST_PATH" ]]; then
  cp "$OUTPUT_PATH" "$LATEST_PATH"
  echo "Wrote ${OUTPUT_PATH}"
  echo "Wrote ${LATEST_PATH}"
else
  echo "Wrote ${OUTPUT_PATH}"
fi
