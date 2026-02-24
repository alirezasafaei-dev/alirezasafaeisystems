#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '[codex-bootstrap] %s\n' "$*"
}

die() {
  printf '[codex-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="${CODEX_HOME}/config.toml"
MODELS_CACHE="${CODEX_HOME}/models_cache.json"
SKILLS_DIR="${CODEX_HOME}/skills"
SKILL_INSTALLER="${SKILLS_DIR}/.system/skill-installer/scripts/install-skill-from-github.py"

require_command codex
require_command jq
require_command python3
[[ -f "$CONFIG_FILE" ]] || die "Codex config not found at ${CONFIG_FILE}"

ACTIVE_MODEL="$(awk -F' = ' '/^model = / { gsub(/"/, "", $2); print $2; exit }' "$CONFIG_FILE")"
if [[ -z "$ACTIVE_MODEL" ]]; then
  ACTIVE_MODEL="gpt-5.3-codex"
  log "No explicit model found in config; using fallback ${ACTIVE_MODEL}"
fi

CONTEXT_WINDOW=""
EFFECTIVE_PERCENT=""

if [[ -f "$MODELS_CACHE" ]]; then
  CONTEXT_WINDOW="$(jq -r --arg model "$ACTIVE_MODEL" '.models[]? | select(.slug == $model) | .context_window // empty' "$MODELS_CACHE" | head -n 1)"
  EFFECTIVE_PERCENT="$(jq -r --arg model "$ACTIVE_MODEL" '.models[]? | select(.slug == $model) | .effective_context_window_percent // empty' "$MODELS_CACHE" | head -n 1)"
fi

if [[ ! "$CONTEXT_WINDOW" =~ ^[0-9]+$ ]]; then
  CONTEXT_WINDOW=272000
fi

if [[ ! "$EFFECTIVE_PERCENT" =~ ^[0-9]+$ ]]; then
  EFFECTIVE_PERCENT=95
fi

TARGET_LIMIT="$(awk -v context="$CONTEXT_WINDOW" -v pct="$EFFECTIVE_PERCENT" 'BEGIN { value = int((context * pct / 100) * 0.80); if (value < 100000) value = 100000; print value }')"
CURRENT_LIMIT="$(awk -F' = ' '/^model_auto_compact_token_limit = / { print $2; exit }' "$CONFIG_FILE" || true)"

if [[ "$CURRENT_LIMIT" == "$TARGET_LIMIT" ]]; then
  log "Auto compact limit already set to ${TARGET_LIMIT}."
else
  if grep -qE '^model_auto_compact_token_limit = [0-9]+' "$CONFIG_FILE"; then
    sed -i -E "s/^model_auto_compact_token_limit = [0-9]+/model_auto_compact_token_limit = ${TARGET_LIMIT}/" "$CONFIG_FILE"
  else
    printf '\nmodel_auto_compact_token_limit = %s\n' "$TARGET_LIMIT" >> "$CONFIG_FILE"
  fi
  log "Set model_auto_compact_token_limit=${TARGET_LIMIT} (model=${ACTIVE_MODEL}, context=${CONTEXT_WINDOW}, effective_pct=${EFFECTIVE_PERCENT})."
fi

if codex mcp get openaiDeveloperDocs >/dev/null 2>&1; then
  log "MCP server openaiDeveloperDocs already configured."
else
  codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp >/dev/null
  log "Added MCP server openaiDeveloperDocs."
fi

REQUIRED_SKILLS=(
  doc
  gh-fix-ci
  openai-docs
  playwright
  security-best-practices
  security-threat-model
)

if [[ ! -f "$SKILL_INSTALLER" ]]; then
  log "Skill installer script not found at ${SKILL_INSTALLER}; skipping auto install."
else
  for skill in "${REQUIRED_SKILLS[@]}"; do
    if [[ -d "${SKILLS_DIR}/${skill}" ]]; then
      log "Skill '${skill}' already installed."
      continue
    fi

    log "Installing missing skill '${skill}'..."
    python3 "$SKILL_INSTALLER" \
      --repo openai/skills \
      --path "skills/.curated/${skill}"
  done
fi

FINAL_LIMIT="$(awk -F' = ' '/^model_auto_compact_token_limit = / { print $2; exit }' "$CONFIG_FILE")"
log "Completed. Active model=${ACTIVE_MODEL}; auto compact limit=${FINAL_LIMIT}."
