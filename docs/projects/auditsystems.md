# AuditSystems — ASDEV Audit Platform

**Role:** Primary revenue product  
**Status:** Live / focus  
**Domain:** https://audit.alirezasafaeisystems.ir/  
**Repository:** https://github.com/alirezasafaei-dev/auditsystems  
**Local path:** `sites/live/auditsystems`

---

## Purpose

Turn technical website problems into trusted, actionable audit reports and paid conversion paths.

## Supports ASDEV goals

1. More submitted audits
2. Better and more trusted reports
3. Paid users and agency contacts
4. Production reliability (worker, queue, reports)
5. Lower audit execution cost

## Current capabilities

- PostgreSQL-backed job queue and worker
- Provider adapters (defaults to MOCK; production payment unverified)
- Public sample report page (credible anonymized report)
- Live at `audit.alirezasafaeisystems.ir`

## Next priorities

1. Finalize productized Audit offer (scope, pricing policy) — blocked on owner decision
2. Activate one real payment path with verified callback
3. End-to-end audit flow verification with CSRF/session bootstrap
4. Conversion funnel reporting (E3-04)

## Links

- [Launch checklist (migrated)](../../archive/migrated-from-meta-repo.md#auditsystems-launch)
- [Master roadmap](../strategy/ASDEV_AUDIT_MASTER_ROADMAP.md)
- Product docs: `sites/live/auditsystems/DOCUMENTATION.md`