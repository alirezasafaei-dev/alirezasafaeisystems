# Environment Roles and Sync Policy — ASDEV

**Status:** Mandatory  
**Scope:** All ASDEV agents, scripts, servers, project repos, automation loops, deployment flows, and operator reports.

## Core purpose

This policy removes ambiguity between the owner's computer, the automation server, and the production servers. Every agent must use the exact environment names below and must not invent alternative names.

## Canonical environment names

| Canonical name | Meaning | Default role | Mutation policy |
|---|---|---|---|
| `LOCAL_PC` | The owner's own computer/workstation. MiMo is usually the primary commander here. | Command center, high-context orchestration, local review, SSH control of servers. | Local automation may be added only after `AUTOMATION_SERVER` is stable. |
| `AUTOMATION_SERVER` | External automation server, currently `asdev@91.107.153.223`. | Always-on automation loop, GitHub sync, queue worker, MCP, agent services, reporting. | Safe automation work allowed. Production-impacting actions remain gated. |
| `IRAN_PROD_SERVER` | Iran production/live deployment server where live sites are deployed. | Public production runtime for live websites/services. | Strictly gated. No deploy, rollback, nginx reload, DNS change, migration, or destructive mutation without exact approval phrase. |
| `GITHUB_MAIN` | GitHub `main` branch of the relevant canonical repo. | Source of truth for code, prompts, queue, policy, docs, and automation contracts. | All environments must sync from it safely. |

## Canonical agent roles

| Agent | Role | Allowed mode | Notes |
|---|---|---|---|
| `MiMo` | Primary orchestration agent. | Runs on `LOCAL_PC` and may also run on `AUTOMATION_SERVER`. | MiMo coordinates high-context work and decides when to call other agents. |
| `OpenCode` | Implementation and patch agent. | Called by MiMo or automation queue. | Use for code/script edits, refactors, tests, and targeted fixes. |
| `Hermes` | Telegram reporting/status/approval gateway. | Always-on service when configured. | Hermes is the default and only Telegram reporting owner. |
| `OpenClaw` | Gateway/diagnostic/MCP-support agent. | Active only for non-Telegram gateway/diagnostic unless explicitly changed. | Must not poll Telegram if Hermes owns Telegram. |
| `bot.js` | GitHub command-bus integration if still used. | Scheduled/service only when needed. | Must label GitHub Issue #45 as issue command bus, not as a branch. |

## GitHub source-of-truth rule

GitHub `main` is the source of truth for:

- prompt files
- queue files
- governance policies
- deploy verification rules
- automation scripts
- operational docs
- memory/current-state files
- report templates

If a file exists in GitHub `main`, agents must assume it is intended for automation unless a policy says otherwise.

## No-manual-normal-work rule

Normal automation work must not require the owner to:

- SSH into the server to manually copy prompt files
- manually paste a prompt into an agent because the server missed a GitHub update
- manually pull GitHub on `AUTOMATION_SERVER` after every commit
- manually tell the server to notice a queue item
- manually restart a loop after a safe agent failure

Manual owner action is allowed only for:

- exact approval gates
- secrets/account/license/token provisioning
- production deploy/rollback/migration/DNS/nginx actions
- hardware/network problems outside automation control
- local PC automation setup, which is explicitly a later phase

## Sync contract

Every automation environment must be able to answer:

1. What repo am I in?
2. What branch am I on?
3. What is local HEAD?
4. What is origin/main HEAD?
5. Is local clean/dirty?
6. Am I ahead/behind/diverged?
7. Did I pull latest policy/prompt/queue?
8. Did I ingest new safe queue tasks?
9. Did I report blockers?
10. Did I avoid gated production mutations?

## Required sync behavior

`AUTOMATION_SERVER` must run an automatic sync loop that:

- fetches `origin/main` periodically
- pulls/rebases when local repo is clean and remote is ahead
- commits safe generated reports/state when appropriate
- refuses destructive reset of unknown dirty changes
- writes a drift report when dirty/risky changes block pull
- validates prompt and queue files after pull
- triggers safe queue ingestion after pull
- reports status to logs and Telegram/Hermes if configured

`LOCAL_PC` may run the same sync script manually or by a local timer after `AUTOMATION_SERVER` is stable.

`IRAN_PROD_SERVER` must not auto-pull/deploy production code unless a separate production deployment policy explicitly allows it. It may run read-only health/reporting sync only.

## Stale-status rule

Agents and Telegram reports must never display stale or ambiguous status labels.

Bad examples:

- `branch 45`
- `running latest`
- `synced`
- `healthy`

Required examples:

- `repo=alirezasafaeisystems branch=main local=abc1234 origin=def5678 state=behind_by_1`
- `GitHub Issue #45 command bus active`
- `MCP local=:8000 public=/sse status=ok`
- `queue safe=3 gated=4 done=12`

If `45` means GitHub issue, say `GitHub Issue #45`, not branch.

## Telegram ownership rule

Hermes is the default Telegram reporting owner.

OpenClaw must not use Telegram polling while Hermes is configured for Telegram. If both try to use Telegram, agents must disable OpenClaw Telegram polling and keep OpenClaw for gateway/diagnostic only.

## Deployment and production gates

This policy does not weaken approval gates.

`IRAN_PROD_SERVER` is production. The following remain gated:

- deploy/cutover
- rollback
- nginx reload
- DNS changes
- migrations
- destructive cleanup
- public monitoring timer activation
- production secret/config mutation

## Reporting requirement

Every sync/automation cycle must write or update a report with:

- UTC timestamp
- environment name
- hostname
- repo path
- branch
- local HEAD
- origin/main HEAD
- clean/dirty state
- ahead/behind/diverged state
- safe generated changes committed or not
- prompt files found/missing
- queue counts
- services/timers health
- blocked/gated items
- next safe action

## Definition of done

The environment is considered clear and non-ambiguous only when:

- `LOCAL_PC`, `AUTOMATION_SERVER`, and `IRAN_PROD_SERVER` are labeled correctly in reports
- GitHub main is pulled automatically on `AUTOMATION_SERVER`
- prompt files committed to GitHub are discoverable by server automation
- queue files are ingested automatically
- Hermes/OpenClaw roles are not conflicting
- stale branch/status labels are fixed
- production actions remain gated
- reports prove the state without manual interpretation
