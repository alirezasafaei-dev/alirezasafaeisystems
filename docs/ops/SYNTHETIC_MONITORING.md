# Synthetic Monitoring — ASDEV Audit Platform

## Overview

Synthetic monitoring provides continuous visibility into ASDEV Audit availability, response time, error rates, and SSL health. All checks run from the workspace automation layer with Telegram alerting on failure.

**Target URL:** https://audit.alirezasafaeisystems.ir/
**VPS:** 193.93.169.247 (Nginx → PM2 port 3010)

---

## 1. What to Monitor

| Check | Metric | Source |
|---|---|---|
| Uptime | HTTP status code (expect 200) | `monitor-platform.sh`, `live-healthcheck.sh` |
| Response time | `time_total` from curl | `monitor-platform.sh` |
| API readiness | `/api/ready` returns 200 | `monitor-platform.sh` |
| API health | `/api/health` returns 200 | `monitor-platform.sh` |
| SSL certificate expiry | Days until expiration | `monitor-platform.sh`, `health-check.sh` |
| PM2 process status | `web` and `worker` running | `deploy/auditsystems/health-check.sh` |
| Disk usage | Percentage of root filesystem | `deploy/auditsystems/health-check.sh` |
| Memory usage | Percentage of RAM | `deploy/auditsystems/health-check.sh` |
| Error rate | 5xx responses per second | `ops/monitoring/alert-rules.yml` (Prometheus) |
| API latency p95 | Histogram quantile | `ops/monitoring/alert-rules.yml` (Prometheus) |

---

## 2. How to Monitor

### 2.1 Platform Monitor (Primary)

```bash
# Check all 3 sites + SSL + VPS
./scripts/monitor-platform.sh

# With Telegram alert on failure
./scripts/monitor-platform.sh --notify

# JSON output for programmatic use
./scripts/monitor-platform.sh --json
```

**What it checks:**
- `audit.alirezasafaeisystems.ir` — HTTP 200 + response time
- `alirezasafaeisystems.ir` — HTTP 200 + response time
- `persiantoolbox.ir` — HTTP 200 + response time
- `/api/ready` and `/api/health` endpoints
- SSL certificate expiry for all 3 domains
- VPS status via SSH

### 2.2 Live Healthcheck (Quick)

```bash
# Lightweight check — 3 URLs only
./scripts/live-healthcheck.sh
```

### 2.3 AuditSystems Health Check (VPS-Side)

```bash
# Deep check — PM2, HTTP, API, disk, memory, SSL
./deploy/auditsystems/health-check.sh
```

### 2.4 Prometheus + Alertmanager (Advanced)

Configured in `sites/live/auditsystems/ops/monitoring/`:

- `prometheus.yml` — scrapes `/api/metrics` every 15s from localhost:3000
- `alert-rules.yml` — fires on:
  - **HighApi5xxRate**: 5xx rate > 1 req/s for 10m → `critical`
  - **ElevatedApiLatencyP95**: p95 > 1500ms for 10m → `warning`
  - **ZeroTraffic**: no traffic for 30m → `warning`

---

## 3. Check Intervals

| Check | Interval | Cron Expression | Script |
|---|---|---|---|
| Uptime (all sites) | Every 5 minutes | `*/5 * * * *` | `monitor-platform.sh --notify` |
| API readiness | Every 5 minutes | `*/5 * * * *` | `monitor-platform.sh --notify` |
| SSL certificate expiry | Hourly | `0 * * * *` | `health-check.sh` |
| Full health check | Daily at 06:00 | `0 6 * * *` | `deploy/auditsystems/health-check.sh` |
| Backup verification | Daily at 07:00 | `0 7 * * *` | (see BACKUP_RESTORE_DRILL.md) |
| Daily status report | Daily at 08:00 | `0 8 * * *` | `automation-master.sh report` |
| Prometheus scrape | Every 15s | (daemon) | Prometheus |

### Hermes Cron Setup

```bash
# Register all cron jobs
./scripts/setup-hermes-cron.sh

# Preview without activating
./scripts/setup-hermes-cron.sh --dry-run

# Disable all cron jobs
./scripts/setup-hermes-cron.sh --disable

# List active jobs
hermes cron list

# Trigger a job manually
hermes cron run asdev-platform-monitor
```

### System Cron (on VPS)

```bash
# Install VPS-side cron jobs
bash sites/live/auditsystems/scripts/setup-cron.sh
```

---

## 4. Alert Thresholds

| Metric | Warning | Critical | Action |
|---|---|---|---|
| HTTP status code | != 200 | 000 (timeout) | Restart PM2, check Nginx |
| Response time | > 3s | > 5s | Check DB, worker queue, memory |
| API 5xx rate | > 0.5 req/s | > 1 req/s for 10m | Investigate logs, rollback if needed |
| API p95 latency | > 1000ms | > 1500ms for 10m | Check DB queries, cache |
| SSL expiry | < 30 days | < 7 days | Run `certbot renew` |
| Disk usage | > 70% | > 80% | Clean logs, old releases |
| Memory usage | > 70% | > 80% | Check for leaks, restart |
| Zero traffic | — | > 30 min | Verify ingestion, app health |
| PM2 restarts | > 5/hour | > 10/hour | Check error logs, root cause |

---

## 5. Telegram Notification Setup

Alerts are sent via Telegram when `--notify` flag is used with `monitor-platform.sh`.

### Required Environment Variables

Set in workspace `.env` (never commit):

```bash
TELEGRAM_BOT_TOKEN="your-bot-token"
TELEGRAM_CHAT_ID="your-chat-id"
```

### How It Works

1. `monitor-platform.sh --notify` runs all health checks
2. If `FAILURES > 0`, sends alert to Telegram
3. Alert message format: `⚠️ ASDEV Platform Alert: {N} failures detected at {timestamp}`
4. Uses `curl` to POST to `https://api.telegram.org/bot{token}/sendMessage`

### Setup Steps

1. Create a Telegram bot via [@BotFather](https://tbot.me/BotFather)
2. Get the bot token
3. Add the bot to your monitoring channel/group
4. Get the chat ID (send a message, then `curl https://api.telegram.org/bot{token}/getUpdates`)
5. Add to `.env`:
   ```bash
   TELEGRAM_BOT_TOKEN="..."
   TELEGRAM_CHAT_ID="..."
   ```

### Manual Alert Test

```bash
# Add to .env, then:
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  -d text="✅ Test alert from ASDEV monitoring"
```

---

## 6. Uptime Logging

Every `monitor-platform.sh` run appends to a daily log file:

```
ops/uptime/YYYY-MM-DD.log
```

Format: `{ISO timestamp} audit={status} brand={status} toolbox={status} failures={count}`

### Query Uptime

```bash
# Today's uptime log
cat ops/uptime/$(date -u +%Y-%m-%d).log

# Count failures in the last 7 days
for f in ops/uptime/$(date -u -d '7 days ago' +%Y-%m-%d).log ops/uptime/*.log; do
  grep "failures=[1-9]" "$f" 2>/dev/null
done
```

---

## 7. Monitoring Commands Quick Reference

```bash
# Quick status
./scripts/live-healthcheck.sh

# Full platform check
./scripts/monitor-platform.sh

# Full check with Telegram alert
./scripts/monitor-platform.sh --notify

# VPS deep health check
./deploy/auditsystems/health-check.sh

# VPS status
./scripts/server-status.sh

# PM2 status (on VPS)
ssh asdev@193.93.169.247 "pm2 list"

# Automation full pipeline
./scripts/automation-master.sh full
```
