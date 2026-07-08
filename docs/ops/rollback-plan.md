# Rollback Plan — CRITICAL_SITE

**Last Updated:** 2026-07-08  
**Site:** persiantoolbox (CRITICAL_SITE)  
**Strategy:** symlink swap only (no file copy)

---

## Principles

1. Releases under `releases/` are **immutable**  
2. Rollback only moves `current` symlink to a previous release id  
3. Healthcheck runs **after** symlink swap  
4. Protected site: never delete releases by default  

---

## Production paths

| Item | Path |
|------|------|
| Base | `/srv/asdev/sites/persiantoolbox` |
| Current | `/srv/asdev/sites/persiantoolbox/current` |
| Releases | `/srv/asdev/sites/persiantoolbox/releases/<release_id>` |
| Previous pointer | `/srv/asdev/sites/persiantoolbox/previous-release` |
| Runtime pid | `/srv/asdev/sites/persiantoolbox/asdev-runtime.pid` |
| Port | **3100** |

---

## When to rollback

- Post-activation healthcheck fails (automatic in `asdev-deploy.sh`)  
- Operator observes bad public/local health after go-live  
- Owner requests revert  

---

## Operator commands (production)

**Requires:** `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` for live rollback.

```bash
export PATH="/home/asdev/node/bin:$PATH"
cd /home/asdev/asdev-platform   # or synced ASDEV checkout on host

# Check available releases (no mutation)
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment production \
  --commit <audit-sha> \
  --check

# Live rollback
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment production \
  --commit <audit-sha> \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY

# Optional explicit target
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment production \
  --commit <audit-sha> \
  --target-version <release_id> \
  --approve-phrase APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```

---

## Deterministic target selection

1. If `--target-version` set → use it  
2. Else if `previous-release` file exists → use that id  
3. Else newest non-current directory under `releases/`  
4. If none → **fail** (expected on first production deploy)

---

## After rollback

1. Confirm `current` points to intended release  
2. Confirm process on port 3100  
3. `curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3100/api/ready` → 200  
4. Record incident if user-facing  

---

## Staging rollback

```bash
bash scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment staging \
  --commit <audit-sha> \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY
```

Staging port target: **3200** (registry). Live legacy staging may still be on **3000** until rebind.

---

## First production deploy caveat

No previous production release exists today (`prod_current=no`, `no_prod_releases`).  
First successful production deploy creates the only release; automatic rollback to “previous” is unavailable until a second release exists.  
Mitigation: keep staging verified (`fcc7192…`) and build/artifact confidence high before first prod cutover.

---

## Related

- Incident: `docs/ops/INCIDENT_RUNBOOK.md`  
- Execution: `docs/ops/production-execution-plan.md`  
- Readiness: `docs/ops/production-readiness-gate.md`  
