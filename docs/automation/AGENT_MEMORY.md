# Agent Memory — ASDEV

**Read this first.**  
**SoT:** GitHub `main` @ post-PR#74  
**Workspace:** `/home/dev13/ASDEV`  
**Updated:** 2026-07-08T22:42:00Z

---

## Current architecture

```
GitHub main (SoT) ── merged PR #74 (ops loop + control plane)
        │
AUTOMATION_HOST (/home/dev13/ASDEV)
  control-plane/ · scripts/control-plane · agent-command-center
  Hermes + OpenClaw gateways (user processes)
        │ SSH
IRAN_PROD
  prod :3100 LIVE  release 20260708T221124Z-fcc7192  pin fcc7192
  staging :3000 LIVE  (legacy bind; registry wants 3200)
  meta backup cron 03:15 UTC
```

---

## Current state

| Item | State |
|------|-------|
| main | **a77dbd3+** (PR #74 merged) |
| Prod app-layer | **STABLE** ready/health 200 · ~8–24ms |
| Public edge | **OFF** — waiting phrase |
| AUTOMATION_HOST | DEGRADED_NON_BLOCKING · control plane live |
| Queue | gated edge/timers/migration + new rollback task |
| Backup | FRESH meta on IRAN |

---

## Completed (this mission arc)

1. Staging live  
2. Production app-layer cutover  
3. Stabilization + IRAN backup cron  
4. Control plane transform  
5. **PR #74 merged to main**  
6. Post-merge: IRAN re-sync, daily runbook, queue archive tool  

---

## Known issues / residuals

- No previous_release (first prod)  
- Staging on :3000  
- Meta-only backups  
- Shared secrets residual  
- Hermes/OpenClaw outside PM2  
- Desktop colocation  

---

## Next actions

**Safe:** daily runbook, health check, queue hygiene, docs.  
**Gated:** public edge · live timers · migration · optional second prod deploy for rollback history.

---

## Approval gates

```
APPROVE_CRITICAL_SITE_PUBLIC_EDGE
APPROVE_MONITORING_LIVE_TIMERS
APPROVE_CRITICAL_SITE_MIGRATION
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
APPROVE_PHASE_2_STAGING_DEPLOY
APPROVE_CRITICAL_SITE_STAGING_REBIND   # optional
```

---

## Decisions

| Decision | Why |
|----------|-----|
| Merge #74 without waiting | Owner authorized autonomous necessary ops; SoT must advance |
| No edge without phrase | Blast radius |
| Keep staging running | No unplanned downtime |
| Batch PRs | Anti micro-task thrash |

---

### [2026-07-08 22:42 UTC] Post-merge ops loop

- Merged control plane to main  
- IRAN scripts re-synced; STABILITY_SAMPLE_PASS; DEPLOY_OK; backup FRESH; cron intact  
- Added daily runbook + queue-archive-done  
