# TODAY — ASDEV Immediate Priorities

**Date:** 2026-07-08  
**Source of Truth:** GitHub

---

## Done this cycle

| Item | Status |
|------|--------|
| OWNER_PC sync main | Done |
| AUTOMATION_HOST re-audit | DEGRADED_NON_BLOCKING |
| Deploy engine bugfix + hardening | Done (mission PR) |
| CRITICAL_SITE staging preflight dry-run | READY_WITH_WARNINGS |
| Monitoring foundation scripts | Done |
| Queue + agent memory refresh | Done |

---

## Now / next

| Priority | Task | Status | Gate |
|----------|------|--------|------|
| 1 | Merge mission PR (deploy fix + reports + monitoring) | In progress | Owner review |
| 2 | Resolve CRITICAL_SITE source/artifact for staging executor | Pending | None (prep) |
| 3 | Live CRITICAL_SITE staging deploy | Blocked | `APPROVE_PHASE_2_STAGING_DEPLOY` |
| 4 | CI re-sample when GHA healthy | Pending | No spam reruns |
| 5 | Live monitoring timers | Blocked | `APPROVE_MONITORING_LIVE_TIMERS` |

---

## Explicitly not today

- Production deploy
- IRAN_PROD nginx/pm2 mutation
- Live non-critical quarantine
- Database migration
- DNS/SSL changes

---

## Validation (local, before merge)

```bash
bash -n scripts/deploy/asdev-*.sh scripts/monitoring/*.sh
bash scripts/ops/validate-registry-schema.sh
bash scripts/ops/check-dangerous-patterns.sh
bash scripts/deploy/asdev-preflight.sh --site persiantoolbox --environment staging --commit "$(git rev-parse HEAD)" --dry-run
bash scripts/deploy/asdev-deploy.sh --site persiantoolbox --environment staging --commit "$(git rev-parse HEAD)" --dry-run
bash scripts/deploy/asdev-rollback.sh --site persiantoolbox --environment staging --commit "$(git rev-parse HEAD)" --dry-run
```

---

## NEXT_GATE

```
APPROVE_PHASE_2_STAGING_DEPLOY
```
