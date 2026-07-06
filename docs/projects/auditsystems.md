# AuditSystems — ASDEV Audit Platform

**Role:** Primary revenue product  
**Status:** Live / focus  
**Domain:** https://audit.alirezasafaeisystems.ir/  
**Repository:** https://github.com/alirezasafaei-dev/auditsystems  
**Local path:** `sites/live/auditsystems`

---

## Case study — ASDEV Audit Platform

### Problem

Website owners need to understand technical SEO, performance, and security issues in plain language — with a credible report format before they pay or engage a team.

### Constraints

- Must not fake customer metrics or rankings
- Worker/queue reliability required for trust
- Billing not yet activated (out of Phase 1 scope)
- Bilingual FA/EN surfaces with consistent conversion tracking

### Architecture / approach

- PostgreSQL-backed job queue + worker for audit runs
- Provider adapters (MOCK default in dev)
- Shared sample report module (`src/lib/sample-report/`)
- CTA registry + `AuditCtaLink` for `seo_cta_click` attribution
- IntentRouter adapter for legacy layout with unified analytics
- Public routes: `/audit`, `/sample-report`, `/pricing` (+ `/en/*`)

### Production evidence

| Item | Status |
|---|---|
| Live domain | `audit.alirezasafaeisystems.ir` |
| Sample report (FA/EN) | `/sample-report`, `/en/sample-report` |
| CTA registry | `src/lib/audit-cta-registry.ts` |
| Public route smoke script | `scripts/smoke-public-routes.sh` |
| CSRF on audit submit | FA + EN audit pages |

### What was measured

- Smoke script covers homepage, audit, pricing, sample-report (FA/EN)
- Conversion funnel reporting (E3-04): **Evidence pending**

### What is not claimed

- No verified paid subscriber count
- No customer logos or named case studies on live marketing pages
- No guaranteed audit completion time SLA on public copy
- Payment path not verified in production

### Links

- Live: https://audit.alirezasafaeisystems.ir/
- Sample report: https://audit.alirezasafaeisystems.ir/sample-report
- Repo: https://github.com/alirezasafaei-dev/auditsystems

### CTA

Start free assessment → `/audit` · View sample → `/sample-report` · Professional review → portfolio `/qualification`

---

## Next priorities (product)

1. Activate one real payment path (owner decision — post Phase 1)
2. Conversion funnel reporting (E3-04)
3. Scheduled audits and retention (Phase 1 roadmap item 7)

## Links

- [Master roadmap](../strategy/ASDEV_AUDIT_MASTER_ROADMAP.md)
- [CTA registry (product)](https://github.com/alirezasafaei-dev/auditsystems/blob/main/docs/CTA_REGISTRY.md)
- Product docs: `sites/live/auditsystems/DOCUMENTATION.md`