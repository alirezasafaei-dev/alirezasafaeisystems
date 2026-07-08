# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T22:40:00Z  
**Status:** CONTROL_PLANE_V1 · PROD_APP_STABLE · EDGE_OFF  
**Machine queue:** `control-plane/queue/queue.json`

---

## Live state

| Layer | State |
|-------|-------|
| AUTOMATION_HOST | Control plane v1 · DEGRADED_NON_BLOCKING |
| Production app | STABLE `:3100` fcc7192 |
| Staging | LIVE legacy `:3000` |
| Public edge | OFF |
| JSON queue | seeded + CLIs |

---

## Queue (human)

### Done
- ASDEV control plane transform v1  
- Prod app-layer + stabilization  

### Pending gated
1. Public edge — `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`  
2. Live monitoring timers — `APPROVE_MONITORING_LIVE_TIMERS`  
3. Migrations — `APPROVE_CRITICAL_SITE_MIGRATION`  

### Safe next
- Merge PRs (#73 ops loop if open, control-plane PR)  
- Daily `automation-health-check.sh`  
- Keep memory/queue aligned  

---

## NEXT_AUTONOMOUS_ACTION

Operate via control-plane queue; stop only on approval phrases or real blockers.
