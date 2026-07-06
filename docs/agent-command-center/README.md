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
2. The agent executes only that task.
3. The agent reports in the PR conversation using `REPORT_TEMPLATE.md`.
4. The agent stops after reporting and waits for the next approved prompt.

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

## Note

This PR is the handoff channel. Agents should put execution reports here and wait for the next prompt.
