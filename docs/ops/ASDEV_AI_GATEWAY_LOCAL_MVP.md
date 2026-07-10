# ASDEV AI Gateway Local MVP

**Status:** Local-first scaffold  
**Environment:** `LOCAL_PC`  
**Policy:** `docs/governance/ASDEV_AI_GATEWAY_POLICY.md`

## Why this exists

ASDEV uses several AI agents and providers: MiMo, OpenCode, DeepSeek, Hermes, OpenClaw, and possible local models.

The gateway prevents confusion and provider lock-in by recording which provider should handle which task, whether it is available, what limits it has, and what fallback was chosen.

## Why this is not a public product yet

The uploaded research report suggests a public Persian AI chatbot can be built with open-source stacks and free providers. The implementation risk is not the chat UI; it is provider stability, cost, abuse, rate limits, GPU cost, and terms of service.

Therefore this starts as an internal ASDEV infrastructure tool. Public AI chat is deferred until PersianToolbox revenue stabilization and owner approval.

## Files

| File | Purpose |
|---|---|
| `docs/governance/ASDEV_AI_GATEWAY_POLICY.md` | rules and routing policy |
| `docs/ops/ASDEV_AI_PROVIDER_REGISTRY.md` | provider registry and task mapping |
| `config/ai-providers.example.json` | safe example provider config |
| `scripts/ai-router/provider-health.sh` | provider availability scaffold |
| `scripts/ai-router/run-task.sh` | task routing scaffold |
| `prompts/opencode/LOCAL_AI_GATEWAY_MVP.md` | OpenCode implementation prompt |

## Run provider health

```bash
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/provider-health.sh
```

Expected outputs:

```text
docs/reports/ai-router/latest-provider-status.md
.state/ai-router/latest.json
```

## Route a task plan

```bash
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh provider-health prompts/ai-router/sample-provider-health.md
```

The scaffold writes a routing plan. It does not auto-execute external providers by default.

## Provider defaults

| Task class | Default provider |
|---|---|
| `repo-audit` | MiMo |
| `code-patch` | OpenCode |
| `text-reasoning` | DeepSeek |
| `provider-health` | local script |
| `report` | Hermes |

Override with:

```bash
ASDEV_AI_PROVIDER=opencode bash scripts/ai-router/run-task.sh code-patch prompts/ai-router/sample-code-patch.md
```

## Handoff to automation server

Do not install this as an always-on automation service until:

- local MVP passes
- provider health reports are stable
- fallback behavior is verified
- secrets handling is proven safe
- owner approves automation rollout

Potential future service on `AUTOMATION_SERVER`:

```text
asdev-ai-router.service
asdev-ai-router.timer
```

## Public product gate

A public AI chat product needs a separate decision and business model.

Minimum requirements:

- provider terms checked
- rate limits
- cost cap
- abuse controls
- privacy/data routing policy
- admin monitoring
- monetization plan
- PersianToolbox revenue stabilization complete
