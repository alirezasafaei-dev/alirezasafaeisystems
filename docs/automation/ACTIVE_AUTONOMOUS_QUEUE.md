# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T22:25:00Z  
**Status:** PRODUCTION_APP_LAYER_LIVE · OPS_LOOP_v1_BATCH  
**Source of Truth:** GitHub

---

## Live state

| Layer | State |
|-------|-------|
| Production app | LIVE `20260708T221124Z-fcc7192` on `127.0.0.1:3100` ready/health 200 |
| Staging | LIVE `20260708T210149Z-fcc7192` on legacy `:3000` ready 200 |
| Public edge | PREPARED (not configured) |
| Monitoring foundation | scripts + standard docs ready; timers not live |
| Backup evidence | WEAK (no IRAN backup dir yet) |

---

## Queue

### 1. ASDEV-OPS-LOOP-PR (active)
- Batch: reports, public-edge plan, monitoring, DR, agent OS, site template, roadmaps  
- **Status:** IN_PROGRESS → PR

### 2. ASDEV-BACKUP-ONSITE
- Parameterize backup/restore for `/srv/asdev/sites/persiantoolbox`  
- Restore drill report  
- **Status:** NEXT (safe, no edge)

### 3. ASDEV-PUBLIC-EDGE
- nginx → 3100, SSL, DNS, public launch  
- **Status:** PENDING — `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`

### 4. ASDEV-MONITORING-TIMERS
- Install cron/systemd for probes  
- **Status:** PENDING — `APPROVE_MONITORING_LIVE_TIMERS`

### 5. ASDEV-SECRETS-SHARED
- Owner places prod env under shared  
- **Status:** residual for full features

### 6. ASDEV-STAGING-REBIND
- `:3000` → `:3200`  
- **Status:** OPTIONAL

---

## Completed

| ID | Result |
|----|--------|
| ASDEV-STAGING-LIVE | DONE |
| ASDEV-RC-FREEZE | DONE |
| ASDEV-PROD-PREFLIGHT | DONE |
| ASDEV-PROD-APP-LAYER | DONE — SUCCESS |
| ASDEV-POST-DEPLOY-VALIDATE | DONE — HEALTHY |

---

## NEXT_AUTONOMOUS_ACTION

After this PR: implement ASDEV onsite backup + restore drill (still no public edge).
