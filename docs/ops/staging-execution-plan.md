# CRITICAL_SITE Staging Execution Plan

**Site:** CRITICAL_SITE (`persiantoolbox.ir` / registry `persiantoolbox`)  
**Last Updated:** 2026-07-08  
**Live deploy status:** NOT EXECUTED — requires owner phrase

---

## Gate

```text
APPROVE_PHASE_2_STAGING_DEPLOY
```

Without this exact phrase, only dry-run/check modes are allowed.

---

## Architecture facts

| Fact | Detail |
|------|--------|
| Product repo | Separate: `alirezasafaei-dev/persiantoolbox` (public) |
| Mother repo | `alirezasafaei-dev/alirezasafaeisystems` (registry + deploy engine) |
| Registry staging base | `/srv/asdev/sites/persiantoolbox-staging` (IRAN_PROD) |
| Registry prod base | `/srv/asdev/sites/persiantoolbox` (IRAN_PROD) |
| Local source layout | `sites/live/persiantoolbox` (prepared, gitignored) |

---

## Phase 0 — Owner PC / AUTOMATION_HOST prep (no IRAN_PROD mutation)

```bash
cd /home/dev13/ASDEV
git checkout main && git pull --ff-only

# Prepare CRITICAL_SITE source (local only)
bash scripts/deploy/asdev-prepare-site-source.sh --site persiantoolbox --dry-run
bash scripts/deploy/asdev-prepare-site-source.sh --site persiantoolbox --apply

# Local CI Router equivalent (when GHA is red)
bash scripts/ops/run-ci-router-local.sh origin/main

# Dry-runs (approval-free)
COMMIT="$(git -C sites/live/persiantoolbox rev-parse HEAD)"
bash scripts/ops/validate-registry-schema.sh
bash scripts/deploy/asdev-preflight.sh --site persiantoolbox --environment staging --commit "$COMMIT" --dry-run
bash scripts/deploy/asdev-deploy.sh --site persiantoolbox --environment staging --commit "$COMMIT" --dry-run
bash scripts/deploy/asdev-healthcheck.sh --site persiantoolbox --environment staging --commit "$COMMIT" --dry-run
bash scripts/deploy/asdev-rollback.sh --site persiantoolbox --environment staging --commit "$COMMIT" --dry-run
bash scripts/ops/check-critical-site-protection.sh
```

---

## Phase 1 — Live staging (ONLY after phrase)

**Execute on the host that can write IRAN_PROD staging paths** (typically AUTOMATION_HOST with approved remote path, or on IRAN_PROD itself). This plan does **not** grant that access.

```bash
# Exact command template — do not run until phrase granted
COMMIT="<persiantoolbox-repo-sha>"

./scripts/deploy/asdev-preflight.sh \
  --site persiantoolbox \
  --environment staging \
  --commit "$COMMIT"

./scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment staging \
  --commit "$COMMIT" \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY

./scripts/deploy/asdev-healthcheck.sh \
  --site persiantoolbox \
  --environment staging \
  --commit "$COMMIT"
```

### Rollback (staging)

```bash
./scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment staging \
  --commit "$COMMIT" \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Success criteria (staging)

1. `current` symlink under staging base points to new release id  
2. Healthcheck local-port `/api/ready` returns success  
3. `release.meta` present in release dir  
4. `previous-release` pointer recorded when prior release existed  
5. No production symlink touched  

---

## Explicitly forbidden in this plan

- Production deploy  
- nginx reload / pm2 production restart without separate approval  
- Database migration  
- DNS / SSL changes  
- Deleting releases  

---

## After successful staging

Next production gate (separate):

```text
APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY
```
