# Staging Rebind Plan — CRITICAL_SITE `:3000` → `:3200`

**Status:** PLAN ONLY — optional, not required for production `:3100`  
**Last Updated:** 2026-07-08  
**Registry target:** `staging_port=3200`  
**Current live staging:** legacy **`:3000`** (healthy)

---

## Why

| Fact | Detail |
|------|--------|
| Registry | production **3100**, staging **3200** |
| Live staging today | still bound to **3000** from first staging cutover |
| Production | already isolated on **3100** — **no conflict** |
| Goal | align live staging with registry + free 3000 for other uses |

This rebind is **optional**. Production app-layer does not depend on it.

---

## Risk assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Staging downtime during rebind | Low–med | short window; prod untouched |
| Someone still curls :3000 | Low | document new port; update any private probes |
| Accidental prod stop | High if careless | never touch prod pid/port; use staging site root only |
| Public edge pointing at wrong port | N/A until edge | staging edge not configured |

**Do not** rebind during an active public-edge cutover without coordination.

---

## Preconditions

1. Production healthy on `127.0.0.1:3100`  
2. Staging healthy on current port (today `:3000`)  
3. Port **3200** free  
4. Platform scripts synced under `/home/asdev/asdev-platform`  
5. Owner accepts brief staging unavailability  

Approval: **not** the production phrase. Prefer explicit ops note or  
`APPROVE_CRITICAL_SITE_STAGING_REBIND` if owner wants a hard gate.  
Without that phrase, agents **plan only** (this document).

---

## Execution steps (when approved)

### 1. Preflight on IRAN_PROD

```bash
ss -ltn | grep -E ':(3000|3100|3200)\b'
curl -sS -o /dev/null -w "prod=%{http_code}\n" http://127.0.0.1:3100/api/ready
curl -sS -o /dev/null -w "stg_old=%{http_code}\n" http://127.0.0.1:3000/api/ready
# 3200 must be free
```

### 2. Stop staging runtime only

Staging paths (registry):

- Base: `/srv/asdev/sites/persiantoolbox-staging`  
  (or current staging root if different — verify before kill)

```bash
STG_ROOT=/srv/asdev/sites/persiantoolbox-staging
# If legacy staging still under prod tree, identify via pid on :3000
# Prefer: kill only the pid listening on 3000 after confirming it is staging release

pid_stg=$(ss -ltnp | awk '/:3000/ {print}' )  # inspect, do not blind-kill
# Safer: use staging asdev-runtime.pid if present
if [[ -f "$STG_ROOT/asdev-runtime.pid" ]]; then
  kill "$(cat "$STG_ROOT/asdev-runtime.pid")" || true
fi
# Confirm 3000 released
ss -ltn | grep 3000 || echo "3000 free"
```

**Never** kill pid bound to **3100**.

### 3. Redeploy staging to port 3200

```bash
cd /home/asdev/asdev-platform
COMMIT=fcc7192af26a5713e31d4ec078365f9507c8108a  # or newer approved pin
bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment staging \
  --commit "$COMMIT" \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY
```

Deploy engine must resolve `staging_port=3200` from registry.

### 4. Validate

```bash
bash scripts/monitoring/check-prod-app-layer.sh --port 3100
curl -sS -o /dev/null -w "stg_new=%{http_code}\n" http://127.0.0.1:3200/api/ready
curl -sS -o /dev/null -w "stg_new_health=%{http_code}\n" http://127.0.0.1:3200/api/health
ss -ltn | grep -E ':(3000|3100|3200)\b'
```

Expected:

| Port | State |
|------|-------|
| 3100 | prod still 200 |
| 3200 | staging 200 |
| 3000 | free |

### 5. Record

Write `docs/reports/critical-site-staging-rebind-latest.md` with release id, ports, health codes.

---

## Rollback

If staging on 3200 fails:

1. Stop failed staging process on 3200  
2. Redeploy staging again or restart previous staging release on 3200  
3. Emergency only: restore previous working method on 3000 (document as regression)

Production remains on 3100 throughout.

---

## Explicit non-goals

- No nginx/DNS/SSL changes  
- No production redeploy  
- No migration  
- No killing processes without pid ownership check  

---

## Decision

| Option | When |
|--------|------|
| **Defer** | Default until public edge or multi-site needs 3000 |
| **Execute** | Before staging public vhost, or when 3000 needed elsewhere |
