# ASDEV Autonomous Loop Governance Policy

**Status:** ACTIVE — Official control-plane policy  
**Authority:** Supersedes informal chat-only loop instructions  
**Last Updated:** 2026-07-09  
**Repository:** `alirezasafaei-dev/alirezasafaeisystems`  
**Related:**  
- `docs/governance/AUTONOMOUS_PRODUCTIVITY_MODE.md` (mode)  
- `docs/governance/APPROVAL_GATES.md` (hard gates)  
- `docs/architecture/automation-control-plane.md` (architecture)  
- `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md` (mimo + opencode on OWNER_PC)  
- `AGENTS.md` (entry governance)

---

## 1. Purpose

Define how automation agents and human operators run **continuous improvement** on ASDEV without:

- stopping after each small task  
- treating chat as source of truth  
- thrashing GitHub with micro-commits  
- mutating production without explicit approval  

**Core rule:**

> Agents must **not** stop after completing a task.  
> After every completed task they must select the **highest-value safe** next task and continue.

---

## 2. GitHub as Source of Truth

| Layer | Role |
|-------|------|
| **GitHub `main`** | Only authoritative SoT for code, docs, memory, queue schema, policy |
| **OWNER_PC** `/home/dev13/ASDEV` | Working copy / interactive agent |
| **AUTOMATION_HOST** | Executor + control plane runtime (same host colocated today) |
| **IRAN_PROD / public VPS** | Runtime only — not SoT |

### Consistency chain

```
GitHub main
    ↓ pull/push PR
OWNER_PC /home/dev13/ASDEV
    ↓ rsync scripts/docs (no secrets)
AUTOMATION_HOST control-plane runtime
    ↓ deploy engines (gated)
IRAN_PROD / public production hosts
```

Agents must **detect and report drift** (e.g. product main ahead of live release, registry vs live ports) without inventing a second SoT.

---

## 3. Autonomous loop behavior

### NEVER stop because

- a task finished  
- a PR was created  
- a report was written  
- documentation was updated  
- the queue looks empty (search for next ROI work)  

### After every completed action

1. Inspect system state  
2. Compare against roadmap (`docs/memory/ACTIVE_ROADMAP.md`, `roadmap/`)  
3. Identify highest ROI **safe** improvement  
4. Execute  
5. Validate  
6. Commit in **logical batches**  
7. Push  
8. Continue  

### Hard stop conditions ONLY

| Code | Condition |
|------|-----------|
| A | Production mutation needs exact approval phrase |
| B | Security risk / missing credentials for required action |
| C | Honest search finds **no** remaining safe high-value work |

Informal “go ahead” is **not** a production phrase (see APPROVAL_GATES).

---

## 4. Agent operating rules

1. **Read first** (order):  
   - `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` (this file)  
   - `docs/memory/ASDEV_CURRENT_STATE.md`  
   - `docs/automation/ASDEV_MEMORY.md`  
   - `docs/governance/APPROVAL_GATES.md`  
   - `control-plane/queue/queue.json`  
2. **Register identity** when available (`docs/automation/AGENT_REGISTRY.md`).  
3. **Heartbeat** on AUTOMATION_HOST when running control-plane work:  
   `bash scripts/control-plane/agent-heartbeat.sh`  
4. **Leave handoff** so the next session can continue without chat history.  
5. **Prefer reuse** of `scripts/control-plane/*` and `scripts/agent-command-center/*` over new frameworks.

---

## 5. Priority system (ROI order)

Always prefer, in order:

1. Reliability improvement  
2. Automation improvement  
3. Security improvement  
4. Developer experience  
5. Deployment maturity  
6. Documentation and memory  

Within product/platform work, respect `docs/strategy/FOCUS_POLICY.md` (ASDEV Audit goals when choosing product scope).

---

## 6. Memory requirements

### Canonical locations

| File | Role |
|------|------|
| `docs/memory/ASDEV_CURRENT_STATE.md` | Live snapshot |
| `docs/memory/DECISION_LOG.md` | Decisions + rationale |
| `docs/memory/ACTIVE_ROADMAP.md` | Near-term roadmap |
| `docs/memory/ARCHITECTURE_MEMORY.md` | Stable topology |
| `docs/memory/INCIDENTS.md` | Incidents / outages |
| `docs/memory/AGENT_HANDOFF.md` | Cross-session handoff |
| `docs/automation/ASDEV_MEMORY.md` | Permanent summary |
| `docs/automation/AGENT_MEMORY.md` | Working/session memory |

### Rule

Every **important** operation updates at least CURRENT_STATE or DECISION_LOG (and INCIDENTS if outage).

---

## 7. Queue management rules

| Rule | Detail |
|------|--------|
| Machine queue | `control-plane/queue/queue.json` |
| Human queue | `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md` |
| Claim | `scripts/control-plane/queue-claim.sh` |
| Complete | `scripts/control-plane/queue-complete.sh` |
| Stale | `detect-stale-tasks.sh` (in_progress > 24h) |
| Retry | `retry-policy.sh` — max retries then `blocked` |
| History | `record-execution.sh` → `control-plane/history/` |

Gated tasks (`approval_required` set) must **not** auto-execute without phrase in session.

Empty queue ≠ stop: invent safe work from missions A–E (below) or roadmap.

---

## 8. Commit / PR batching rules

| Do | Don't |
|----|--------|
| One PR per subsystem / mission batch | Endless one-file PRs |
| Meaningful conventional commits | Commit spam |
| Secret scan before push | Force-push main |
| Respect GitHub rate limits | Poll GHA endlessly |

Preferred prefixes: `docs(automation):`, `ops(control-plane):`, `feat(os):`.

---

## 9. Security boundaries

### NEVER without explicit approval phrase / owner OK

- DNS changes  
- SSL production activation / public edge cutover  
- Database migrations  
- Firewall / security group destructive changes  
- Deleting production data or release history hard-delete  
- Production destructive operations  

### ALWAYS allowed (safe autonomous)

- Docs, policy, memory, roadmaps  
- Control-plane scripts that are dry-run by default  
- Read-only audits (GSC with existing credentials, remote status)  
- Local validation, tests, typecheck  
- Non-destructive queue/memory updates  

Secrets never enter git: no `.env`, private keys, tokens, dumps.

---

## 10. Production approval gates

Canonical list: `docs/governance/APPROVAL_GATES.md`

| Phrase | Unlocks |
|--------|---------|
| `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` | nginx/SSL/DNS public cutover |
| `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` | production app deploy/redeploy |
| `APPROVE_PHASE_2_STAGING_DEPLOY` | staging deploy |
| `APPROVE_CRITICAL_SITE_MIGRATION` | DB migrations |
| `APPROVE_MONITORING_LIVE_TIMERS` | live probe timers install |
| `APPROVE_CRITICAL_SITE_STAGING_REBIND` | staging port rebind live |
| `APPROVE_RELEASE_DELETE` | hard-delete releases |

---

## 11. Long-run missions (backlog when queue empty)

| ID | Mission | Focus |
|----|---------|--------|
| A | Control plane | queue, ownership, history, retry, recovery |
| B | Agent memory | docs/memory/* always current |
| C | Project factory | project.yaml + deploy/health/rollback per site |
| D | Deploy platform | release lifecycle, rollback confidence, reports |
| E | Automation host | scheduler, workers, self-diagnosis, logs |

---

## 12. Reporting format

Report only after **meaningful milestones** (not every micro-step):

```text
STATUS:
COMPLETED:
FILES CHANGED:
COMMITS:
PR:
SYSTEM IMPROVEMENT:
CURRENT BLOCKERS:
NEXT AUTONOMOUS ACTION:
```

---

## 13. Control-plane entrypoints (do not duplicate)

| Concern | Entry |
|---------|--------|
| Health | `scripts/ops/automation-health-check.sh` |
| Loop once | `scripts/control-plane/loop-once.sh` |
| Loop bounded | `scripts/control-plane/loop-until-blocked.sh` |
| Queue CLI | `scripts/control-plane/queue-*.sh` |
| Agent ACC | `scripts/agent-command-center/run-autonomous-loop.sh` |
| Architecture | `docs/architecture/automation-control-plane.md` |

This policy is **governance**; scripts implement it. Prefer pointers over reimplementation.

---

## 14. Install record

| Field | Value |
|-------|--------|
| Installed | 2026-07-09 |
| Policy path | `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` |
| Chat override | Moved into GitHub SoT (this file) |
