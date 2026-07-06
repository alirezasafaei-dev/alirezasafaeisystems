# ASDEV Automation Layer

**Status:** Hermes-first gate active — n8n package **deferred** until owner approves architecture choice  
**Primary product:** ASDEV Audit Platform  
**Command thread:** [PR #42](https://github.com/alirezasafaei-dev/alirezasafaeisystems/pull/42)

---

## What this layer is

A **controlled multi-agent execution layer** that routes work to CLI agents (Codex, Grok, Gemini, DeepSeek, MiMo, Hermes, etc.) while keeping:

- **GitHub** as source of truth (tasks, PRs, reports, approvals)
- **Owner approval** as mandatory gate for protected work
- **ASDEV Audit** as default execution focus

Automation accelerates handoff — it does not remove judgment.

---

## Current decision gate (2026-07-06)

| Step | Status |
|---|---|
| Hermes capability review | ✅ See [`HERMES_CAPABILITY_REVIEW.md`](HERMES_CAPABILITY_REVIEW.md) |
| Owner architecture choice | ⏳ Pending |
| n8n orchestrator docs/scaffolding | 🚫 **Blocked** until step 2 |

**Owner rule:** Do not build n8n until Hermes review is complete and a path is chosen.

---

## What automation is allowed to do

- Poll GitHub PR/issue comments for approved prompts
- Classify tasks and route to agent candidates
- Track task status (proposed → approved → running → reported)
- Normalize agent reports to a standard schema
- Notify owner (Telegram, PR comment, dashboard)
- Read-only inspection and docs-only planning without approval

---

## What automation must never do

- Bypass owner approval
- Auto-approve production changes
- Auto-deploy
- Auto-push to `main`
- Modify PersianToolbox runtime without explicit owner approval
- Activate billing/payment
- Override ASDEV focus policy or frozen project rules

---

## Planned docs (after owner decision)

When architecture is approved, add:

```text
docs/automation/
├── N8N_MULTI_AGENT_ORCHESTRATOR.md   # if hybrid or n8n-only
├── AGENT_REGISTRY.md
├── TASK_SCHEMA.md
├── REPORT_SCHEMA.md
├── APPROVAL_GATES.md
├── PERSIANTOOLBOX_PROTECTION.md
└── WORKFLOW_EXAMPLES.md

ops/n8n/                               # optional, example-only
├── docker-compose.example.yml
└── env.example
```

---

## Related

- [`../agent-command-center/README.md`](../agent-command-center/README.md) — PR #42 command thread
- [`../strategy/FOCUS_POLICY.md`](../strategy/FOCUS_POLICY.md)
- [`HERMES_CAPABILITY_REVIEW.md`](HERMES_CAPABILITY_REVIEW.md)