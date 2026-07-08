# Backup Freshness Report — CRITICAL_SITE

**Checked at:** 2026-07-08T22:27:34Z (stability observation window)  
**Backup root:** `/srv/asdev/backups/persiantoolbox`  
**Cron (unchanged):** `15 3 * * * /home/asdev/bin/asdev-meta-backup.sh`

| Artifact | Notes |
|----------|--------|
| `20260708T222048Z.tar.gz` | first meta backup |
| `20260708T222632Z.tar.gz` | second meta backup (newest at ops install) |

| Field | Value |
|-------|-------|
| newest (at last ops) | `20260708T222632Z.tar.gz` |
| age | minutes (≪ 36h) |
| status | **FRESH** |
| secrets in archive | no |
| restore drill (prior) | PASS (meta extract) |

```
BACKUP_FRESHNESS=FRESH
schedule_modified=no
```

Workflow: `docs/ops/backup-verification-workflow.md`  
Checklist: `docs/ops/backup-restore-checklist.md`
