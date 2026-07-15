# Release #103 Production Closure

**Status:** `DEPLOYED`  
**Deployment completed:** 2026-07-15T21:07:00Z  
**Closure recorded:** 2026-07-16  
**Production mutation:** Authorized and completed

This document is the immutable operational summary for Release #103. It records what was approved, what was deployed, the verification evidence, the accepted risks, and the work that remains outside this release.

## Release identity

| Component | Frozen source SHA | Release ID | Runtime |
|---|---|---|---|
| AuditSystems | `d55312543ef74b003aeac6aa560980e78b876e57` | `20260715T204648Z-d5531254` | PM2: `auditsystems-web`, `auditsystems-worker`; host port `3012` |
| ASDEV mother / portfolio | `3f7dfde370eb025960aa5397d0dded15affc4d7d` | `20260715T210429Z-3f7dfde3` | PM2: `my-portfolio-production` |

The mother repository may advance after the release because automation-only status reports are synchronized to `main`. Those later commits do not change the frozen Release #103 identity above.

## Authorization

Production deployment was performed only after explicit owner authorization for the exact AuditSystems and mother SHAs, a defined UTC window, and rollback authorization.

Required token shape:

```text
APPROVED_PRODUCTION_RELEASE_<release> audit=<full-sha> mother=<full-sha> window=<UTC> rollback=AUTHORIZED
```

Never reuse an authorization token for a different SHA, release, or deployment window.

## Scope delivered

Release #103 was a security and operational hardening release. It intentionally contained no user-interface redesign.

- HMAC-signed unsubscribe tokens with domain separation.
- Production rate limiting changed to fail closed.
- Report password submission moved from URL parameters to a POST body.
- CSRF protection added to brand/settings mutations.
- Legacy unsubscribe tokens invalidated.
- Database dump removed from the repository working tree.
- Release-safety and CI guards added.
- Backup/restore scripts corrected for `DATABASE_URL` normalization.
- Phase 2 security evidence and Phase 3 PostgreSQL rehearsal evidence recorded.

## Pull requests included

### Mother repository

- [#109](https://github.com/alirezasafaei-dev/alirezasafaeisystems/pull/109) — CI bootstrap.
- [#115](https://github.com/alirezasafaei-dev/alirezasafaeisystems/pull/115) — real worker contract and acceptance.
- [#116](https://github.com/alirezasafaei-dev/alirezasafaeisystems/pull/116) — Phase 2 and Phase 3 evidence.

### AuditSystems repository

- [#46](https://github.com/alirezasafaei-dev/auditsystems/pull/46) — security hardening.
- [#47](https://github.com/alirezasafaei-dev/auditsystems/pull/47) — backup/restore safety.
- [#48](https://github.com/alirezasafaei-dev/auditsystems/pull/48) — HMAC unsubscribe remediation.
- [#49](https://github.com/alirezasafaei-dev/auditsystems/pull/49) — findings F-001 through F-006 remediation.
- [#50](https://github.com/alirezasafaei-dev/auditsystems/pull/50) — final remediation.
- [#51](https://github.com/alirezasafaei-dev/auditsystems/pull/51) — CI guard.

## Release gates

| Gate | Result | Evidence summary |
|---|---|---|
| Phase 0 — GitHub truth | PASS | Required PRs merged and exact SHAs frozen |
| Phase 1 — quality | PASS | Mother: 203/203 tests; AuditSystems: 686/686 tests; lint, typecheck, build, and secret scan passed |
| Phase 2 — security | PASS | F-001 through F-006 reviewed and remediated or explicitly accepted |
| Phase 3 — PostgreSQL 16 rehearsal | PASS | Clean/idempotent migrations, verified backup, disposable restore, table/migration/connectivity checks |
| Production authorization | PASS | Exact-SHA owner token and rollback authorization verified |
| Production deployment | PASS | Both immutable releases activated and health checks passed |

Evidence digests recorded by the release process:

- Phase 2 SHA-256: `7523032f4289556c44149fb8fe68ce07728fc769eba1647e9dafaee55ce9f58d`
- Phase 3 SHA-256: `86f696bb4fe9eabe429d4468c4d1f28f64931da6893b5904b60adc74312bf7a7`

## Production verification

| Check | Expected | Release #103 result |
|---|---:|---|
| `https://audit.alirezasafaeisystems.ir/api/ready` | HTTP 200; database and Redis ready | PASS |
| `https://audit.alirezasafaeisystems.ir/api/health` | HTTP 200; status OK | PASS |
| `https://audit.alirezasafaeisystems.ir/qualification` | HTTP 200 | PASS |
| `https://audit.alirezasafaeisystems.ir/sample-report` | HTTP 200 | PASS |
| `https://alirezasafaeisystems.ir/` | HTTP 200 | PASS |
| Audit current symlink | `20260715T204648Z-d5531254` | PASS |
| Mother current symlink | `20260715T210429Z-3f7dfde3` | PASS |

The AuditSystems readiness response confirmed both database and Redis connectivity. The deployed AuditSystems artifact contained the expected HMAC implementation. Visual appearance was expected to remain unchanged because the release scope was security and operations.

## Owner decisions and accepted risk

The following decisions apply only to Release #103:

1. **F-003 / admin-session revocation:** accepted with a maximum 24-hour session lifetime. Emergency revoke-all is available by rotating `ADMIN_SESSION_SECRET`. Individual revocation remains follow-up work.
2. **Legacy unsubscribe tokens:** intentionally invalidated; users must use newly generated links.
3. **Dump history purge:** deferred only because the removed rehearsal dump was classified as disposable and secret-free.
4. **Phase 3 rerun:** not required after the final remediation range because no database migration, backup/restore, deployment, or schema code changed.

These decisions are not standing waivers for later releases.

## Required follow-up before the next production release

| Priority | Work item | Tracking |
|---|---|---|
| P1 | Make the database-dump guard classify each file independently and enforce it in required CI | [AuditSystems #52](https://github.com/alirezasafaei-dev/auditsystems/issues/52) |
| P1 | Add individual admin-session revocation and revisit the Release #103 risk acceptance | [AuditSystems #53](https://github.com/alirezasafaei-dev/auditsystems/issues/53) |

DevAtlas availability is not part of Release #103 and any existing DevAtlas 502 response must not be attributed to this deployment.

## Closure

- Release #103 is deployed and healthy.
- No release blocker remains open.
- Rollback remains authorized for a production incident.
- Issues #52 and #53 remain intentionally open as post-release P1 work.
- Future deployments must follow [RELEASE_RUNBOOK.md](RELEASE_RUNBOOK.md) and use newly frozen SHAs and a new owner authorization.
