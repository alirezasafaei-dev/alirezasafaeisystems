# ASDEV Goals + Roadmap — Operating Doctrine

**Status:** ACTIVE — Primary operating roadmap for all ASDEV agents
**Date:** 2026-07-08
**Commander:** MiMo (ASDEV Autopilot Governor)

---

# ASDEV North Star

ASDEV must become a real autonomous product-building and product-operations system.

The goal is not just automation scripts.
The goal is a live, reliable, self-improving product system that can:

1. Keep the live product healthy.
2. Detect blockers automatically.
3. Choose the next highest-value sprint when idle.
4. Assign work to the right agent.
5. Create focused PRs.
6. Run tests and validation.
7. Merge safe validated work.
8. Deploy only when gates pass.
9. Audit the live site.
10. Improve growth, UX, SEO, reliability, and conversion continuously.
11. Report everything to Issue #45 without owner copy-paste.

---

# Chain of Command

## Owner
- Sets high-level goals.
- Gives explicit approval for sensitive operations.
- Does not manage daily tasks.
- Does not copy reports between tools.

## MiMo (Commander / Governor / Brain)
- Owns roadmap, backlog, sprint planning, agent assignment, PR coordination, reports.
- Detects idle state and starts the next sprint automatically.
- Posts all final reports to Issue #45.

## Hermes/VPS (Scheduler / Monitor)
- Runs periodic checks.
- Watches Issue #45.
- Checks health, timers, PR state, deploy status, blockers.
- Reports state changes.

## OpenCode (Worker)
- Small and medium implementation tasks.
- Patches, tests, docs, scripts, repetitive fixes.
- No risky merge or deploy authority.

## Codex (Critical Reviewer)
- Reviews security, deploy, schema, auth, billing, database, production-impacting changes.
- Can block unsafe work.

## Grok (Scout / Attacker)
- Finds hidden risks, edge cases, growth opportunities, architecture weaknesses.
- Produces aggressive review and alternative plans.

## Telegram Bot (Status UI)
- Must show `/status`, `/prs`, `/blockers`, `/last`.
- No execution authority unless Phase 2 explicitly approved.

## ChatGPT (External Auditor)
- Hourly monitor.
- Strategic correction layer.
- Not the core brain.

## Issue #45 (Command Center)
- Single command bus.
- Single report bus.
- Single source of truth for automation state.

---

# Core Operating Rule

When there are:
- no blockers;
- no open PRs;
- healthy live site;
- healthy VPS timer;
- healthy bot;
- no failed tests;

then ASDEV is not "done". It must automatically start the next highest-value sprint.

---

# Sprint Priority Order

1. Broken control plane / automation bugs.
2. Live health and monitoring.
3. Backup and restore readiness.
4. Security hardening.
5. Performance and speed.
6. Live UX audit fixes.
7. SEO and conversion.
8. Test coverage.
9. Documentation cleanup.
10. Growth backlog execution.
11. Product feature improvements.
12. Refactor and maintainability.
13. Incident simulation and rollback drills.
14. Analytics and decision dashboards.

---

# Roadmap

## Phase 0 — Control Plane Stability ✅ COMPLETE
- Fix Telegram bot repo slug bug ✅
- Fix /status, /prs, /blockers, /last ✅
- Ensure Issue #45 latest comment fetched correctly ✅
- Add dry-run tests for bot commands ✅
- Confirm VPS timer active ✅
- Confirm no duplicate loops ✅
- Confirm all reports go to Issue #45 ✅

## Phase 1 — Autopilot Governor Formalization ✅ COMPLETE
- AUTOPILOT_GOVERNOR.md ✅
- AGENT_CHAIN_OF_COMMAND.md ✅
- IDLE_TO_NEXT_SPRINT_POLICY.md ✅
- AUTONOMOUS_SPRINT_TYPES.md ✅
- Chain of command documented ✅
- Idle detection defined ✅
- Sprint selection defined ✅
- Merge/deploy policy defined ✅

## Phase 2 — Live Reliability
- Synthetic route checks
- Uptime evidence
- Healthcheck script
- Error log review
- Alert plan
- Incident runbook
- Rollback drill documentation

## Phase 3 — Backup and Restore Readiness
- Document backup method
- Verify backup schedule
- Create restore runbook
- Non-destructive restore validation

## Phase 4 — Security Hardening
- Security header audit
- Check exposed stack traces
- Check public admin routes
- Check secret leakage risk
- Check GitHub token scopes

## Phase 5 — Performance Budget
- Measure key route response times
- Define performance budget
- Create issues for slow routes

## Phase 6 — Live UX Audit
- Audit homepage first impression
- Audit CTA clarity
- Audit error/empty states
- Audit mobile layout
- Audit report readability

## Phase 7 — SEO and Conversion Basics
- Check page titles, meta descriptions
- Check robots/sitemap
- Check canonical URLs, OpenGraph
- Check conversion events

## Phase 8 — Test Coverage Expansion
- Add tests for bot repo config
- Add tests for GitHub API helpers
- Add smoke tests for public routes
- Add tests for analytics events

## Phase 9 — Growth Backlog Execution
- Prioritize 7-day growth backlog
- Build high-value landing improvements
- Add trust signals
- Improve audit-readiness flow

## Phase 10 — Product Feature Maturity
- Dynamic scoring engine
- Audit history
- Better recommendations
- Export/report sharing
- Organization dashboard
- Admin reporting

---

# Merge Policy

Auto-merge allowed: docs-only, tests-only, bot fixes, monitoring scripts, read-only automation.
No auto-merge: deploy, auth, database, billing, schema, production runtime, broad PRs.

---

# Deploy Policy

Allowed only when: owner approval documented, build passes, tests pass, healthcheck passes, backup exists, no secrets exposed, no destructive DB action, post-deploy smoke tests pass.

---

# Safety Rules

Never: print secrets, commit .env, edit PersianToolbox without approval, use paid API by default, perform destructive DB work, merge risky changes casually.

Always: create focused PRs, validate before merge, report to Issue #45, keep owner out of routine coordination.
