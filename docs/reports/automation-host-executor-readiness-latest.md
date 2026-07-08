# AUTOMATION_HOST Executor Readiness — Latest

**Date:** 2026-07-08T20:10:00Z  
**Checker:** `scripts/monitoring/check-automation-host-readiness.sh`

---

## Checklist

| Requirement | Status | Notes |
|-------------|--------|-------|
| ASDEV repo | OK | `/home/dev13/ASDEV` resolvable |
| deploy/registry.tsv | OK | Present, validates |
| deploy scripts | OK | asdev-deploy family present |
| git / bash / ssh | OK | Present |
| node / pnpm | OK | Present |
| curl / rsync | OK | Present |
| docker | OK (optional) | Present |
| pm2 | WARN | Idle 0 processes |
| Disk / memory | OK | Ample free |
| Self-hosted GHA runner | WARN | Not present (not required for local executor) |
| IRAN_PROD paths locally | N/A | `/srv/asdev` not on OWNER_PC (expected; deploy target is IRAN_PROD) |

---

## Live classification output

```
CLASSIFICATION=DEGRADED_NON_BLOCKING
ERRORS=0
WARNINGS=2
```

---

## Implication for CRITICAL_SITE staging

- Safe to run **dry-run / check** deploy engine locally.
- Live staging deploy still requires:
  1. `APPROVE_PHASE_2_STAGING_DEPLOY`
  2. Execution context with IRAN_PROD staging paths and site source/artifact
  3. No mutation until that gate

---

## Classification

**DEGRADED_NON_BLOCKING** (executor usable for orchestration + dry-runs)
