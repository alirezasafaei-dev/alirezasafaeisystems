# Production Readiness Gate — CRITICAL_SITE

**Last Updated:** 2026-07-08  
**Purpose:** Checklist before `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` is meaningful

---

## Gate result fields

Mark each: PASS / FAIL / N/A / BLOCKED

---

## 1. Preflight checks

- [ ] Registry schema validates (21 cols, ports isolated)
- [ ] `asdev-preflight.sh --environment production --dry-run` PASS
- [ ] Source ready (`asdev-prepare-site-source` or IRAN checkout)
- [ ] No deploy lock on prod_base
- [ ] Disk free ≥ 1GB on deploy filesystem

```bash
bash scripts/ops/validate-registry-schema.sh
bash scripts/ops/check-port-isolation.sh
bash scripts/deploy/asdev-preflight.sh --site persiantoolbox --environment production --commit <sha> --dry-run
```

---

## 2. Backup verification

- [ ] Onsite backup path known / recent backup exists (or accepted risk recorded)
- [ ] Restore drill doc reviewed (`docs/ops/BACKUP_RESTORE_DRILL.md`)
- [ ] Shared path will not be wiped by deploy (rsync excludes shared)

---

## 3. Staging verification

- [ ] Staging LIVE_OK (ready/health 200)
- [ ] Staging release id recorded
- [ ] Staging on **registry staging_port (3200)** after rebind — or temporary legacy note accepted
- [ ] No production current symlink yet (first prod) OR previous prod known

```bash
ASDEV_VPS_ENV_FILE=<private> bash scripts/ops/asdev-remote-status.sh
```

---

## 4. Port validation

- [ ] Registry: prod_port=3100, staging_port=3200 for CRITICAL_SITE
- [ ] prod_port ≠ staging_port (validator PASS)
- [ ] Production target port free (or owned by previous prod runtime)
- [ ] Staging not listening on production port

```bash
bash scripts/ops/check-port-isolation.sh --live
```

---

## 5. Nginx validation

- [ ] Target upstream for production documented (3100)
- [ ] Staging upstream documented (3200) if public staging exists
- [ ] **No nginx reload performed in this gate**
- [ ] Owner knows whether edge change is required for public go-live

---

## 6. PM2 / process ownership

- [ ] Production start method: `node-standalone` via deploy engine (not ad-hoc)
- [ ] Pid file location: `<prod_base>/asdev-runtime.pid`
- [ ] PM2 not required for CRITICAL_SITE under current engine
- [ ] No accidental `pm2 delete` of unrelated processes

---

## 7. Health validation

- [ ] Health path `/api/ready` returns 200 after activation
- [ ] Deploy engine rolls back symlink if health fails
- [ ] Healthcheck script dry-run/check modes work

---

## 8. Rollback verification

- [ ] Rollback dry-run rehearsal PASS
- [ ] previous-release pointer mechanism understood
- [ ] First production deploy: no previous release → rollback limitation accepted

```bash
bash scripts/ops/rehearse-rollback-dry-run.sh --site persiantoolbox --environment production
```

---

## 9. Post-deploy monitoring

- [ ] Monitoring foundation scripts present
- [ ] Plan for post-deploy HTTP check (manual or timer after separate approval)
- [ ] Alert channel known (no secrets in git)

---

## 10. Safety guards in engine

- [ ] Immutable releases under `releases/`
- [ ] Only `current` symlink changes at cutover
- [ ] No arbitrary eval in asdev-deploy path
- [ ] Migration changes blocked without `APPROVE_CRITICAL_SITE_MIGRATION`
- [ ] Port collision blocked

---

## Overall gate

| Status | Meaning |
|--------|---------|
| **PASS** | Phrase may be requested |
| **PASS_WITH_WARNINGS** | Phrase possible if warnings accepted |
| **FAIL** | Do not approve production |

### Current assessment (automated hardening cycle)

| Item | Status |
|------|--------|
| Registry isolation | PASS (3100/3200) |
| Engine guards | PASS |
| Staging live | PASS (legacy port 3000 until rebind) |
| Staging rebind to 3200 | **PENDING** (needs staging redeploy) |
| Nginx applied | N/A / not applied |
| Production live | NOT STARTED |

**Gate: PASS_WITH_WARNINGS** — ready to request production phrase after staging rebind to 3200 (recommended) or explicit acceptance of cutover that stops legacy :3000 first.
