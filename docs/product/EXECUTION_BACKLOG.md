# ASDEV Audit — Execution Backlog

**Last updated:** 2026-07-07
**Product:** ASDEV Audit Platform
**Total tasks:** 20 prioritized across 8 categories

---

## Legend

- **Priority:** P0 (launch blocker) → P1 (critical) → P2 (important) → P3 (nice-to-have)
- **Status:** TODO | IN_PROGRESS | DONE
- **Agent:** MiMo | OpenCode | Codex | Grok | Hermes

---

## Category 1: Launch Blockers

### Task 1.1 — Verify Usage Limit Enforcement on All Paths

- **Priority:** P0
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/app/api/audit/runs/` (audit creation endpoint)
  - `src/app/api/projects/` (project creation endpoint)
  - `src/lib/usage.ts` (canRunAudit, canCreateProject)
- **Acceptance criteria:**
  - Audit API returns 403 with upgrade link when limit reached
  - Project creation returns 403 with upgrade link when limit reached
  - No bypass possible through direct API calls
  - Error pages show current usage and upgrade option
- **Validation:**
  ```bash
  pnpm test -- --grep "usage"
  pnpm typecheck
  ```
- **Agent:** Codex

### Task 1.2 — End-to-End Payment Flow Verification

- **Priority:** P0
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/__tests__/payment-flow.test.ts`
  - `src/lib/payments.ts`
  - `src/app/api/payments/`
  - `src/app/api/billing/`
- **Acceptance criteria:**
  - Free → Starter checkout works
  - Starter → Pro upgrade works
  - Failed payment handled gracefully
  - Expired payment cleaned up
  - Mock provider end-to-end passes
- **Validation:**
  ```bash
  pnpm test -- --grep "payment"
  pnpm run payment:preflight
  ```
- **Agent:** OpenCode

### Task 1.3 — Health Check Endpoint Validation

- **Priority:** P0
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/health.ts`
  - `src/app/api/health/route.ts`
  - `src/app/api/ready/route.ts`
- **Acceptance criteria:**
  - `/api/health` returns 200 with database and Redis status
  - `/api/ready` returns 200 when all dependencies are up
  - Health check completes in < 2s
  - Redis check gracefully skips when not configured
- **Validation:**
  ```bash
  pnpm test -- --grep "health"
  curl http://localhost:3000/api/ready
  ```
- **Agent:** Hermes

---

## Category 2: Product Correctness

### Task 2.1 — Finding Code Documentation

- **Priority:** P1
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/finding-registry.ts` (30+ finding codes)
  - `src/lib/FINDINGS.md` (new documentation file)
  - `src/lib/types.ts` (FindingCode type)
- **Acceptance criteria:**
  - Every finding code in `finding-registry.ts` documented in FINDINGS.md
  - Each entry: code, category, severity, explanation, recommendation, business impact
  - Documentation matches registry metadata exactly
- **Validation:**
  ```bash
  grep -c "## " src/lib/FINDINGS.md  # Should match finding count
  pnpm typecheck
  ```
- **Agent:** MiMo

### Task 2.2 — Scoring System Test Fixtures

- **Priority:** P1
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/fixtures/audit/` (new directory)
  - `src/lib/scoring.test.ts`
  - `src/lib/scoring.ts`
- **Acceptance criteria:**
  - Fixture: good website (score 80+)
  - Fixture: average website (score 50-70)
  - Fixture: bad website (score < 40)
  - Each fixture: saved HTML + expected findings + expected score range
  - Tests verify scoring against all fixtures
- **Validation:**
  ```bash
  pnpm test -- --grep "scoring"
  ```
- **Agent:** OpenCode

### Task 2.3 — Rules Regression Test Expansion

- **Priority:** P1
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/__tests__/rules.regression.test.ts`
  - `src/lib/rules.ts`
  - `src/lib/types.ts`
- **Acceptance criteria:**
  - Each finding code has at least 2 test cases (positive + negative)
  - False positive prevention tested
  - Severity consistency verified
  - Tests run in < 5s total
- **Validation:**
  ```bash
  pnpm test -- --grep "rules"
  ```
- **Agent:** OpenCode

---

## Category 3: User Experience

### Task 3.1 — Executive Summary on Reports

- **Priority:** P1
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/summary.ts`
  - `src/lib/summary.types.ts`
  - `src/lib/pdf.ts`
  - Report page component
- **Acceptance criteria:**
  - Executive summary is first section in report
  - Includes: overall score, category scores, top 3 issues, estimated fix time
  - Summary is ≤ 200 words
  - PDF includes executive summary as first page
- **Validation:**
  ```bash
  pnpm test -- --grep "summary"
  pnpm typecheck
  ```
- **Agent:** OpenCode

### Task 3.2 — Email Capture on Reports

- **Priority:** P1
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/components/EmailCapture.tsx`
  - New API endpoint: `src/app/api/reports/[token]/capture/`
  - `src/lib/validators.ts`
- **Acceptance criteria:**
  - Email form visible after executive summary
  - Form submits to capture endpoint
  - AuditLead record created with email, runId, timestamp
  - Confirmation includes report link
  - Email validation (format, required)
- **Validation:**
  ```bash
  pnpm test -- --grep "email"
  pnpm typecheck
  ```
- **Agent:** OpenCode

### Task 3.3 — Error Pages (404, 403, 500)

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/app/not-found.tsx`
  - `src/app/forbidden.tsx`
  - `src/app/error.tsx`
  - `src/app/global-error.tsx`
  - `src/app/rate-limited.tsx`
- **Acceptance criteria:**
  - All error pages are branded and bilingual
  - Error pages include helpful next steps
  - Error boundaries catch component crashes
  - Pages load in < 1s
- **Validation:**
  ```bash
  pnpm build
  curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/nonexistent
  ```
- **Agent:** OpenCode

### Task 3.4 — Dashboard Usage Stats Widget

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - Dashboard home page component
  - `src/lib/usage.ts`
  - `src/app/api/stats/`
- **Acceptance criteria:**
  - Dashboard home loads in < 1s
  - Usage stats show real-time counts (audits used, projects used)
  - Recent audits show last 5 with scores
  - Quick actions are one-click accessible
- **Validation:**
  ```bash
  pnpm build
  curl http://localhost:3000/api/stats
  ```
- **Agent:** MiMo

---

## Category 4: Reliability

### Task 4.1 — Backup Automation

- **Priority:** P1
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `scripts/backup-db.sh`
  - `scripts/restore-db.sh`
  - `scripts/setup-cron.sh`
- **Acceptance criteria:**
  - Backup script runs without errors
  - Backups stored in `/var/backups/auditsystems/`
  - Restore script can restore from backup
  - Daily backup via cron
  - 30-day retention
- **Validation:**
  ```bash
  bash scripts/backup-db.sh
  ls -la /var/backups/auditsystems/
  ```
- **Agent:** Hermes

### Task 4.2 — Smoke Test Suite

- **Priority:** P1
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `scripts/smoke-public-routes.sh`
  - `scripts/smoke-full.sh`
  - `scripts/deploy/smoke-audit-flow.cjs`
- **Acceptance criteria:**
  - Smoke test script runs in < 30s
  - Tests: homepage loads, audit form submits, sample report loads, login/signup works, API health check returns OK
  - All critical paths covered
  - Exit code 0 on success, non-zero on failure
- **Validation:**
  ```bash
  bash scripts/smoke-public-routes.sh http://localhost:3000
  ```
- **Agent:** Hermes

### Task 4.3 — Worker Graceful Shutdown Verification

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/worker/index.ts`
  - `src/worker/queue.ts`
  - `ecosystem.config.cjs`
- **Acceptance criteria:**
  - Worker handles SIGINT and SIGTERM gracefully
  - In-progress jobs complete before shutdown
  - Expired leases recycled on startup
  - PM2 restart cycle works correctly
- **Validation:**
  ```bash
  pm2 restart auditsystems-worker
  pm2 logs auditsystems-worker --lines 10
  ```
- **Agent:** Hermes

---

## Category 5: Security

### Task 5.1 — CSP Header Audit

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `next.config.ts` (headers section)
- **Acceptance criteria:**
  - CSP header prevents XSS
  - HSTS enabled for all pages
  - X-Frame-Options prevents clickjacking
  - No `unsafe-eval` unless required
  - Audit for any overly permissive directives
- **Validation:**
  ```bash
  curl -I http://localhost:3000 | grep -i "content-security-policy"
  curl -I http://localhost:3000 | grep -i "strict-transport-security"
  ```
- **Agent:** Codex

### Task 5.2 — Account Lockout Verification

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/account-lockout.ts`
  - `src/lib/authRateLimit.ts`
  - `src/app/api/auth/`
- **Acceptance criteria:**
  - Account lockout triggers after 5 failed attempts
  - Lockout duration is configurable
  - Successful login resets attempt counter
  - Rate limiting on auth endpoints is stricter than general
- **Validation:**
  ```bash
  pnpm test -- --grep "lockout"
  pnpm test -- --grep "authRateLimit"
  ```
- **Agent:** Codex

---

## Category 6: Deployment

### Task 6.1 — Deploy Script Validation

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `scripts/deploy-production.sh`
  - `scripts/vps-deploy.sh`
  - `scripts/deploy/` directory
- **Acceptance criteria:**
  - Deploy script runs pre-flight checks (`.env`, `DATABASE_URL`)
  - Build succeeds before deploy
  - Database migration runs automatically
  - Plans seeded after migration
  - PM2 restart works
  - Health check passes after deploy
- **Validation:**
  ```bash
  bash scripts/deploy-production.sh --dry-run
  ```
- **Agent:** Hermes

### Task 6.2 — VPS Status Monitoring

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `scripts/vps-deploy.sh` (status command)
  - `deploy/` health check scripts
- **Acceptance criteria:**
  - `vps:status` shows PM2 process status
  - Health check confirms database connectivity
  - SSL certificate status visible
  - Disk usage reported
- **Validation:**
  ```bash
  pnpm vps:status
  ```
- **Agent:** Hermes

---

## Category 7: Observability

### Task 7.1 — Structured Logging Verification

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/logger.ts`
  - `src/lib/observability.ts`
  - `src/lib/metrics.ts`
- **Acceptance criteria:**
  - All logs include request ID
  - All authenticated logs include user ID
  - Audit-related logs include audit ID
  - Payment-related logs include payment ID
  - Log levels configurable via env
- **Validation:**
  ```bash
  pnpm test -- --grep "observability"
  pnpm test -- --grep "metrics"
  ```
- **Agent:** MiMo

### Task 7.2 — Prometheus Metrics Validation

- **Priority:** P3
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/app/api/metrics/route.ts`
  - `src/lib/metrics.ts`
- **Acceptance criteria:**
  - `/api/metrics` returns valid Prometheus format
  - Metrics include: request count, response time, error rate
  - Metrics include: audit queue depth, job success/failure rates
  - Metrics endpoint is admin-only or internal
- **Validation:**
  ```bash
  curl http://localhost:3000/api/metrics
  ```
- **Agent:** MiMo

---

## Category 8: Growth

### Task 8.1 — SEO Content: 10 Blog Posts

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/content/` directory
  - `src/app/blog/` pages
- **Acceptance criteria:**
  - 10 SEO-optimized blog posts on audit topics
  - Each post: 1500+ words, original content, CTA to audit
  - Each post has unique SEO metadata
  - Each post has internal links to 2+ other posts
  - Each post passes Lighthouse SEO audit
- **Validation:**
  ```bash
  pnpm build
  pnpm seo:audit
  ```
- **Agent:** MiMo

### Task 8.2 — Agency Landing Page

- **Priority:** P2
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/app/landing/agency/page.tsx`
- **Acceptance criteria:**
  - Agency page loads and explains value proposition
  - Highlights: white-label reports, multiple clients, monthly monitoring
  - Agency-specific pricing explanation
  - Agency signup flow (separate from individual)
  - Page linked from pricing page
- **Validation:**
  ```bash
  pnpm build
  curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/landing/agency
  ```
- **Agent:** OpenCode

### Task 8.3 — Referral System Implementation

- **Priority:** P3
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/lib/referral.ts`
  - Dashboard referral page
  - `prisma/schema.prisma` (Referral model exists)
- **Acceptance criteria:**
  - Each user gets unique referral code
  - Referral link tracks signup attribution
  - Referral dashboard shows stats (referral count, conversions)
  - Incentive applied automatically on qualifying referral
- **Validation:**
  ```bash
  pnpm test -- --grep "referral"
  pnpm typecheck
  ```
- **Agent:** MiMo

### Task 8.4 — Monthly Report Generation

- **Priority:** P3
- **Status:** TODO
- **Repo:** `sites/live/auditsystems`
- **Files:**
  - `src/scripts/generate-monthly-reports.ts`
  - `src/lib/monthly-report.ts`
- **Acceptance criteria:**
  - Generate monthly summary report for each organization
  - Include: audits performed, scores, improvements, issues resolved
  - Send via email to organization owners
  - Add PDF export for monthly report
- **Validation:**
  ```bash
  pnpm reports:monthly --dry-run
  ```
- **Agent:** MiMo

---

## Summary

| Category | Count | P0 | P1 | P2 | P3 |
|---|---|---|---|---|---|
| Launch Blockers | 3 | 3 | 0 | 0 | 0 |
| Product Correctness | 3 | 0 | 3 | 0 | 0 |
| User Experience | 4 | 0 | 2 | 2 | 0 |
| Reliability | 3 | 0 | 2 | 1 | 0 |
| Security | 2 | 0 | 0 | 2 | 0 |
| Deployment | 2 | 0 | 0 | 2 | 0 |
| Observability | 2 | 0 | 0 | 1 | 1 |
| Growth | 4 | 0 | 0 | 2 | 2 |
| **Total** | **23** | **3** | **7** | **9** | **4** |

### Recommended Execution Order

1. **Week 1:** Tasks 1.1, 1.2, 1.3 (launch blockers)
2. **Week 2:** Tasks 2.1, 2.2, 2.3, 3.1 (product correctness + executive summary)
3. **Week 3:** Tasks 3.2, 4.1, 4.2 (email capture + reliability)
4. **Week 4:** Tasks 3.3, 3.4, 5.1, 5.2 (UX + security)
5. **Week 5:** Tasks 6.1, 6.2, 7.1, 7.2 (deployment + observability)
6. **Week 6:** Tasks 8.1, 8.2, 8.3, 8.4 (growth)
