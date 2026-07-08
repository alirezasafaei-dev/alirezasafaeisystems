# TODAY — ASDEV Immediate Priorities

**Date:** 2026-07-08  
**Source of Truth:** GitHub  
**Canonical also:** `/TODAY_ROADMAP.md`

---

## Done

| Item | Status |
|------|--------|
| CRITICAL_SITE staging live | SUCCESS |
| Production app-layer | LIVE `:3100` ready/health 200 |
| Post-deploy validation | HEALTHY |
| Public edge plan + template | PREPARED (not applied) |
| Monitoring standard + new probes | DONE |
| DR runbook | DONE |
| Agent memory / queue / roadmaps | UPDATED |
| Site-standard template | DONE |

## Now

| Priority | Task | Gate |
|----------|------|------|
| 1 | Land ops-loop PR | review/merge |
| 2 | Onsite backup + restore drill | none (safe) |
| 3 | Public edge | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |

## Stop

- No nginx/DNS/SSL without public-edge phrase  
- No migrations without migration phrase  
- No live monitoring timers without timer phrase  
