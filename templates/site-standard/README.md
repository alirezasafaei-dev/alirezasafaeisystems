# Universal Site Standard Template — ASDEV

**Version:** 1.0  
**Last Updated:** 2026-07-08  
**Purpose:** Every future ASDEV site follows the same deploy, monitor, rollback, and docs model.

---

## Required tree (per site)

```
sites/live/<site-name>/          # product source (or site-source-map target)
templates/site-standard/         # this template (copy skeleton into new site docs)

# On IRAN_PROD (runtime layout)
/srv/asdev/sites/<site-name>/
  current -> releases/<release_id>
  releases/
  shared/
  asdev-runtime.pid
  asdev-runtime.log

# In platform repo for each site registration
deploy/registry.tsv              # one row per site
```

### Docs skeleton (copy into `sites/live/<site>/docs/ops/` or platform `docs/projects/`)

```
deploy/          # site-specific deploy notes (ports, health path)
docs/            # runbooks, architecture
config/          # non-secret examples only (*.example.env)
scripts/         # site helpers (optional; prefer platform scripts)
monitoring/      # site probe notes / expected endpoints
rollback/        # site rollback notes
```

This repo ships the skeleton under:

```
templates/site-standard/
  deploy/README.md
  docs/README.md
  config/site.example.env
  scripts/README.md
  monitoring/README.md
  rollback/README.md
```

---

## Platform contracts (do not fork)

| Concern | Standard |
|---------|----------|
| Deploy engine | `scripts/deploy/asdev-*.sh` |
| Registry | `deploy/registry.tsv` (distinct prod/staging ports) |
| Health | HTTP ready/health after activate |
| Rollback | symlink-only to previous release |
| Approvals | explicit phrases for prod/staging/migration/edge |
| Monitoring | `scripts/monitoring/*` + `docs/ops/monitoring-standard.md` |
| Docs style | reports under `docs/reports/`; ops under `docs/ops/` |

---

## Onboarding a new site

1. Add product source under `sites/live/<site>` or map in `deploy/site-source-map.tsv`  
2. Add registry row with unique `prod_port` / `staging_port`  
3. Copy this template skeleton into site docs  
4. Dry-run: `asdev-preflight.sh` + `asdev-deploy.sh --dry-run`  
5. Staging only with staging phrase  
6. Production only with production phrase  
7. Public edge only with public edge phrase  

---

## CRITICAL_SITE reference implementation

| Field | Value |
|-------|-------|
| site id | `persiantoolbox` |
| prod_port | 3100 |
| staging_port | 3200 |
| health | `/api/ready`, `/api/health` |
| runtime | node-standalone |
