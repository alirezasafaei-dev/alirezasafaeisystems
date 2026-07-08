# Docker Container Inventory — AUTOMATION_HOST

**Date:** 2026-07-08T22:31:00Z  
**Engine:** Docker 29.1.3 · 6 containers (1 running, 5 stopped)  
**Policy:** Inspect → document → decide. **No blind delete.**

---

## Inventory

| Name | Image | Status | Project/label | Decision |
|------|-------|--------|---------------|----------|
| modular-monolith-postgres | postgres:16-alpine | **Up healthy** · unless-stopped | microcatalog compose | **KEEP** — active |
| persiantoolbox-postgres | postgres:16-alpine | Exited 0 · 10d · unless-stopped | unlabeled | **ARCHIVE** — not IRAN prod runtime; leave stopped |
| halo-secret-redis | redis:7-alpine | Exited 0 · 4w · restart=no | compose project `halo-secret` | **ARCHIVE** — legacy non-ASDEV-critical |
| halo-secret-db | postgres:16-alpine | Exited 0 · 4w · restart=no | compose project `halo-secret` | **ARCHIVE** — legacy |
| practical_edison | (sha only) | Exited 1 · 13d | none | **ARCHIVE** — failed one-off; do not restart |
| elated_hofstadter | (sha only) | Exited 1 · 13d | none | **ARCHIVE** — failed one-off; do not restart |

---

## Decision definitions

| Decision | Meaning |
|----------|---------|
| KEEP | Required or actively used; monitor health |
| REPAIR | Broken but needed — fix with owner scope |
| ARCHIVE | Stopped/legacy; keep until owner approves removal |

---

## halo-secret-* detail

- Compose project: `halo-secret`  
- Stopped cleanly (exit 0) ~4 weeks ago  
- **Not** part of CRITICAL_SITE IRAN production path  
- Prior mission: treat as legacy non-blocking  
- Action now: **document only** — do not `docker rm` without owner approval  

---

## Risks

| Risk | Note |
|------|------|
| Volume data retention | Unknown; inspect volumes before any rm |
| Name collision | Avoid starting new stacks reusing halo-secret names |
| Disk | 51 images present — optional prune later with approval |

---

## Recommended later (approval)

1. `docker volume ls` inventory (separate report)  
2. Owner phrase or explicit OK to remove ARCHIVE containers  
3. Image prune unused  

```
CONTAINER_INVENTORY=DOCUMENTED
DESTRUCTIVE_CLEANUP=NOT_PERFORMED
```
