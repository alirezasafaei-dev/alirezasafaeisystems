# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T21:28:21Z
**Status:** Active
**Source of Truth:** GitHub

---

## Current Queue

### 1. ASDEV-STAGING-REBIND
- **Title:** Rebind CRITICAL_SITE staging from legacy :3000 to registry :3200
- **Mode:** automation-script
- **Approval:** `APPROVE_PHASE_2_STAGING_DEPLOY` (already granted class; confirm if re-executing)
- **Status:** PENDING — architecture ready; live rebind not done in hardening gate
- **Risk:** medium (staging only)

### 2. ASDEV-PROD-GATE
- **Title:** CRITICAL_SITE production deploy
- **Mode:** read-only until approval
- **Approval:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`
- **Status:** BLOCKED — hardening PASS_WITH_WARNINGS
- **Precondition:** ports isolated in registry; staging rebind recommended

### 3. ASDEV-EDGE-NGINX (optional)
- **Title:** Wire nginx upstreams 3100/3200
- **Approval:** nginx reload not granted
- **Status:** DOCUMENTED only

### 4. ASDEV-MONITOR-LIVE
- **Approval:** `APPROVE_MONITORING_LIVE_TIMERS`
- **Status:** BLOCKED

---

## Completed

| ID | Result |
|----|--------|
| ASDEV-HARDENING-GATE | DONE — PASS_WITH_WARNINGS |
| ASDEV-PORT-ISOLATION | DONE — registry + engine |
| ASDEV-PROD-READINESS-DOC | DONE |
| ASDEV-ROLLBACK-REHEARSE | DONE (dry-run) |
| ASDEV-STAGING-LIVE | LIVE_OK (legacy :3000) |

---

## NEXT

Recommended: staging rebind then production phrase.

```
APPROVE_PHASE_2_STAGING_DEPLOY
```
(for rebind to 3200)

then

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
