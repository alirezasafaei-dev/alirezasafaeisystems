# CRITICAL_SITE Protection Policy

**Site:** `persiantoolbox.ir`  
**Deploy Path:** `/srv/asdev/sites/persiantoolbox.ir/`  
**Status:** ACTIVE — This site generates revenue and traffic for the ASDEV Audit platform.

---

## 1. Definition

A **CRITICAL_SITE** is a production site that must remain fully operational at all times. Any downtime directly impacts revenue, lead generation, or audit flow. This policy defines non-negotiable protection rules and the process for safe maintenance.

---

## 2. Protected Assets

| Asset | Location | Purpose |
|---|---|---|
| Live deployment | `/srv/asdev/sites/persiantoolbox.ir/current` | Symlink to active release |
| Shared directory | `/srv/asdev/sites/persiantoolbox.ir/shared` | Persistent config, uploads, env |
| PM2 process | Process managed by PM2 | Application runtime |
| Nginx config | `/etc/nginx/sites-available/persiantoolbox.ir` | Reverse proxy + SSL |
| Database | PostgreSQL/SQLite backing the site | Data persistence |
| Metadata | `/srv/asdev/sites/persiantoolbox.ir/metadata.json` | Deployment tracking |

---

## 3. Prohibited Actions (Without Emergency Override)

1. **Do not remove** the deploy directory, current symlink, or shared directory
2. **Do not disable** the site's nginx server block
3. **Do not stop or restart** the PM2 process without a staged deploy
4. **Do not drop** or truncate the site's database
5. **Do not delete** the `shared/` directory or its contents
6. **Do not manually modify** the `current` symlink — only deploy scripts may change it
7. **Do not modify** SSL certificates without validation
8. **Do not remove** environment variables from shared config

---

## 4. Allowed Actions

- Running the protection check script (`check-critical-site-protection.sh`)
- Staged deploys via the approved deploy pipeline
- Viewing logs (`pm2 logs`, nginx error logs)
- Monitoring health endpoints
- Database backups (read-only or export)

---

## 5. Emergency Override

When a destructive action is absolutely required:

1. Set the environment variable: `EMERGENCY_OVERRIDE_CRITICAL_SITE=<phrase>`
2. Run the action through the guard script (`protect-critical-site.sh`)
3. The override is **logged** to `/var/log/critical-site-overrides.log`
4. A post-incident review is **mandatory** within 24 hours

The override phrase must be provided at runtime — it is never stored in scripts or config files.

---

## 6. Verification Schedule

| Check | Frequency | Script |
|---|---|---|
| Protection status | Before any deploy | `check-critical-site-protection.sh` |
| Full health check | Daily (automated) | `check-critical-site-protection.sh --full` |
| PM2 process status | Every 5 minutes | Platform monitor |
| SSL certificate expiry | Weekly | Platform monitor |

---

## 7. Incident Response

1. Run `check-critical-site-protection.sh` to identify what is broken
2. Check PM2 logs: `pm2 logs persiantoolbox`
3. Check nginx logs: `tail -f /var/log/nginx/persiantoolbox_error.log`
4. If symlink is broken, re-deploy from last known good release
5. If database is down, restore from latest backup
6. Document incident in deployment log
