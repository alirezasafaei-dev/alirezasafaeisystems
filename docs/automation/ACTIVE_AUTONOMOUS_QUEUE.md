# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08 21:06 UTC
**Status:** Active
**Source of Truth:** GitHub

---

## Current Queue

### 1. ASDEV-PROD-GATE
- **Title:** CRITICAL_SITE production deploy (blocked)
- **Mode:** read-only until approval
- **Approval:** owner (`APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`)
- **Status:** BLOCKED
- **Precondition:** Staging LIVE_OK (`20260708T210149Z-fcc7192`, ready/health 200)

### 2. ASDEV-STAGING-EDGE (optional)
- **Title:** Optional nginx/public staging vhost for CRITICAL_SITE
- **Mode:** automation-script
- **Approval:** owner (not granted in master loop for nginx)
- **Status:** PENDING — local-port staging works without edge

### 3. ASDEV-CI-INFRA
- **Title:** GitHub Actions infra recovery sample
- **Mode:** read-only
- **Status:** PENDING — non-blocking

### 4. ASDEV-MONITOR-LIVE
- **Approval:** `APPROVE_MONITORING_LIVE_TIMERS`
- **Status:** BLOCKED

---

## Completed

| ID | Result |
|----|--------|
| ASDEV-STAGING-GATE | DONE — live staging SUCCESS |
| ASDEV-STAGING-SOURCE | DONE |
| ASDEV-STAGING-PREFLIGHT | DONE |
| ASDEV-DEPLOY-RUNTIME-START | DONE (node-standalone) |

---

## NEXT_GATE

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
