# ASDEV Deployment Index

**Last Updated:** 2026-07-06  
**Scripts location:** Meta-repo `~/my-project/deploy/` (transitional until workspace restructure)

---

## Live products

| Project | Domain | Port | PM2 Process | Server Path | Deploy entrypoint |
|---|---|---|---|---|---|
| PersianToolbox | persiantoolbox.ir | 3000 | `persiantoolbox` | `/home/ubuntu/persiantoolbox/` | `sites/live/persiantoolbox/scripts/vps-deploy.sh` |
| AlirezaSafaeiSystems | alirezasafaeisystems.ir | 3002 | `my-portfolio-production` | `/var/www/my-portfolio/` | `sites/live/alirezasafaeisystems/scripts/vps-deploy.sh` |
| AuditSystems | audit.alirezasafaeisystems.ir | 3010 | `asdev-audit-ir-production-web` + worker | `/var/www/asdev-audit-ir/` | `sites/live/auditsystems/scripts/vps-deploy.sh` |

---

## Hold (do not deploy)

| Project | Domain | Port | Status |
|---|---|---|---|
| DevAtlas | TBD | 3003/3004 (registry) or 3020/3021 (local) | VPS path reserved, not running |

---

## Deploy script registry

```text
deploy/
├── DEPLOYMENT_STANDARD.md
├── registry.tsv
├── persiantoolbox/     deploy.sh, rollback.sh, health-check.sh
├── alirezasafaeisystems/
├── auditsystems/
└── devatlas/           (hold — do not use for production deploy)
```

---

## Rules

1. **One project at a time** — wait for health checks before next deploy
2. **Deploy from project directory** — not from meta-repo root alone
3. **Health checks mandatory** — rollback if failed
4. **Keep previous release 24h** for rollback
5. **No secrets in Git** — env files live on server only
6. **Owner approval required** for all production deploys

---

## Quick commands

```bash
# From meta-repo root (status/prepare only)
./scripts/deploy-vps.sh status
./scripts/deploy-vps.sh prepare auditsystems

# From project repo (actual deploy)
cd sites/live/auditsystems && bash scripts/vps-deploy.sh deploy production

# Health checks
./deploy/auditsystems/health-check.sh
./deploy/persiantoolbox/health-check.sh
./deploy/alirezasafaeisystems/health-check.sh
```

---

## Reference

Full deployment rules: meta-repo `DEPLOYMENT_RULES.md` (transitional).  
Product-specific: each repo's `docs/VPS_DEPLOYMENT.md` or `DOCUMENTATION.md`.