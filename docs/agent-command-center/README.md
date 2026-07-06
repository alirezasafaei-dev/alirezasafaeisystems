# ASDEV Agent Command Center

Purpose: one place for agent prompts and reports for ASDEV Audit execution.

Primary product: **ASDEV Audit Platform**.

## Read first

1. `docs/strategy/ASDEV_AUDIT_MASTER_ROADMAP.md`
2. `docs/strategy/FOCUS_POLICY.md`
3. `AGENTS.md`
4. `docs/agent-command-center/NEXT_AGENT_PROMPT.md`
5. `docs/agent-command-center/REPORT_TEMPLATE.md`

## Workflow

1. The next task is written in `NEXT_AGENT_PROMPT.md` or in the PR conversation.
2. If `NEXT_AGENT_PROMPT.md` says **No active implementation prompt**, do not execute runtime work. Wait for owner-approved prompt.
3. The agent executes only the approved task.
4. The agent reports in the PR conversation using `REPORT_TEMPLATE.md`.
5. The agent stops after reporting and waits for the next approved prompt.

## PersianToolbox protection (default)

PersianToolbox is protected production software (~101 tools, ~1300 tests).

The command center must **not** route sensitive PersianToolbox changes by default:

- No runtime, UI, routing, template, analytics, test, or build changes via `NEXT_AGENT_PROMPT.md` without explicit owner approval.
- Docs-only planning may be allowed when marked `BLOCKED / owner-approval-required / docs-plan only`.
- See `docs/automation/PERSIANTOOLBOX_PROTECTION.md` and PR `# Critical Guard — PersianToolbox Production Protection`.

Blocked default state heading: `# Next Agent Prompt — Awaiting Owner Approval`

## Valid ASDEV Audit goals

Every task must support at least one:

1. More submitted audits
2. Better and more trusted reports
3. More leads, signups, paid users, or agency contacts
4. Better production reliability, security, and operations
5. Lower audit cost, support cost, or execution time

If none apply, do not execute the task.

## Scope rule

Allowed focus:

- `auditsystems` as primary product
- `alirezasafaeisystems` as brand and governance hub
- `persiantoolbox` as traffic source

Frozen unless explicitly approved:

- DevAtlas standalone
- CreatorMembership
- MicroCatalog
- Rubika
- Novax
- Halo
- new products

## Stop and report before

- production deploy
- payment activation
- repository deletion
- force push
- broad architecture change
- work on frozen projects

## Automation

| Asset | Purpose |
|---|---|
| `scripts/agent-command-center/monitor-pr.sh` | Poll PR #42; detect unhandled prompts vs reports |
| `docs/agent-command-center/STATE.json` | Last handled prompt/report comment IDs |
| `.github/workflows/agent-command-center-hourly.yml` | Hourly monitor (warns if prompt pending) |

### Actionable prompt headings (monitor detects these)

- `# Next Agent Prompt — {title}` (except blocked default below)
- `Protected review requested.`
- `Hermes-first check requested.`
- `# Decision — {title}`

### Blocked prompt headings (no execution)

- `# Next Agent Prompt — Awaiting Owner Approval`

### Guard headings (read and obey; logged by monitor)

- `# Critical Guard — {title}`
- `# Monitoring Continues`

### Report heading (required after execution)

- `# Agent Execution Report — {title}`

### Monitor statuses

- `NO_PROMPT` — no actionable prompt comment yet
- `PROMPT_PENDING` — actionable prompt exists without a newer execution report
- `PROMPT_HANDLED_NEW` — report found; state updated
- `IDLE_WAITING` — waiting for next actionable prompt

### Agent protocol (every session)

1. Run `scripts/agent-command-center/monitor-pr.sh`
2. If `PROMPT_PENDING`, read latest `# Next Agent Prompt` comment or `NEXT_AGENT_PROMPT.md`
3. Execute, validate, commit (separate repos)
4. Post `# Agent Execution Report` on PR #42
5. Stop

## Note

This PR is the handoff channel. Agents should put execution reports here and wait for the next prompt.
