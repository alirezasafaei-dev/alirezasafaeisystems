# Incident Runbook — ASDEV Audit Platform

## Overview

This runbook defines incident severity levels, response procedures, escalation paths, and communication templates for the ASDEV Audit platform.

**Primary target:** https://audit.alirezasafaeisystems.ir/
**VPS:** 193.93.169.247
**PM2 processes:** `asdev-audit-ir-production-web`, `asdev-audit-ir-production-worker`
**Database:** PostgreSQL on 127.0.0.1:5432

---

## 1. Severity Levels

| Level | Name | Impact | Response Time | Example |
|---|---|---|---|---|
| **P0** | Critical | Site down, data loss, security breach | Immediate (< 15 min) | Complete outage, database corruption, unauthorized access |
| **P1** | High | Major feature broken, significant degradation | < 1 hour | Audit submission failing, payment errors, API 5xx spike |
| **P2** | Medium | Minor feature broken, performance degraded | < 4 hours | Slow response times, non-critical API errors, UI bugs |
| **P3** | Low | Cosmetic, no user impact | < 24 hours | Typos, minor UI issues, documentation gaps |

---

## 2. Immediate Response (All Levels)

### Step 1: Confirm the Incident

```bash
# Quick health check
./scripts/live-healthcheck.sh

# Full platform check
./scripts/monitor-platform.sh

# VPS deep check
./deploy/auditsystems/health-check.sh
```

### Step 2: Check PM2 Status

```bash
ssh asdev@193.93.169.247 "pm2 list"
ssh asdev@193.93.169.247 "pm2 logs asdev-audit-ir-production-web --lines 50"
ssh asdev@193.93.169.247 "pm2 logs asdev-audit-ir-production-worker --lines 50"
```

### Step 3: Check Nginx

```bash
ssh asdev@193.93.169.247 "sudo nginx -t"
ssh asdev@193.93.169.247 "sudo tail -20 /var/log/nginx/error.log"
```

### Step 4: Check Database

```bash
ssh asdev@193.93.169.247 "sudo systemctl status postgresql"
ssh asdev@193.93.169.247 "psql -h 127.0.0.1 -U postgres -c 'SELECT 1;'"
```

### Step 5: Check Disk and Memory

```bash
ssh asdev@193.93.169.247 "df -h /"
ssh asdev@193.93.169.247 "free -h"
```

---

## 3. P0 — Critical Incident Response

**Trigger:** Site completely down, data loss detected, security breach confirmed.

### Response Procedure

1. **Confirm outage** (2 min)
   ```bash
   curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/
   curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/api/ready
   ```

2. **Attempt quick restart** (3 min)
   ```bash
   ssh asdev@193.93.169.247 "pm2 restart asdev-audit-ir-production-web asdev-audit-ir-production-worker"
   sleep 10
   curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/api/ready
   ```

3. **If restart fails — check logs** (5 min)
   ```bash
   ssh asdev@193.93.169.247 "pm2 logs --lines 100"
   ssh asdev@193.93.169.247 "sudo tail -50 /var/log/nginx/error.log"
   ```

4. **If code issue — rollback** (5 min)
   ```bash
   ./deploy/auditsystems/rollback.sh production
   ```

5. **If infrastructure issue** (10 min)
   - Nginx down: `ssh asdev@193.93.169.247 "sudo systemctl restart nginx"`
   - Database down: `ssh asdev@193.93.169.247 "sudo systemctl restart postgresql"`
   - Disk full: clean logs, old releases, temp files
   - Memory: check for leaks, restart PM2

6. **If data loss suspected** (immediate)
   - Stop all write operations
   - Identify last known good backup
   - Restore from backup (see BACKUP_RESTORE_DRILL.md §4.1)
   - Do NOT overwrite existing data without confirmation

7. **If security breach** (immediate)
   - Rotate all secrets (database password, API keys, session secrets)
   - Check for unauthorized changes: `ssh asdev@193.93.169.247 "git -C /var/www/asdev-audit-ir/current/production status"`
   - Review access logs
   - Block suspicious IPs at firewall level

### Escalation (P0)

- **0-15 min:** On-call engineer attempts resolution
- **15-30 min:** Escalate to system admin
- **30+ min:** Full team alert, consider external help

---

## 4. P1 — High Incident Response

**Trigger:** Major feature broken, significant performance degradation, payment errors.

### Response Procedure

1. **Confirm scope** (5 min)
   ```bash
   # Test specific feature
   curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/api/ready
   curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/api/health
   ```

2. **Check error rate** (5 min)
   ```bash
   # Look for 5xx in recent logs
   ssh asdev@193.93.169.247 "pm2 logs asdev-audit-ir-production-web --lines 200 | grep -i error"
   ```

3. **Attempt fix** (15 min)
   - If isolated to one endpoint: check specific code path
   - If performance: check DB queries, worker queue, memory
   - If payment: check Zarinpal API status, webhook logs

4. **If not fixable in 15 min — escalate** (see Escalation)

### Escalation (P1)

- **0-15 min:** On-call engineer
- **15-30 min:** System admin + product owner notified
- **30+ min:** Treat as P0

---

## 5. P2 — Medium Incident Response

**Trigger:** Minor feature broken, performance degraded, non-critical errors.

### Response Procedure

1. **Document the issue** — note symptoms, affected users, timeline
2. **Check if it's reproducible** — test from multiple angles
3. **Fix or schedule** — fix if < 30 min, otherwise schedule for next sprint
4. **Monitor** — watch for escalation to P1

---

## 6. P3 — Low Incident Response

**Trigger:** Cosmetic issues, documentation gaps, no user impact.

### Response Procedure

1. **Log in backlog** — create issue or add to `docs/FROZEN_BACKLOG.md`
2. **Fix when convenient** — no urgency
3. **No escalation needed**

---

## 7. Escalation Paths

```
P0: On-call → System Admin → Full Team → External Support
P1: On-call → System Admin → (escalate to P0 if unresolved)
P2: On-call → Schedule fix
P3: Backlog → Fix when convenient
```

### Contact Matrix

| Role | When to Contact |
|---|---|
| On-call Engineer | First responder for all incidents |
| System Admin | Infrastructure issues, server access, database |
| Product Owner | User-facing impact, business decisions |
| External Support | VPS provider, domain registrar, payment provider |

---

## 8. Communication Templates

### Initial Alert (Internal)

```
🚨 INCIDENT ALERT
Severity: P{0-3}
Status: Investigating
Affected: ASDEV Audit Platform (audit.alirezasafaeisystems.ir)
Symptoms: [description]
Timeline: Started at HH:MM UTC
Next update: HH:MM UTC
```

### Resolution Update (Internal)

```
✅ INCIDENT RESOLVED
Severity: P{0-3}
Duration: X minutes
Root cause: [brief description]
Resolution: [what was done]
Impact: [affected users/features]
Follow-up: [action items]
```

### User-Facing Message (if needed)

```
We're currently experiencing issues with [feature]. Our team is working on a fix.
We expect to resolve this within [timeframe]. We'll update you shortly.

Status: [investigating/fixing/monitoring]
```

---

## 9. Common Incidents and Fixes

### Site Down (P0)

| Symptom | Likely Cause | Fix |
|---|---|---|
| HTTP 502/503 | PM2 process crashed | `pm2 restart all` |
| HTTP 502 | Nginx can't reach backend | Check PM2 port, restart PM2 |
| HTTP 500 | Application error | Check PM2 logs, fix code |
| Connection refused | Nginx down | `sudo systemctl restart nginx` |
| Timeout | Database down | `sudo systemctl restart postgresql` |

### Audit Submission Failing (P1)

| Symptom | Likely Cause | Fix |
|---|---|---|
| 500 on POST /api/audit | Worker crash or DB error | Check worker logs, DB connection |
| Timeout on submission | Worker overloaded | Check worker queue, restart |
| Payment webhook fails | Zarinpal API issue | Check external status, retry logic |

### Performance Degradation (P1-P2)

| Symptom | Likely Cause | Fix |
|---|---|---|
| Slow page loads | DB query performance | Add indexes, optimize queries |
| High memory usage | Memory leak | Restart PM2, check for leaks |
| Disk filling up | Log accumulation | Clean old logs, set logrotate |
| High CPU | Infinite loop or heavy computation | Check worker processes |

### Database Issues (P0-P1)

| Symptom | Likely Cause | Fix |
|---|---|---|
| Connection refused | PostgreSQL down | `sudo systemctl restart postgresql` |
| Too many connections | Connection pool exhaustion | Restart app, check pool settings |
| Slow queries | Missing indexes | Analyze with `EXPLAIN`, add indexes |
| Corruption | Disk failure or crash | Restore from backup |

### SSL Certificate Issues (P1)

| Symptom | Likely Cause | Fix |
|---|---|---|
| Certificate expired | Certbot auto-renewal failed | `sudo certbot renew` |
| Certificate warning | Domain mismatch | Check certbot config |
| Mixed content | HTTP resources on HTTPS page | Fix resource URLs |

---

## 10. Post-Incident Review

After any P0 or P1 incident, conduct a review within 48 hours.

### Review Template

```markdown
# Post-Incident Review — [Date]

## Incident Summary
- **Severity:** P{0-3}
- **Duration:** X minutes/hours
- **Impact:** [description]
- **Users affected:** [estimate]

## Timeline
- HH:MM — Incident detected
- HH:MM — Investigation started
- HH:MM — Root cause identified
- HH:MM — Fix deployed
- HH:MM — Monitoring confirmed resolution

## Root Cause
[Technical explanation of what went wrong]

## What Went Well
- [list positive aspects of response]

## What Could Be Improved
- [list areas for improvement]

## Action Items
| Action | Owner | Due | Status |
|---|---|---|---|
| [action] | [person] | [date] | [status] |

## Prevention
[What changes will prevent this from happening again]
```

### Store Reviews

Save completed reviews in `ops/reports/incident-YYYY-MM-DD.md`.

---

## 11. Monitoring During Incidents

During an active incident, increase monitoring frequency:

```bash
# Watch mode — check every 30 seconds
while true; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/api/ready)
  echo "[$(date -u +%H:%M:%S)] Status: $STATUS"
  if [ "$STATUS" = "200" ]; then
    echo "Service recovered"
    break
  fi
  sleep 30
done
```

---

## 12. Quick Reference

```bash
# Emergency restart
ssh asdev@193.93.169.247 "pm2 restart all"

# Check everything
./scripts/monitor-platform.sh

# Rollback
./deploy/auditsystems/rollback.sh production

# Database backup (before risky operations)
ssh asdev@193.93.169.247 "/var/backups/asdev-audit/backup-db.sh"

# View recent logs
ssh asdev@193.93.169.247 "pm2 logs --lines 100"
```
