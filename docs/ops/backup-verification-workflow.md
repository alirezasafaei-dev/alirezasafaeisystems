# Backup Verification Workflow — CRITICAL_SITE

**Status:** Foundation (manual / on-demand)  
**Last Updated:** 2026-07-08  
**Does not:** install or change live timers, alter existing cron schedules, enable edge

---

## Purpose

Prove that onsite meta backups are **present, fresh, and restorable** before relying on them in an incident.

Existing schedule on IRAN_PROD (do not change in this workflow unless owner requests):

```
15 3 * * * /home/asdev/bin/asdev-meta-backup.sh
```

---

## Artifacts

| Item | Path pattern |
|------|----------------|
| Backup root | `/srv/asdev/backups/persiantoolbox/` |
| Timestamp dir | `YYYYMMDDTHHMMSSZ/` |
| Archive | `YYYYMMDDTHHMMSSZ.tar.gz` |
| Manifest | `backup.manifest`, `release.meta`, `current.link`, `releases.list` |
| Cron log | `/home/asdev/logs/asdev-meta-backup.log` |

**Meta-only by default** — no shared secrets unless explicitly included with encryption offsite.

---

## Workflow A — Freshness report (read-only)

On IRAN_PROD:

```bash
ASDEV_BACKUP_ROOT=/srv/asdev/backups/persiantoolbox \
  bash /home/asdev/asdev-platform/scripts/monitoring/check-backup-freshness.sh

# Optional report file (operator machine or host)
ASDEV_BACKUP_ROOT=/srv/asdev/backups/persiantoolbox \
  bash /home/asdev/asdev-platform/scripts/monitoring/report-backup-freshness.sh
```

Pass criteria: newest artifact age ≤ 36 hours (default).

---

## Workflow B — Manual meta backup (on demand)

Does not change cron:

```bash
bash /home/asdev/asdev-platform/scripts/deploy/asdev-backup-site.sh \
  --site-root /srv/asdev/sites/persiantoolbox \
  --backup-root /srv/asdev/backups/persiantoolbox \
  --execute
```

Then re-run freshness check.

---

## Workflow C — Restore verification (scratch only)

See `docs/ops/backup-restore-checklist.md`.

Never extract over live `current` without an incident + approval path.

---

## Reporting

After each verification cycle, append or refresh:

- `docs/reports/backup-freshness-latest.md` (generated or hand-written)  
- Optional: note in `docs/reports/critical-site-stability-report.md`

Use host aliases only — no raw IPs or secrets.

---

## Failure actions

| Failure | Action |
|---------|--------|
| No backup root | create root; run manual `--execute` once |
| Age > 36h | run manual backup; inspect cron log; **do not** silently change schedule without note |
| Corrupt tarball | re-run backup; keep prior good artifact |
| Restore drill fail | open incident note; do not claim DR ready |

---

## Related

- `docs/ops/disaster-recovery-runbook.md`  
- `docs/ops/backup-restore-checklist.md`  
- `scripts/deploy/asdev-backup-site.sh`  
- `scripts/monitoring/check-backup-freshness.sh`  
