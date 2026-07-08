# MONTHLY_ROADMAP — ASDEV

**Period:** July 2026 (rolling 30 days)

---

## Theme

Turn CRITICAL_SITE first app-layer success into a **repeatable multi-site production platform**.

## Outcomes

| Outcome | Measure |
|---------|---------|
| Public CRITICAL_SITE | HTTPS 200 on domain via nginx→3100 |
| Backup discipline | Freshness check green ≤ 36h; restore drill logged |
| Platform standard | New site onboarded via `templates/site-standard` only |
| Agent continuity | `AGENT_MEMORY` + handoff always current |
| Rollback maturity | ≥2 production releases → symlink rollback proven |

## Workstreams

1. **Edge & launch** — public edge, DNS/SSL, smoke  
2. **Resilience** — backup encrypt, offsite, quarterly drill  
3. **Observability** — timers, deploy status, disk, backup age  
4. **Multi-site** — registry rows, port isolation, template  
5. **Automation host** — optional workers/runners without fragility  

## Stop rules

- No production/edge/migration without exact phrase  
- No secrets in git or reports  
- Prefer one PR per major phase  

Also: `docs/roadmaps/NEXT_30_DAYS.md`
