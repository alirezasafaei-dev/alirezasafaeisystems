# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T21:38:40Z
**Status:** Active
**Source of Truth:** GitHub

---

## Current Queue

### 1. ASDEV-MERGE-RC
- **Title:** Owner merge PR #72 to main (release candidate)
- **Mode:** docs-only (owner action)
- **Status:** PENDING_OWNER
- **Blocks clean main-based prod**

### 2. ASDEV-PROD-GATE
- **Title:** CRITICAL_SITE production deploy
- **Approval:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`
- **Status:** READY_FOR_APPROVAL (engineering)
- **Pin:** product `fcc7192…` / staging release `20260708T210149Z-fcc7192`

### 3. ASDEV-STAGING-REBIND (optional)
- **Title:** Rebind staging :3000 → :3200
- **Approval:** `APPROVE_PHASE_2_STAGING_DEPLOY`
- **Status:** OPTIONAL — does not block prod :3100

### 4. ASDEV-EDGE-NGINX (optional)
- **Status:** DOCUMENTED — not applied

---

## Completed

| ID | Result |
|----|--------|
| ASDEV-FINAL-RC-AUDIT | DONE |
| ASDEV-HARDENING-GATE | DONE |
| ASDEV-STAGING-LIVE | LIVE_OK |
| ASDEV-CUTOVER-SIM | PASS (dry-run) |

---

## NEXT_GATE

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

(after merge PR #72 recommended)
