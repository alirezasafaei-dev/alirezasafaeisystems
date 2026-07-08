# CRITICAL_SITE Production Execution Plan

**Site:** CRITICAL_SITE (`persiantoolbox.ir` / registry `persiantoolbox`)  
**Last Updated:** 2026-07-08  
**Live production status:** NOT EXECUTED — requires owner phrase  
**Staging precondition:** LIVE_OK (`20260708T210149Z-fcc7192`, ready/health 200)

---

## Gate (required)

```text
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

Without this exact phrase, only dry-run/check modes are allowed.

---

## Preconditions (must be true)

| Check | Expected |
|-------|----------|
| Staging healthy | `/api/ready` and `/api/health` 200 on staging runtime |
| Staging release known | e.g. `20260708T210149Z-fcc7192` or newer approved commit |
| AUTOMATION_HOST | DEGRADED_NON_BLOCKING or READY |
| IRAN_PROD disk/swap | Sufficient free disk; swap recommended on 4G hosts |
| Production phrase | Exact match |
| No concurrent deploy lock | preflight OK |

---

## Lessons from staging (apply to production)

1. Build on IRAN_PROD when OWNER→IRAN bulk transfer is unreliable  
2. Use `NODE_OPTIONS=--max-old-space-size=3072` + swap on small hosts  
3. `HUSKY=0` / `pnpm install --ignore-scripts` then build  
4. Do **not** set `NODE_ENV=production` before install (skips devDependencies)  
5. Start `node-standalone` after symlink; healthcheck post-activation  
6. Never touch staging-only paths when activating production  

---

## Phase 0 — Dry-run (approval-free)

```bash
cd /home/dev13/ASDEV
COMMIT="$(git -C sites/live/persiantoolbox rev-parse HEAD)"  # or pin known-good SHA

bash scripts/ops/validate-registry-schema.sh
bash scripts/deploy/asdev-preflight.sh \
  --site persiantoolbox --environment production --commit "$COMMIT" --dry-run
bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox --environment production --commit "$COMMIT" --dry-run
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox --environment production --commit "$COMMIT" --dry-run
bash scripts/ops/check-critical-site-protection.sh

# Remote read-only status (private env file, not in git)
ASDEV_VPS_ENV_FILE=/path/to/private.env.vps \
  bash scripts/ops/asdev-remote-status.sh
```

---

## Phase 1 — Live production (ONLY after phrase)

Execute on IRAN_PROD (or orchestrate via AUTOMATION_HOST SSH).

```bash
export PATH="/home/asdev/node/bin:$PATH"
export NODE_OPTIONS="--max-old-space-size=3072"
export HUSKY=0
export NEXT_TELEMETRY_DISABLED=1
unset NODE_ENV

COMMIT="<product-sha>"   # prefer same as verified staging unless intentional upgrade

# Platform checkout on host (example path used in staging mission)
cd /home/asdev/asdev-platform

bash scripts/deploy/asdev-preflight.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$COMMIT"

bash scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$COMMIT" \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

bash scripts/deploy/asdev-healthcheck.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$COMMIT"
```

### Production rollback

```bash
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment production \
  --commit "$COMMIT" \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

---

## Success criteria

1. Production `current` points to new release id  
2. Healthcheck 200 on configured port/path  
3. `release.meta` present  
4. Staging remains intact (or intentionally left as previous)  
5. Public CRITICAL_SITE responds (after any edge config — separate if needed)

---

## Explicitly forbidden without extra approval

- DNS changes  
- SSL/certbot  
- Firewall / fail2ban  
- Database migration  
- Deleting old releases (needs `APPROVE_RELEASE_DELETE`)  
- nginx reload only if required for first-time site enable — prefer document and request if not already wired  

---

## Residual risks

| Risk | Mitigation |
|------|------------|
| 4G host OOM during build | swap + 3072 heap (proven in staging) |
| Missing production env secrets | Place under shared path before live; never commit |
| Port conflict with staging on 3000 | Production registry port is 3000 — **must** stop or rebind staging before/during prod if same host/port |
| Public edge not configured | Confirm nginx/site exists before calling “public go-live” |

### Port note (critical)

Staging currently uses `127.0.0.1:3000`. Registry production healthcheck is also port **3000**.  
Before production start on the same host, either:

- stop staging runtime, or  
- change staging to another port and update registry/staging process  

This must be resolved in the production runbook step, not after failure.

---

## After production success

- Record release in `docs/reports/critical-site-production-deploy-latest.md`  
- Update AGENT_MEMORY + queue  
- Consider monitoring timers only with `APPROVE_MONITORING_LIVE_TIMERS`
