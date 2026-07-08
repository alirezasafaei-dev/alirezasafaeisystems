# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T21:12:00Z
**Status:** Active
**Source of Truth:** GitHub

---

## Queue Rules

- Valid modes only: read-only, docs-only, test-only, product-branch, automation-script
- No combined modes
- Current phase first

---

## Current Queue (Priority Order)

### 1. ASDEV-PROD-GATE
- **Title:** CRITICAL_SITE production deploy
- **Mode:** read-only until approval
- **Risk:** high
- **Approval:** owner (`APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`)
- **Status:** BLOCKED
- **Precondition:** Staging LIVE_OK (`20260708T210149Z-fcc7192`)

### 2. ASDEV-AUTOHOST-KEEP
- **Title:** Keep AUTOMATION_HOST executor healthy (read-only recheck)
- **Mode:** read-only
- **Risk:** low
- **Approval:** auto
- **Status:** DONE this cycle — DEGRADED_NON_BLOCKING (usable)
- **Notes:** PM2 idle expected; no real GHA runner; runner false-positive fixed

### 3. ASDEV-STAGING-EDGE (optional)
- **Title:** Public staging edge/nginx for CRITICAL_SITE
- **Mode:** automation-script
- **Risk:** medium
- **Approval:** owner (nginx not granted)
- **Status:** PENDING — local-port staging sufficient for now

### 4. ASDEV-CI-INFRA
- **Title:** Sample GHA when infra recovers (no spam)
- **Mode:** read-only
- **Status:** PENDING — non-blocking

### 5. ASDEV-MONITOR-LIVE
- **Title:** Live monitoring timers
- **Approval:** `APPROVE_MONITORING_LIVE_TIMERS`
- **Status:** BLOCKED

---

## Completed (mission)

| ID | Result |
|----|--------|
| ASDEV-STAGING-GATE | DONE — LIVE_OK |
| ASDEV-STAGING-SOURCE | DONE |
| ASDEV-STAGING-PREFLIGHT | DONE |
| ASDEV-DEPLOY-ENGINE | DONE |
| ASDEV-MONITOR-FOUNDATION | DONE |
| ASDEV-AUTOHOST-AUDIT | DONE — DEGRADED_NON_BLOCKING |
| ASDEV-DOCS-WORKLOG | DONE |

---

## NEXT_GATE

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
