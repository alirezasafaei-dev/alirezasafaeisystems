# ASDEV AI Provider Registry

**Status:** Initial local-first registry  
**Owner environment:** `LOCAL_PC`  
**Policy:** `docs/governance/ASDEV_AI_GATEWAY_POLICY.md`

## Summary

This registry tracks provider capability, access, limitations, and the intended routing role for ASDEV internal automation.

The values below are operational starting assumptions and must be verified by local scripts before any provider is marked production-worthy.

## Providers

| Provider | Role | Current access assumption | VPN/proxy | Main risk | First action |
|---|---|---|---|---|---|
| MiMo | Primary long-context reasoning and planning | User reports heavy use with ~1M token sessions | VPN likely needed from Iran | access policy/availability can change | verify CLI/UI invocation and record limits |
| OpenCode | Implementation agent | Installed/usable locally | no VPN reported | model-specific limits | implement local AI gateway MVP |
| DeepSeek | low-cost/free-ish reasoning/coding fallback | web/free access exists; API terms must be checked | unknown | public/free access is not a stable backend contract | add provider profile, do not public-proxy |
| Hermes | reporting + provider inventory/free model pool | configured on automation stack | proxy via Hermes if configured | provider list may drift | export configured provider inventory safely |
| OpenClaw | gateway/diagnostic/MCP helper | active as gateway/diagnostic | depends on deployment | Telegram conflict | keep Telegram polling disabled |
| Local model | offline fallback | not selected | none after model download | quality/GPU/latency | research only after MVP |

## Provider test matrix

Every provider test must record:

| Field | Required |
|---|---|
| timestamp UTC | yes |
| environment | yes |
| provider | yes |
| command or invocation | yes, redacted |
| model name | if known |
| VPN/proxy needed | yes/no/unknown |
| auth required | yes/no/unknown |
| success | yes/no |
| latency seconds | yes |
| token estimate | if available |
| rate-limit observed | yes/no |
| error | summarized |
| output sample | safe excerpt only |

## Task routing defaults

| Task | Primary | Fallback 1 | Fallback 2 |
|---|---|---|---|
| huge repo audit | MiMo | DeepSeek | OpenCode report-only |
| code patch | OpenCode | MiMo-generated patch plan | manual GitHub edit |
| prompt compression | DeepSeek | MiMo | Hermes pool |
| server status report | Hermes | local scripts | OpenCode summary |
| provider health | local script | Hermes report | manual inspection |
| production deploy | none | gated | gated |

## Local-first MVP acceptance

The MVP must create:

- `config/ai-providers.example.json`
- `scripts/ai-router/provider-health.sh`
- `scripts/ai-router/run-task.sh`
- `docs/reports/ai-router/latest-provider-status.md`
- `.state/ai-router/latest.json` locally, ignored if sensitive
- a safe sample run with OpenCode

## Public-product warning

Do not expose personal/free provider accounts to public users.

A future public Persian AI assistant must use an approved commercial/provider contract, strict rate limits, abuse controls, and a monetization model.
