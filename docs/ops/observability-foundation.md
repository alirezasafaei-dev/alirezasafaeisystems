# Observability Foundation — ASDEV

**Status:** Foundation only — **no** `APPROVE_MONITORING_LIVE_TIMERS` install  
**Last Updated:** 2026-07-08

---

## Layers

| Layer | Source | Status |
|-------|--------|--------|
| App health | `/api/ready`, `/api/health` | LIVE on IRAN :3100 |
| Deploy status | `check-deploy-status.sh` | ready |
| Stability sample | `check-prod-stability-sample.sh` | ready |
| Host health | `automation-health-check.sh` | ready |
| Backup freshness | `check-backup-freshness.sh` / report script | ready |
| Public HTTP | `check-critical-site-http.sh` | meaningful after edge |
| Metrics export | planned Prometheus textfile or JSON | **prep only** |
| Dashboards | docs spec below | **prep only** |
| Live timers | cron/systemd probes | **GATED** |

---

## Metrics (to collect later)

```
asdev_app_up{site,env} 1/0
asdev_app_ready_latency_ms
asdev_deploy_info{release,commit}
asdev_backup_age_hours
asdev_host_disk_used_ratio
asdev_queue_pending
asdev_queue_stale_in_progress
```

Export path proposal (not installed):  
`control-plane/health/metrics.prom` written by a future timer.

---

## Logs

| Log | Location |
|-----|----------|
| App runtime | IRAN `asdev-runtime.log` |
| Meta backup | IRAN `~/logs/asdev-meta-backup.log` |
| Control plane loop | `control-plane/logs/` (gitignored) |
| Agent session | interactive / Hermes |

---

## Alerts (policy only)

See `docs/ops/alerting-policy.md`. Do not page on desktop Chrome CPU.

Classes:

1. App ready fail on IRAN loopback  
2. Deploy pid dead  
3. Backup stale > 36h  
4. Disk > 90%  

---

## Dashboard sketch

1. CRITICAL_SITE app-layer green/red  
2. Last deploy release id  
3. Backup age  
4. AUTOMATION_HOST classification  
5. Queue pending gated vs runnable  

No SaaS required for foundation.
