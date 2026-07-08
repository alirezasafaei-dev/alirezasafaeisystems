# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T21:15:44Z
**Status:** Active
**Source of Truth:** GitHub

---

## Current Queue

### 1. ASDEV-PROD-GATE
- **Title:** CRITICAL_SITE production deploy
- **Mode:** read-only until approval
- **Approval:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`
- **Status:** BLOCKED
- **Prep:** production dry-run DONE; execution plan ready
- **Risk note:** staging holds port 3000 — must resolve before prod start on same host

### 2. ASDEV-PROD-PORT-PLAN
- **Title:** Resolve staging/production port conflict (3000)
- **Mode:** docs-only until live change
- **Status:** DOCUMENTED in production-execution-plan.md
- **Action at prod time:** stop staging runtime OR rebind staging before prod

### 3. ASDEV-STAGING-EDGE (optional)
- **Approval:** nginx not granted
- **Status:** PENDING

### 4. ASDEV-CI-INFRA
- **Status:** SAMPLED — still INFRA_DEGRADED (3–6s fails); local CI Router PASS

### 5. ASDEV-MONITOR-LIVE
- **Approval:** `APPROVE_MONITORING_LIVE_TIMERS`
- **Status:** BLOCKED

---

## Completed this loop

| ID | Result |
|----|--------|
| ASDEV-STAGING-LIVE | LIVE_OK re-verified |
| ASDEV-PROD-PREFLIGHT-DRY | DONE |
| ASDEV-PROD-PLAN | DONE |
| ASDEV-REMOTE-STATUS | DONE (script) |
| ASDEV-AUTOHOST | DEGRADED_NON_BLOCKING |

---

## NEXT_GATE

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
