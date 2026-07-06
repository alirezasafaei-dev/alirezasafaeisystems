# ASDEV Server Operations

**Last Updated:** 2026-07-06

High-level server operations reference. Credentials live on the server and in `.secrets/` — never in this repo.

---

## Production stack

- **Host:** VPS (Ubuntu)
- **Process manager:** PM2
- **Reverse proxy:** Nginx
- **Databases:** PostgreSQL (Audit), SQLite/PostgreSQL (Portfolio), SQLite (Toolbox)

---

## Live services

| Service | URL | PM2 | Health check |
|---|---|---|---|
| PersianToolbox | https://persiantoolbox.ir/ | `persiantoolbox` | `deploy/persiantoolbox/health-check.sh` |
| Portfolio / ASDEV brand | https://alirezasafaeisystems.ir/ | `my-portfolio-production` | `deploy/alirezasafaeisystems/health-check.sh` |
| ASDEV Audit | https://audit.alirezasafaeisystems.ir/ | `asdev-audit-ir-production-web`, `asdev-audit-ir-production-worker` | `deploy/auditsystems/health-check.sh` |

---

## Operational priorities (Audit-first)

1. Audit worker queue health and report pipeline
2. Audit web process and CSRF/session bootstrap
3. Cross-site analytics and attribution (Portfolio `/api/track`)
4. Toolbox uptime (traffic engine)
5. Portfolio uptime (trust hub)

DevAtlas, Novax, and secondary projects have **no production operational priority**.

---

## Incident response

1. Check PM2 status: `pm2 list`
2. Run project health-check script
3. Check Nginx upstream and local port binding
4. Rollback if health check fails post-deploy
5. Document in product `docs/runtime/Incidents/` if material

Escalation reference: `docs/ONCALL_ESCALATION.md` (product repo).

---

## Approval boundaries

Agents must **not** without owner approval:

- Change Nginx/server configuration
- Run production database migrations
- Rotate or expose credentials
- Deploy hold/secondary projects
- Delete PM2 processes or release directories

---

## Evidence baseline

Production evidence requirements (E0-05):

- Live commit hash matches deployed artifact
- Health endpoints return 200
- Audit worker processes jobs
- Sitemap/canonical URLs correct
- Analytics events flow with consent

See meta-repo `IMPLEMENTATION-STATUS.md` for last verified snapshot (transitional).