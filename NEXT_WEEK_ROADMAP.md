# NEXT_WEEK_ROADMAP — ASDEV

**Period:** 2026-07-08 → 2026-07-15

---

## Goals

1. **Public edge for CRITICAL_SITE** after owner phrase  
2. **Backup + restore drill** green on IRAN_PROD  
3. **Monitoring timers** (if approved)  
4. **No micro-PR thrash** — batch by phase  

## Plan

| Day focus | Work | Gate |
|-----------|------|------|
| D0–D1 | Land ops-loop PR; memory/queue stable | none |
| D1–D2 | Onsite backup path for persiantoolbox + restore drill report | none (app data only) |
| D2–D3 | Public edge execution when phrase granted | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| D3–D4 | External smoke + optional staging rebind 3200 | edge / ops window |
| D4–D5 | Monitoring live timers if approved | `APPROVE_MONITORING_LIVE_TIMERS` |
| D5–D7 | Second production release (rollback history) if product change | prod phrase |

## Explicit non-goals this week

- Unrelated product features outside reliability/revenue path  
- SaaS monitoring lock-in  
- Quarantine live of non-critical sites without phrase  

Also: `docs/roadmaps/NEXT_7_DAYS.md`
