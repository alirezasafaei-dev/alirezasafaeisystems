# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T20:15:00Z
**Status:** Active
**Source of Truth:** GitHub (alirezasafaei-dev/alirezasafaeisystems)

---

## Queue Rules

- Each task has: ID, Title, Repo, Mode, Risk, Approval, Validation, Stop Gates, Done Definition
- Valid modes: read-only, docs-only, test-only, product-branch, automation-script
- No combined modes (e.g., docs-only+automation-script is invalid)
- Risk: low, medium, high
- Approval: auto (no approval needed), owner (requires owner approval)
- Stop gates: conditions that halt execution

---

## Current Queue (Priority Order)

### 1. ASDEV-STAGING-GATE
- **Title:** Wait for owner staging deploy approval (CRITICAL_SITE)
- **Repo:** alirezasafaeisystems
- **Mode:** read-only
- **Risk:** high
- **Approval:** owner (`APPROVE_PHASE_2_STAGING_DEPLOY`)
- **Validation:** Live staging not started until phrase present
- **Stop Gates:** Any production path; any deploy without phrase
- **Done Definition:** Owner grants phrase; staging deploy executed under Phase 2 plan
- **Status:** BLOCKED — preflight dry-run complete (`READY_WITH_WARNINGS`)

### 2. ASDEV-STAGING-SOURCE
- **Title:** Ensure CRITICAL_SITE source/artifact available on executor path for staging
- **Repo:** alirezasafaeisystems
- **Mode:** automation-script
- **Risk:** medium
- **Approval:** auto (prep only; no live deploy)
- **Validation:** `sites/live/persiantoolbox` or artifact path resolvable on deploy host
- **Stop Gates:** No IRAN_PROD mutation without staging approval
- **Done Definition:** Documented path + dry-run deploy can see source/artifact
- **Status:** PENDING — missing local `sites/live/persiantoolbox` on OWNER_PC

### 3. ASDEV-CI-INFRA
- **Title:** Re-check GitHub Actions when infra recovers (no rerun spam)
- **Repo:** alirezasafaeisystems
- **Mode:** read-only
- **Risk:** low
- **Approval:** auto
- **Validation:** One status sample; classify INFRA vs code
- **Stop Gates:** No tight polling; no mass reruns
- **Done Definition:** CI Router green once or remaining infra blocker documented
- **Status:** PENDING — currently `INFRA_DEGRADED_NON_BLOCKING`

### 4. ASDEV-MONITOR-LIVE
- **Title:** Optional live monitoring timers (after separate approval)
- **Repo:** alirezasafaeisystems
- **Mode:** automation-script
- **Risk:** medium
- **Approval:** owner (`APPROVE_MONITORING_LIVE_TIMERS`)
- **Validation:** Foundation scripts already present; install timers only after phrase
- **Stop Gates:** No IRAN_PROD install without approval
- **Done Definition:** Timers installed on AUTOMATION_HOST only
- **Status:** BLOCKED — foundation ready; live install not approved

### 5. ASDEV-QUARANTINE-PLAN
- **Title:** Non-critical quarantine plan (inventory → allowlist)
- **Repo:** alirezasafaeisystems
- **Mode:** docs-only
- **Risk:** low
- **Approval:** auto for planning; live needs separate phrase
- **Validation:** CRITICAL_SITE never in allowlist
- **Stop Gates:** No live quarantine / delete / nginx
- **Done Definition:** Current plan report kept fresh
- **Status:** DONE (plan refresh this cycle) — live still forbidden

---

## Completed This Cycle

| ID | Result |
|----|--------|
| ASDEV-AUTOHOST-READONLY | DONE — DEGRADED_NON_BLOCKING |
| ASDEV-STAGING-PREFLIGHT | DONE — READY_WITH_WARNINGS |
| ASDEV-DEPLOY-HARDEN | DONE — get_field fix + release.meta + previous-release |
| ASDEV-MONITOR-FOUNDATION | DONE — scripts + runbook + policy |
| ASDEV-QUEUE-MEMORY | DONE — this file + AGENT_MEMORY |

---

## Archived / Superseded

- ASDEV-P71-CI (PR #71 merged; remaining failures are infra-class)
- ASDEV-AUTOHOST-READONLY (approval granted and executed)
- Backup-wait BW01–BW03 backlog — superseded by platform loop
- See `docs/automation/QUEUE_ARCHIVE_20260708.md` for older items

---

## Queue Stats

| Metric | Value |
|---|---|
| Total tasks | 5 |
| Pending | 2 |
| In-progress | 0 |
| Completed (cycle) | 5 |
| Blocked | 2 |
