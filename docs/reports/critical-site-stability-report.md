# CRITICAL_SITE Stability Report — Production App Layer

**Observed at:** 2026-07-08T22:27:34Z  
**Host alias:** IRAN_PROD  
**Scope:** Application layer only (`127.0.0.1:3100`)  
**Public edge:** NOT enabled  
**Classification:** **STABLE**

---

## 1. Summary

| Area | Result |
|------|--------|
| Process | Alive (pid **72355**, etime ~11m42s at sample → continuous since deploy) |
| Health | ready **200** · health **200** (all samples) |
| Latency | ready p50 ~13ms · max ~14ms (5 samples) |
| Errors in runtime log | **none** |
| Resource pressure | **none** (load ~0, mem avail ~3.1G, disk 27%) |
| Product pin | **`fcc7192af26a5713e31d4ec078365f9507c8108a`** |
| Release | `20260708T221124Z-fcc7192` |

```
STABILITY=STABLE
public_edge=OFF
ready_for_edge_prep=YES (app layer)
```

---

## 2. Application process

| Field | Value |
|-------|-------|
| PID file | `/srv/asdev/sites/persiantoolbox/asdev-runtime.pid` |
| PID | 72355 |
| Alive | yes |
| Command | `next-server` (Next.js 16.2.9) |
| CPU (sample) | **0.9%** |
| Mem % (sample) | **4.9%** |
| RSS (sample) | **~187 MB** (191788 KB) |
| Bind | `127.0.0.1:3100` only |

---

## 3. Health & latency

### `/api/ready` (5 samples)

| # | HTTP | total (s) | TTFB (s) |
|---|------|-----------|----------|
| 1 | 200 | 0.014 | 0.013 |
| 2 | 200 | 0.013 | 0.013 |
| 3 | 200 | 0.014 | 0.012 |
| 4 | 200 | 0.013 | 0.013 |
| 5 | 200 | 0.012 | 0.011 |

### `/api/health` (3 samples)

| # | HTTP | total (s) |
|---|------|-----------|
| 1 | 200 | 0.012 |
| 2 | 200 | 0.012 |
| 3 | 200 | 0.012 |

**Assessment:** Sub-20ms loopback latency; no timeouts; no non-2xx.

---

## 4. Runtime logs

| Item | Value |
|------|-------|
| Path | `/srv/asdev/sites/persiantoolbox/asdev-runtime.log` |
| Size | 114 bytes |
| Content | Next.js ready banner on `:3100` |
| error/exception/fatal matches | **0** |

---

## 5. Host resources

| Resource | Value |
|----------|-------|
| Disk `/` | 27% used · 9.4G / 38G · **27G free** |
| Mem total | 3820 MB |
| Mem available | **~3189 MB** |
| Swap free | **~1830 MB** (of 2047) |
| Load average | 0.00, 0.09, 0.19 |
| Uptime | ~1 day 6.5h |

No disk, memory, or load alerts.

---

## 6. Port isolation

| Port | Listener | Role |
|------|----------|------|
| 3100 | pid 72355 | **production** |
| 3000 | pid 70004 | staging (legacy bind) |
| 3200 | — | free (registry staging target) |

Production and staging do **not** share a port.

---

## 7. Staging co-host (unchanged)

| Field | Value |
|-------|-------|
| Ready | 200 on `:3000` |
| Release | `20260708T210149Z-fcc7192` |
| Commit | same pin `fcc7192…` |
| Root | `/srv/asdev/sites/persiantoolbox-staging` |

Staging **not** stopped during this observation.

---

## 8. Backup snapshot (observation only)

| Item | Value |
|------|-------|
| Artifacts | `20260708T222048Z`, `20260708T222632Z` |
| Cron (existing) | `15 3 * * *` meta backup — **not modified** this loop |
| Freshness | newest ~minutes old at last ops check |

---

## 9. Risks before public exposure

| Risk | Severity | Note |
|------|----------|------|
| No multi-release rollback history | Medium | `previous_release` empty |
| Shared secrets residual | Medium | full product features may need shared env |
| Meta-only backups | Medium | not full app/DB |
| Public edge not configured | Info | intentional |
| Staging on :3000 vs registry 3200 | Low | plan ready; not blocking prod |

---

## 10. Recommendation

**Hold public edge** until owner issues `APPROVE_CRITICAL_SITE_PUBLIC_EDGE`.  
App layer is **stable enough** for edge prep when approved.

Do **not** enable nginx/DNS/SSL/migrations/live monitoring timers without phrases.
