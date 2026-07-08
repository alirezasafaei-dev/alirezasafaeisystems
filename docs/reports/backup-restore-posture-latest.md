# Backup / Restore Posture — CRITICAL_SITE

**Date:** 2026-07-08T22:25:00Z  
**Classification:** **WEAK — IMPROVING**

---

## Evidence

| Check | Result |
|-------|--------|
| Production release live | YES — recoverable via redeploy pin `fcc7192` |
| Symlink rollback previous | NO — first release |
| `/srv/asdev/backups` on IRAN_PROD | **CREATED** — first meta backup `20260708T222048Z` |
| Platform backup helper | ADDED — `scripts/deploy/asdev-backup-site.sh` |
| Restore drill executed | YES — extract to `/srv/asdev/restore-drill/…` meta OK |
| DR runbook | YES — `docs/ops/disaster-recovery-runbook.md` |

---

## Immediate operator path (safe, no edge)

On IRAN_PROD after platform scripts synced:

```bash
bash scripts/deploy/asdev-backup-site.sh --execute
ASDEV_BACKUP_ROOT=/srv/asdev/backups/persiantoolbox \
  bash scripts/monitoring/check-backup-freshness.sh
```

Then restore-list drill (meta only):

```bash
ls -la /srv/asdev/backups/persiantoolbox/
tar -tzf /srv/asdev/backups/persiantoolbox/<ts>.tar.gz | head
```

Do **not** include shared env until encrypted offsite target exists.

---

## Status

```
BACKUP_POSTURE=BASIC_META_OK
first_backup=20260708T222048Z
restore_drill=PASS (meta only)
NEXT=schedule recurring backup; encrypt shared env offsite when secrets placed
```
