# NEXT 7 DAYS — ASDEV Roadmap

**Period:** 2026-07-08 to 2026-07-15  
**Source of Truth:** GitHub

---

## 1. CRITICAL_SITE staging → verify → production gate

- [x] Registry + deploy engine dry-run (preflight)
- [ ] Ensure source/artifact on executor
- [ ] Live staging after `APPROVE_PHASE_2_STAGING_DEPLOY`
- [ ] Staging smoke + healthcheck
- [ ] Production only after separate `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`

---

## 2. AUTOMATION_HOST as stable executor

- [x] Classify PM2 idle / legacy Docker as non-blocking
- [x] Tooling readiness checker script
- [ ] Optional: self-hosted runner (only if needed)
- [ ] Optional: ASDEV PM2 ecosystem if long-running worker required

---

## 3. CI usefulness

- [x] Classify multi-workflow fail as infra-class
- [ ] When GHA recovers: confirm CI Router green on mission PR
- [ ] Do **not** invest in legacy app workflow thrash this week unless blocking merge policy

---

## 4. Monitoring foundation → optional live timers

- [x] HTTP / host / disk / backup-freshness scripts
- [x] Runbook + alerting policy
- [ ] Live timers only with `APPROVE_MONITORING_LIVE_TIMERS`

---

## 5. Non-critical quarantine (plan only)

- [x] Current plan document
- [ ] IRAN_PROD inventory (read-only) when scheduled
- [ ] Live quarantine only with explicit future approval

---

## Validation standard

- Registry schema green
- Dangerous-pattern check green
- Deploy/rollback/healthcheck dry-run green for CRITICAL_SITE
- No secrets in git

---

## Stop conditions

- Staging/production without exact approval phrase
- Destructive Docker/DB/firewall actions
- GitHub API spam / mass workflow reruns
