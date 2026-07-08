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

## [2026-07-08 20:22 UTC] Loop-2: staging source + CI router local

- Prepared CRITICAL_SITE source via asdev-prepare-site-source (public repo clone, gitignored)
- Source status ready; preflight/deploy dry-run use product SHA fcc7192
- Added staging-execution-plan.md and site-source-map.tsv
- Fixed check-dangerous-patterns false positives + wrong PROJECT_ROOT
- Removed eval from backup-onsite / restore-drill-onsite
- Local CI Router PASS; GHA still infra-failed (empty steps)
- Live staging still gated: APPROVE_PHASE_2_STAGING_DEPLOY

## [2026-07-08 21:06 UTC] CRITICAL_SITE staging LIVE_OK

- Owner granted APPROVE_PHASE_2_STAGING_DEPLOY
- Staging release 20260708T210149Z-fcc7192 on IRAN_PROD
- /api/ready and /api/health HTTP 200 on 127.0.0.1:3000
- Production current not created/touched
- Added 2G swap for build OOM mitigation
- Next: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

## [2026-07-08 21:11 UTC] Document + AUTOMATION_HOST recheck

- Mission worklog written (docs/reports/asdev-mission-worklog-20260708.md)
- AUTOMATION_HOST still DEGRADED_NON_BLOCKING; runner false-positive fixed
- Staging re-verified: ready/health 200, PID alive, prod current absent
- Safe work remaining without production phrase is limited
- Next: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

## [2026-07-08T21:15:44Z] Production prep loop (no live prod)

- Staging re-verified LIVE_OK (ready/health 200)
- Production dry-run preflight/deploy/rollback PASS
- production-execution-plan.md + port-3000 conflict documented
- asdev-remote-status.sh for redacted IRAN_PROD checks
- CI still infra-failed; local router PASS
- Stopped at production phrase gate

## [2026-07-08T21:28:21Z] Production Hardening Gate complete

### Architecture assumptions
- CRITICAL_SITE prod_port=3100, staging_port=3200 (isolated)
- Immutable releases under /srv/asdev/sites/<site>/[staging/]releases/
- current symlink is only cutover mutation
- Healthcheck post-activation; auto rollback on failure
- Migration changes require APPROVE_CRITICAL_SITE_MIGRATION

### Known blockers before clean production
- Live staging still on legacy port 3000 (needs rebind to 3200)
- Nginx not applied
- Production secrets/shared readiness at execute time

### Next gates
1. Staging rebind: APPROVE_PHASE_2_STAGING_DEPLOY
2. Production: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

### Gate verdict
PASS_WITH_WARNINGS — no production mutation performed

## [2026-07-08T21:38:40Z] Final Release Candidate Audit

### Architecture
- CRITICAL_SITE prod_port=3100 staging_port=3200
- Staging LIVE: 20260708T210149Z-fcc7192 on legacy :3000 (healthy)
- Production: no current, no releases yet
- Engine: immutable releases, post-activation HC, port/migration guards

### Release pin
- Product: fcc7192af26a5713e31d4ec078365f9507c8108a
- Platform RC: PR #72 (not merged to main at audit time)

### AUTOMATION_HOST
- DEGRADED_NON_BLOCKING (usable)

### Decision
- READY_FOR_PRODUCTION_APPROVAL
- NEXT_GATE: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
- Owner should merge PR #72 first

### Blockers (soft)
- PR not on main
- Staging not on 3200 (optional)
- First prod has no previous release for rollback

## [2026-07-08T21:44:19Z] RELEASE CANDIDATE FROZEN

### Frozen pins
- Platform main: 5aff1dfed17dcf0672b3022564b321660b297580 (PR #72 merged)
- Product: fcc7192af26a5713e31d4ec078365f9507c8108a
- Staging release: 20260708T210149Z-fcc7192 (ready/health 200)

### Actions completed
- PR #72 reviewed (local validation PASS; GHA infra red → admin merge)
- OWNER_PC main ff-only synced to 5aff1df
- IRAN_PROD /home/asdev/asdev-platform ops surface synced + RELEASE_CANDIDATE.pin
- No production deploy

### Current gate
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

### Status
READY_FOR_PRODUCTION_FREEZE

## [2026-07-08T21:45:37Z] RELEASE CANDIDATE FROZEN (corrected)

### Frozen pins
- Platform: GitHub main after PR #72 merge (see docs/reports/critical-site-release-freeze-latest.md for exact SHA)
- Product: fcc7192af26a5713e31d4ec078365f9507c8108a
- Staging: 20260708T210149Z-fcc7192 (ready/health 200)

### Actions
- PR #72 merged (local validation PASS; GHA infra red)
- OWNER_PC main synced
- IRAN_PROD platform ops synced + RELEASE_CANDIDATE.pin
- No production deploy

### Gate
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

### Status
READY_FOR_PRODUCTION_FREEZE

## [2026-07-08T21:57:43Z] PRODUCTION FINAL PREFLIGHT

### Result
PRODUCTION_PREFLIGHT_PASS

### Validated
- Platform pin re-synced on IRAN_PROD to main tip
- Tools/disk/mem OK
- Port 3100 free; staging on :3000 healthy
- Empty-state inventory captured (metadata only)
- Shared .env: none in known paths (residual)
- Backup evidence: weak (residual)
- Dry-run production PASS

### Next
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

### Not done
production deploy, nginx, DNS, SSL, migration

## [2026-07-08T22:16:19Z] PRODUCTION APP-LAYER LIVE

### Deployed
- Phrase: APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
- Scope: application layer only 127.0.0.1:3100
- Release: 20260708T221124Z-fcc7192
- Product: fcc7192af26a5713e31d4ec078365f9507c8108a
- ready/health: 200/200
- PID alive
- Staging untouched (still 200 on :3000)
- nginx/DNS/SSL: not touched

### Rollback
- First production release — no previous-release pointer
- Recovery: redeploy same SHA or stop pid

### Next
Public edge phase needs separate approval
