# CRITICAL_SITE Staging Deploy — Latest

**Date:** 2026-07-08T21:06:00Z  
**Approval used:** `APPROVE_PHASE_2_STAGING_DEPLOY`  
**Site:** CRITICAL_SITE (`persiantoolbox` / persiantoolbox.ir)  
**Environment:** **staging only**

---

## Result

| Item | Value |
|------|-------|
| Status | **SUCCESS** |
| Product commit | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Release id | `20260708T210149Z-fcc7192` |
| Staging base | `/srv/asdev/sites/persiantoolbox-staging` |
| Current symlink | points to release above |
| Runtime | node standalone on `127.0.0.1:3000` |
| `/api/ready` | **HTTP 200** |
| `/api/health` | **HTTP 200** |
| Production `current` touched | **NO** |

---

## What was executed

1. SSH to IRAN_PROD (operator identity; host redacted)
2. Created `/srv/asdev/sites/persiantoolbox-staging` + shared parent (no prod current)
3. Added 2G swap (OOM mitigation for Next build on 4G host)
4. Synced ASDEV deploy engine + cloned product source on host
5. Built release on IRAN_PROD (`pnpm install --ignore-scripts` + `pnpm run build`, heap 3072)
6. Symlink activation + node-standalone start + healthcheck

---

## Failures overcome (this cycle)

| Failure | Mitigation |
|---------|------------|
| Local SSH key default mismatch | Use operator key + private env host (not printed) |
| `/srv` root-owned | sudo layout create for ASDEV paths |
| First remote builds OOM (exit 137) | 2G swap + `NODE_OPTIONS=--max-old-space-size=3072` |
| husky missing under release tree | `HUSKY=0` / `--ignore-scripts` install |
| Large artifact SCP/rsync timeout OWNER_PC→IRAN_PROD | Build on IRAN_PROD instead of bulk upload |

---

## Not executed

- Production deploy / production symlink
- nginx reload
- DNS / SSL changes
- Database migration
- Public edge exposure of staging (local-port only for now)

---

## Next gate

```
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

Optional before production:

- Edge/nginx staging vhost (if public staging URL required)
- Confirm staging env secrets under shared path
- Artifact pipeline (build on OWNER_PC, transfer when network path reliable)

---

## Safety

- No secrets written to GitHub
- No production process restart
- Staging runtime pid: `asdev-runtime.pid` under staging base only
