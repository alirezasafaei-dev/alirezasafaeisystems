# Hermes vs n8n — ASDEV Architecture Decision

**Date:** 2026-07-06  
**Decision:** **Hermes-first + GitHub** (n8n optional glue only)  
**Supersedes:** n8n-as-main-orchestrator assumption

---

## Question

For coordinating Codex, Grok, Gemini, DeepSeek, MiMo, Hermes, Antigravity, and Devin — should ASDEV use:

- **A)** n8n as main orchestrator
- **B)** Hermes as main orchestrator
- **C)** Hybrid with clear role split

---

## Decision matrix

| Criterion | n8n-first | Hermes-first | Winner |
|---|---|---|---|
| Native agent execution | ❌ Shell out to CLIs | ✅ Built-in AIAgent loop | Hermes |
| Multi-profile agents | Manual per workflow | ✅ Native profiles + kanban routing | Hermes |
| Task queue / dispatch | Custom DB nodes | ✅ Kanban SQLite + dispatch | Hermes |
| Cron / schedules | ✅ | ✅ | Tie |
| GitHub as source of truth | ✅ Easy nodes | ✅ Via `gh` + monitor script | Tie |
| Visual approval UI | ✅ Strong | ⚠️ Gateway `/approve` + Telegram | n8n (optional) |
| Owner notifications | ✅ Many connectors | ✅ Gateway + `hermes send` | Tie |
| Separation of concerns (router vs agent) | ✅ n8n never edits code | ⚠️ Hermes can edit if misconfigured | n8n |
| Already installed locally | ❌ | ✅ v0.17.0 | Hermes |
| Operational complexity | +1 service (Postgres, keys) | Existing `~/.hermes` | Hermes |
| API for external UI | Webhooks only | ✅ API server (runs, status, approval) | Hermes |
| Security approvals | Human-in-the-loop nodes | ✅ Command approval + gateway deny | Hermes |

---

## Final recommendation

### ✅ Adopt: **Hermes + GitHub** (Option C-lite)

```text
Hermes-first orchestration
GitHub = source of truth
n8n = optional dashboard / notifications / approval UI
```

### ❌ Reject: **n8n as main orchestrator**

n8n would duplicate what Hermes already provides (cron, webhooks, multi-step routing) while adding latency and another secrets surface — without native agent tool-calling.

### ⏸️ Defer: **n8n scaffolding**

Build `ops/n8n/` only if owner explicitly requests after Phase P2 (GitHub loop) is running and gaps remain:

- Non-technical approval dashboard
- Complex multi-channel notification fan-out
- Integration with non-Hermes enterprise tools

---

## Role split (if n8n added later)

| Layer | Tool | Allowed |
|---|---|---|
| Source of truth | GitHub | Prompts, reports, approvals, history |
| Orchestration | Hermes | Classify, route, execute, report |
| Agent workers | Hermes profiles + external CLIs | Code/docs within gates |
| Notifications | Hermes gateway **or** n8n | Alert owner only |
| Visual ops | n8n **or** Hermes dashboard | Read-only status preferred |
| Never | n8n | Code edit, push, deploy, billing |

---

## Evidence summary

Local inspection + Hermes upstream docs:

| Hermes feature | ASDEV relevance |
|---|---|
| Profiles with descriptions for kanban routing | Multi-agent role separation |
| Kanban dispatch / swarm | Task orchestration |
| Cron internals (`~/.hermes/cron/jobs.json`) | PR #42 polling |
| API server (start run, status, approval, stop) | Optional n8n hook |
| Gateway (Telegram, Slack, …) | Owner alerts |
| Security / approval modes | Aligns with ASDEV gates — **YOLO forbidden** |

See also: [`HERMES_CAPABILITY_REVIEW.md`](HERMES_CAPABILITY_REVIEW.md)

---

## Owner confirmation

Owner direction on PR #42 (2026-07-06):

> Before building n8n, write Hermes-first architecture; n8n only if needed as dashboard/notification glue.

**Status:** Confirmed — proceed with Hermes-first doc package; pause n8n MVP.

---

## Alternatives considered

| Alternative | Why not primary |
|---|---|
| GitHub-only (no Hermes) | Owner relay too slow; no dispatch |
| n8n-only | No native agents; more glue code |
| Custom Python orchestrator | Reinvents Hermes kanban/cron |
| Devin-only | Cost + autonomy too high for all tasks |