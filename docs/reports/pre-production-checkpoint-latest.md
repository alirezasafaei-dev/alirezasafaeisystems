# Pre-Production Checkpoint — CRITICAL_SITE

**Date:** 2026-07-08T21:57:00Z  
**Mode:** Final production preflight (read-only + docs)  
**Production mutation:** **none**

---

## Frozen release pair

| Layer | Pin |
|-------|-----|
| Platform | `alirezasafaei-dev/alirezasafaeisystems` @ **`02d3c54`** (`02d3c54447fbaf056dbcbbbed374ae500996f1cc`) |
| Product | `alirezasafaei-dev/persiantoolbox` @ **`fcc7192`** (`fcc7192af26a5713e31d4ec078365f9507c8108a`) |
| Staging evidence | `20260708T210149Z-fcc7192` · ready/health **200** |

```
platform 02d3c54 + product fcc7192 = production candidate
```

---

## 1) Production environment validation (IRAN_PROD)

| Check | Result |
|-------|--------|
| Platform checkout exists | PASS |
| RELEASE_CANDIDATE.pin present | PASS (re-synced to `02d3c54`) |
| Deploy engine present | PASS |
| Registry prod/staging ports | PASS · 3100 / 3200 |
| Tools: git bash node pnpm rsync curl ss | PASS |
| Node | v22.16.0 |
| pnpm | 11.10.0 |
| Disk / | 25% used · 27G avail |
| Mem avail | ~3.1G · swap free ~1.9G |
| prod_base exists | PASS |
| prod_current | **no** (empty production) |
| prod_releases | **0** |
| Staging still healthy | PASS (ready 200 on legacy :3000) |

---

## 2) Secret configuration validation (existence only)

| Check | Result |
|-------|--------|
| Known shared env candidates | **none found** |
| shared/ directory | empty (dir exists, no files) |
| Values printed | **never** |

**Interpretation:** Staging runtime is healthy without a shared production `.env` on disk in known locations. First production cutover can still target **application layer on 127.0.0.1:3100**. Full product features (DB/payments/etc.) require owner to place env under shared path **before or immediately after** first cutover if those features are required for go-live.

**Residual risk (accepted for layer-1):** missing shared secrets inventory.

---

## 3) Runtime validation

| Check | Result |
|-------|--------|
| Target prod port | **3100** |
| port 3100 | **free** |
| port 3200 | free |
| port 3000 | listening (staging legacy) |
| Conflict with prod 3100 | **none** |
| Health URL | `http://127.0.0.1:3100/api/ready` |
| PM2 | not installed / unused |
| Strategy | `node-standalone` via `asdev-deploy.sh` |
| prod pidfile | none (expected pre-first-deploy) |

---

## 4) Database safety (read-only)

| Check | Result |
|-------|--------|
| DB connection keys in known env files | **not found** (no env file) |
| psql client | no |
| redis-cli | no |
| Migration applied | **not run** (forbidden) |
| Migration files in staging release | no/unknown |
| Backup evidence (app) | weak (only generic apt backup metadata under system backups) |

**Residual risk:** no verified app DB backup/host connectivity evidence. Acceptable if first deploy is app-layer only without DB-dependent features; **not** acceptable for data-critical go-live without owner follow-up.

---

## 5) First-deploy safety point (documentation)

### Empty production state (checkpoint)

Captured on IRAN_PROD under:

`/home/asdev/asdev-platform/pre-production-checkpoint/empty-state-inventory.txt`

(metadata only; IPs redacted)

Summary:

- prod_current=no  
- prod_releases=0  
- staging_current=20260708T210149Z-fcc7192  
- listening: :3000 (staging), :22, DNS local  
- shared: empty  
- nginx sites-enabled: none listed  

### Rollback limitations

- First production release has **no previous release** for symlink rollback.  
- Operational recovery = rebuild/redeploy pin `fcc7192` or stop process + remove broken current.  
- See `docs/ops/rollback-plan.md`.

### Known risks

1. Shared `.env` not present in known paths  
2. No strong app backup evidence on host  
3. Staging still on legacy :3000 (does not block :3100)  
4. No nginx edge for public hostname yet (by design for phase-1)  
5. First deploy rollback limited  

---

## Exact deploy command template (DO NOT RUN without owner phrase)

```bash
# On IRAN_PROD after APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
export PATH="/home/asdev/node/bin:$PATH"
export NODE_OPTIONS="--max-old-space-size=3072"
export HUSKY=0
export NEXT_TELEMETRY_DISABLED=1
unset NODE_ENV

cd /home/asdev/asdev-platform
PRODUCT_COMMIT=fcc7192af26a5713e31d4ec078365f9507c8108a

# Ensure product source at pin, then:
bash scripts/deploy/asdev-preflight.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$PRODUCT_COMMIT"

bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$PRODUCT_COMMIT" \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

# Expect:
# - current -> releases/*-fcc7192
# - process on 127.0.0.1:3100
# - curl http://127.0.0.1:3100/api/ready -> 200
```

**Not in this phase:** nginx reload, DNS, SSL, public edge.

---

## Local validation (OWNER_PC)

| Check | Result |
|-------|--------|
| main @ 02d3c54 | PASS |
| product pin match local checkout | PASS |
| registry/port isolation | PASS |
| production dry-run | PASS (port 3100) |

---

## Final decision

```
PRODUCTION_PREFLIGHT_PASS

NEXT_GATE:
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

**With residual warnings** (secrets inventory empty, weak backup evidence, first-deploy rollback limit). These do **not** block a localhost application-layer first production cutover; they **do** require owner awareness before declaring full public production.
