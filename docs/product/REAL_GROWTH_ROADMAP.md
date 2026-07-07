# ASDEV Audit — Product Growth Roadmap

**Last updated:** 2026-07-07
**Product:** ASDEV Audit Platform (`sites/live/auditsystems`)
**Status:** Live MVP → Scaling to revenue

---

## 1. Product Vision

ASDEV Audit is a website audit platform built for the Persian-speaking market. It checks websites for technical SEO, speed, security, UX, accessibility, and technical health, then produces a clear, actionable, sellable report.

**Core value proposition:** Submit a URL, get a professional audit report in minutes — not days.

**North star metric:** Completed audit reports that convert into a lead, signup, paid plan, or agency contact.

**Funnel:**
```
Visitor → Audit Request → Report → Lead/Signup → Paid Plan/Agency Contact → Retention
```

---

## 2. Target Users

| Segment | Need | Revenue path |
|---|---|---|
| **Business owners** | Know if their website is healthy | Free audit → Starter plan |
| **SEO specialists** | Audit clients at scale | Pro plan → Agency plan |
| **Agencies** | White-label reports for clients | Agency plan → Enterprise |
| **Developers** | Quick technical health check | Free audit → Pro plan |
| **E-commerce** | Speed and conversion optimization | Starter → Pro plan |

---

## 3. Milestones

### M0 — Infrastructure ✅

- PostgreSQL database with Prisma ORM
- Queue-based job processing (FOR UPDATE SKIP LOCKED)
- PM2 process management (web + worker)
- VPS deployment at `/var/www/asdev-audit-ir`, port 3010
- Health checks, readiness probes, Prometheus metrics

### M1 — Live MVP ✅

- Audit form with QUICK and DEEP modes
- 30+ finding codes across 6 categories
- Report page with token-based sharing
- PDF generation with RTL support
- Custom session-based auth (scrypt + HMAC cookies)
- Organization, project, and membership model
- Bilingual support (fa-IR / en-IR)

### M2 — Reliability ✅

- SSRF protection with DNS verification and private IP blocking
- Rate limiting (Upstash Redis or local Redis)
- CSRF protection and security headers (CSP, HSTS, X-Frame-Options)
- Account lockout after failed attempts
- Structured logging and observability
- Database backup and restore scripts

### M3 — Onboarding ✅

- Dashboard with projects, audits, billing
- Usage limits checking (canRunAudit, canCreateProject)
- Plan comparison and checkout flow
- Email verification flow
- Sample report for sales

### M4 — Analytics and Growth ✅

- Scoring system (0-100 with category breakdowns)
- Action plan generation (Quick Wins, Major Projects, Fill-ins, Thankless)
- Finding registry with 30+ documented finding codes
- Audit comparison and score trends
- Scheduled audits with cron runner
- CTA registry and UTM tracking

### M5 — Revenue (Active)

- Billing and subscription system (free/starter/pro/agency)
- Payment providers (Zarinpal, IdPay, PayPing, Mock)
- Invoice model and usage ledger
- Checkout flow and payment callbacks
- Upgrade/downgrade/cancel flows
- Monthly report generation
- Referral system

---

## 4. Success Metrics

| Metric | Target | Current |
|---|---|---|
| Uptime | 99.5% | Monitored via `/api/health` |
| Page load (TTFB) | < 2s | Measured via audit scanner |
| Login success rate | > 99% | Session-based auth |
| Audit creation rate | > 50/day | Queue-based processing |
| Report generation time | < 60s | Worker concurrency |
| Paid conversion rate | > 5% | Tracked via AuditLead |
| Monthly active users | 100+ | Dashboard tracking |

---

## 5. Product Modules

### 5.1 Auth Module

- **Files:** `src/lib/auth.ts`, `src/lib/emailVerification.ts`, `src/lib/account-lockout.ts`, `src/lib/passwordValidation.ts`
- **Features:** Custom session-based auth (scrypt + HMAC cookies), email verification, account lockout, password validation, session management
- **Cookie:** `saas_session` with 7-day expiry
- **API routes:** `src/app/api/auth/`

### 5.2 Dashboard Module

- **Files:** `src/app/app/` (dashboard pages), `src/lib/organization.ts`, `src/lib/usage.ts`
- **Features:** Projects, audits, billing, settings, team management
- **Routes:** `/app/` (dashboard), `/app/projects/`, `/app/billing/`, `/app/settings/`

### 5.3 Organization Module

- **Files:** `src/lib/organization.ts`, `src/lib/team-auth.ts`
- **Features:** Multi-tenant organizations, membership roles (OWNER/ADMIN/VIEWER), team invitations
- **Models:** Organization, Membership, TeamMemberInvite

### 5.4 Audit Flow Module

- **Files:** `src/lib/rules.ts`, `src/lib/extractResources.ts`, `src/lib/seo.ts`, `src/lib/types.ts`, `src/lib/validators.ts`
- **Features:** URL normalization, resource extraction via Cheerio, 30+ finding codes, SSRF protection
- **Worker:** `src/worker/audit.handler.ts`, `src/worker/queue.ts`, `src/worker/index.ts`
- **Queue:** PostgreSQL-based with FOR UPDATE SKIP LOCKED, exponential backoff retry

### 5.5 Report Module

- **Files:** `src/lib/scoring.ts`, `src/lib/summary.ts`, `src/lib/action-plan.ts`, `src/lib/reportShare.ts`, `src/lib/pdf.ts`
- **Features:** Scoring (0-100), executive summary, action plan, PDF generation, token-based sharing, view counting
- **Routes:** `/audit/r/[token]` (report page), `/api/pdf/` (PDF download)

### 5.6 Billing Module

- **Files:** `src/lib/plans.ts`, `src/lib/payments.ts`, `src/lib/subscription.ts`, `src/lib/billing-events.ts`, `src/lib/billing-auth.ts`
- **Plans:** Free, Starter (290K Toman), Pro (990K Toman), Agency (2.99M Toman)
- **Providers:** Zarinpal, IdPay, PayPing, Mock
- **Routes:** `/app/billing/`, `/api/billing/`, `/api/payments/`, `/api/checkout/`

### 5.7 Monitoring Module

- **Files:** `src/lib/health.ts`, `src/lib/metrics.ts`, `src/lib/observability.ts`, `src/lib/logger.ts`
- **Endpoints:** `/api/health`, `/api/ready`, `/api/metrics`
- **Features:** Database health, Redis health, structured logging, request tracking

---

## 6. Risk Map

| Risk | Severity | Mitigation | Status |
|---|---|---|---|
| **Secrets exposure** | CRITICAL | `.env` excluded from git, `.gitignore` enforced | Mitigated |
| **SSRF attacks** | HIGH | DNS verification, private IP blocking in `src/lib/validators.ts` | Mitigated |
| **SQL injection** | HIGH | Prisma parameterized queries, no raw SQL except queue | Mitigated |
| **Session hijacking** | MEDIUM | HMAC-signed tokens, 7-day expiry, IP hashing | Mitigated |
| **Rate limiting bypass** | MEDIUM | Upstash Redis or local Redis fallback | Mitigated |
| **Database failure** | HIGH | Daily backup scripts, restore procedures | Mitigated |
| **Worker crash** | MEDIUM | PM2 autorestart, max 10 restarts, 5s delay | Mitigated |
| **Build failure** | LOW | CI/CD validation, `pnpm check` gate | Mitigated |
| **Payment fraud** | MEDIUM | Provider verification, double-payment prevention | Mitigated |
| **UX gaps** | LOW | Error pages, loading states, bilingual support | Partially mitigated |

---

## 7. Roadmap Table

| # | Task | Category | Files | Value | Risk | Agent |
|---|---|---|---|---|---|---|
| 1 | Executive summary on reports | Report UX | `src/lib/summary.ts`, report page | HIGH | LOW | OpenCode |
| 2 | Email capture on reports | Conversion | `src/components/EmailCapture.tsx`, new API | HIGH | MEDIUM | OpenCode |
| 3 | Score trend chart | Retention | `src/components/ScoreTrend.tsx`, dashboard | MEDIUM | LOW | OpenCode |
| 4 | Audit comparison view | Retention | `src/lib/audit-comparison.ts`, new page | MEDIUM | LOW | OpenCode |
| 5 | Schedule UI page | Retention | `src/components/ScheduleManager.tsx`, new page | MEDIUM | LOW | MiMo |
| 6 | Dashboard usage stats widget | UX | Dashboard home page | MEDIUM | LOW | OpenCode |
| 7 | Error pages (404/403/500) | UX | `src/app/error.tsx`, `src/app/not-found.tsx` | MEDIUM | LOW | OpenCode |
| 8 | Report history page | UX | New dashboard page | MEDIUM | LOW | MiMo |
| 9 | Findings documentation | Documentation | `src/lib/FINDINGS.md`, finding-registry | MEDIUM | LOW | MiMo |
| 10 | Test fixtures for scoring | Quality | `src/fixtures/audit/`, scoring tests | MEDIUM | LOW | OpenCode |
| 11 | Billing event logging | Revenue | `src/lib/billing-events.ts`, new events | MEDIUM | LOW | MiMo |
| 12 | Checkout flow E2E tests | Revenue | `src/lib/__tests__/payment-flow.test.ts` | MEDIUM | LOW | OpenCode |
| 13 | CSP header hardening | Security | `next.config.ts` | HIGH | LOW | Codex |
| 14 | Backup automation | Ops | `scripts/backup-db.sh`, cron | HIGH | LOW | Hermes |
| 15 | Smoke test suite | Ops | `scripts/smoke-public-routes.sh` | HIGH | LOW | Hermes |
| 16 | Platform monitor | Ops | `scripts/monitor-platform.sh` | HIGH | LOW | Hermes |
| 17 | SEO content expansion | Growth | `src/content/`, landing pages | MEDIUM | LOW | MiMo |
| 18 | Agency landing page | Growth | `src/app/landing/agency/` | MEDIUM | LOW | OpenCode |
| 19 | Referral system | Growth | `src/lib/referral.ts`, dashboard | MEDIUM | MEDIUM | MiMo |
| 20 | Monthly report generation | Retention | `src/scripts/generate-monthly-reports.ts` | MEDIUM | LOW | MiMo |

---

## 8. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 16 (standalone output) |
| Runtime | React 19, TypeScript 6 |
| Database | PostgreSQL via Prisma 6.19 |
| Queue | PostgreSQL (FOR UPDATE SKIP LOCKED) |
| Auth | Custom scrypt + HMAC cookies |
| PDF | pdf-lib with RTL support |
| HTML parsing | Cheerio |
| Testing | Vitest 4.1 |
| Process mgmt | PM2 (ecosystem.config.cjs) |
| Payments | Zarinpal, IdPay, PayPing, Mock |
| Rate limiting | Upstash Redis or local Redis |
| Deployment | VPS at `/var/www/asdev-audit-ir`, port 3010 |

---

## 9. Environment Variables

Required (from `.env.example`):
- `DATABASE_URL` — PostgreSQL connection string
- `IP_HASH_SALT` — For anonymizing IP addresses
- `CSRF_SECRET` — CSRF token signing
- `SESSION_SECRET` — Session token signing
- `DOWNLOAD_TOKEN_SECRET` — PDF download tokens
- `ADMIN_SESSION_SECRET` — Admin panel sessions

Optional:
- `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` — Distributed rate limiting
- `REDIS_URL` — Local Redis fallback
- `ZARINPAL_MERCHANT_ID` / `PAYPING_API_KEY` / `IDPAY_API_KEY` — Payment providers
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID` — Analytics

---

## 10. Quality Gates

Before any deployment:

```bash
pnpm lint          # ESLint, zero warnings
pnpm typecheck     # TypeScript strict
pnpm test          # 589+ tests passing
pnpm build         # Next.js production build
```

Full quality gate:
```bash
pnpm check         # lint + typecheck + test + build
```
