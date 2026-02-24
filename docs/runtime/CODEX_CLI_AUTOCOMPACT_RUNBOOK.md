# Codex CLI Auto Compact Runbook

This runbook standardizes Codex CLI bootstrap for this workstation with three goals:

1. Keep conversation compaction automatic and sized from real model metadata.
2. Ensure the OpenAI docs MCP is configured for official documentation lookups.
3. Keep required Codex skills installed for daily engineering workflows.

## Scope

Automation targets local Codex state under `~/.codex`:

- `~/.codex/config.toml`
- `~/.codex/models_cache.json`
- `~/.codex/skills/`
- global MCP registry managed via `codex mcp`

## Prerequisites

- `codex` CLI installed and authenticated
- `jq`
- `python3`
- network access to GitHub and `https://developers.openai.com/mcp`

## Commands

```bash
pnpm run codex:bootstrap
pnpm run codex:report
```

Equivalent direct calls:

```bash
bash scripts/codex/bootstrap-codex-cli.sh
bash scripts/codex/report-codex-cli-state.sh
```

## Auto Compact Policy

The bootstrap script computes `model_auto_compact_token_limit` from active model metadata:

- source: `context_window` and `effective_context_window_percent` from `~/.codex/models_cache.json`
- formula: `int(context_window * effective_percent/100 * 0.80)`
- floor: `100000`

If metadata is unavailable, the fallback profile is:

- `context_window = 272000`
- `effective_context_window_percent = 95`

## MCP Policy

`openaiDeveloperDocs` is required and enforced as a global MCP server:

```bash
codex mcp add openaiDeveloperDocs --url https://developers.openai.com/mcp
```

## Required Skills

The bootstrap enforces these curated skills (installing missing ones):

- `doc`
- `gh-fix-ci`
- `openai-docs`
- `playwright`
- `security-best-practices`
- `security-threat-model`

## Evidence

After each bootstrap, generate and commit a dated runtime snapshot in:

- `docs/runtime/CODEX_CLI_AUTOCOMPACT_STATUS_YYYY-MM-DD.md`

This captures actual local values for version, model, compact limit, MCP state, features, and skill installation state.
