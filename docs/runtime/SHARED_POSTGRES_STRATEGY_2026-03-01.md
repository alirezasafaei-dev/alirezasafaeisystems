# Shared PostgreSQL Strategy (3 Sites)

## Decision
- One PostgreSQL cluster on VPS
- Isolated database + role per site/environment
- No shared application schema across products

## Isolation Map
- Portfolio:
  - `asdev_portfolio_production` / role `asdev_portfolio_prod`
  - `asdev_portfolio_staging` / role `asdev_portfolio_staging`
- Audit:
  - `asdev_audit_production` / role `asdev_audit_user`
  - `asdev_audit_staging` / role `asdev_audit_user`
- PersianToolbox:
  - `persian_tools_prod` / role `persian_tools_prod`
  - `persian_tools_staging` / role `persian_tools_staging`

## Operational Rules
1. Each app uses its own DB user only.
2. No cross-app read/write grants.
3. Secrets stored only on VPS (`/etc/asdev-postgres/credentials.env`, mode `600`).
4. Application envs reference per-app `DATABASE_URL` only.

## Automation
- Audit cluster:
  - `scripts/db/vps-postgres-cluster-audit.sh`
- Provision/verify isolation:
  - `scripts/db/vps-provision-shared-postgres.sh`
- Show URL hints:
  - `scripts/db/vps-show-postgres-env-hints.sh`
