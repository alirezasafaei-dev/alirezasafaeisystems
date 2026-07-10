# OpenCode Prompt — LOCAL AI Gateway MVP

```text
RUN_CONTEXT: LOCAL_PC

You are OpenCode, the IMPLEMENTATION_AGENT for ASDEV.

Your job is to build the local-first MVP of the ASDEV AI Gateway. Do not touch production. Do not deploy. Do not SSH to IRAN_PROD_SERVER. Do not mutate AUTOMATION_SERVER unless explicitly instructed after local MVP passes.

Definitions:
- LOCAL_PC = owner's workstation. This is the target for the MVP.
- AUTOMATION_SERVER = asdev@91.107.153.223. Later handoff target only.
- IRAN_PROD_SERVER = live production deployment server. Strictly gated.
- GITHUB_MAIN = source of truth.
- PRIMARY_AGENT = MiMo.
- IMPLEMENTATION_AGENT = OpenCode.
- REPORTING_AGENT = Hermes.
- OPENCLAW = gateway/diagnostic only; no Telegram polling while Hermes owns Telegram.

Read first:
1. docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md
2. docs/governance/ASDEV_AI_GATEWAY_POLICY.md
3. docs/ops/ASDEV_AI_PROVIDER_REGISTRY.md
4. config/ai-providers.example.json
5. scripts/ai-router/provider-health.sh
6. scripts/ai-router/run-task.sh
7. docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md
8. docs/memory/ASDEV_CURRENT_STATE.md

Context:
The user has access to multiple AI agents/providers:
- MiMo: huge context, can use ~1M tokens per session, may require VPN from Iran.
- OpenCode: good implementation agent, no VPN, but some model limits.
- DeepSeek: free/cheap models, good fallback, but public/free access must not be treated as a stable backend contract.
- Hermes: reporting and configured free model pool.
- OpenClaw: gateway/diagnostic only.

Goal:
Create a safe local AI Gateway MVP that can:
- inventory available providers
- check provider health without secrets leakage
- select a provider based on task class
- generate a routing plan/report
- prepare for future automation integration

Hard rules:
1. Do not call production systems.
2. Do not deploy anything.
3. Do not commit secrets, .env files, tokens, cookies, browser profiles, logs with private data, or provider credentials.
4. Do not proxy personal/free AI accounts as a public product.
5. Do not claim a provider is stable/free/permanent unless verified from safe local evidence and official terms.
6. Do not make LOCAL_PC fully looped yet.
7. Do not start public AI chat product work.
8. Keep this internal infrastructure only.

Implementation tasks:

P0 — repo and baseline
- Confirm repo status.
- Create a working branch if local policy requires it.
- Verify scripts are executable or make them executable.
- Run shellcheck if available, but do not fail only because shellcheck is missing.

P1 — provider health script
Improve `scripts/ai-router/provider-health.sh` so it:
- reads `config/ai-providers.example.json` or `config/ai-providers.local.json` if present
- never prints secret env values
- checks command availability for MiMo/OpenCode/Hermes/OpenClaw
- checks DeepSeek only as CONFIG_MISSING or CONFIGURED_NOT_CALLED unless a safe adapter exists
- writes:
  - docs/reports/ai-router/latest-provider-status.md
  - .state/ai-router/latest.json
- uses exact statuses from policy:
  AVAILABLE, AVAILABLE_WITH_VPN, RATE_LIMITED, AUTH_REQUIRED, CONFIG_MISSING, DOWN, UNKNOWN_NOT_TESTED, DISABLED_BY_POLICY

P2 — task routing script
Improve `scripts/ai-router/run-task.sh` so it:
- supports task classes:
  repo-audit, code-patch, text-reasoning, provider-health, report
- selects provider by policy
- supports ASDEV_AI_PROVIDER override
- supports `--dry-run` default
- supports `--execute` only for safe local commands and only after showing the selected command
- writes Markdown + JSON report
- records fallback decision if selected provider unavailable
- never executes production mutation commands

P3 — sample tasks
Create safe sample task files:
- prompts/ai-router/sample-repo-audit.md
- prompts/ai-router/sample-code-patch.md
- prompts/ai-router/sample-provider-health.md

Each sample must be harmless and must not require secrets.

P4 — documentation
Create or update:
- docs/ops/ASDEV_AI_GATEWAY_LOCAL_MVP.md

It must explain:
- why this is internal-first, not public ChatGPT clone
- provider roles
- how to run provider health
- how to route a task dry-run
- how to run OpenCode manually
- how to read reports
- how to hand off to AUTOMATION_SERVER later
- why public product is deferred until PersianToolbox revenue stabilization/freeze

P5 — validation
Run:
- bash -n scripts/ai-router/provider-health.sh
- bash -n scripts/ai-router/run-task.sh
- ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/provider-health.sh
- ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh provider-health prompts/ai-router/sample-provider-health.md

If shellcheck exists:
- shellcheck scripts/ai-router/provider-health.sh scripts/ai-router/run-task.sh

P6 — final report
Create:
- docs/reports/ai-router/LOCAL_AI_GATEWAY_MVP_<UTC_TIMESTAMP>.md

Include:
- verdict: LOCAL_AI_GATEWAY_MVP_PASS / WITH_WARNINGS / BLOCKED
- commands run
- provider status summary
- files changed
- tests run
- what was not tested
- automation handoff readiness
- next safe action

Commit changes with a clear message.

Do not claim automation integration is complete. This is local-first only.
```
