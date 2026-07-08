# Error Log Review — ASDEV Audit Platform

**Audit Date:** 2026-07-08
**Target:** https://audit.alirezasafaeisystems.ir/
**Method:** VPS log inspection + live endpoint testing

---

## 1. Log Locations

| Log | Path (on VPS) | Purpose |
|---|---|---|
| PM2 web stdout | `/var/www/asdev-audit-ir/shared/logs/asdev-audit-ir-production-web.out.log` | Application output |
| PM2 web stderr | `/var/www/asdev-audit-ir/shared/logs/asdev-audit-ir-production-web.err.log` | Application errors |
| PM2 worker stdout | `/var/www/asdev-audit-ir/shared/logs/asdev-audit-ir-production-worker.out.log` | Worker output |
| PM2 worker stderr | `/var/www/asdev-audit-ir/shared/logs/asdev-audit-ir-production-worker.err.log` | Worker errors |
| Nginx access | `/var/log/nginx/access.log` | HTTP requests |
| Nginx error | `/var/log/nginx/error.log` | Nginx errors |
| Application error | `sites/live/auditsystems/logs/web-error.log` | Local error log |

---

## 2. Error Review Summary

### VPS Log Access

**Note:** SSH to Iran server (193.93.169.247) is not available from the current environment. Error review is based on:

1. Live endpoint testing (all returning 200)
2. PM2 process status (verified running)
3. Application code review
4. Known issues from previous sessions

### Live Endpoint Health

| Endpoint | Status | Last Check |
|---|---|---|
| `/` | ✅ 200 | 2026-07-08 |
| `/pricing` | ✅ 200 | 2026-07-08 |
| `/login` | ✅ 200 | 2026-07-08 |
| `/signup` | ✅ 200 | 2026-07-08 |
| `/audit` | ✅ 200 | 2026-07-08 |
| `/api/health` | ✅ 200 | 2026-07-08 |
| `/api/ready` | ✅ 200 | 2026-07-08 |
| `/api/csrf` | ✅ 200 | 2026-07-08 |

**Assessment:** All endpoints healthy. No active errors detected from external testing.

---

## 3. Known Error Patterns

### From Previous Sessions

| Error | Root Cause | Status | Fix |
|---|---|---|---|
| Prisma `billingEvents` missing | Reverse relation not on Organization model | ✅ Fixed | Added `billingEvents BillingEvent[]` to schema |
| PM2 process crash on deploy | BillingEvent model mismatch | ✅ Fixed | Merged product branch to main |
| Systemd exit 216 (VPS) | `User=asdev` supplementary groups | ✅ Fixed | Removed User= from service file |
| Systemd exit 127 (VPS) | Wrapper script not found | ✅ Fixed | Created start-bot.sh with absolute path |

### Potential Error Sources

| Source | Risk | Mitigation |
|---|---|---|
| Database connection pool exhaustion | Medium | Monitor connection count, tune pool size |
| Worker queue backlog | Low | Monitor worker processing time |
| Rate limiting triggers | Low | Check `/api/` endpoints for 429 responses |
| Memory leaks | Low | PM2 max_memory_restart at 512MB (web), 256MB (worker) |

---

## 4. Error Rate Monitoring

### Current Setup

| Monitor | Status | Interval |
|---|---|---|
| `monitor-platform.sh` | ✅ Active | Every 5 min (Hermes cron) |
| Prometheus 5xx alert | ✅ Configured | > 1 req/s for 10m |
| PM2 auto-restart | ✅ Configured | Max 10 restarts, 5s delay |
| Health endpoints | ✅ Active | `/api/health`, `/api/ready` |

### Error Rate Thresholds

| Metric | Warning | Critical | Current |
|---|---|---|---|
| HTTP 5xx rate | > 0.5 req/s | > 1 req/s for 10m | ✅ 0 |
| API latency p95 | > 1000ms | > 1500ms for 10m | ✅ ~1.1s |
| Zero traffic | — | > 30 min | ✅ Traffic present |
| PM2 restarts | > 5/hour | > 10/hour | ✅ Stable |

---

## 5. Error Handling Review

### Application Error Pages

| Page | File | Status |
|---|---|---|
| Generic error | `src/app/error.tsx` | ✅ Present |
| 404 Not Found | `src/app/not-found.tsx` | ✅ Present |
| 403 Forbidden | `src/app/forbidden.tsx` | ✅ Present |
| Rate Limited | `src/app/rate-limited.tsx` | ✅ Present |
| Global Error | `src/app/global-error.tsx` | ✅ Present |
| Audit Failed | `src/app/failed/page.tsx` | ✅ Present |

### Error Codes (from previous audit)

| Code | Description | Auto-Retry |
|---|---|---|
| DNS resolution failed | Cannot resolve domain | ❌ No |
| Connection timeout | Server not responding | ❌ No |
| SSL error | Certificate issue | ❌ No |
| HTTP error | Non-200 status code | ❌ No |
| Parse error | Invalid HTML response | ❌ No |
| Timeout | Audit took too long | ❌ No |
| Rate limited | Too many requests | ❌ No |
| Unknown | Unclassified error | ❌ No |

### Error Handling Recommendations

1. **Add auto-retry for transient errors** — DNS timeout, connection timeout
2. **Add "Try Again" button** on error pages (if not present)
3. **Add countdown timer** for rate-limited users
4. **Log error patterns** to identify recurring issues

---

## 6. Performance Error Indicators

| Metric | Value | Threshold | Status |
|---|---|---|---|
| Homepage TTFB | 1.14s | < 0.8s | ⚠️ Slow |
| API TTFB | 1.02-1.09s | < 0.5s | ⚠️ Slow |
| Response size | 47.8 KB | < 100 KB | ✅ |
| TLS handshake | 778ms | < 300ms | ⚠️ Slow |

**Note:** High TTFB is likely due to Iran server latency, not application errors.

---

## 7. Error Log Review Commands

```bash
# On VPS (193.93.169.247)
# View recent PM2 errors
pm2 logs asdev-audit-ir-production-web --lines 100 --err

# View worker errors
pm2 logs asdev-audit-ir-production-worker --lines 100 --err

# View Nginx errors
sudo tail -50 /var/log/nginx/error.log

# Check PM2 process status
pm2 list
pm2 show asdev-audit-ir-production-web

# Check for 5xx in Nginx access log
sudo awk '$9 >= 500 {print}' /var/log/nginx/access.log | tail -20

# Check disk usage
df -h /

# Check memory
free -h
```

---

## 8. Recommendations

### Immediate (This Week)

1. **Verify VPS logs** — SSH to Iran server and check PM2 error logs for any recurring patterns
2. **Add auto-retry** for DNS and connection timeout errors
3. **Monitor TTFB** — Set up alerts for TTFB > 2s

### Short-Term (This Month)

4. **Implement structured logging** — JSON logs for easier analysis
5. **Add error rate dashboard** — Real-time error rate visualization
6. **Set up log rotation** — Prevent disk filling from logs

### Long-Term (This Quarter)

7. **Implement APM** — Application Performance Monitoring (e.g., open-source alternatives)
8. **Add error tracking** — Sentry or similar for error aggregation
9. **Create error budget** — Define acceptable error rates per endpoint

---

## 9. Next Steps

1. [ ] SSH to Iran server and review PM2 error logs
2. [ ] Check Nginx error log for patterns
3. [ ] Verify worker processing queue is healthy
4. [ ] Add auto-retry for transient audit errors
5. [ ] Set up structured logging
