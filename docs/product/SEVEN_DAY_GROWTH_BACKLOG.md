# 7-Day Growth Backlog — ASDEV Audit Platform

## Overview

A prioritized 7-day execution plan to improve acquisition, conversion, retention, and visibility for the ASDEV Audit platform. Each task is scoped to be completable within a single day.

**Platform:** https://audit.alirezasafaeisystems.ir/
**Codebase:** `sites/live/auditsystems/`
**Tech stack:** Next.js 16, TypeScript, Prisma, PostgreSQL, Vitest

---

## Day 1: SEO Foundations

### Task 1.1 — Meta Tags Audit and Fix

- **Description:** Review all pages for missing or duplicate `<title>`, `<meta description>`, `<meta keywords>`, and Open Graph tags. Add structured data (JSON-LD) for the audit service.
- **Expected impact:** Improved search visibility, higher CTR from SERPs
- **Effort:** 3 hours
- **Priority:** P0
- **Files:** `src/app/**/page.tsx`, `src/components/SEO.tsx` (if exists)

### Task 1.2 — Sitemap and robots.txt

- **Description:** Verify `/sitemap.xml` is generated and includes all public pages. Ensure `robots.txt` allows crawling of public pages while blocking `/api/`, `/admin/`, and private routes.
- **Expected impact:** Better crawl efficiency, faster indexing
- **Effort:** 1 hour
- **Priority:** P0
- **Files:** `src/app/sitemap.ts`, `src/app/robots.ts`

### Task 1.3 — Page Speed Baseline

- **Description:** Run Lighthouse audit on homepage and key landing pages. Document current scores (Performance, Accessibility, SEO, Best Practices). Identify top 3 bottlenecks.
- **Expected impact:** Baseline for optimization, identifies quick wins
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/scripts/lighthouse-local.ts`

### Task 1.4 — Canonical URLs

- **Description:** Ensure all pages have proper `<link rel="canonical">` tags to prevent duplicate content issues. Check for trailing slash consistency.
- **Expected impact:** Prevents SEO penalties from duplicate content
- **Effort:** 1 hour
- **Priority:** P1
- **Files:** `src/app/**/page.tsx`

---

## Day 2: Content Marketing

### Task 2.1 — Landing Page Copy Review

- **Description:** Audit the homepage and audit submission page copy. Ensure clear value proposition, strong CTAs, and trust signals (testimonials, stats, guarantees).
- **Expected impact:** Higher conversion rate from visitor to audit submission
- **Effort:** 3 hours
- **Priority:** P0
- **Files:** `src/app/page.tsx`, `src/app/audit/page.tsx`

### Task 2.2 — Create "How It Works" Section

- **Description:** Add a prominent "How It Works" section to the homepage showing the 3-step audit process: Submit → Analyze → Report. Use icons and short copy.
- **Expected impact:** Reduces friction for first-time visitors, improves conversion
- **Effort:** 2 hours
- **Priority:** P0
- **Files:** `src/app/page.tsx`, `src/components/`

### Task 2.3 — Add Trust Signals

- **Description:** Add social proof elements: number of audits performed, companies served (if available), star ratings, money-back guarantee badge.
- **Expected impact:** Increases trust, improves conversion by 10-20%
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/app/page.tsx`, `src/components/`

### Task 2.4 — FAQ Section

- **Description:** Create an FAQ section addressing common questions: What is a code audit? How long does it take? What do I get? Is it secure? How much does it cost?
- **Expected impact:** Reduces support load, improves SEO with long-tail keywords
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/app/faq/page.tsx` or `src/components/FAQ.tsx`

---

## Day 3: User Onboarding

### Task 3.1 — First-Audit Guided Flow

- **Description:** Create a guided onboarding flow for new users: welcome screen → choose project type → paste repository URL → review preview → submit. Use a step indicator.
- **Expected impact:** Reduces abandonment during first audit submission
- **Effort:** 4 hours
- **Priority:** P0
- **Files:** `src/app/audit/`, `src/components/`

### Task 3.2 — Email Welcome Sequence

- **Description:** Implement a welcome email sent after first signup. Content: welcome message, link to first audit, quick-start guide, support contact.
- **Expected impact:** Increases activation rate, reduces churn
- **Effort:** 3 hours
- **Priority:** P1
- **Files:** `src/worker/`, `src/lib/email.ts`

### Task 3.3 — Progress Indicators

- **Description:** Add real-time progress indicators during audit execution: "Fetching repository...", "Analyzing code structure...", "Running security checks...", "Generating report..."
- **Expected impact:** Reduces perceived wait time, prevents user dropoff
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/app/audit/`, `src/components/`

### Task 3.4 — Quick-Start Template

- **Description:** Create a template/default project configuration that pre-fills common settings (language, framework, focus areas). Users can customize after.
- **Expected impact:** Faster first submission, lower barrier to entry
- **Effort:** 1 hour
- **Priority:** P2
- **Files:** `src/app/audit/`, `src/lib/`

---

## Day 4: Conversion Optimization

### Task 4.1 — A/B Test Pricing Display

- **Description:** Implement A/B test for pricing page: version A (monthly focus), version B (annual savings highlight). Track conversion to paid.
- **Expected impact:** Identify optimal pricing presentation, improve paid conversion
- **Effort:** 3 hours
- **Priority:** P0
- **Files:** `src/app/pricing/page.tsx`

### Task 4.2 — Exit-Intent Popup

- **Description:** Add exit-intent popup offering a free mini-audit or discount code. Only show once per session, respect "don't show again" preference.
- **Expected impact:** Capture 5-10% of abandoning visitors
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/components/ExitIntentPopup.tsx`

### Task 4.3 — Upgrade Prompt in Report

- **Description:** Add contextual upgrade prompts in the free audit report: "Unlock detailed recommendations", "Get PDF export", "Access historical trends".
- **Expected impact:** Converts free users to paid, increases ARPU
- **Effort:** 2 hours
- **Priority:** P0
- **Files:** `src/app/report/`, `src/components/`

### Task 4.4 — Social Sharing Buttons

- **Description:** Add share buttons to audit report summary: LinkedIn, Twitter, copy link. Pre-fill with compelling share text.
- **Expected impact:** Organic growth through user sharing, backlinks
- **Effort:** 1 hour
- **Priority:** P1
- **Files:** `src/components/ShareButtons.tsx`

---

## Day 5: Retention Features

### Task 5.1 — Audit History Dashboard

- **Description:** Create a dashboard showing all past audits with status, score trend, and quick links. Allow re-run and comparison.
- **Expected impact:** Increases return visits, improves retention
- **Effort:** 4 hours
- **Priority:** P0
- **Files:** `src/app/dashboard/`, `src/components/`

### Task 5.2 — Weekly Digest Email

- **Description:** Send weekly email to active users: new audits summary, score changes, recommended actions, product updates.
- **Expected impact:** Keeps users engaged, drives repeat usage
- **Effort:** 3 hours
- **Priority:** P1
- **Files:** `src/worker/`, `src/lib/email.ts`

### Task 5.3 — Score Trend Chart

- **Description:** Add a line chart showing audit score over time. Allow filtering by project and date range.
- **Expected impact:** Shows value of continuous auditing, encourages regular use
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/components/ScoreChart.tsx`

### Task 5.4 — Re-Audit Reminder

- **Description:** Add a "Schedule re-audit" button on report page. Send reminder email if no re-audit in 30 days.
- **Expected impact:** Increases audit frequency, improves retention
- **Effort:** 2 hours
- **Priority:** P2
- **Files:** `src/app/report/`, `src/worker/`

---

## Day 6: Trust and Credibility

### Task 6.1 — Case Studies Page

- **Description:** Create 2-3 case studies showing before/after audit results. Include: company type, issues found, improvements made, metrics.
- **Expected impact:** Builds trust, helps prospects visualize value
- **Effort:** 3 hours
- **Priority:** P1
- **Files:** `src/app/case-studies/page.tsx`

### Task 6.2 — Security Badge

- **Description:** Display a "Security Audited" or "SOC 2 Ready" badge on the site. Link to security page explaining measures.
- **Expected impact:** Builds trust for security-conscious buyers
- **Effort:** 1 hour
- **Priority:** P2
- **Files:** `src/components/SecurityBadge.tsx`, `src/app/security/page.tsx`

### Task 6.3 — Testimonials Section

- **Description:** Add a testimonials carousel on the homepage. Use real feedback from beta users or create placeholders for future collection.
- **Expected impact:** Social proof improves conversion
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/components/Testimonials.tsx`

### Task 6.4 — API Documentation

- **Description:** Create API documentation page for developers who want to integrate audit results into their CI/CD pipelines.
- **Expected impact:** Opens new user segment (developers/teams), improves SEO
- **Effort:** 3 hours
- **Priority:** P2
- **Files:** `src/app/docs/api/page.tsx`

---

## Day 7: Growth Infrastructure

### Task 7.1 — Referral System

- **Description:** Implement referral tracking: unique referral codes, referral dashboard, reward system (extra audits, discounts).
- **Expected impact:** Viral growth loop, reduces CAC
- **Effort:** 4 hours
- **Priority:** P0
- **Files:** `src/app/referrals/`, `src/lib/referral.ts`

### Task 7.2 — Analytics Dashboard

- **Description:** Set up analytics tracking: page views, audit submissions, conversion funnel, user retention. Use privacy-friendly analytics (Plausible or Umami).
- **Expected impact:** Data-driven decisions, identifies drop-off points
- **Effort:** 2 hours
- **Priority:** P0
- **Files:** `src/lib/analytics.ts`, `src/app/layout.tsx`

### Task 7.3 — UTM Tracking

- **Description:** Implement UTM parameter handling for marketing campaigns. Store referral source in user profile. Track conversion by channel.
- **Expected impact:** Measures marketing ROI, identifies best channels
- **Effort:** 2 hours
- **Priority:** P1
- **Files:** `src/lib/analytics.ts`, `src/app/page.tsx`

### Task 7.4 — Churn Prevention

- **Description:** Identify users at risk of churning (no login in 14 days, no audit in 30 days). Send targeted re-engagement emails.
- **Expected impact:** Reduces churn by 10-15%
- **Effort:** 3 hours
- **Priority:** P1
- **Files:** `src/worker/`, `src/lib/email.ts`

---

## Summary

| Day | Theme | Tasks | Total Effort |
|---|---|---|---|
| 1 | SEO Foundations | 4 | 7 hours |
| 2 | Content Marketing | 4 | 9 hours |
| 3 | User Onboarding | 4 | 10 hours |
| 4 | Conversion Optimization | 4 | 8 hours |
| 5 | Retention Features | 4 | 11 hours |
| 6 | Trust and Credibility | 4 | 9 hours |
| 7 | Growth Infrastructure | 4 | 11 hours |
| **Total** | | **28** | **65 hours** |

### Priority Distribution

- **P0 (Must Do):** 8 tasks — SEO meta tags, sitemap, landing page copy, how it works, guided flow, pricing A/B, upgrade prompts, audit history, referral system, analytics
- **P1 (Should Do):** 14 tasks — Lighthouse, canonical URLs, trust signals, FAQ, email welcome, progress indicators, exit popup, social sharing, weekly digest, score chart, case studies, testimonials, UTM tracking, churn prevention
- **P2 (Nice to Have):** 6 tasks — quick-start template, re-audit reminder, security badge, API docs

### Expected Outcomes (After 7 Days)

- **SEO:** +30-50% organic traffic potential (meta tags, sitemap, content)
- **Conversion:** +15-25% improvement (trust signals, guided flow, pricing A/B)
- **Retention:** +20-30% improvement (dashboard, weekly digest, score trends)
- **Growth:** Referral loop activated, analytics baseline established

---

## Execution Notes

- All tasks should pass `pnpm lint`, `pnpm typecheck`, `pnpm test` before merge
- No paid API dependencies — use free tools and existing infrastructure
- No PersianToolbox changes — scope strictly to auditsystems
- Each task should be a separate PR for review
- Track progress in `docs/product/EXECUTION_BACKLOG.md`
