# ASDEV AI Gateway — Local MVP Report

**Generated:** 2026-07-10T14:54:39Z  
**Verdict:** LOCAL_AI_GATEWAY_MVP_PASS  
**Environment:** LOCAL_PC  
**Agent:** OpenCode (implementation agent)  
**Policy:** `docs/governance/ASDEV_AI_GATEWAY_POLICY.md`

## Commands executed

```bash
# Syntax checks
bash -n scripts/ai-router/provider-health.sh         # PASS
bash -n scripts/ai-router/run-task.sh                # PASS

# Provider health check
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/provider-health.sh    # PASS

# Task router — dry-run (default mode)
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --dry-run provider-health prompts/ai-router/sample-provider-health.md   # PASS
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --dry-run code-patch prompts/ai-router/sample-code-patch.md           # PASS
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --dry-run repo-audit prompts/ai-router/sample-repo-audit.md           # PASS
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --dry-run text-reasoning prompts/ai-router/sample-provider-health.md # PASS

# Task router — execute mode (safe local only)
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --execute provider-health prompts/ai-router/sample-provider-health.md # PASS (EXECUTED_SUCCESS)

# Safety gate — unsafe execute refused
ASDEV_ENVIRONMENT=LOCAL_PC bash scripts/ai-router/run-task.sh --execute code-patch prompts/ai-router/sample-code-patch.md           # PASS (EXECUTION_REFUSED_SAFETY)
```

## Provider status summary

| Provider | Status | Evidence |
|---|---|---|
| MiMo | `AVAILABLE` | `mimo` command found on LOCAL_PC |
| OpenCode | `AVAILABLE` | `opencode` command found |
| DeepSeek | `DISABLED_BY_POLICY` | Disabled in config; API adapter not implemented |
| Hermes | `AVAILABLE` | `hermes` command found |
| OpenClaw | `AVAILABLE` | `openclaw` command found; Telegram disabled by policy |
| Local small model | `DISABLED_BY_POLICY` | Not MVP-ready |

## Files changed

| File | Change |
|---|---|
| `scripts/ai-router/provider-health.sh` | Rewritten: reads JSON config, uses policy status vocabulary, jq parsing, safe env checks |
| `scripts/ai-router/run-task.sh` | Rewritten: `--dry-run`/`--execute` flags, fallback chain, safety gate, better reporting |
| `docs/ops/ASDEV_AI_GATEWAY_LOCAL_MVP.md` | Updated: dry-run/execute docs, provider roles, handoff plan, public product deferral |

## New files created

- `docs/reports/ai-router/latest-provider-status.md` — status report
- `.state/ai-router/latest.json` — JSON state (gitignored)
- `docs/reports/ai-router/LOCAL_AI_GATEWAY_MVP_20260710T145439Z.md` — this report

## Existing files (verified, no changes needed)

- `config/ai-providers.example.json` — provider registry config (no secrets)
- `prompts/ai-router/sample-provider-health.md` — sample task
- `prompts/ai-router/sample-code-patch.md` — sample task
- `prompts/ai-router/sample-repo-audit.md` — sample task
- `docs/governance/ASDEV_AI_GATEWAY_POLICY.md` — governance policy
- `docs/ops/ASDEV_AI_PROVIDER_REGISTRY.md` — provider registry docs
- `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md` — queue
- `docs/memory/ASDEV_CURRENT_STATE.md` — memory state

## Tests performed

- Syntax check: `bash -n` on both scripts — PASS
- Provider health: script runs, reads config, reports statuses — PASS
- Task router dry-run: all 4 task classes produce routing plans — PASS
- Task router execute: safe local command runs successfully — PASS
- Safety gate: unsafe `--execute` correctly refused with `EXECUTION_REFUSED_SAFETY` — PASS
- State files: `.state/ai-router/` is gitignored — CONFIRMED
- No secrets leaked in any report output — CONFIRMED

## What was not tested

- DeepSeek API adapter (not implemented — intentionally deferred by policy)
- MiMo actual invocation (manual setup, may need VPN)
- Hermes full reporting pipeline (requires automation server context)
- shellcheck (not installed on LOCAL_PC — acceptable per P0 rules)
- Cross-environment runs (AUTOMATION_SERVER, IRAN_PROD_SERVER not touched)

## Automation handoff readiness

| Criteria | Status |
|---|---|
| Local MVP works | PASS |
| Provider reports stable | PASS |
| Secrets handling proven safe | PASS (no secrets in reports, state gitignored) |
| Fallback behavior documented | PASS |
| Owner approves rollout | PENDING (`APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT`) |

**Not ready for automation server deployment yet.** Requires owner approval.

## Next safe actions

1. Owner reviews and approves this report
2. Update `docs/memory/ASDEV_CURRENT_STATE.md` with AI Gateway progress
3. Owner provides `APPROVE_AI_GATEWAY_AUTOMATION_ROLLOUT` when ready
4. Install router services on `AUTOMATION_SERVER` after approval
5. Implement DeepSeek safe API adapter (after provider terms review)
