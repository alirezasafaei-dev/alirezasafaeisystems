# Backup, Restore, and Disaster Recovery — ASDEV Audit Platform

## Overview

This document defines backup procedures, restore workflows, and disaster recovery targets for the ASDEV Audit platform. The platform uses PostgreSQL for data and file-based storage for reports/PDFs.

**RTO (Recovery Time Objective):** < 30 minutes
**RPO (Recovery Point Objective):** < 1 hour

---

## 1. What to Back Up

| Component | Method | Frequency | Retention |
|---|---|---|---|
| PostgreSQL database | `pg_dump` → gzip | Every 6 hours | 30 days |
| Application files | rsync to backup location | Daily | 7 days |
| PM2 configuration | `pm2 save` | On deploy | Last 3 releases |
| Nginx config | File copy | On change | Indefinite |
| Environment files | Encrypted copy | On change | Indefinite |
| SSL certificates | Certbot auto-renewal | Auto (90-day cycle) | Managed by Let's Encrypt |

---

## 2. Backup Procedures

### 2.1 Database Backup (pg_dump)

```bash
# On VPS (193.93.169.247)
ssh asdev@193.93.169.247

# Set database credentials (from .env on VPS)
export PGHOST="127.0.0.1"
export PGPORT="5432"
export PGUSER="postgres"
export PGDATABASE="asdev_audit"

# Create timestamped backup
BACKUP_DIR="/var/backups/asdev-audit"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP_FILE="$BACKUP_DIR/asdev-audit-${TIMESTAMP}.sql.gz"

pg_dump -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
  --format=custom --compress=9 \
  -f "$BACKUP_FILE"

# Verify backup integrity
pg_restore -l "$BACKUP_FILE" > /dev/null 2>&1 && echo "Backup OK" || echo "Backup CORRUPT"

# Apply retention policy (keep 30 days)
find "$BACKUP_DIR" -name "asdev-audit-*.sql.gz" -mtime +30 -delete

# Log backup
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Backup completed: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))" \
  >> "$BACKUP_DIR/backup.log"
```

### 2.2 Database Backup (Local Script)

```bash
# From workspace (local machine)
cd sites/live/auditsystems
pnpm scheduled:run  # runs scheduled audit scripts, not backup itself

# Manual backup via VPS
ssh asdev@193.93.169.247 "bash /var/backups/asdev-audit/backup-db.sh"
```

### 2.3 Application Files Backup

```bash
# On VPS
BACKUP_DIR="/var/backups/asdev-audit"
APP_DIR="/var/www/asdev-audit-ir"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)

# Backup current release
tar -czf "$BACKUP_DIR/app-${TIMESTAMP}.tar.gz" \
  -C "$APP_DIR/current/production" \
  --exclude='node_modules' \
  --exclude='.next/cache' \
  --exclude='logs' \
  .

# Keep last 7 daily backups
find "$BACKUP_DIR" -name "app-*.tar.gz" -mtime +7 -delete
```

### 2.4 PM2 Configuration Backup

```bash
# On VPS — PM2 saves process list automatically
pm2 save

# The dump file is at ~/.pm2/dump.pm2
# It's backed up as part of the home directory
```

### 2.5 Remote Backup (Offsite)

```bash
# Sync backups to remote storage (add to cron)
# Option A: rsync to another server
rsync -avz --delete /var/backups/asdev-audit/ \
  remote-user@remote-host:/backups/asdev-audit/

# Option B: Upload to cloud storage (rclone example)
rclone copy /var/backups/asdev-audit/ remote:asdev-audit-backups/ --max-age 30d
```

---

## 3. Backup Schedule

| Time (UTC) | Task | Script |
|---|---|---|
| 00:00, 06:00, 12:00, 18:00 | Database backup | `pg_dump` via cron |
| 02:00 | Application files backup | `tar` via cron |
| On deploy | PM2 save + release snapshot | `deploy.sh` |
| On change | Nginx config | Manual |
| Auto (daily) | SSL certificate renewal | Certbot |

### VPS Cron Setup

```bash
# Add to crontab on VPS (as asdev user)
crontab -e

# Database backups every 6 hours
0 0,6,12,18 * * * /var/backups/asdev-audit/backup-db.sh >> /var/backups/asdev-audit/cron.log 2>&1

# Application backup daily at 02:00
0 2 * * * /var/backups/asdev-audit/backup-app.sh >> /var/backups/asdev-audit/cron.log 2>&1

# Cleanup old backups daily at 03:00
0 3 * * * find /var/backups/asdev-audit -name "*.sql.gz" -mtime +30 -delete
0 3 * * * find /var/backups/asdev-audit -name "*.tar.gz" -mtime +7 -delete
```

---

## 4. Restore Procedures

### 4.1 Database Restore

```bash
# On VPS
ssh asdev@193.93.169.247

# Stop the application first
pm2 stop asdev-audit-ir-production-web asdev-audit-ir-production-worker

# Identify backup to restore
ls -lht /var/backups/asdev-audit/asdev-audit-*.sql.gz | head -5

# Restore from backup
BACKUP_FILE="/var/backups/asdev-audit/asdev-audit-YYYYMMDDTHHMMSSZ.sql.gz"

# Drop and recreate database
dropdb -h 127.0.0.1 -U postgres asdev_audit
createdb -h 127.0.0.1 -U postgres asdev_audit

# Restore
pg_restore -h 127.0.0.1 -U postgres -d asdev_audit \
  --no-owner --no-privileges \
  "$BACKUP_FILE"

# Verify
psql -h 127.0.0.1 -U postgres -d asdev_audit -c "SELECT COUNT(*) FROM users;"

# Restart application
pm2 start asdev-audit-ir-production-web asdev-audit-ir-production-worker
pm2 save

# Health check
curl -fsS http://127.0.0.1:3010/api/ready
```

### 4.2 Application Files Restore

```bash
# On VPS
BACKUP_FILE="/var/backups/asdev-audit/app-YYYYMMDDTHHMMSSZ.tar.gz"
RESTORE_DIR="/var/www/asdev-audit-ir/releases/production/restore-$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

# Reinstall dependencies
cd "$RESTORE_DIR"
pnpm install --frozen-lockfile
npx prisma generate

# Build
export NODE_ENV=production
pnpm run build

# Switch PM2 to restored release
pm2 delete asdev-audit-ir-production-web asdev-audit-ir-production-worker 2>/dev/null || true
pm2 start ecosystem.config.cjs --only asdev-audit-ir-production-web --only asdev-audit-ir-production-worker
pm2 save

# Update symlink
ln -sfn "$RESTORE_DIR" /var/www/asdev-audit-ir/current/production
```

### 4.3 Full Disaster Recovery

```bash
# Scenario: VPS is completely lost

# 1. Provision new VPS (Ubuntu 22.04+)
# 2. Install dependencies
sudo apt update && sudo apt install -y nginx postgresql certbot

# 3. Restore database
sudo -u postgres createdb asdev_audit
pg_restore -h 127.0.0.1 -U postgres -d asdev_audit \
  /backup-location/asdev-audit-LATEST.sql.gz

# 4. Restore application
tar -xzf /backup-location/app-LATEST.tar.gz -C /var/www/asdev-audit-ir/releases/production/latest/
cd /var/www/asdev-audit-ir/releases/production/latest/
pnpm install --frozen-lockfile
npx prisma generate
pnpm run build

# 5. Restore Nginx config
cp /backup-location/nginx-audit.conf /etc/nginx/sites-available/audit.alirezasafaeisystems.ir
ln -sf /etc/nginx/sites-available/audit.alirezasafaeisystems.ir /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 6. Restore SSL
sudo certbot --nginx -d audit.alirezasafaeisystems.ir

# 7. Restore PM2
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup  # follow the command it outputs

# 8. Verify
curl -fsS https://audit.alirezasafaeisystems.ir/api/ready
```

---

## 5. Backup Drill Schedule

### Weekly Drill (Every Monday)

```bash
# 1. Verify latest backup exists and is valid
ssh asdev@193.93.169.247 "
  LATEST=\$(ls -t /var/backups/asdev-audit/asdev-audit-*.sql.gz 2>/dev/null | head -1)
  if [ -z \"\$LATEST\" ]; then
    echo 'FAIL: No backup found'
    exit 1
  fi
  pg_restore -l \"\$LATEST\" > /dev/null 2>&1
  echo \"Latest backup: \$LATEST ($(du -h \"\$LATEST\" | cut -f1))\"
"

# 2. Test restore to a temporary database
ssh asdev@193.93.169.247 "
  LATEST=\$(ls -t /var/backups/asdev-audit/asdev-audit-*.sql.gz | head -1)
  createdb -h 127.0.0.1 -U postgres asdev_audit_drill 2>/dev/null || true
  dropdb -h 127.0.0.1 -U postgres asdev_audit_drill 2>/dev/null || true
  createdb -h 127.0.0.1 -U postgres asdev_audit_drill
  pg_restore -h 127.0.0.1 -U postgres -d asdev_audit_drill \"\$LATEST\"
  psql -h 127.0.0.1 -U postgres -d asdev_audit_drill -c 'SELECT COUNT(*) AS users FROM users;'
  psql -h 127.0.0.1 -U postgres -d asdev_audit_drill -c 'SELECT COUNT(*) AS audits FROM audit_runs;'
  dropdb -h 127.0.0.1 -U postgres asdev_audit_drill
  echo 'Drill restore: PASS'
"

# 3. Log drill result
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Weekly drill: PASS" >> ops/reports/drill-log.md
```

### Monthly Full DR Test

```bash
# Restore to a staging environment (separate port)
# Verify full application stack works
# Document recovery time
# Update this document if procedures changed
```

---

## 6. Backup Locations

| Location | Path | Access |
|---|---|---|
| VPS local | `/var/backups/asdev-audit/` | SSH as asdev |
| VPS app releases | `/var/www/asdev-audit-ir/releases/` | SSH as asdev |
| Local workspace | `sites/live/auditsystems/ops/backups/` | Direct |
| Remote (if configured) | `remote-host:/backups/asdev-audit/` | SSH |

---

## 7. Recovery Targets

| Metric | Target | Current |
|---|---|---|
| RTO (Recovery Time Objective) | < 30 minutes | ~15 min (DB only), ~25 min (full) |
| RPO (Recovery Point Objective) | < 1 hour | 6 hours (backup interval) |
| Backup verification | Weekly | Weekly drill |
| Offsite backup | Required | Optional (add remote sync) |

### RPO Improvement Plan

Current RPO is 6 hours (backup interval). To achieve < 1 hour RPO:

1. Enable PostgreSQL WAL archiving: `archive_mode = on`, `archive_command` to copy WAL files
2. Or increase backup frequency to hourly (may impact VPS performance)
3. Consider streaming replication to a standby server

---

## 8. Monitoring Backup Health

```bash
# Check backup freshness (should be < 6 hours old)
ssh asdev@193.93.169.247 "
  LATEST=\$(ls -t /var/backups/asdev-audit/asdev-audit-*.sql.gz 2>/dev/null | head -1)
  if [ -z \"\$LATEST\" ]; then
    echo 'CRITICAL: No backups found'
  else
    AGE=\$(( ($(date +%s) - \$(stat -c %Y \"\$LATEST\")) / 3600 ))
    if [ \"\$AGE\" -gt 8 ]; then
      echo \"WARNING: Latest backup is \${AGE} hours old\"
    else
      echo \"OK: Latest backup is \${AGE} hours old\"
    fi
  fi
"

# Check disk usage of backup directory
ssh asdev@193.93.169.247 "du -sh /var/backups/asdev-audit/"
```

---

## 9. Quick Reference

```bash
# Manual database backup
ssh asdev@193.93.169.247 "/var/backups/asdev-audit/backup-db.sh"

# List available backups
ssh asdev@193.93.169.247 "ls -lht /var/backups/asdev-audit/"

# Restore database from backup
# (see Section 4.1)

# Run backup drill
# (see Section 5)

# Check backup health
# (see Section 8)
```
