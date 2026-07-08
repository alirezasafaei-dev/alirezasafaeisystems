# Universal Deployment Model — ASDEV

**Version:** 2.0  
**Last Updated:** 2026-07-08  
**Goal:** Every future project deploys identically via the same engine.

---

## Pipeline (identical for all sites)

```
1. PREFLIGHT     asdev-preflight.sh
2. PREPARE SRC   asdev-prepare-site-source.sh (if needed)
3. BUILD         registry build_command_id → new releases/<id>/
4. META          write release.meta (commit, ports, previous_release)
5. ACTIVATE      atomic current → new release (symlink)
6. HEALTH        asdev-healthcheck.sh AFTER activate
7. ON FAIL       auto symlink back to previous (when exists)
8. REPORT        docs/reports/* or control-plane history
9. GC            asdev-release-gc.sh (never hard-delete protected without phrase)
```

---

## Required capabilities

| Capability | Implementation |
|------------|----------------|
| Build | `node-pnpm-build` (extensible command ids) |
| Release creation | timestamp + short SHA under `releases/` |
| Health check | registry path + port; ready/health HTTP |
| Activation | symlink strategy |
| Rollback | `asdev-rollback.sh` + rehearse dry-run |
| Cleanup | quarantine excess releases |
| Reporting | release.meta + operator reports |
| History | `asdev-release-history.sh` |

---

## Environment matrix

| Env | Approval | Port field |
|-----|----------|------------|
| staging | `APPROVE_PHASE_2_STAGING_DEPLOY` | staging_port |
| production | `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` for protected | prod_port |

Dry-run always allowed without phrase.

---

## Zero-downtime intent

- New release built beside live  
- Symlink flip is atomic  
- Health after flip; rollback on failure  
- Public edge (nginx) is **out of band** and gated separately  

---

## Adding a new project

1. Add product source (or artifact map)  
2. Add `deploy/registry.tsv` row (unique ports)  
3. Add `project.yaml` (or templates/projects entry)  
4. Dry-run preflight + deploy  
5. Staging with phrase  
6. Production with phrase  
7. Edge only with public-edge phrase  

---

## Related

- `deploy/DEPLOYMENT_STANDARD.md`  
- `docs/ops/deployment-history-and-rollback.md`  
- `docs/ops/runtime-port-isolation.md`  
