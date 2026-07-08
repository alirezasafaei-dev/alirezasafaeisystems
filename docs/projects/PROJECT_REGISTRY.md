# Project Registry — ASDEV

**Updated:** 2026-07-08  
**Machine source:** `deploy/registry.tsv`  
**Human source:** this file + `docs/projects/*.md` + `templates/projects/*.project.yaml`

---

## Sites

| ID | Name | Critical | Owner | Repo path | Prod port | Staging port | Health | Deploy | Rollback | Status |
|----|------|----------|-------|-----------|-----------|--------------|--------|--------|----------|--------|
| persiantoolbox | PersianToolbox | **yes** | platform+product | sites/live/persiantoolbox | **3100** | 3200 | /api/ready | symlink node-standalone | symlink previous | **prod app-layer LIVE** · edge OFF · staging live :3000 legacy |
| alirezasafaeisystems | AlirezaSafaeiSystems | no | platform | . (monorepo) | 3001 | 3101 | /api/ready | symlink | symlink | monorepo + control plane docs |
| auditsystems | AuditSystems | no | platform | sites/live/auditsystems | 3002 | 3102 | /api/ready | symlink | symlink | registry row; source may be missing on host |
| devatlas | DevAtlas | no | platform | sites/live/devatlas | 3003 | 3103 | /api/health | symlink | symlink | registry row; frozen product scope unless Audit-aligned |

---

## Field definitions

| Field | Meaning |
|-------|---------|
| Critical | Protected; production needs CRITICAL_SITE phrases |
| Deploy | Strategy from registry |
| Rollback | symlink to previous release when exists |
| Status | human operational summary |

---

## Ownership model

| Role | Responsibility |
|------|----------------|
| code | product repo / monorepo path |
| ops | AUTOMATION_HOST agents + deploy engine |
| runtime | IRAN_PROD |

---

## Validation

```bash
bash scripts/ops/validate-registry-schema.sh
bash scripts/ops/audit-sites-standard.sh
```

## Related project notes

- `docs/projects/persiantoolbox.md`  
- `docs/projects/alirezasafaeisystems.md`  
- `docs/projects/auditsystems.md`  
- `docs/projects/devatlas.md`  
