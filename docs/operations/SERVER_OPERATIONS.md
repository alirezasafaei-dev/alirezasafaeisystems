# ASDEV Server Operations

**Last Updated:** 2026-07-16

High-level server operations reference. Credentials live on the server and in protected secret storage — never in this repository or release evidence.

---

## Production stack

- **Host:** VPS (Ubuntu)
- **Process manager:** PM2
- **Reverse proxy:** Nginx
- **Databases:** PostgreSQL (Audit), SQLite/PostgreSQL (Portfolio), SQLite (Toolbox)

---

## Live services

| Service | URL | Verified PM2 identity | Health check |
|---|---|---|---|
| PersianToolbox | https://persiantoolbox.ir/ | `persiantoolbox` | `deploy/persiantoolbox/health-check.sh` |
| Portfolio / ASDEV brand | https://alirezasafaeisystems.ir/ | `my-portfolio-production` | `deploy/alirezasafaeisystems/health-check.sh` |
| ASDEV Audit | https://audit.alirezasafaeisystems.ir/ | `auditsystems-web`, `auditsystems-worker` (Release #103) | `deploy/auditsystems/health-check.sh` |

Runtime identity must be verified on the host. Repository script defaults may differ from the active VPS registry; see [DEPLOYMENT_INDEX.md](DEPLOYMENT_INDEX.md).

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
2. Run the project health-check script
3. Confirm active symlink, deployed SHA/build metadata, Nginx upstream, and local port
4. Check Nginx and application error logs without exposing secrets
5. Roll back if a release health check fails or the artifact differs from the approved SHA
6. Document material incidents in the product incident log

Escalation reference: `docs/ONCALL_ESCALATION.md` (product repo).

---

## Approval boundaries

Agents must **not** without owner approval:

- change Nginx/server configuration;
- run production database migrations;
- rotate or expose credentials;
- deploy hold/secondary projects;
- delete PM2 processes, backups, or release directories;
- purge Git history.

A release-specific production authorization does not authorize unrelated infrastructure work.

---

## Evidence baseline

Production evidence requirements:

- approved full commit hashes match deployed artifacts;
- immutable release IDs and current symlinks agree;
- effective PM2 names and host ports are recorded;
- health and readiness endpoints return HTTP 200;
- Audit readiness confirms database and Redis;
- Audit worker is online and queue behavior is normal;
- public smoke routes pass;
- rollback target and verified backup are recorded;
- no secret is present in logs, artifacts, or GitHub comments.

See [RELEASE_RUNBOOK.md](RELEASE_RUNBOOK.md) for the coordinated procedure and [RELEASE_103_PRODUCTION_CLOSURE.md](RELEASE_103_PRODUCTION_CLOSURE.md) for the latest completed release record.
