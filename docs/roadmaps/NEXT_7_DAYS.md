# NEXT 7 DAYS — ASDEV Roadmap

**Period:** 2026-07-08 to 2026-07-15
**Source of Truth:** GitHub

---

## 1. CRITICAL_SITE Stabilization

- Verify live site health (https://alirezasafaeisystems.ir/)
- Run synthetic route checks
- Verify uptime evidence
- Create healthcheck script
- Review error logs
- Document incident runbook

**Validation:** Healthcheck passes, no critical errors in logs, all routes respond.

---

## 2. ASDEV Root Rename

- Audit current ASDEV directory structure
- Define clean naming conventions
- Update all internal references
- Verify no broken links or imports
- Update docs to reflect new structure

**Validation:** `pnpm build` succeeds, all docs links resolve.

---

## 3. Deploy Engine Correction

- Review current deploy scripts
- Fix any deploy pipeline issues
- Add validation gates to deploy process
- Ensure deploy only happens with owner approval
- Test deploy flow in dry-run mode

**Validation:** Deploy script runs in dry-run without errors, validation gates present.

---

## 4. Staging Deploy

- Set up staging environment configuration
- Create staging deploy workflow
- Deploy to staging first, verify
- Run smoke tests on staging
- Get owner approval for production deploy

**Validation:** Staging site responds, smoke tests pass, owner approves production.

---

## 5. Monitoring

- Create monitoring docs (ASDEV-BW03)
- Define alert thresholds
- Set up synthetic monitoring templates
- Create alert notification plan
- Document escalation procedures

**Validation:** Monitoring docs complete, alert thresholds defined, templates created.

---

## 6. Quarantine Preparation

- Review quarantined features (PR-D, PR-E)
- Document what's quarantined and why
- Define criteria for un-quarantine
- Create testing plan for quarantined features
- Schedule owner review for quarantine decisions

**Validation:** Quarantine inventory complete, un-quarantine criteria defined.

---

## Task Priority

| Priority | Task | Risk | Approval |
|---|---|---|---|
| 1 | CRITICAL_SITE stabilization | low | auto |
| 2 | Monitoring prep | low | auto |
| 3 | Deploy engine correction | medium | owner |
| 4 | Staging deploy | medium | owner |
| 5 | ASDEV root rename | low | auto |
| 6 | Quarantine preparation | low | auto |

---

## Success Criteria

By end of 7 days:
- Live site health verified and monitored
- Deploy pipeline corrected and tested
- Staging environment operational
- Monitoring templates ready
- Quarantine inventory documented
