# ASDEV Deployment Index

**Last Updated:** 2026-07-16  
**Scripts location:** Meta-repo `~/my-project/deploy/` (transitional until workspace restructure)

---

## Live products

| Project | Domain | Effective production port | PM2 Process | Server Path | Deploy entrypoint |
|---|---|---:|---|---|---|
| PersianToolbox | persiantoolbox.ir | 3000 | `persiantoolbox` | `/home/ubuntu/persiantoolbox/` | `sites/live/persiantoolbox/scripts/vps-deploy.sh` |
| AlirezaSafaeiSystems | alirezasafaeisystems.ir | 3002 | `my-portfolio-production` | `/var/www/my-portfolio/` | `sites/live/alirezasafaeisystems/scripts/vps-deploy.sh` |
| AuditSystems | audit.alirezasafaeisystems.ir | 3012 | `auditsystems-web` + `auditsystems-worker` | `/var/www/asdev-audit-ir/` | `sites/live/auditsystems/scripts/vps-deploy.sh` |

The AuditSystems values above reflect the verified Release #103 production runtime. The repository-local lower-level deploy script currently defaults to port `3010` and process names prefixed with `asdev-audit-ir-production-`. Treat that as a portable script default, not proof of the active VPS registry. Operators must verify the effective Nginx upstream, PM2 names, port, and current symlink before every deployment.

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
7. **Verify runtime drift** — registry, PM2, Nginx, port, symlink, and deployed SHA must agree

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

- Coordinated release procedure: [RELEASE_RUNBOOK.md](RELEASE_RUNBOOK.md)
- Release #103 production record: [RELEASE_103_PRODUCTION_CLOSURE.md](RELEASE_103_PRODUCTION_CLOSURE.md)
- Product-specific instructions: each repo's `docs/VPS_DEPLOYMENT.md` or `DOCUMENTATION.md`
