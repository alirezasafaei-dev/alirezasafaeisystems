# Active Autonomous Queue — ASDEV

**Last Updated:** 2026-07-08T22:42:00Z  
**Status:** MAIN_MERGED · PROD_STABLE · EDGE_OFF  
**Machine queue:** `control-plane/queue/queue.json`

---

## Live

| Layer | State |
|-------|-------|
| GitHub main | PR #74 merged |
| Prod | STABLE `:3100` fcc7192 |
| Staging | LIVE `:3000` |
| Edge | OFF |
| Control plane | operational |

---

## Queue

### Safe / continuous
- Daily control-plane runbook  
- Health check + queue list  
- Weekly archive done tasks  

### Gated (waiting owner phrase)
| ID theme | Phrase |
|----------|--------|
| Public edge | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| Live timers | `APPROVE_MONITORING_LIVE_TIMERS` |
| Migrations | `APPROVE_CRITICAL_SITE_MIGRATION` |
| Second prod release (rollback history) | `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` |
| Staging rebind 3000→3200 | optional `APPROVE_CRITICAL_SITE_STAGING_REBIND` |

---

## NEXT_AUTONOMOUS_ACTION

Continue safe hygiene only. Stop for gated phrases above.
