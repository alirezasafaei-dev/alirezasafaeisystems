# CRITICAL_SITE Production Preflight Dry-Run — Latest

**Date:** 2026-07-08T21:15:00Z  
**Mode:** dry-run only (no live production)  
**Commit under test:** `fcc7192af26a5713e31d4ec078365f9507c8108a` (same as healthy staging)

---

## Commands

| Step | Result |
|------|--------|
| `asdev-preflight.sh … production --dry-run` | PASS with warnings (expected on OWNER_PC for missing `/srv` paths locally) |
| `asdev-deploy.sh … production --dry-run` | PASS — would deploy to `/srv/asdev/sites/persiantoolbox` |
| `asdev-rollback.sh … production --dry-run` | PASS — no previous prod release yet |
| `validate-registry-schema` | PASS |
| Protection check | PASS (when run) |

---

## Staging precondition

| Check | Value |
|-------|-------|
| Staging release | `20260708T210149Z-fcc7192` |
| ready/health | 200/200 |
| PID alive | yes |
| Prod current | no |

---

## Blockers before live production

1. Exact phrase: `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`  
2. **Port 3000 conflict:** staging runtime currently bound to 3000; production registry also uses 3000  
3. Production env/secrets under shared path (not in git)  
4. Confirm public edge/nginx if “public go-live” is required  

---

## Classification

**READY_FOR_PRODUCTION_WITH_WARNINGS**

Ready for live production **after** phrase + port/secrets plan.

---

## NEXT_GATE

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
