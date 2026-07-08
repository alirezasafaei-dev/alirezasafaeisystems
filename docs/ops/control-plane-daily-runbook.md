# Control Plane Daily Runbook — AUTOMATION_HOST

**Audience:** operators / agents  
**Host:** AUTOMATION_HOST (`/home/dev13/ASDEV`)  
**SoT:** GitHub `main`

---

## Morning checklist (≤10 min)

```bash
cd /home/dev13/ASDEV
git pull --ff-only origin main

# 1) Host self-health
bash scripts/ops/automation-health-check.sh

# 2) Task queue
bash scripts/control-plane/queue-list.sh

# 3) Optional one loop iteration (does not run gated prod)
bash scripts/control-plane/loop-once.sh
```

## CRITICAL_SITE app-layer (IRAN, read-only)

```bash
# Requires private env + SSH key (never commit)
export ASDEV_VPS_ENV_FILE=/path/to/private.env
bash scripts/ops/asdev-remote-status.sh

# Or on IRAN_PROD directly:
bash /home/asdev/asdev-platform/scripts/monitoring/check-prod-app-layer.sh
bash /home/asdev/asdev-platform/scripts/monitoring/check-deploy-status.sh
bash /home/asdev/asdev-platform/scripts/monitoring/check-prod-stability-sample.sh
ASDEV_BACKUP_ROOT=/srv/asdev/backups/persiantoolbox \
  bash /home/asdev/asdev-platform/scripts/monitoring/check-backup-freshness.sh
```

Expect: ready/health **200**, `DEPLOY_OK`, backup **FRESH** (if cron healthy).

## After completing work

1. Update `docs/automation/AGENT_MEMORY.md` if decisions/blockers changed  
2. `queue-complete` / `queue-add` as needed  
3. `queue-archive-done.sh` weekly  
4. Batch commit + **one PR** (not micro-PRs)  
5. Never put secrets in reports  

## Hard stops (do not free-run)

| Phrase | Action |
|--------|--------|
| `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` | nginx / SSL / DNS |
| `APPROVE_MONITORING_LIVE_TIMERS` | install probe timers |
| `APPROVE_CRITICAL_SITE_MIGRATION` | DB migrations |
| `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` | production redeploy |
| `APPROVE_PHASE_2_STAGING_DEPLOY` | staging redeploy |
| `APPROVE_CRITICAL_SITE_STAGING_REBIND` | optional 3000→3200 |

## Do not

- Scatter micro-tasks  
- `docker rm` / `pm2 delete` without approval  
- Change IRAN meta-backup cron casually  
- Treat OWNER_PC desktop noise as production outage  

## Related

- `docs/architecture/automation-control-plane.md`  
- `docs/automation/AGENT_REGISTRY.md`  
- `docs/automation/TASK_QUEUE_SYSTEM.md`  
- `control-plane/queue/queue.json`  
