# Agent Memory — ASDEV

**Format:** Each entry records agent state at a point in time.  
**Source of Truth:** GitHub (`alirezasafaei-dev/alirezasafaeisystems`)  
**Workspace:** `/home/dev13/ASDEV`

---

## Architecture (current)

```
GitHub main (SoT)
    │
    ▼
/home/dev13/ASDEV  (OWNER_PC / AUTOMATION_HOST checkout)
    │  deploy engine, registry, monitoring, docs
    ▼
IRAN_PROD
    ├── /home/asdev/asdev-platform   (synced scripts/registry)
    ├── /srv/asdev/sites/persiantoolbox          production :3100
    └── /srv/asdev/sites/persiantoolbox-staging  staging (legacy :3000 live)
```

| Layer | Pin / state |
|-------|-------------|
| Product | `persiantoolbox@fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Production release | `20260708T221124Z-fcc7192` LIVE on `127.0.0.1:3100` |
| Staging release | `20260708T210149Z-fcc7192` LIVE on legacy `:3000` |
| Public edge | NOT configured (plan ready) |
| Registry ports | prod **3100** / staging **3200** |

---

## Current State

**Date:** 2026-07-08T22:25:00Z  
**Loop:** Autonomous Production Operations Loop v1  
**OWNER_PC:** usable executor  
**AUTOMATION_HOST:** DEGRADED_NON_BLOCKING (PM2 idle, no self-hosted runner)  
**CRITICAL_SITE production app-layer:** **LIVE** ready/health **200**  
**CRITICAL_SITE public edge:** waiting `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`  
**CI:** GHA historically infra-degraded; local checks preferred  
**Active queue:** `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md`

---

## Decisions

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-07-06 | Hermes-first orchestration | n8n deferred; GitHub = command center |
| 2026-07-08 | Staging live under PHASE_2 phrase | proven pin `fcc7192` |
| 2026-07-08 | First prod = **app layer only** Option A | reduce blast radius; edge separate |
| 2026-07-08 | Prod port **3100** not 3000 | isolation vs legacy staging |
| 2026-07-08 | Remote build on IRAN | large SCP unstable; heap+swap |
| 2026-07-08 | One PR per major phase | avoid micro-PR thrash |
| 2026-07-08 | Continue autonomous loop after prod | do not stop for tiny tasks |

---

## Rules (non-negotiable)

- GitHub is SoT; never commit `.env`, keys, raw IPs in reports when avoidable  
- Production / edge / migration / live timers require **exact** phrases  
- Prefer automation + reusable scripts + docs  
- Batch related work into one meaningful PR  
- `/home/dev13/ASDEV` is the only active workspace root  

---

## Blockers

| Blocker | Type |
|---------|------|
| Public edge not live | **WAITING_APPROVAL** `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` |
| Backup artifacts missing on IRAN_PROD | technical gap (safe to implement onsite backup next) |
| First prod has no previous_release | expected; need second release for symlink rollback history |
| Shared secrets for full product features | owner placement on host shared path |
| Live monitoring timers | **WAITING_APPROVAL** `APPROVE_MONITORING_LIVE_TIMERS` |

---

## Owner approval phrases

### Granted (this mission arc)

- `APPROVE_OWNER_PC_SYNC_MAIN`  
- `APPROVE_AUTOMATION_HOST_READONLY_AUDIT`  
- `APPROVE_AUTOMATION_HOST_REPAIR_NON_DESTRUCTIVE`  
- `APPROVE_REPO_AUTOMATION_MAINTENANCE`  
- `APPROVE_CI_ROUTER_REPAIR`  
- `APPROVE_QUEUE_MAINTENANCE`  
- `APPROVE_CRITICAL_SITE_STAGING_PREFLIGHT_DRY_RUN`  
- `APPROVE_PHASE_2_STAGING_DEPLOY`  
- `APPROVE_MONITORING_FOUNDATION_PREP`  
- `APPROVE_DOCS_AND_REPORTS_UPDATE`  
- **`APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`** (app layer only — executed)  
- Autonomous Production Operations Loop v1 (post-deploy continue)

### Not granted (stop gates)

- `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`  
- `APPROVE_MONITORING_LIVE_TIMERS`  
- `APPROVE_CRITICAL_SITE_MIGRATION`  
- `APPROVE_NON_CRITICAL_QUARANTINE_LIVE`  
- `APPROVE_RELEASE_DELETE`

Informal “go ahead” is **insufficient** for prod/edge/migration.

---

## Next actions (priority)

1. Land ops-loop PR (docs/scripts/template/roadmaps)  
2. Implement ASDEV-path onsite backup + restore drill (no edge)  
3. On phrase: public edge nginx→3100 + SSL + DNS  
4. On phrase: monitoring live timers  
5. Second production release when product changes → enable rollback history  

---

## What must not be repeated

- Do not redeploy production “just because” loop restarted  
- Do not install nginx template without public-edge phrase  
- Do not treat portfolio backup defaults as CRITICAL_SITE complete  
- Do not spam GHA reruns  
- Do not print secrets / raw IPs / .env contents  
- Do not create many tiny PRs for one mission  

---

## Memory log

### [2026-07-08 22:25 UTC] Autonomous Production Operations Loop v1

- Confirmed production app-layer still HEALTHY (pid alive, ready/health 200, p50~18ms)  
- Phase 2–10 docs/scripts/templates/roadmaps produced in one batch  
- Public edge **prepared only** (template + plan)  
- Automation host reclassified DEGRADED_NON_BLOCKING  
- Next stop gate: `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` or backup implementation work  
