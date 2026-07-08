# CRITICAL_SITE Staging Readiness Report

**Date:** 2026-07-08
**Site:** CRITICAL_SITE (persiantoolbox.ir)
**Status:** READY (pending AUTOMATION_HOST audit)

---

## Registry Entry

| Field | Value |
|-------|-------|
| site_id | persiantoolbox |
| display_name | PersianToolbox |
| priority | 1 |
| protected | true |
| repo_path | sites/live/persiantoolbox |
| artifact_path | artifacts/releases/persiantoolbox |
| prod_base | /srv/asdev/sites/persiantoolbox |
| staging_base | /srv/asdev/sites/persiantoolbox-staging |
| shared_path | /srv/asdev/sites/persiantoolbox/shared |
| healthcheck_mode | local-port |
| healthcheck_port | 3000 |
| healthcheck_path | /api/ready |
| runtime | node |
| process_names | persiantoolbox |
| build_command_id | node-pnpm-build |
| start_command_id | node-standalone |
| deploy_strategy | symlink |
| rollback_strategy | symlink |

---

## Checklist

- [x] Deploy registry entry exists
- [x] staging_base defined
- [x] prod_base defined
- [x] protected=true
- [x] healthcheck_mode defined (local-port)
- [x] healthcheck_port defined (3000)
- [x] healthcheck_path defined (/api/ready)
- [x] Deploy scripts exist (asdev-deploy.sh, asdev-healthcheck.sh, etc.)
- [x] Rollback script exists (asdev-rollback.sh)
- [x] Protection guard exists (check-critical-site-protection.sh)
- [x] Registry validates (20 columns)
- [x] PR #71 merged to main
- [ ] AUTOMATION_HOST readiness (pending audit)

---

## Required Approval Phrase

```bash
APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Staging Command (after approval)

```bash
./scripts/deploy/asdev-deploy.sh \
  --site persiantoolbox \
  --environment staging \
  --commit <commit-sha> \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Rollback Command (if needed)

```bash
./scripts/deploy/asdev-rollback.sh \
  --site persiantoolbox \
  --environment staging \
  --approve-phrase APPROVE_PHASE_2_STAGING_DEPLOY
```

---

## Preconditions for Staging

1. ✅ OWNER_PC synced to main
2. ⏳ AUTOMATION_HOST readiness (pending audit)
3. ✅ Deploy scripts exist on main
4. ✅ Registry validates
5. ✅ Protection guard passes
6. ✅ No server mutation has occurred yet

---

## Risks

- AUTOMATION_HOST status unknown (audit pending)
- GitHub Actions infrastructure issues (CI failing)
- Staging deploy requires explicit owner approval

---

## Conclusion

**CRITICAL_SITE is ready for staging preflight.** All local checks pass. Staging can proceed once:
1. AUTOMATION_HOST audit completes
2. Owner provides `APPROVE_PHASE_2_STAGING_DEPLOY`
