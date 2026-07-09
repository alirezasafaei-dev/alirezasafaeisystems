# Agent Operating Rules — ASDEV

**Last Updated:** 2026-07-08
**Status:** Active

---

## Rule 1: GitHub Is Source of Truth

All planning, goals, rules, memory, and task state live in GitHub. Never store authoritative state only on OWNER_PC, AUTOMATION_HOST, or IRAN_PROD.

## Rule 2: Read Before Work

Before any task, read in order:
1. `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` (**loop governance — mandatory**)
2. ASDEV.md
3. docs/automation/ASDEV_SOURCE_OF_TRUTH.md
4. docs/memory/ASDEV_CURRENT_STATE.md
5. docs/automation/AGENT_MEMORY.md
6. docs/strategy/FOCUS_POLICY.md
7. docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md / control-plane/queue/queue.json

## Rule 3: Focus Alignment

Every task must support one of:
1. More submitted audits
2. Better and more trusted reports
3. More leads, signups, paid users, or agency contacts
4. Better production reliability, security, and operations
5. Lower audit cost, support cost, or execution time

If none apply, reject the task.

## Rule 4: Validation Before Done

All code changes must pass:
- `pnpm lint`
- `pnpm type-check`
- `pnpm test`
- `pnpm build`

No exceptions. No skipping.

## Rule 5: Focused PRs

One logical change per PR. Never bundle unrelated changes. PR descriptions must follow the handoff protocol.

## Rule 6: No Merge Without Owner Review

Agents never merge their own PRs. Owner review is required for all merges. Auto-merge is only allowed for:
- Docs-only changes
- Tests-only changes
- Bot fixes
- Monitoring scripts

## Rule 7: No Deploy Without Owner Approval

Deploying to IRAN_PROD requires explicit owner approval. No auto-deploy. No silent deploy.

## Rule 8: Handoff Protocol

Every completed task must produce a handoff per `AGENT_HANDOFF_PROTOCOL.md` with all seven required fields.

## Rule 9: Agent Memory Updates

After completing work, update `AGENT_MEMORY.md` with:
- Decisions made
- Blockers found
- Current state
- Next actions

## Rule 10: No Secrets in Code or Memory

Never commit `.env` files, API keys, passwords, tokens, or credentials. Never log secrets. Never include secrets in agent memory or handoffs.

## Rule 11: No Destructive Operations Without Approval

The following require explicit owner approval:
- Force push
- Hard reset
- Branch deletion
- Database migration in production
- File deletion in production
- Firewall or fail2ban changes

## Rule 12: Respect Backup-Wait Directives

When backup-wait is active:
- No server access
- No deploy/install/build/restart/reload
- No deletion
- No sensitive material in reports
- No merge without owner review

## Rule 13: Report to Command Center

Post status updates to Issue #45. Do not require owner to copy-paste between tools.

## Rule 14: Autonomous Sprint Rule

When idle (no blockers, no open PRs, healthy live site), automatically start the next highest-value sprint per priority order in ASDEV_OPERATING_DOCTRINE.md.

## Rule 15: No Scope Creep

Do not add features, refactor code, or introduce abstractions beyond what the task requires. Stay focused.

---

*These rules are mandatory for all agents operating in the ASDEV system.*
