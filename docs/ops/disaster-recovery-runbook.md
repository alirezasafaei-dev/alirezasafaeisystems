# Disaster Recovery Runbook — ASDEV CRITICAL_SITE

**Version:** 1.0  
**Last Updated:** 2026-07-08  
**Hosts:** aliases only (`IRAN_PROD`, `OWNER_PC`, `AUTOMATION_HOST`)  
**RTO target (app layer):** < 30 minutes  
**RPO target:** best-effort until shared backup root is established  

---

## Scope

Recover **CRITICAL_SITE** (`persiantoolbox`) application layer and (after public edge) reverse proxy path.

Does **not** authorize new production deploys without `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`.

---

## What must be recoverable

| Asset | Location pattern (alias) | Priority |
|-------|--------------------------|----------|
| Immutable releases | `IRAN_PROD:/srv/asdev/sites/persiantoolbox/releases/*` | P0 |
| current symlink | `…/persiantoolbox/current` | P0 |
| Shared env (secrets) | `…/persiantoolbox/shared/` (never in git) | P0 |
| Runtime pid/log | `asdev-runtime.pid`, `asdev-runtime.log` | P1 |
| Platform deploy engine | `IRAN_PROD:~/asdev-platform` or synced scripts | P1 |
| nginx edge config | `/etc/nginx/sites-*` (after public edge) | P1 |
| TLS material | Let's Encrypt live paths (host-managed) | P1 |
| Database dumps | when product DB is enabled under shared | P0 if live data |

---

## Current gap (2026-07-08)

- First production release exists: `20260708T221124Z-fcc7192`  
- **No previous_release** → symlink rollback history empty  
- **No backup artifacts** observed under `/srv/asdev/backups` on IRAN_PROD  
- Onsite backup scripts still portfolio-oriented (`backup-onsite.sh` defaults)  

**Implication:** recovery today = redeploy same pin + rebuild, not restore from backup.

---

## Recovery playbooks

### A. Process dead, release intact

1. Confirm port 3100 free or owned by dead pid  
2. Start from `current` with same start command (node-standalone) used by deploy engine  
3. Prefer: re-run deploy same SHA with approval phrase (idempotent path)  
4. Validate: `check-prod-app-layer.sh` + `check-deploy-status.sh` on host  

### B. Bad release (health fail after future multi-release)

1. `asdev-rollback.sh --site persiantoolbox --environment production` (with required phrase/guards)  
2. Healthcheck after symlink swap  
3. If fail: emergency stop pid; open incident  

### C. Host loss / disk wipe

1. Rebuild IRAN_PROD base (Node, swap policy, user `asdev`)  
2. Restore platform scripts from GitHub main  
3. Restore shared secrets from **offline encrypted backup** (owner-held; never git)  
4. Redeploy product pin `fcc7192…` (or newer approved pin)  
5. Re-apply public edge only with `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`  

### D. Public edge misconfig (after edge is live)

1. Restore prior nginx config from host backup dir  
2. `nginx -t && systemctl reload nginx`  
3. Leave app layer on :3100 running  

---

## Backup standard (to implement)

### Daily onsite (IRAN_PROD)

Capture to `/srv/asdev/backups/persiantoolbox/YYYYMMDDTHHMMSSZ/`:

- tarball of `current` release metadata + `release.meta`  
- copy of shared config **excluding** raw secrets from reports (encrypt secrets archive with owner key)  
- nginx sites-available snippet if edge active  
- optional: `pg_dump` when DB URL present  

Retention: 7 daily · 4 weekly · 3 monthly.

### Offsite

- Encrypted push to owner-controlled store (`push-offsite-backup.sh` pattern)  
- Never unencrypted secrets off-box  

### Freshness monitor

```bash
ASDEV_BACKUP_ROOT=/srv/asdev/backups/persiantoolbox \
  bash scripts/monitoring/check-backup-freshness.sh
```

---

## Restore verification (required, not optional)

A backup is **not** valid until a restore drill succeeds.

### Minimum quarterly drill

1. Create scratch dir under `/srv/asdev/restore-drill/<id>/`  
2. Extract latest backup tarball  
3. Verify `release.meta` readable and commit matches expected pin  
4. Optional: start temporary process on **unused high port** (never 3100/3200 if prod/staging live)  
5. Curl ready/health on drill port  
6. Tear down drill process  
7. Record: `docs/reports/backup-restore-drill-latest.md`  

Scripts to evolve:

- `scripts/deploy/restore-drill-onsite.sh` (parameterize for `/srv/asdev/sites/*`)  
- `scripts/deploy/backup-onsite.sh` (add ASDEV site-root mode)  

### Immediate drill (no production mutation)

Documented dry posture for this loop:

| Step | Result |
|------|--------|
| Prove release tree exists | PASS (live release on IRAN_PROD) |
| Prove app health | PASS (200/200 on :3100) |
| Prove restore from backup artifact | **FAIL / N/A** — no backup artifact yet |
| Document gap | this runbook |

---

## Incident severity

| Class | Example | First action |
|-------|---------|--------------|
| SEV1 | prod :3100 down | restart/redeploy; page owner |
| SEV2 | public edge 5xx, app local OK | nginx/DNS path only |
| SEV3 | backup stale > 36h | fix backup job same day |
| SEV4 | monitoring timer drift | non-urgent |

---

## Approval map

| Action | Phrase |
|--------|--------|
| Production redeploy | `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` |
| Public edge change | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| Migration | `APPROVE_CRITICAL_SITE_MIGRATION` |
| Live monitoring timers | `APPROVE_MONITORING_LIVE_TIMERS` |
| Release hard-delete | `APPROVE_RELEASE_DELETE` |

---

## Related docs

- `docs/ops/rollback-plan.md`  
- `docs/ops/BACKUP_RESTORE_DRILL.md` (legacy portfolio/audit notes; prefer this runbook for CRITICAL_SITE)  
- `docs/ops/INCIDENT_RUNBOOK.md`  
- `docs/ops/monitoring-standard.md`  
