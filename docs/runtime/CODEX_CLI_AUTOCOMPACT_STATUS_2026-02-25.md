# Codex CLI Auto Compact Status (2026-02-25)

Generated on 2026-02-25 18:08:09 UTC.

## Effective Configuration
- Codex CLI version: `codex-cli 0.104.0`
- Active model: `gpt-5.3-codex`
- Reasoning effort: `xhigh`
- model_auto_compact_token_limit: `206720`
- models_cache fetched_at: `2026-02-25T18:08:02.905058460Z`
- model context_window: `272000`
- model effective_context_window_percent: `95`

## MCP Status
```text
Name                 Url                                Bearer Token Env Var  Status   Auth       
openaiDeveloperDocs  https://developers.openai.com/mcp  -                     enabled  Unsupported

openaiDeveloperDocs
  enabled: true
  transport: streamable_http
  url: https://developers.openai.com/mcp
  bearer_token_env_var: -
  http_headers: -
  env_http_headers: -
  remove: codex mcp remove openaiDeveloperDocs
```

## Feature Flags (selected)
```text
use_linux_sandbox_bwrap          experimental       true
multi_agent                      experimental       true
apps                             experimental       true
skill_mcp_dependency_install     stable             true
```

## Required Skills
- doc: installed
- gh-fix-ci: installed
- openai-docs: installed
- playwright: installed
- security-best-practices: installed
- security-threat-model: installed

## Scheduled Maintenance (cron)
```text
17 3 * * * /usr/bin/env bash -lc 'cd "/home/dev/Project_Me_All/Project_Me/alirezasafaeisystems" && bash scripts/codex/maintain-codex-cli.sh --push >> artifacts/codex-cli-maintain.log 2>&1' # codex-cli-maintain
```

## Verification Commands
```bash
codex --version
codex mcp list
codex mcp get openaiDeveloperDocs
codex features list | rg '^((multi_agent|apps|skill_mcp_dependency_install|use_linux_sandbox_bwrap))[[:space:]]'
crontab -l | rg --fixed-strings 'codex-cli-maintain'
awk -F' = ' '/^model_auto_compact_token_limit = / { print $2; exit }' ~/.codex/config.toml
```
