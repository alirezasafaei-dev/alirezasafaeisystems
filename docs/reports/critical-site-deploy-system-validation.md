# CRITICAL_SITE Deployment System Validation

**Date:** 2026-07-08T22:27:34Z  
**Environment:** production (app layer)  
**Result:** **PASS** (with first-deploy rollback caveat)

---

## Frozen product confirmation

| Expected | Observed | Match |
|----------|----------|-------|
| `fcc7192af26a5713e31d4ec078365f9507c8108a` | `fcc7192af26a5713e31d4ec078365f9507c8108a` | **YES** |
| Short | `fcc7192` | in `release_id` | **YES** |

---

## Layout checks

| Check | Result |
|-------|--------|
| Site root | `/srv/asdev/sites/persiantoolbox` |
| `current` symlink | → `releases/20260708T221124Z-fcc7192` |
| Symlink resolves | YES |
| Active release dir exists | YES |
| Only production release present | YES (single dir under `releases/`) |

---

## release.meta

```
site=persiantoolbox
environment=production
commit=fcc7192af26a5713e31d4ec078365f9507c8108a
release_id=20260708T221124Z-fcc7192
created_at=2026-07-08T22:11:25Z
runtime=node
build_command_id=node-pnpm-build
start_command_id=node-standalone
previous_release=
runtime_port=3100
prod_port=3100
staging_port=3200
```

| Field | OK? |
|-------|-----|
| environment=production | YES |
| runtime_port=3100 | YES |
| commit matches freeze | YES |
| previous_release | empty (expected first prod) |

---

## Runtime linkage

| Check | Result |
|-------|--------|
| `asdev-runtime.pid` | 72355 alive |
| Process binds 3100 | YES |
| Health after activate | ready/health 200 |

---

## Rollback command (documented — not executed)

Platform script present on IRAN: `asdev-rollback.sh` = **yes**

```bash
bash /home/asdev/asdev-platform/scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment production \
  --commit fcc7192af26a5713e31d4ec078365f9507c8108a \
  --dry-run
```

**Caveat:** Symlink rollback to a *previous* release is **not available** until a second production release exists (`previous_release` empty).

**Recovery alternatives today:**

1. Redeploy same pin with `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`  
2. Emergency stop: `kill $(cat /srv/asdev/sites/persiantoolbox/asdev-runtime.pid)`  

---

## Deploy / runtime logs

| Log | Finding |
|-----|---------|
| `asdev-runtime.log` | Clean Next.js ready; no errors |
| Deploy engine | Platform scripts synced under `/home/asdev/asdev-platform` (7 `asdev-*.sh`) |

---

## Status

```
DEPLOY_SYSTEM=PASS
product_pin=fcc7192
release=20260708T221124Z-fcc7192
rollback_history=NONE_FIRST_DEPLOY
```
