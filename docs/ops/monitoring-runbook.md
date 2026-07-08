# Monitoring Runbook — ASDEV

**Last Updated:** 2026-07-08  
**Status:** Foundation (no live production timers enabled by this document)

---

## Scope

Monitoring foundation for:

1. **CRITICAL_SITE** public HTTP health (`persiantoolbox.ir`)
2. **AUTOMATION_HOST** executor readiness
3. Local disk capacity on OWNER_PC / AUTOMATION_HOST
4. Backup freshness (when backup root is configured)

No IRAN_PROD mutation. No nginx/pm2 restarts. No DNS/SSL changes.

---

## Scripts

| Script | Purpose | Mode |
|--------|---------|------|
| `scripts/monitoring/check-prod-app-layer.sh` | Loopback prod ready/health (`:3100`) | read-only HTTP |
| `scripts/monitoring/check-deploy-status.sh` | current symlink, meta, pid | local read-only |
| `scripts/monitoring/check-critical-site-http.sh` | Public HTTP root/ready/health | read-only HTTP |
| `scripts/monitoring/check-automation-host-readiness.sh` | Tooling + repo + resource checks | local read-only |
| `scripts/monitoring/check-disk-local.sh` | Disk used% thresholds | local read-only |
| `scripts/monitoring/check-backup-freshness.sh` | Newest backup age | local read-only |

All scripts support `--dry-run` / `--check`.  
Standard: `docs/ops/monitoring-standard.md`.

---

## Manual execution

```bash
# Dry-run first
bash scripts/monitoring/check-prod-app-layer.sh --dry-run
bash scripts/monitoring/check-deploy-status.sh --dry-run
bash scripts/monitoring/check-critical-site-http.sh --dry-run
bash scripts/monitoring/check-automation-host-readiness.sh --dry-run
bash scripts/monitoring/check-disk-local.sh --dry-run
bash scripts/monitoring/check-backup-freshness.sh --dry-run

# Live checks (still non-mutating)
# On IRAN_PROD:
bash scripts/monitoring/check-prod-app-layer.sh
bash scripts/monitoring/check-deploy-status.sh
# Anywhere:
bash scripts/monitoring/check-critical-site-http.sh   # meaningful after public edge
bash scripts/monitoring/check-automation-host-readiness.sh
bash scripts/monitoring/check-disk-local.sh
ASDEV_BACKUP_ROOT=/path/to/backups bash scripts/monitoring/check-backup-freshness.sh
```

---

## Thresholds (defaults)

| Check | Warning | Critical |
|-------|---------|----------|
| Disk used% | ≥ 80% | ≥ 90% |
| Backup age | — | > 36 hours |
| CRITICAL_SITE HTTP | non-2xx | any endpoint non-2xx |
| AUTOMATION_HOST | missing optional tools / idle PM2 | missing critical tools or repo |

---

## When a check fails

1. Re-run once with `--dry-run` then live to confirm.
2. Classify:
   - **Transient** (timeout, brief 5xx) → wait, recheck
   - **Local host** (disk, tools) → repair AUTOMATION_HOST only under approved non-destructive scope
   - **CRITICAL_SITE outage** → follow `docs/ops/INCIDENT_RUNBOOK.md`; do **not** deploy without approval phrase
3. Record result in `docs/reports/` or agent memory — not as GitHub spam comments.

---

## Live timers

Installing cron/systemd timers is **not** enabled by this foundation PR.

Required future approval for live monitoring install on hosts:

`APPROVE_MONITORING_LIVE_TIMERS`

---

## Aliases only

Never put raw IPs, tokens, or private paths with secrets into alerts or reports.
Use: `OWNER_PC`, `AUTOMATION_HOST`, `IRAN_PROD`, `CRITICAL_SITE`.
