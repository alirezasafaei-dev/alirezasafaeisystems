# Uptime Evidence — ASDEV Audit Platform

## 1. Current Status

**Last checked:** Run `./scripts/live-healthcheck.sh` for real-time status

**Target URL:** https://audit.alirezasafaeisystems.ir/
**API endpoint:** https://audit.alirezasafaeisystems.ir/api/ready
**Health endpoint:** https://audit.alirezasafaeisystems.ir/api/health

### Quick Status Check

```bash
# From workspace
./scripts/live-healthcheck.sh

# Full platform check
./scripts/monitor-platform.sh

# VPS deep check
./deploy/auditsystems/health-check.sh
```

---

## 2. SLA Targets

| Metric | Target | Measurement |
|---|---|---|
| Monthly uptime | ≥ 99.5% | HTTP 200 on /api/ready |
| Response time (p50) | < 2s | curl time_total |
| Response time (p95) | < 5s | curl time_total |
| Response time (p99) | < 10s | curl time_total |
| Error rate (5xx) | < 1% | 5xx responses / total requests |
| SSL validity | Always valid | Let's Encrypt auto-renewal |
| Backup freshness | < 6 hours | pg_dump timestamp |

### SLA Calculation

```
Uptime % = (Total minutes - Downtime minutes) / Total minutes × 100

Monthly target: 99.5%
Allowed downtime: ~3.6 hours/month (~216 minutes)
Allowed downtime/day: ~7.2 minutes
```

---

## 3. Historical Uptime Data

### Uptime Log Location

```
ops/uptime/YYYY-MM-DD.log
```

### Query Uptime Records

```bash
# List all uptime log files
ls -la ops/uptime/

# View today's log
cat ops/uptime/$(date -u +%Y-%m-%d).log

# Count failures in the last 30 days
for f in ops/uptime/*.log; do
  grep -c "failures=[1-9]" "$f" 2>/dev/null && echo "  -> $f"
done

# Calculate approximate uptime percentage
TOTAL=$(cat ops/uptime/*.log 2>/dev/null | wc -l)
FAILURES=$(grep -c "failures=[1-9]" ops/uptime/*.log 2>/dev/null || echo 0)
echo "Checks: $TOTAL, Failures: $FAILURES"
if [ "$TOTAL" -gt 0 ]; then
  UPTIME=$(echo "scale=2; ($TOTAL - $FAILURES) / $TOTAL * 100" | bc)
  echo "Approximate uptime: ${UPTIME}%"
fi
```

### Sample Uptime Log Entries

```
2026-07-07T13:00:21Z audit=? brand=? toolbox=? failures=1
2026-07-06T12:00:15Z audit=200 brand=200 toolbox=200 failures=0
```

Format: `{timestamp} audit={status} brand={status} toolbox={status} failures={count}`

---

## 4. Monitoring Setup

### Active Monitoring Stack

| Component | Tool | Interval | Location |
|---|---|---|---|
| Uptime check | `monitor-platform.sh` | Every 5 min | Hermes cron |
| SSL check | `monitor-platform.sh` | Every 5 min | Hermes cron |
| API health | `monitor-platform.sh` | Every 5 min | Hermes cron |
| Full health check | `health-check.sh` | Daily 06:00 | System cron |
| Prometheus scrape | Prometheus daemon | Every 15s | VPS |
| Alert rules | Alertmanager | On threshold | VPS |

### Prometheus Metrics

Configured in `sites/live/auditsystems/ops/monitoring/`:

**Scrape config** (`prometheus.yml`):
- Target: `localhost:3000`
- Path: `/api/metrics`
- Interval: 15s

**Alert rules** (`alert-rules.yml`):
- `HighApi5xxRate`: 5xx > 1 req/s for 10m → critical
- `ElevatedApiLatencyP95`: p95 > 1500ms for 10m → warning
- `ZeroTraffic`: no traffic for 30m → warning

### Telegram Alerts

Configured via `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` environment variables.

```bash
# Test alert
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  -d text="✅ Uptime test from ASDEV monitoring"
```

---

## 5. How to Verify Uptime

### Manual Verification

```bash
# 1. Check HTTP status
curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/
# Expected: 200

# 2. Check API readiness
curl -s -o /dev/null -w "%{http_code}" https://audit.alirezasafaeisystems.ir/api/ready
# Expected: 200

# 3. Check response time
curl -s -o /dev/null -w "time_total: %{time_total}s\n" https://audit.alirezasafaeisystems.ir/
# Expected: < 5s

# 4. Check SSL certificate
echo | openssl s_client -servername audit.alirezasafaeisystems.ir \
  -connect audit.alirezasafaeisisms.ir:443 2>/dev/null | \
  openssl x509 -noout -dates
# Expected: notAfter date in the future

# 5. Check PM2 processes (on VPS)
ssh asdev@193.93.169.247 "pm2 list"
# Expected: both web and worker in "online" status
```

### Automated Verification

```bash
# Run all checks
./scripts/monitor-platform.sh

# Check with Telegram alert
./scripts/monitor-platform.sh --notify

# Full pipeline
./scripts/automation-master.sh full
```

### External Verification

- **UptimeRobot** (free): Add https://audit.alirezasafaeisystems.ir/api/ready as monitor
- **Freshping** (free): Add HTTP check for the same URL
- **Browser test**: Open https://audit.alirezasafaeisystems.ir/ in browser

---

## 6. Uptime Reporting

### Generate Uptime Report

```bash
# Count checks and failures
echo "=== Uptime Report ==="
echo "Period: Last 30 days"
echo ""

TOTAL_CHECKS=0
TOTAL_FAILURES=0

for f in ops/uptime/*.log; do
  if [ -f "$f" ]; then
    DAY_CHECKS=$(wc -l < "$f")
    DAY_FAILURES=$(grep -c "failures=[1-9]" "$f" 2>/dev/null || echo 0)
    TOTAL_CHECKS=$((TOTAL_CHECKS + DAY_CHECKS))
    TOTAL_FAILURES=$((TOTAL_FAILURES + DAY_FAILURES))
  fi
done

echo "Total checks: $TOTAL_CHECKS"
echo "Total failures: $TOTAL_FAILURES"
if [ "$TOTAL_CHECKS" -gt 0 ]; then
  UPTIME=$(echo "scale=2; ($TOTAL_CHECKS - $TOTAL_FAILURES) / $TOTAL_CHECKS * 100" | bc)
  echo "Uptime: ${UPTIME}%"
  echo "Downtime incidents: $TOTAL_FAILURES"
fi
```

### Export for Stakeholders

```bash
# CSV format
echo "date,audit_status,brand_status,toolbox_status,failures"
cat ops/uptime/*.log | sed 's/.*\(20[0-9-]*\).* audit=\([^ ]*\).* brand=\([^ ]*\).* toolbox=\([^ ]*\).* failures=\([0-9]*\)/\1,\2,\3,\4,\5/'
```

---

## 7. Uptime Guarantee Evidence

For customer-facing SLA claims, collect:

1. **Uptime logs**: `ops/uptime/*.log`
2. **Monitoring screenshots**: From external uptime monitor (UptimeRobot, etc.)
3. **Response time data**: From `monitor-platform.sh` output
4. **SSL validity**: Certificate expiry dates
5. **Backup logs**: From `ops/backups/backup.log`

### SLA Compliance Checklist

- [ ] Uptime logs present for the reporting period
- [ ] External monitoring active (UptimeRobot or equivalent)
- [ ] Response time within SLA targets
- [ ] SSL certificate valid
- [ ] Backups within freshness target
- [ ] No P0 incidents unresolved
- [ ] All P1 incidents resolved within SLA

---

## 8. Quick Commands

```bash
# Real-time status
./scripts/live-healthcheck.sh

# Full check with alerts
./scripts/monitor-platform.sh --notify

# View uptime logs
cat ops/uptime/$(date -u +%Y-%m-%d).log

# Check SSL
echo | openssl s_client -servername audit.alirezasafaeisystems.ir \
  -connect audit.alirezasafaeisystems.ir:443 2>/dev/null | \
  openssl x509 -noout -enddate

# Check PM2
ssh asdev@193.93.169.247 "pm2 list"

# Generate report
./scripts/automation-master.sh report
```
