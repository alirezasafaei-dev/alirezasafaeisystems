# CRITICAL_SITE Staging Execution Plan

**Site:** CRITICAL_SITE (`persiantoolbox.ir` / registry `persiantoolbox`)  
**Last Updated:** 2026-07-08T21:14:00Z  
**Live deploy status:** **EXECUTED — LIVE_OK**

---

## Gate used

```text
APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Live result (current)

| Field | Value |
|-------|-------|
| Release | `20260708T210149Z-fcc7192` |
| Product commit | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Base | `/srv/asdev/sites/persiantoolbox-staging` |
| Runtime | node standalone `127.0.0.1:3000` |
| ready / health | **200 / 200** (re-verified) |
| Production current | **not present** |

Read-only recheck:

```bash
ASDEV_VPS_ENV_FILE=/path/to/private.env.vps \
  bash scripts/ops/asdev-remote-status.sh
```

---

## Architecture facts

| Fact | Detail |
|------|--------|
| Product repo | `alirezasafaei-dev/persiantoolbox` (public) |
| Mother repo | `alirezasafaei-dev/alirezasafaeisystems` |
| Staging base | `/srv/asdev/sites/persiantoolbox-staging` |
| Prod base | `/srv/asdev/sites/persiantoolbox` |
| Local source | `sites/live/persiantoolbox` (gitignored checkout) |

---

## How staging was executed (reference)

1. SSH from AUTOMATION_HOST/OWNER_PC to IRAN_PROD  
2. Create `/srv/asdev` layout (staging + shared parent)  
3. Add 2G swap (OOM mitigation)  
4. Platform at `/home/asdev/asdev-platform` + product clone  
5. Build on IRAN_PROD with heap 3072, HUSKY=0, ignore-scripts install  
6. Symlink + start standalone + healthcheck  

Details: `docs/reports/critical-site-staging-deploy-latest.md`

---

## Redeploy staging (same approval phrase)

Only if intentionally refreshing staging:

```bash
# on IRAN_PROD with PATH including node/pnpm
COMMIT=<sha>
bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment staging \
  --commit "$COMMIT" \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Rollback staging

```bash
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment staging \
  --commit <audit-sha> \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Next

See `docs/ops/production-execution-plan.md`.

```text
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

**Port conflict warning:** staging holds port 3000; production registry also uses 3000 on same host — resolve before production start.
