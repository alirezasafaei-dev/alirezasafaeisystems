# Agent Memory — ASDEV

**Read this first** before any agent work.  
**SoT:** GitHub `alirezasafaei-dev/alirezasafaeisystems`  
**Workspace:** `/home/dev13/ASDEV`  
**Updated:** 2026-07-08T22:40:00Z

---

## Current architecture

```
GitHub (SoT)
    │
AUTOMATION_HOST (hostname asdev · OWNER_PC colocated)
    ├── /home/dev13/ASDEV  control-plane/ + scripts + docs
    ├── Hermes gateway + OpenClaw gateway (user processes)
    └── SSH → IRAN_PROD
              ├── production persiantoolbox :3100  LIVE
              └── staging :3000 (legacy) LIVE
```

Control plane contract: `docs/architecture/automation-control-plane.md`  
Agent registry: `docs/automation/AGENT_REGISTRY.md`  
Machine queue: `control-plane/queue/queue.json`

---

## Current state

| Layer | State |
|-------|-------|
| AUTOMATION_HOST | **DEGRADED_NON_BLOCKING** · usable control plane |
| Health score | ~7/10 |
| CRITICAL_SITE prod app | **STABLE** `20260708T221124Z-fcc7192` pin **fcc7192** `:3100` |
| Public edge | OFF |
| PM2 | idle (0) |
| Docker | 1 healthy running; 5 exited legacy |
| Control plane tree | **created** |
| JSON task queue | **seeded** |

---

## Completed work (recent)

- CRITICAL_SITE staging + production app-layer  
- Post-prod stabilization reports  
- IRAN script sync + meta backup cron  
- **Control plane transform v1:** audit, architecture, registry, queue, loop engine, GitHub model, health script, container inventory, PM2 policy, roadmaps  

---

## Known issues

- Hermes/OpenClaw not under PM2 policy  
- Desktop colocation resource contention  
- GHA TLS flakiness  
- Staging still on :3000  
- First prod has no previous_release  
- Meta backups only on IRAN  

---

## Active projects

1. ASDEV control plane (this)  
2. CRITICAL_SITE production edge (gated)  
3. Site-standard multi-site rollout  

---

## Next actions

1. Merge control-plane PR  
2. Use `queue-list` / `loop-once` in sessions  
3. Stop for: `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` · `APPROVE_MONITORING_LIVE_TIMERS` · `APPROVE_CRITICAL_SITE_MIGRATION`  

---

## Important decisions

| Decision | Rationale |
|----------|-----------|
| GitHub = only SoT | No tribal host state |
| AUTOMATION_HOST = orchestration not runtime | CRITICAL_SITE stays on IRAN |
| JSON queue + markdown queue | Machine + human |
| One PR per major phase | Avoid micro-PR thrash |
| No blind docker/pm2 delete | Safety |
| App-layer prod before edge | Blast radius |

---

## Approval gates (hard stop)

```
APPROVE_CRITICAL_SITE_PUBLIC_EDGE
APPROVE_MONITORING_LIVE_TIMERS
APPROVE_CRITICAL_SITE_MIGRATION
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY  (redeploy)
APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Memory log

### [2026-07-08 22:40 UTC] Control plane transform v1

- Full AUTOMATION_HOST audit → score ~7/10 DEGRADED_NON_BLOCKING  
- Created control-plane tree, queue system, agent registry, health check  
- Container inventory: keep microcatalog postgres; archive halo-secret*  
- No production mutation; no live timer install  
