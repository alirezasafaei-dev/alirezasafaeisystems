# IRAN Platform Sync + Meta Backup Cron

**Date:** 2026-07-08  
**Scope:** Safe post-production ops (no edge, no migration, no monitoring live timers)  
**Host:** IRAN_PROD  

---

## 1. Platform script sync

Synced from OWNER_PC branch `ops/autonomous-production-ops-loop-v1` →  
`/home/asdev/asdev-platform/`:

| Path | Result |
|------|--------|
| `scripts/deploy/` | synced (includes `asdev-backup-site.sh`) |
| `scripts/monitoring/` | synced (app-layer + deploy-status) |
| `scripts/ops/` | synced |
| `deploy/registry.tsv` + standards | synced |
| `ops/nginx/` templates | synced (not installed into system nginx) |
| Selected `docs/ops/*` | synced |

Verified on host:

- `asdev-backup-site.sh` executable  
- `check-prod-app-layer.sh` / `check-deploy-status.sh` present  
- nginx **template only** under platform tree  

---

## 2. Recurring meta backup

| Item | Value |
|------|-------|
| Wrapper | `/home/asdev/bin/asdev-meta-backup.sh` |
| Schedule | `15 3 * * *` (03:15 UTC daily) |
| Backup root | `/srv/asdev/backups/persiantoolbox` |
| Retention | keep last ~14 timestamp dirs |
| Log | `/home/asdev/logs/asdev-meta-backup.log` |
| Secrets in archive | **no** (meta only) |

This is **backup automation**, not `APPROVE_MONITORING_LIVE_TIMERS`.

---

## 3. Validation after install

| Check | Expected |
|-------|----------|
| `check-deploy-status.sh` | DEPLOY_OK |
| `check-prod-app-layer.sh` | ready/health 200 |
| `asdev-backup-site.sh --execute` | BACKUP_OK |
| Production :3100 | still healthy |
| Staging :3000 | still healthy |
| nginx | **unchanged** |

---

## 4. Staging rebind

Plan only: `docs/ops/staging-rebind-3000-to-3200.md`  
**Not executed.**

---

## Status

```
IRAN_PLATFORM_SYNC=OK
META_BACKUP_CRON=INSTALLED
PUBLIC_EDGE=NOT_TOUCHED
STAGING_REBIND=PLAN_ONLY
```
