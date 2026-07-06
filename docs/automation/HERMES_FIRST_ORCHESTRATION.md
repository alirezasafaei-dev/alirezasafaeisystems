# Hermes-First Orchestration — ASDEV Multi-Agent Architecture

**Status:** Approved direction (owner 2026-07-06)  
**Decision:** Hermes = primary orchestrator; GitHub = source of truth; n8n = optional UI/notification glue only  
**Primary product:** ASDEV Audit Platform

---

## Purpose

Coordinate multiple CLI agents (Codex, Grok, Gemini, DeepSeek, MiMo, Hermes, Antigravity, Devin) without:

- Losing owner judgment
- Bypassing approval gates
- Risking PersianToolbox production stability
- Treating n8n as the agent brain

Hermes accelerates **controlled execution**. It does not replace ASDEV focus policy.

---

## High-level architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    GitHub (source of truth)                  │
│  PR #42 prompts · reports · approvals · issue/task record   │
└───────────────────────────┬─────────────────────────────────┘
                            │ poll / webhook
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Hermes ASDEV Controller profile                 │
│  classify task · enforce gates · pick worker · track status  │
└───────────────────────────┬─────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
   hermes-code-codex   hermes-review-grok   hermes-docs-gemini
   hermes-code-deepseek  hermes-ops-mimo   hermes-autonomy-devin
          │                 │                 │
          └─────────────────┼─────────────────┘
                            ▼
              Worktree-isolated execution in allowed repos
                            │
                            ▼
              Standard Agent Execution Report → PR #42
                            │
                            ▼
              Owner / ChatGPT review → next approved prompt
```

### Optional layer (only if needed)

```text
n8n ──► dashboard · approval buttons · extra notifications · external integrations
         (never code execution · never auto-push · never auto-deploy)
```

---

## Lifecycle

| Stage | Owner | Hermes | GitHub |
|---|---|---|---|
| 1. Task proposed | Posts prompt on PR #42 | — | Stores prompt comment |
| 2. Classified | — | Controller reads prompt, sets `repo_scope`, `agent`, gates | — |
| 3. Approved | Explicit approval comment or Telegram `/approve` | Blocks until approved if required | Records approval |
| 4. Assigned | — | Kanban task created; profile selected | Optional issue label |
| 5. Running | — | `kanban dispatch` or `-z` oneshot in worktree | — |
| 6. Reported | — | Worker posts `# Agent Execution Report` via `gh` | PR comment |
| 7. Normalized | — | Controller validates report schema | — |
| 8. Reviewed | Summarizes risks; writes next prompt | — | New prompt comment |
| 9. Next cycle | — | Monitor detects `PROMPT_PENDING` | — |

**Hard stop:** Agent stops after report. No self-chaining without new approved prompt.

---

## Hermes components used

| Component | ASDEV role |
|---|---|
| **Profiles** | One isolated agent per role (model, tools, memory) — see [`HERMES_AGENT_PROFILES.md`](HERMES_AGENT_PROFILES.md) |
| **Kanban** | Task queue: ready → claimed → running → done/blocked |
| **Cron** | Poll PR #42 hourly; health checks; stale-task reclaim |
| **Webhook** | Optional GitHub event → controller (issue_comment, pull_request) |
| **Gateway** | Telegram owner alerts + `/approve` `/deny` when configured |
| **API server** | Optional hook for n8n dashboard (status, stop, approval) |
| **Sessions** | Audit trail per task; resume for multi-step work |
| **Worktrees** | Parallel agents without WIP collision |

References: [Hermes Architecture](https://hermes-agent.nousresearch.com/docs/developer-guide/architecture), [Profiles](https://hermes-agent.nousresearch.com/docs/user-guide/profiles), [Programmatic Integration](https://hermes-agent.nousresearch.com/docs/developer-guide/programmatic-integration)

---

## Repo scope rules

| Repo | Default autonomy | Notes |
|---|---|---|
| `auditsystems` | code-implementation with validation | Primary product |
| `alirezasafaeisystems` | docs + governance + safe scaffolding | Mother repo / command center |
| `persiantoolbox` | **read-only / docs-plan** | Protected — see [`PERSIANTOOLBOX_PROTECTION.md`](PERSIANTOOLBOX_PROTECTION.md) |
| `devatlas`, frozen | read-only inspection only | No new scope |

---

## ASDEV Audit goals (mandatory filter)

Every automated task must support at least one:

1. More submitted audits
2. Better and more trusted reports
3. More leads, signups, paid users, or agency contacts
4. Better production reliability, security, and operations
5. Lower audit cost, support cost, or execution time

If none apply → task status `frozen`; do not dispatch.

---

## Failure handling

| Failure | Action |
|---|---|
| Validation fails | Report must show failures; task → `blocked`; notify owner |
| Wrong repo touched | Abort; revert worktree; escalate |
| PersianToolbox runtime attempted without approval | Hard block; no commit |
| Agent timeout | Kanban reclaim; max 2 retries then `blocked` |
| Missing approval | Stay in `proposed`; Telegram reminder |
| YOLO / bypass flags | **Forbidden** in ASDEV profiles |

---

## What is explicitly out of scope for automation

- Production deploy
- Payment / billing activation
- Auto-push to `main`
- Force push, repo deletion
- DevAtlas standalone revival
- Broad PersianToolbox refactors

---

## Implementation phases (docs-only for now)

| Phase | Deliverable | Deploy? |
|---|---|---|
| **P0** | This doc package | No |
| **P1** | Hermes profiles + kanban board `asdev-audit` | Local only |
| **P2** | GitHub command loop wired to PR #42 | Local cron |
| **P3** | Telegram approval via gateway | Optional |
| **P4** | n8n notification dashboard | Only if owner requests |

---

## Related docs

- [`HERMES_GITHUB_COMMAND_LOOP.md`](HERMES_GITHUB_COMMAND_LOOP.md)
- [`HERMES_AGENT_PROFILES.md`](HERMES_AGENT_PROFILES.md)
- [`HERMES_APPROVAL_GATES.md`](HERMES_APPROVAL_GATES.md)
- [`HERMES_VS_N8N_DECISION.md`](HERMES_VS_N8N_DECISION.md)
- [`../agent-command-center/README.md`](../agent-command-center/README.md)