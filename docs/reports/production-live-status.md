# Production Live Status — CRITICAL_SITE

**Checked at:** 2026-07-08T22:17:55Z  
**Host alias:** IRAN_PROD  
**Environment:** production (application layer)  
**Classification:** **HEALTHY**

---

## Application

| Metric | Value |
|--------|-------|
| Release | `20260708T221124Z-fcc7192` |
| Commit | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Symlink | `/srv/asdev/sites/persiantoolbox/current` → release above |
| PID | 72355 (`next-server`) |
| Alive | yes |
| Bind | `127.0.0.1:3100` |
| CPU (sample) | ~4.9% |
| RSS (sample) | ~190MB (~4.8% of host RAM) |
| Runtime log | Next.js 16.2.9 Ready; no error tail |

### Health latency (3 samples)

| Probe | HTTP | Time |
|-------|------|------|
| ready #1 | 200 | 0.023s |
| ready #2 | 200 | 0.018s |
| ready #3 | 200 | 0.016s |
| health | 200 | 0.018s |

---

## Infrastructure

| Item | Value |
|------|-------|
| Port 3100 | LISTEN 127.0.0.1 (prod) |
| Port 3000 | LISTEN 127.0.0.1 (staging legacy) |
| Port 3200 | not listening (staging not rebound yet) |
| Disk root | 27% used · ~27G free |
| Mem available | ~3197 MB |
| Swap free | ~1827 MB |
| nginx sites-available (asdev user) | not listing prod edge config under this user |
| Backup dir under `/srv/asdev/backups` | **present** — first meta backup `20260708T222048Z` |
| Cron (asdev) | empty |
| systemd asdev units (user view) | none listed |

---

## Staging (co-host, unchanged)

| Item | Value |
|------|-------|
| Release | `20260708T210149Z-fcc7192` |
| Ready | 200 on legacy `:3000` |
| Isolation vs prod | PASS (different ports) |

---

## Public edge

| Item | State |
|------|-------|
| App public via ASDEV nginx cutover | **NO** (not executed) |
| DNS/SSL ownership change this mission | **NO** |
| Plan | `docs/ops/public-edge-plan.md` |

---

## Errors observed

None in ready/health probes or short runtime log tail.

---

## Follow-ups (non-blocking for app-layer)

1. Shared secrets placement for full product features  
2. App-layer backup + restore drill on IRAN_PROD  
3. Staging rebind 3000 → 3200  
4. Public edge after `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`  
5. Second production release to enable symlink rollback history  

---

## Status code

```
PRODUCTION_LIVE_STATUS=HEALTHY
app_layer=LIVE
public_edge=NOT_CONFIGURED
backup_evidence=WEAK
```
