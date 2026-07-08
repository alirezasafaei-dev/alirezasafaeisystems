# CRITICAL_SITE First Production Deploy

**Date:** 2026-07-08T22:11:25Z (deploy) · report frozen 2026-07-08T22:20:00Z  
**Approval:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`  
**Scope:** Application layer only (`127.0.0.1:3100`)  
**Result:** **SUCCESS**

---

## Pins

| Layer | Value |
|-------|-------|
| Platform (docs tip at freeze) | `02d3c54` then main advanced with release docs |
| Product | `fcc7192af26a5713e31d4ec078365f9507c8108a` |
| Release ID | `20260708T221124Z-fcc7192` |
| Host alias | IRAN_PROD |
| Site id | `persiantoolbox` |

---

## Preflight (re-validated before cutover)

| Check | Result |
|-------|--------|
| Product SHA | PASS — `fcc7192` |
| Disk free | PASS — ~27G root |
| Memory | PASS — ~3.1G available |
| Port 3100 free before start | PASS |
| Release dir `/srv/asdev/sites/persiantoolbox` | PASS |
| Deploy scripts on platform path | PASS |
| Staging still healthy | PASS (legacy `:3000`) |

---

## Execution (app layer only)

```
asdev-deploy.sh \
  --site persiantoolbox \
  --environment production \
  --commit fcc7192af26a5713e31d4ec078365f9507c8108a \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

Remote build on IRAN_PROD (swap 2G, Node heap 3072, `HUSKY=0` / ignore-scripts).

---

## Post-cutover validation

| Check | Result |
|-------|--------|
| Release created | YES — `20260708T221124Z-fcc7192` |
| `current` symlink | YES → that release |
| Process | YES — pid 72355 (`next-server`) |
| Bind | `127.0.0.1:3100` |
| `/api/ready` | 200 |
| `/api/health` | 200 |
| nginx / DNS / SSL | **not modified** |
| migration | **not run** |
| previous_release | empty (first production release) |

---

## Intentionally excluded

- nginx reload  
- DNS  
- SSL/certbot  
- public traffic  
- firewall changes  
- staging stop/rebind  

---

## Rollback posture

First production release: **no prior release** for symlink rollback.

1. Redeploy same pin with same approval phrase  
2. Emergency stop: kill pid from `asdev-runtime.pid`  

See also: `docs/reports/critical-site-production-app-layer-deploy-latest.md`

---

## Status

```
PRODUCTION_APP_LAYER_LIVE
release=20260708T221124Z-fcc7192
port=3100 ready=200 health=200
```
