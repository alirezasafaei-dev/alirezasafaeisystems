# project.yaml Specification

**Version:** 1.0  
**Last Updated:** 2026-07-08

Every ASDEV-managed site/product should have `project.yaml` at product root (or monorepo path referenced by registry).

---

## Schema (YAML)

```yaml
id: persiantoolbox                 # registry site_id
name: PersianToolbox
owner: platform+product
status: production_app_layer       # draft|staging|production_app_layer|public|frozen
critical: true

source:
  path: sites/live/persiantoolbox
  vcs: git

deploy:
  registry_site: persiantoolbox
  prod_port: 3100
  staging_port: 3200
  health: /api/ready
  strategy: symlink
  runtime: node-standalone

ownership:
  code: alirezasafaei-dev
  ops: AUTOMATION_HOST
  runtime: IRAN_PROD

docs:
  readme: README.md
  memory: docs/ops/PROJECT_MEMORY.md   # optional

checks:
  health: /api/ready
  health_alt: /api/health

rollback:
  mode: symlink-previous
  notes: first prod may lack previous_release
```

---

## Required companion files

| File | Purpose |
|------|---------|
| `README.md` | human entry |
| deploy registration | `deploy/registry.tsv` row |
| health endpoints | documented + implemented |
| rollback notes | docs or template/site-standard |
| ownership | project.yaml + CODEOWNERS |

---

## Validation

```bash
bash scripts/ops/validate-project-yaml.sh --root sites/live/persiantoolbox
bash scripts/ops/audit-sites-standard.sh
```
