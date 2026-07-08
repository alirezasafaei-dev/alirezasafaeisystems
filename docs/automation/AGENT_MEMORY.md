# Agent Memory — ASDEV

**Format:** Point-in-time agent state.  
**Source of Truth:** GitHub (`alirezasafaei-dev/alirezasafaeisystems`)  
**Workspace:** `/home/dev13/ASDEV`

---

## Architecture

```
GitHub main (SoT) ──► /home/dev13/ASDEV (OWNER_PC)
                              │
                              ▼ rsync platform scripts
                     IRAN_PROD:/home/asdev/asdev-platform
                              │
              ┌───────────────┴────────────────┐
              ▼                                ▼
   production /srv/asdev/sites/          staging …/persiantoolbox-staging
   persiantoolbox  :3100                 legacy :3000 (registry wants 3200)
```

---

## Production application state (live)

| Field | Value |
|-------|-------|
| Status | **STABLE** app-layer |
| Release | `20260708T221124Z-fcc7192` |
| Frozen product | **`fcc7192af26a5713e31d4ec078365f9507c8108a`** |
| Bind | `127.0.0.1:3100` |
| PID | 72355 alive (`next-server`) |
| ready / health | **200 / 200** · ~12–14ms |
| Runtime log errors | none |
| Host | disk 27% · mem avail ~3.1G · load ~0 |
| Public edge | **OFF** |
| Stability report | `docs/reports/critical-site-stability-report.md` |

---

## Frozen release

| Layer | Pin |
|-------|-----|
| Product | `persiantoolbox@fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Production release id | `20260708T221124Z-fcc7192` |
| Staging release id | `20260708T210149Z-fcc7192` (same product pin) |
| previous_release | **empty** (first production deploy) |

---

## Completed phases

1. Staging live (PHASE_2 phrase)  
2. RC freeze + production preflight  
3. Production **app-layer** deploy (`APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`)  
4. Post-deploy validation + ops loop v1 docs/scripts  
5. IRAN platform sync + daily **meta** backup cron (03:15 UTC)  
6. **Post-production stabilization loop** (this entry): stability report, deploy validation, backup workflows, staging rebind preflight script, memory refresh  

---

## Remaining approval gates (hard stops)

| Phrase | Unlocks |
|--------|---------|
| `APPROVE_CRITICAL_SITE_PUBLIC_EDGE` | nginx → SSL → DNS → public launch |
| `APPROVE_MONITORING_LIVE_TIMERS` | install live probe timers (beyond existing backup cron) |
| `APPROVE_CRITICAL_SITE_MIGRATION` | database migrations |
| `APPROVE_CRITICAL_SITE_STAGING_REBIND` (optional) | staging 3000→3200 live rebind |

**Do not:** enable nginx, change DNS, enable SSL, run migrations, enable live timers without phrases.  
**Existing meta backup cron is not a monitoring live timer** — do not alter it in stabilization loops unless asked.

---

## Decisions

| Date | Decision |
|------|----------|
| 2026-07-08 | First prod = app layer only (Option A) |
| 2026-07-08 | Ports: prod 3100 / staging registry 3200 |
| 2026-07-08 | Remote build on IRAN for product pin |
| 2026-07-08 | One PR per major phase (PR #73 ops loop) |
| 2026-07-08 | Stabilize before public exposure |

---

## Blockers / residuals

- Public edge waiting approval  
- No symlink rollback history until second prod release  
- Meta backups only (no encrypted shared env / DB dump yet)  
- Staging still on legacy :3000 (plan + preflight only)  
- Shared secrets placement for full product features  

---

## Next autonomous (safe)

1. Land / keep PR #73 updated with stabilization docs  
2. Optional: second observation window / report refresh  
3. Do **not** rebind staging or open edge without phrase  

---

## Memory log

### [2026-07-08 22:30 UTC] Post-production stabilization loop

- Read-only IRAN observation → **STABLE**  
- Deploy system validation PASS; product pin **fcc7192** confirmed  
- Backup verification workflow + restore checklist + freshness report  
- Scripts: stability sample, backup freshness report, staging rebind preflight (no stop)  
- Gates unchanged: PUBLIC_EDGE · MONITORING_LIVE_TIMERS · MIGRATION  
