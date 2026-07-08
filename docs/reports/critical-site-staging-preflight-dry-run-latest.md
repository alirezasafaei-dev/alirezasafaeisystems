# CRITICAL_SITE Staging Preflight Dry-Run — Latest

**Date:** 2026-07-08T20:10:00Z  
**Site:** CRITICAL_SITE (`persiantoolbox.ir` / registry id `persiantoolbox`)  
**Approval used:** APPROVE_CRITICAL_SITE_STAGING_PREFLIGHT_DRY_RUN  
**Commit under test:** `eaddee439e72fa2d0fe6fe1d17b2ad4f01542054`

---

## Commands executed (safe only)

| Step | Command | Exit |
|------|---------|------|
| Registry | `scripts/ops/validate-registry-schema.sh` | 0 |
| Dangerous patterns | `scripts/ops/check-dangerous-patterns.sh` | 0 |
| Healthcheck order | `scripts/ops/check-healthcheck-order.sh` | 0 |
| Protection | `scripts/ops/check-critical-site-protection.sh` | 0 |
| Preflight dry-run | `asdev-preflight.sh --site persiantoolbox --environment staging --commit … --dry-run` | 0 (6 warnings) |
| Deploy dry-run | `asdev-deploy.sh … --dry-run` | 0 |
| Healthcheck dry-run | `asdev-healthcheck.sh … --dry-run` | 0 |
| Rollback dry-run | `asdev-rollback.sh … --dry-run` | 0 |

---

## Bugs found and fixed this cycle

1. **`get_field` unbound `$2`** in `asdev-preflight.sh`, `asdev-rollback.sh`, `asdev-release-gc.sh`  
   - Symptom: empty registry fields, false disk-space error, rollback crash under `set -u`
2. **Rollback required approval even on `--dry-run`** — fixed (dry-run/check are approval-free)
3. **Disk check when deploy base missing** — now falls back to parent/root instead of reporting 0MB
4. **Deploy hardening** — `release.meta` + `previous-release` pointer for safer rollback selection

---

## Preflight warnings (expected on OWNER_PC)

| Warning | Meaning |
|---------|---------|
| Repo path `sites/live/persiantoolbox` missing locally | Site source not vendored in this checkout |
| Staging deploy base missing locally | Expected: target is IRAN_PROD path |
| Shared path missing locally | Same |
| Commit not in local site repo | No local site git tree |
| local-port health not reachable | Staging not running on OWNER_PC |
| Disk checked on `/` | Fallback after missing deploy base |

---

## What was NOT executed

- Live staging deploy
- Symlink switch
- Build on IRAN_PROD
- nginx/pm2 changes
- Database migration
- Production deploy

---

## Public HTTP probe (informational, not staging)

`check-critical-site-http.sh` from OWNER_PC:

| Endpoint | Result |
|----------|--------|
| `/` | timeout / HTTP 000 |
| `/api/ready` | timeout / HTTP 000 |
| `/api/health` | HTTP 200 (~9s) |

Network path from OWNER_PC to CRITICAL_SITE is partial; treat as **observation**, not deploy-engine failure.

---

## Classification

**READY_WITH_WARNINGS** (improved: source now ready locally)

Deploy engine + registry + protection dry-runs are green after bugfixes.  
Local CRITICAL_SITE source prepared via `asdev-prepare-site-source.sh` (`status=ready`).

Live staging still needs:

1. ~~Site source or artifact available on executor path~~ → **DONE on OWNER_PC**
2. IRAN_PROD staging paths / execution host with `/srv/asdev/...`
3. Owner phrase below

---

## NEXT_GATE

```
APPROVE_PHASE_2_STAGING_DEPLOY
```
