# ASDEV AI Gateway Policy

**Status:** Draft mandatory for local-first implementation  
**Scope:** ASDEV internal agents, `LOCAL_PC`, `AUTOMATION_SERVER`, future AI provider routing, and any PersianToolbox AI-assisted features.

## Purpose

ASDEV may use several AI providers and agents, but the system must not depend on one fragile provider or a manual prompt-paste workflow.

The goal is an internal AI Gateway that can route tasks to the best available provider while recording reliability, limits, latency, cost, and evidence.

This is an internal infrastructure project first. It is not approval to launch a public unlimited free ChatGPT clone.

## Canonical environments

Use the environment names from `docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md`:

- `LOCAL_PC` — owner workstation; first implementation target.
- `AUTOMATION_SERVER` — external automation server; later always-on routing and reporting target.
- `IRAN_PROD_SERVER` — production server; strictly gated and not part of the local-first MVP.
- `GITHUB_MAIN` — source of truth.

## Provider roles

| Provider / Agent | Primary role | Allowed first use | Notes |
|---|---|---|---|
| MiMo | long-context planning, repo-level reasoning, high-context audits | Manual/local orchestration | Strong for huge context; may need VPN from Iran; do not treat free access as permanent. |
| OpenCode | code implementation, patching, tests, local repo edits | First MVP executor on `LOCAL_PC` | Use while idle for local-first gateway implementation. |
| DeepSeek | low-cost/free-ish reasoning/coding/text fallback | Provider registry + manual checks first | Do not rely on unofficial free web access for a public product. |
| Hermes | reporting, Telegram, provider inventory, free model pool, routing status | Report/provider status | Default reporting layer. |
| OpenClaw | gateway/diagnostic/MCP support | Diagnostic only | Must not poll Telegram while Hermes owns Telegram. |
| Local model | emergency fallback, private/offline experiments | Research only | Not primary unless GPU/quality/cost are proven. |

## Internal vs public use

### Allowed now

- Internal ASDEV automation support.
- Local provider registry and health checks.
- Routing safe tasks to available agents.
- Capturing provider reliability and limits.
- Writing reports to GitHub.
- Preparing automation integration.

### Not allowed yet

- Public unlimited free chat for users.
- Proxying personal/free accounts as a public backend.
- Selling access to a provider whose terms, limits, and reliability are not approved.
- Sending private user data to unknown/free providers.
- Production integration on `IRAN_PROD_SERVER` without approval.

## Routing principles

The router must classify a task before choosing a provider:

| Task class | Preferred provider | Fallback |
|---|---|---|
| high-context repo audit | MiMo | DeepSeek / OpenCode report mode |
| code patch | OpenCode | MiMo instruction + manual patch |
| simple reasoning/text | DeepSeek | Hermes free pool |
| automation report | Hermes | local report only |
| provider health | local scripts | Hermes report |
| production mutation | none | gated approval only |

## Required metadata for every routed task

Every run must record:

- timestamp UTC
- environment name
- provider selected
- task class
- input source path or summary
- model name if known
- command used, redacted if needed
- duration
- exit status
- estimated token use if available
- cost if known
- whether VPN/proxy was needed
- output path
- error summary
- fallback chain used

## Safety rules

- No secrets in prompts, logs, reports, screenshots, traces, or GitHub commits.
- No `.env` files committed.
- No production mutation without approval.
- No public user data sent to free or unknown providers.
- No claim that a provider is free/permanent unless verified from official terms.
- No routing to an agent that is down without recording failure.
- No silent fallback; every fallback must be reported.
- No use of OpenClaw Telegram polling while Hermes owns Telegram.

## Provider status vocabulary

Use these exact statuses:

- `AVAILABLE`
- `AVAILABLE_WITH_VPN`
- `RATE_LIMITED`
- `AUTH_REQUIRED`
- `CONFIG_MISSING`
- `DOWN`
- `UNKNOWN_NOT_TESTED`
- `DISABLED_BY_POLICY`

## MVP definition

The local-first MVP is complete when `LOCAL_PC` has:

- provider registry file
- provider health script
- task routing script
- sample task execution
- report output
- OpenCode prompt for implementation
- no server or production mutation
- clear handoff plan to `AUTOMATION_SERVER`

## Automation handoff condition

Do not move this to `AUTOMATION_SERVER` until:

- local MVP works
- provider reports are stable
- secrets handling is proven safe
- fallback behavior is documented
- owner approves automation rollout

## Public product condition

Do not start a public AI chat product until PersianToolbox revenue stabilization is complete and the owner approves a separate business model.

A public product must have:

- hard rate limits
- abuse prevention
- provider terms review
- privacy/data routing policy
- monetization or cost ceiling
- admin monitoring
- user-facing reliability expectations
