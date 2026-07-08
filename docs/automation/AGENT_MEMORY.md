# Agent Memory — ASDEV

**Format:** Each entry records agent state at a point in time.
**Source of Truth:** GitHub (alirezasafaei-dev/alirezasafaeisystems)

---

## Current State

**Date:** 2026-07-08T20:15:00Z  
**Current Source of Truth:** GitHub main (local HEAD was `eaddee4` at cycle start; mission branch pending merge)  
**OWNER_PC:** SYNCED_CLEAN  
**AUTOMATION_HOST:** DEGRADED_NON_BLOCKING  
**CRITICAL_SITE staging:** READY_WITH_WARNINGS (dry-run only)  
**CI:** INFRA_DEGRADED_NON_BLOCKING  
**Active queue:** `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md`

---

## Decisions Made

| Date | Decision | Rationale |
|---|---|---|
| 2026-07-06 | Hermes-first orchestration approved | n8n deferred; GitHub = command center |
| 2026-07-06 | Issue #45 as command bus | Single source for reports and commands |
| 2026-07-08 | Backup-wait phase ended for queue | Superseded by autonomous master loop approvals |
| 2026-07-08 | PM2 empty = non-blocking | No ASDEV ecosystem configured |
| 2026-07-08 | halo-secret containers = legacy non-blocking | Exited weeks; not ASDEV-critical |
| 2026-07-08 | Staging next gate | APPROVE_PHASE_2_STAGING_DEPLOY |

---

## Blockers

- Live staging deploy: needs `APPROVE_PHASE_2_STAGING_DEPLOY`
- CRITICAL_SITE source path `sites/live/persiantoolbox` not present on OWNER_PC checkout
- GitHub Actions infrastructure degraded (multi-workflow fail in seconds; log TLS timeouts)
- Live monitoring timers: needs `APPROVE_MONITORING_LIVE_TIMERS`
- Production deploy: needs `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` (not next)

---

## Next Action

1. Owner grants `APPROVE_PHASE_2_STAGING_DEPLOY` **only if** ready for IRAN_PROD staging mutation
2. Resolve site source/artifact on executor before live staging
3. After staging success, prepare production gate separately
4. Do not spam CI reruns until GHA infra recovers

---

## Owner Approval Phrases

### Granted this master loop

- APPROVE_OWNER_PC_SYNC_MAIN
- APPROVE_AUTOMATION_HOST_READONLY_AUDIT
- APPROVE_AUTOMATION_HOST_REPAIR_NON_DESTRUCTIVE
- APPROVE_REPO_AUTOMATION_MAINTENANCE
- APPROVE_CI_ROUTER_REPAIR
- APPROVE_QUEUE_MAINTENANCE
- APPROVE_CRITICAL_SITE_STAGING_PREFLIGHT_DRY_RUN
- APPROVE_MONITORING_FOUNDATION_PREP
- APPROVE_DOCS_AND_REPORTS_UPDATE

### Not granted (stop gates)

- APPROVE_PHASE_2_STAGING_DEPLOY
- APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
- APPROVE_MONITORING_LIVE_TIMERS
- APPROVE_NON_CRITICAL_QUARANTINE_LIVE

### Informal phrases (still require explicit deploy phrases for prod/staging)

- "approved" / "go ahead" / "ship it" — **insufficient alone** for CRITICAL_SITE deploy

---

## What Must Not Be Repeated

- Do not re-audit AUTOMATION_HOST as BLOCKING solely for empty PM2
- Do not restart legacy exited halo-secret containers without need
- Do not thrash GitHub Actions reruns
- Do not live staging without APPROVE_PHASE_2_STAGING_DEPLOY
- Do not print secrets, raw IPs, or .env contents
- Do not create tiny fragmented PRs for the same mission

---

## Memory Updates

Agents append new entries at the bottom of this file when:
- A decision is made
- A blocker is discovered or resolved
- An approval is granted
- A task completes or fails
- The source of truth state changes

Format:

```
## [YYYY-MM-DD HH:MM UTC] Entry Title
- What happened
- Why it matters
- What's next
```

---

## [2026-07-08 20:15 UTC] Autonomous high-output master loop

- Reconciled OWNER_PC to main `eaddee4` (clean ff-only)
- Re-audited AUTOMATION_HOST → DEGRADED_NON_BLOCKING
- Fixed deploy engine `get_field` bugs; hardened release.meta + previous-release
- Completed CRITICAL_SITE staging preflight dry-run → READY_WITH_WARNINGS
- Added monitoring foundation scripts + runbook + alerting policy
- Refreshed queue, roadmaps, reports
- Stopped at staging live gate
- Next: APPROVE_PHASE_2_STAGING_DEPLOY
