# ASDEV Idle-to-Next-Sprint Policy

**Status:** Active
**Date:** 2026-07-08

## Idle Detection

System is IDLE when ALL are true:
- No open PRs requiring action (blocked PRs don't count)
- No failing tests
- No active blockers
- Health checks green (live site 200, VPS timer active, bot active)
- No pending owner approvals for next action

## Sprint Selection

When idle, MiMo selects the next sprint from this priority list:

| Priority | Category | Example Tasks |
|---|---|---|
| 1 | Fix broken automation | Bot failures, timer issues, command bus gaps |
| 2 | Production health | Monitoring, alerting, health checks |
| 3 | Backup/restore | Backup verification, restore drills |
| 4 | Security hardening | Headers, CSP nonces, auth hardening |
| 5 | Performance | TTFB optimization, caching, CDN |
| 6 | UX/live audit | Error states, empty states, mobile |
| 7 | SEO/conversion | Titles, schemas, CTAs, onboarding |
| 8 | Test coverage | Missing tests, regression coverage |
| 9 | Documentation | Runbooks, API docs, guides |
| 10 | Growth backlog | 7-day growth tasks |

## Sprint Format

Each sprint must include:
- Goal (one sentence)
- Why now (business justification)
- Task list (3-8 tasks)
- Assigned agents
- Files likely touched
- Validation commands
- Risk level (low/medium/high)
- Merge policy (auto/manual)
- Deploy policy (yes/no)
- Rollback plan
- Final report format

## Execution Rules

1. MiMo selects sprint from priority list
2. MiMo creates tasks in Issue #45
3. MiMo assigns to agents
4. Agents execute and report
5. MiMo validates
6. MiMo merges safe PRs
7. MiMo deploys if gates pass
8. MiMo posts final report
9. MiMo checks if idle → repeat

## Stop Conditions

Stop and wait for owner if:
- Deploy requires owner approval
- Schema migration required
- Billing/payment changes needed
- PersianToolbox edit requested
- Secret exposure risk
- Production incident
