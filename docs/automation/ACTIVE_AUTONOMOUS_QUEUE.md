# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T20:22:00Z
**Status:** Active
**Source of Truth:** GitHub (alirezasafaei-dev/alirezasafaeisystems)

---

## Queue Rules

- Valid modes only: read-only, docs-only, test-only, product-branch, automation-script
- No combined modes
- Current phase first; no stale backup-wait blockers

---

## Current Queue (Priority Order)

### 1. ASDEV-STAGING-GATE
- **Title:** Wait for owner staging deploy approval (CRITICAL_SITE)
- **Mode:** read-only
- **Risk:** high
- **Approval:** owner (`APPROVE_PHASE_2_STAGING_DEPLOY`)
- **Status:** BLOCKED — local prep complete; live deploy gated
- **Done Definition:** Live staging executed after exact phrase

### 2. ASDEV-STAGING-IRAN-PATH
- **Title:** Confirm IRAN_PROD staging base path exists (read-only) before live deploy
- **Mode:** read-only
- **Risk:** medium
- **Approval:** auto for read-only remote check when access available
- **Status:** PENDING — `/srv/asdev` not on OWNER_PC
- **Stop Gates:** No mutation on IRAN_PROD

### 3. ASDEV-CI-INFRA
- **Title:** Re-check GitHub Actions when infra recovers
- **Mode:** read-only
- **Risk:** low
- **Status:** PENDING — GHA still empty-steps failures; **local CI Router PASS**
- **Validation:** `scripts/ops/run-ci-router-local.sh origin/main`

### 4. ASDEV-MONITOR-LIVE
- **Title:** Optional live monitoring timers
- **Mode:** automation-script
- **Approval:** owner (`APPROVE_MONITORING_LIVE_TIMERS`)
- **Status:** BLOCKED

### 5. ASDEV-QUARANTINE-LIVE
- **Title:** Non-critical quarantine live (not approved)
- **Mode:** docs-only until approval
- **Status:** BLOCKED — plan only

---

## Completed (this autonomous loop)

| ID | Result |
|----|--------|
| ASDEV-STAGING-SOURCE | DONE — PT cloned to `sites/live/persiantoolbox` (gitignored), source ready |
| ASDEV-STAGING-PLAN | DONE — `docs/ops/staging-execution-plan.md` |
| ASDEV-CI-ROUTER-LOCAL | DONE — local router + false-positive fixes |
| ASDEV-DEPLOY-EVAL-HARDEN | DONE — removed eval from backup/restore-drill |
| ASDEV-MONITOR-FOUNDATION | DONE (prior cycle) |
| ASDEV-STAGING-PREFLIGHT | DONE — READY_WITH_WARNINGS |

---

## Queue Stats

| Metric | Value |
|---|---|
| Active tasks | 5 |
| Blocked | 3 |
| Pending | 2 |
| Safe work remaining without staging phrase | limited (IRAN path read-only if access; docs) |
