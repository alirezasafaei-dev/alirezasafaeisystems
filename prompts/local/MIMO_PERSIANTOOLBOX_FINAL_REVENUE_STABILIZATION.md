# MiMo Prompt — PersianToolbox Final Revenue Stabilization

```text
RUN_CONTEXT: LOCAL_PC

You are MiMo, the primary ASDEV orchestration agent running on LOCAL_PC.

Definitions are mandatory:
- LOCAL_PC = owner's workstation. You are running here unless explicitly proven otherwise.
- AUTOMATION_SERVER = external automation server, asdev@91.107.153.223.
- IRAN_PROD_SERVER = Iran live production/deployment server. Strictly gated.
- GITHUB_MAIN = GitHub main branch source of truth.
- PRIMARY_AGENT = MiMo.
- IMPLEMENTATION_AGENT = OpenCode.
- REPORTING_AGENT = Hermes.
- OPENCLAW = gateway/diagnostic only; no Telegram polling while Hermes owns Telegram.

Business decision:
PersianToolbox is entering final stabilization. After the defects below are fixed and verified, stop feature development/code expansion for this project. Move effort to traffic acquisition, marketing, monetization, sales, SEO distribution, and other higher-priority projects. Do not keep polishing endlessly.

Target repo:
alirezasafaei-dev/persiantoolbox

Primary live site:
https://persiantoolbox.ir

Critical user complaint:
- First visit/load must be fast. Site must show useful content quickly, not a blank client-side shell.
- Admin panel/dashboard must be real, reliable, complete, and usable for operations.
- Zarinpal payment still does not work: clicking buy shows loading, appears stuck, and later opens a URL like https://api.zarinpal.com/pg/StartPay/<authority>.
- Paid purchase/subscription must require registration/login first so the payment/subscription can be tied to a unique user id.

Mandatory references to read first:
1. PersianToolbox docs/ops/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md
2. PersianToolbox docs/ops/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md
3. PersianToolbox docs/audits/admin-panel-security-and-testing-report.md
4. PersianToolbox payment/auth code:
   - app/api/subscription/checkout/route.ts
   - app/api/subscription/confirm/route.ts
   - app/api/payments/checkout/route.ts
   - lib/payments/payment-integration.ts
   - lib/payments/payment-urls.ts
   - components/features/pricing/PricingContent.tsx
   - app/(tools)/premium/page.tsx
   - app/(tools)/premium/PremiumPageClient.tsx
   - components/features/monetization/AccountPage.tsx
   - components/features/monetization/AuthForms.tsx
5. Uploaded audit summary if available: deep audit of PersianToolbox covering CSR, first load, analytics/privacy, a11y, Core Web Vitals, popups, blog depth.

Hard rules:
- Do not deploy, rollback, reload nginx, change DNS, run migrations, or mutate IRAN_PROD_SERVER without exact approval phrase.
- Do not print or commit secrets, tokens, cookies, merchant id, callback secrets, admin credentials, browser profiles, or traces containing private data.
- Do not fake Zarinpal success. Use sandbox/test mode only if configured; otherwise perform dry-run and exact blocker report.
- Do not call payment fixed unless real browser purchase flow is tested up to the allowed safe boundary.
- Do not call admin dashboard fixed unless real admin workflows are tested or explicitly blocked by missing credentials.
- Do not call performance fixed unless cold-load real browser evidence exists.
- Do not add new features except what is required to fix stabilization, payment, admin, speed, observability, or final revenue handoff.

PHASE 0 — Ground truth and release state
- Identify current repo path, branch, local SHA, origin/main SHA.
- Pull latest main safely.
- Identify latest PersianToolbox GitHub commit.
- Identify live release commit shown by /api/version or /api/health if available.
- Compare GitHub HEAD vs live release.
- Write a short drift table.

PHASE 1 — Payment and auth root-cause audit, priority P0
Goal: paid checkout must be reliable and account-bound.

Required product rule:
For paid subscription/paid export, user must be logged in or must register/login before checkout. A payment must be tied to a stable users.id. Anonymous paid checkout is not allowed unless a separate guest-checkout token design is explicitly approved.

Audit and fix:
1. Buy buttons must never spin indefinitely.
2. If unauthenticated, redirect to /account?redirect=<current intended checkout route>, not generic /account.
3. After successful login/register, user must return to the intended pricing/premium/subscription flow.
4. Checkout API responses must be normalized. Client must handle both `error` and `errors[]` consistently.
5. `PricingContent.tsx`, `PremiumPageClient.tsx`, and AccountPage checkout must show explicit payment errors to the user.
6. `loading` state must reset on every failure path.
7. Do not call router.push for external payment URLs unless verified safe; prefer window.location.href for external gateway redirects.
8. Validate planId against actual purchasable plans. If one-time pack ids and subscription ids are mixed, split one-time payment from subscription payment or document/fix the model.
9. Confirm amount unit: UI says تومان but backend stores IRR and sends amount to gateway. Verify whether Zarinpal adapter expects rial or toman and fix any 10x mismatch.
10. Confirm callback URLs:
    - ZARINPAL_CALLBACK_URL
    - ZARINPAL_SUBSCRIPTION_CALLBACK_URL
    - NEXT_PUBLIC_SITE_URL
    - PAYMENT_BASE_URL
    They must match live domain and Zarinpal panel configuration.
11. Confirm StartPay URL host/path is correct for the current gateway mode. If the URL opens `api.zarinpal.com/pg/StartPay/...` and hangs/fails, capture response, redirect chain, status code, browser console/network, and root cause.
12. Confirm `gatewayRef`/Authority storage and lookup works. Payment metadata must map Authority back to payment.
13. Confirm callback GET route can verify payment and create subscription/credits for the correct user.
14. Confirm failed/cancelled payment gives user a clear failure page.
15. Confirm admin/operator can see failed/pending/completed payments.

Required tests:
- Unit tests for unauthenticated checkout response and client handling.
- Component/e2e test: unauthenticated buy redirects to account with redirect param.
- Component/e2e test: authenticated buy creates checkout and redirects to gateway URL.
- API test: checkout returns useful errors[] and client displays them.
- API test: callback maps Authority to payment and activates subscription/credits.
- Real browser live test up to safe boundary: click buy, verify login/register gate, login/register with test account if available, create checkout in test/sandbox if configured.

If live Zarinpal credentials/test card/account are missing:
- Do not fake success.
- Write BLOCKED_PAYMENT_GATEWAY_CREDENTIALS report with exact missing env vars and exact manual check needed.
- Still fix UI/auth/error handling.

PHASE 2 — Admin panel/dashboard operational audit, priority P0
Goal: admin panel must be real, reliable, and operationally useful.

Audit and fix:
1. Find all admin pages/routes/components/APIs.
2. Verify admin auth, role check, CSRF, rate limit, server-side protection, and no client-only auth illusion.
3. Verify admin dashboard loads without JS/runtime/500 errors.
4. Verify dashboard data is real, not hardcoded/stubbed.
5. Verify admin can see:
   - users
   - payments: pending/completed/failed
   - subscriptions/credits
   - revenue summary
   - failed payment reasons
   - latest site health/live verification verdict
   - top tools/useful analytics if already collected
6. Admin actions must have clear success/failure toast/message and audit logging.
7. If admin credentials are unavailable, run API-level tests and mark UI login as blocked.
8. Do not expose admin data publicly.

Required tests:
- Admin API unauthorized returns 401/403.
- Non-admin user cannot access admin APIs/pages.
- Admin user can load dashboard data.
- Payment/subscription rows appear in admin summary after test seed.
- Pending payment appears with gateway authority/payment id.
- All admin routes have real browser smoke or API tests.

PHASE 3 — First-load speed and crawlable content, priority P0/P1
Goal: first visit must render useful content quickly and not depend on a blank CSR shell.

Use the audit findings: CSR bailout, many JS chunks/fonts, weak no-JS/crawler experience, missing field CWV, GTM/Sentry transparency, a11y labels, popup pressure, blog depth.

Audit and fix root causes:
1. Identify pages that emit client-side rendering bailout or blank shell:
   - /
   - /tools
   - /blog
   - at least 10 blog posts
   - /pricing
   - /premium
   - /about
   - critical tool category pages
2. Convert informational pages to SSG/SSR/server components where feasible.
3. Keep only truly interactive widgets as client components.
4. Reduce first-load JS: dynamic import heavy tools, isolate expensive client code, defer non-critical widgets/popups, reduce global providers.
5. Reduce font overhead: only needed weights, font-display strategy, no unnecessary preload explosion.
6. Verify no blank page with JS disabled for informational pages; main content must appear.
7. Implement/verify field Web Vitals collection safely if already using analytics; no private document/tool data should be sent.
8. Clarify GTM/Sentry privacy in transparency/privacy docs if still present.

Required performance evidence:
- Playwright cold-load timing.
- Lighthouse mobile and desktop before/after if possible.
- WebPageTest/PageSpeed optional if available.
- Record LCP, INP/TBT, CLS, JS transfer size, initial HTML content presence.
- Test throttled mobile network.
- Report exact numbers; do not claim 100 unless measured.

Acceptance targets:
- Homepage useful content visible fast on cold load.
- No P0 route renders blank shell.
- Critical pages pass live browser checks.
- No missing JS/CSS chunks.
- No fatal hydration errors.

PHASE 4 — Live verification and deployment gate, priority P0
Current deploy verification has been improved, but verify it is truly policy-compliant.

Required:
- post-deploy verification must include real browser checks, not curl-only.
- It must test nav, mobile menu, blog, critical tools, payment gate, admin protected routes, console errors, network failures.
- It must output official verdict:
  LIVE_VERIFICATION_PASS
  LIVE_VERIFICATION_PASS_WITH_WARNINGS
  LIVE_VERIFICATION_FAIL_ROLLBACK_RECOMMENDED
  LIVE_VERIFICATION_FAIL_HOTFIX_REQUIRED
  DEPLOY_BLOCKED_NOT_VERIFIED
- deploy-blue-green.sh must not print final success if live verification fails.

PHASE 5 — Development freeze and revenue handoff, priority P1
After P0/P1 defects pass:
1. Create/update docs/ops/PERSIANTOOLBOX_REVENUE_MODE_AND_DEV_FREEZE.md.
2. State that no new feature development is allowed unless it fixes revenue, payment, admin, security, legal, or production reliability.
3. Create marketing/revenue backlog:
   - Google Search Console/Bing indexing check
   - top 20 landing pages improvement
   - blog pillar refresh where it directly drives traffic
   - conversion tracking for pricing/payment funnel
   - launch campaign/social/Telegram content
   - backlink/outreach list
   - payment trust copy and FAQ
   - admin revenue monitoring daily/weekly routine
4. Define a weekly business dashboard: traffic, signups, checkout clicks, payment starts, successful payments, revenue, top tools, broken routes.
5. Move remaining nice-to-have code items to frozen backlog.

PHASE 6 — Validation and final report
Run all available checks:
- pnpm lint
- pnpm typecheck
- pnpm test or pnpm vitest --run
- pnpm build
- Playwright live verification against https://persiantoolbox.ir
- Payment sandbox/live-safe test if credentials exist
- Admin dashboard browser/API test
- Secret scan if available

Final report path:
- docs/reports/persiantoolbox/FINAL_REVENUE_STABILIZATION_<timestamp>.md

Final report must include:
- Executive verdict: STABILIZATION_PASS / STABILIZATION_WITH_WARNINGS / PAYMENT_BLOCKED / ADMIN_BLOCKED / PERFORMANCE_BLOCKED
- What was fixed
- What was actually tested
- Payment flow evidence
- Admin dashboard evidence
- First-load performance evidence
- Live verification verdict
- Remaining blockers
- Deploy approval needed or not
- Whether project is ready for development freeze
- Marketing/revenue next actions
- Commit hashes

Do not mark complete unless payment, admin, and first-load have real evidence or exact blockers.
```
