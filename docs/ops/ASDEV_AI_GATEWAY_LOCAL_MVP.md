# ASDEV AI Gateway Local MVP

**Status:** Local-first MVP — active development  
**Environment:** `LOCAL_PC`  
**Policy:** `docs/governance/ASDEV_AI_GATEWAY_POLICY.md`

## Why this is internal infrastructure (not a public product)

ASDEV operates multiple AI agents and providers: MiMo, OpenCode, DeepSeek, Hermes, OpenClaw. Without a gateway, provider selection is ad-hoc, health is unknown, and fallback behavior is manual.

This AI Gateway is an **internal routing and observability layer** — not a public ChatGPT clone. It records which provider should handle which task, whether it is available, what limits exist, and what fallback was selected.

A public AI chat product requires:
- provider terms of service review
- hard rate limits and cost ceilings
- abuse prevention
- privacy/data routing policy
- admin monitoring
- monetization or cost control
- PersianToolbox revenue stabilization first

Until those conditions are met, this remains internal infrastructure only.

## Provider roles

| Provider | Role | Notes |
|---|---|---|
| MiMo | Long-context planning, repo-level audits | Huge context (~1M tokens); may need VPN from Iran |
| OpenCode | Code implementation, patching, tests | First local MVP executor on `LOCAL_PC` |
| DeepSeek | Low-cost reasoning/coding fallback | API adapter not yet implemented; do not treat free web access as stable |
| Hermes | Reporting, provider inventory, Telegram | Default reporting and provider status layer |
| OpenClaw | Gateway/diagnostic, MCP support | Diagnostic only; Telegram disabled by policy |
| Local model | Offline emergency fallback | Research only; not MVP-ready |

## Files

| File | Purpose |
|---|---|
| `docs/governance/ASDEV_AI_GATEWAY_POLICY.md` | Rules, routing policy, provider status vocabulary |
| `docs/ops/ASDEV_AI_PROVIDER_REGISTRY.md` | Provider registry, task mapping, test matrix |
| `config/ai-providers.example.json` | Safe example provider config (no secrets) |
| `scripts/ai-router/provider-health.sh` | Provider availability checker |
| `scripts/ai-router/run-task.sh` | Task router with `--dry-run`/`--execute` support |
| `prompts/ai-router/sample-repo-audit.md` | Sample repo-audit task |
| `prompts/ai-router/sample-code-patch.md` | Sample code-patch task |
| `prompts/ai-router/sample-provider-health.md` | Sample provider-health task |
| `docs/reports/ai-router/latest-provider-status.md` | Latest health check report |
| `.state/ai-router/latest.json` | Latest health check state (JSON) |

## Run provider health

```bash
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/provider-health.sh
```

The script:
- reads `config/ai-providers.example.json` (or `config/ai-providers.local.json` if present)
- checks command availability for MiMo, OpenCode, Hermes, OpenClaw
- checks DeepSeek as `CONFIG_MISSING` or `CONFIGURED_NOT_CALLED` without calling the API
- never prints secret environment values
- writes two outputs:

```text
docs/reports/ai-router/latest-provider-status.md   (human-readable)
.state/ai-router/latest.json                         (machine-readable)
```

## Route a task (dry-run)

Default mode is `--dry-run` — shows the routing plan without executing anything.

```bash
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --dry-run provider-health prompts/ai-router/sample-provider-health.md
```

Other task classes:

```bash
bash scripts/ai-router/run-task.sh --dry-run repo-audit    prompts/ai-router/sample-repo-audit.md
bash scripts/ai-router/run-task.sh --dry-run code-patch    prompts/ai-router/sample-code-patch.md
bash scripts/ai-router/run-task.sh --dry-run text-reasoning prompts/ai-router/sample-provider-health.md
bash scripts/ai-router/run-task.sh --dry-run report        prompts/ai-router/sample-provider-health.md
```

## Execute a safe local command

Only safe local commands (like `provider-health`) can be executed with `--execute`:

```bash
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --execute provider-health prompts/ai-router/sample-provider-health.md
```

Unsafe operations (external API calls, agent commands, SSH, production mutations) are refused with an error.

## Override provider selection

```bash
ASDEV_AI_PROVIDER=opencode bash scripts/ai-router/run-task.sh --dry-run code-patch prompts/ai-router/sample-code-patch.md
```

Valid overrides: `mimo`, `opencode`, `deepseek`, `hermes`, `openclaw`, `auto`.

## Run OpenCode manually

OpenCode is the implementation agent for this MVP. To use it directly:

```bash
# From workspace root
opencode
```

OpenCode reads prompts from `prompts/opencode/` directory. The current implementation prompt is `prompts/opencode/LOCAL_AI_GATEWAY_MVP.md`.

OpenCode does not require VPN on `LOCAL_PC`.

## Read reports

Reports are written to:

- `docs/reports/ai-router/latest-provider-status.md` — latest provider health status
- `docs/reports/ai-router/task-<RUN_ID>.md` — individual task routing plan or execution report

JSON state is written to:

- `.state/ai-router/latest.json` — latest health check state
- `.state/ai-router/task-<RUN_ID>.json` — individual task state

These files contain no secrets, no API keys, no tokens.

## Provider routing defaults

| Task class | Default provider | Fallback |
|---|---|---|
| `repo-audit` | MiMo | OpenCode (report mode) |
| `code-patch` | OpenCode | MiMo (patch plan) |
| `text-reasoning` | DeepSeek | OpenCode |
| `provider-health` | local script | Hermes report |
| `report` | Hermes | local scripts |

The router checks provider availability from the latest health state before selecting. If the preferred provider is unavailable, it records the fallback decision.

## Handoff to AUTOMATION_SERVER

Do not install this on `AUTOMATION_SERVER` until:

1. Local MVP passes all validation tests
2. Provider health reports are stable and accurate
3. Fallback behavior is verified with sample tasks
4. Secrets handling is proven safe (no leaks, no commits)
5. Owner explicitly approves automation rollout (`APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT`)

Potential future services on `AUTOMATION_SERVER`:

```text
asdev-ai-router.service
asdev-ai-router.timer
asdev-provider-health.service
asdev-provider-health.timer
```

The router scripts are designed to be environment-aware via `ASDEV_ENVIRONMENT` variable. Running on `AUTOMATION_SERVER` would use `ASDEV_ENVIRONMENT=AUTOMATION_SERVER`.

## Why public product is deferred

A public Persian AI chat product requires:

- verified provider contract (no personal/free accounts as backend)
- hard rate limits and abuse prevention
- cost monitoring and ceiling
- privacy policy and data routing controls
- admin dashboard and alerting
- monetization or sustainable cost model
- owner approval (`APPROVE_PUBLIC_AI_CHAT_PRODUCT`)
- PersianToolbox revenue stabilization and freeze acceptance

Until these conditions are met, the AI Gateway is internal infrastructure only.
