# Active Roadmap (Memory Control Center)

**Updated:** 2026-07-08  
**Canonical files also:** `/roadmap/*`, `docs/roadmaps/*`

---

## Now (OS factory)

1. Finish Operating System docs + control-plane maturity (this loop)  
2. Project registry completeness  
3. Universal deployment model  
4. Observability architecture (no live install)  
5. Security baseline docs  

## Next (still safe)

- Standardize each site to project.yaml + health/rollback docs  
- Deploy engine zero-downtime tests (dry)  
- Agent heartbeat + stale task automation  

## Gated later

| Order | Item | Phrase |
|-------|------|--------|
| 1 | Public edge CRITICAL_SITE | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| 2 | Live monitoring timers | `APPROVE_MONITORING_LIVE_TIMERS` |
| 3 | Second prod release (rollback history) | `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` |
| 4 | Migrations if needed | `APPROVE_CRITICAL_SITE_MIGRATION` |
| 5 | Other sites staging/prod | respective phrases |

## Not now

- Manual one-off site hacks without standards  
- SaaS lock-in for monitoring  
