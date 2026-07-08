# TODAY_ROADMAP — ASDEV

**Date:** 2026-07-08  
**Loop:** Autonomous Production Operations Loop v1  
**Status:** App-layer production LIVE · public edge WAITING_APPROVAL

---

## Completed today

- [x] CRITICAL_SITE staging live (`20260708T210149Z-fcc7192`)
- [x] RC freeze + production preflight
- [x] `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` → app layer on `127.0.0.1:3100`
- [x] Post-deploy validation (ready/health 200, process alive)
- [x] Public edge plan + nginx 3100 template (not applied)
- [x] Monitoring standard + app-layer/deploy status scripts
- [x] DR runbook with restore-verify requirement
- [x] Automation host health re-audit
- [x] Agent memory + handoff refresh
- [x] Universal site-standard template
- [x] Clean root standard

## Active

- [ ] Batch PR for this ops loop (docs + scripts + template)
- [ ] Owner: shared secrets placement if full product features required

## Blocked / gated

| Item | Gate |
|------|------|
| nginx / SSL / DNS / public launch | `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| Live monitoring timers | `APPROVE_MONITORING_LIVE_TIMERS` |
| Migrations | `APPROVE_CRITICAL_SITE_MIGRATION` |

## Next autonomous (safe without new phrase)

1. Land this PR on main after review  
2. Parameterize backup scripts for `/srv/asdev/sites/*`  
3. First onsite backup + restore drill on IRAN_PROD (non-edge)  
4. Optional staging rebind 3000→3200 (plan + safe window)  

Also mirrored: `docs/roadmaps/TODAY.md`
