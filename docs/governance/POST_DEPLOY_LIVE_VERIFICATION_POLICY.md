# Post-Deploy Live Verification Policy — ASDEV

**Status:** Mandatory  
**Scope:** All ASDEV-owned production deployments and product sites  
**Applies to:** PersianToolbox, ASDEV Audit, ASDEV Systems, Novax, MCP endpoints, public landing pages, mini-apps, bots with web endpoints, and any future public product.

## Core rule

A deployment is **not complete** when build, upload, service restart, DNS switch, PM2 switch, Cloudflare publish, or webhook update succeeds.

A deployment is complete only after the **real live public site/service** has been tested with real browsers and operational checks, and the evidence proves that critical user journeys are working.

Agents must not report `deployed`, `done`, `10/10`, `production-ready`, `stable`, or `healthy` unless this policy has passed or the report clearly says `DEPLOYED BUT LIVE VERIFICATION FAILED`.

## Non-negotiable requirements

After every production deploy or public cutover, the responsible agent must run live verification against the public URL, not only localhost, staging, build output, or curl.

Minimum verification must include:

1. **Live public URL checks**
   - apex domain
   - www domain if configured
   - HTTP to HTTPS redirect
   - canonical host behavior
   - health/ready endpoint if present

2. **Real browser checks**
   - at least one desktop browser run
   - at least one mobile viewport run
   - JavaScript enabled
   - screenshots for P0/P1 failures
   - console errors captured
   - failed network requests captured

3. **Navigation and routing checks**
   - homepage loads with real content
   - navbar links/buttons work by real browser clicks
   - mobile menu opens, closes, and navigates
   - footer links work
   - direct URL loads for key routes
   - client-side navigation and hard refresh both work

4. **Product journey checks**
   - critical tools/pages work with real user inputs
   - blog index and multiple blog posts open if the product has blog
   - lead/contact/payment/upgrade/admin-safe public flows are checked when present
   - forms show validation and submit behavior correctly, without leaking secrets

5. **Static asset checks**
   - `_next/static` or equivalent JS/CSS assets load
   - images/icons/fonts load with correct status and MIME type
   - no missing chunks
   - no stale service-worker or cache breakage

6. **Server/runtime checks**
   - process manager status checked where applicable
   - reverse proxy/upstream checked where applicable
   - application logs checked for fresh errors
   - deploy release id/commit recorded
   - rollback target identified

7. **Evidence report**
   - tested URLs count
   - browsers/devices used
   - failures grouped by severity
   - screenshots/traces/log paths
   - commands run
   - exact commit/release deployed
   - exact verdict

## Required verdicts

The final deployment report must use exactly one of these verdicts:

- `LIVE_VERIFICATION_PASS`
- `LIVE_VERIFICATION_PASS_WITH_WARNINGS`
- `LIVE_VERIFICATION_FAIL_ROLLBACK_RECOMMENDED`
- `LIVE_VERIFICATION_FAIL_HOTFIX_REQUIRED`
- `DEPLOY_BLOCKED_NOT_VERIFIED`

If verification is incomplete, the verdict must be `DEPLOY_BLOCKED_NOT_VERIFIED`.

## Severity definitions

### P0 — production broken
Examples:
- homepage blank or unavailable
- most routes fail
- navbar unusable
- JavaScript bundle missing
- API/ready endpoint down
- public traffic points to wrong release

Required action: recommend rollback or immediate hotfix. Do not claim success.

### P1 — critical journey broken
Examples:
- blog unavailable on a content product
- major tools broken
- forms fail
- payment/upgrade flow broken
- mobile navigation broken

Required action: hotfix before declaring stable.

### P2 — important defect
Examples:
- isolated page broken
- non-critical asset missing
- minor SEO/canonical issue

Required action: document and schedule fix.

### P3 — minor defect
Examples:
- cosmetic issue
- copy issue
- non-critical accessibility issue

Required action: document and prioritize normally.

## Hard honesty rules

Agents must not:

- rely only on `curl` and call the UI healthy
- test only localhost or staging after production deploy
- omit failed pages from the report
- claim all links work without clicking representative links in a real browser
- claim mobile works without a mobile viewport test
- claim 100% stability without evidence
- hide console errors, hydration errors, missing chunks, or 404s
- deploy a second patch blindly without first isolating the root cause
- execute rollback/destructive cleanup without approval gate

## Browser evidence standard

Preferred tooling:

- Playwright route audit
- Playwright trace for critical failures
- screenshots for P0/P1 failures
- console/pageerror/network failure capture
- Lighthouse/CWV only as supporting evidence, not a replacement for functional tests

Every deployment script should either run this directly or call a project-local wrapper such as:

```bash
scripts/deploy/live-verify.sh https://example.com
```

or:

```bash
pnpm test:live -- --base-url=https://example.com
```

## Deployment script contract

Deployment scripts must be refactored so that:

1. build/test/preflight gates run before deploy
2. deploy/cutover happens only after explicit approval when gated
3. live verification runs immediately after deploy/cutover
4. failures generate an incident report
5. P0/P1 failures block success status
6. rollback command and target are printed when needed
7. final status cannot be `success` unless live verification passed

## Required report location

Each project must write a report in one of these locations:

- `docs/reports/live-verification/YYYYMMDD-HHMM-<site>.md`
- `reports/live-verification/YYYYMMDD-HHMM-<site>.md`

Large screenshots/traces may remain outside Git, but the report must reference their paths.

## Approval gates

This policy does not weaken approval gates. It adds a mandatory post-deploy verification gate.

Production deploy, rollback, nginx reload, DNS changes, migrations, destructive cleanup, and public monitoring timers still require their exact approval phrases where applicable.

## Definition of done

A deployment is done only when:

- public URL works
- real browser checks pass
- critical journeys pass
- logs do not show fresh critical errors
- evidence report exists
- rollback target is known
- final verdict is recorded

If any item is missing, the deployment is not done.
