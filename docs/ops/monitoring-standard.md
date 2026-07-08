# Monitoring Standard — ASDEV Platform

**Version:** 1.0  
**Last Updated:** 2026-07-08  
**Status:** Foundation + post-production app-layer probes  
**Tools policy:** Prefer free/open source (bash, curl, systemd/cron, local logs). Avoid SaaS unless owner opts in.

---

## Principles

1. **Read-only by default** — monitors never deploy, reload nginx, or write production state.  
2. **Aliases only in reports** — `IRAN_PROD`, `OWNER_PC`, `AUTOMATION_HOST`, `CRITICAL_SITE`.  
3. **App layer vs public edge** — until public edge is approved, primary production probe is loopback `:3100`.  
4. **Fail loud, act gated** — alert → human/agent diagnose → mutation only with phrase.  
5. **Live timers gated** — install cron/systemd with `APPROVE_MONITORING_LIVE_TIMERS` only.

---

## Check matrix

| Check | Script | What good looks like |
|-------|--------|----------------------|
| App-layer health (prod) | `scripts/monitoring/check-prod-app-layer.sh` | ready+health 200 on `127.0.0.1:3100` |
| Deploy status | `scripts/monitoring/check-deploy-status.sh` | current release + meta + pid alive |
| Public HTTP (edge) | `scripts/monitoring/check-critical-site-http.sh` | public root/ready/health 2xx (only after edge) |
| Automation host | `scripts/monitoring/check-automation-host-readiness.sh` | tools + disk + repo |
| Disk | `scripts/monitoring/check-disk-local.sh` | used% < 80 warn / < 90 crit |
| Backup freshness | `scripts/monitoring/check-backup-freshness.sh` | newest artifact ≤ 36h when root set |

Related runbook: `docs/ops/monitoring-runbook.md`  
Alerting: `docs/ops/alerting-policy.md`

---

## Thresholds

| Signal | Warning | Critical |
|--------|---------|----------|
| Disk used% | ≥ 80% | ≥ 90% |
| Backup age | — | > 36h (if ASDEV_BACKUP_ROOT set) |
| App ready/health | latency > 2s | non-2xx or connection fail |
| Deploy pid | — | pid file missing or process dead |
| Public edge HTTP | single non-2xx | sustained non-2xx |

---

## Recommended schedule (after APPROVE_MONITORING_LIVE_TIMERS)

| Interval | Checks |
|----------|--------|
| every 1–2 min | prod app-layer health (on IRAN_PROD) |
| every 5 min | deploy status |
| every 15 min | disk + automation host readiness |
| every 1 h | backup freshness |
| every 5 min | public HTTP (only after public edge live) |

Example timer units live under `ops/systemd/` — install only with approval.

---

## Deploy status contract

A release is **DEPLOY_OK** when all are true:

1. `current` symlink resolves under `releases/`  
2. `release.meta` present with matching `environment`  
3. runtime pid file exists and process alive  
4. health endpoints 2xx on env port  

Otherwise **DEPLOY_FAIL** → page on-call path in `docs/ops/INCIDENT_RUNBOOK.md`.

---

## What not to monitor (yet)

- Paid APM SaaS  
- Synthetic multi-region unless free/self-hosted  
- Scraping secrets or env files into alert payloads  

---

## Post public-edge switch

When `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` completes:

1. Keep app-layer probe on :3100 (local truth)  
2. Add public probe as external truth  
3. Alert if public fails but local passes → edge/nginx/DNS class  
4. Alert if both fail → app or host class  
