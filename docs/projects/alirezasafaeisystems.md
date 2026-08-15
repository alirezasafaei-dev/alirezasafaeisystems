# AlirezaSafaeiSystems — ASDEV Mother / Brand Site

**Role:** Portfolio, trust hub, acquisition, case studies, lead qualification  
**Status:** Live / maintain + Discover acquisition implementation in review  
**Domain:** https://alirezasafaeisystems.ir/  
**Repository:** https://github.com/alirezasafaei-dev/alirezasafaeisystems  
**Local path:** `sites/live/alirezasafaeisystems`

---

## Discover — approved acquisition surface

`/discover` is an approved ASDEV acquisition surface for turning Instagram/search/direct audience into owned-site traffic, brand discovery, Audit/service exploration and attributable leads. It is not a separate product, service, database or deployment target.

### Product flow

`Instagram / Search / Direct → /discover → /discover/[slug] → official tool and/or ASDEV CTA → qualification / Audit / case studies → lead`

### Architecture

- Same Next.js application, site shell, locale handling and deployment contract.
- Dedicated Prisma `DiscoverItem` model in the existing SQLite database.
- Existing Admin authentication and rate limiting; no parallel auth.
- Dedicated Discover CRUD manager inside the current Admin content surface.
- Published-only public landing/detail queries.
- Internal detail pages hold the short guide before the third-party link.
- Category/search filtering on the landing page.
- UTM attribution preserves only `utm_source`, `utm_medium`, `utm_campaign`, and `utm_content` across internal Discover/ASDEV navigation.
- Existing consent-aware analytics records landing/detail views and external/internal CTA clicks.
- Published detail pages are added to the dynamic sitemap when the content DB is reachable.

### Legacy compatibility

The earlier implementation stored Discover records in `Project(contentType=discover)`. The new migration copies those records into `DiscoverItem` with stable `legacy-*` slugs and leaves all original Project rows untouched for history/rollback. New Discover content belongs in `DiscoverItem` only.

### Governance

Discover is in scope only while it measurably supports acquisition, conversion, attribution, trust or lead routing for the primary ASDEV Audit business. Production deployment and production database migration remain explicit owner approval gates.

### Implementation references

- `docs/superpowers/specs/2026-08-15-discover-acquisition-surface-design.md`
- `docs/superpowers/plans/2026-08-15-discover-acquisition-surface.md`
- `docs/operations/DISCOVER_LOCAL_RUNBOOK.md`

---

## Case study — ASDEV brand and governance site

### Problem

ASDEV needed a single credible surface for:

- Explaining who builds the products
- Routing serious inquiries without fake "large team" positioning
- Holding strategy, roadmap, and project roles in one place
- Converting social discovery into owned traffic instead of sending every visitor directly back out to third-party services

### Constraints

- Solo-operator reality — no invented team or hiring pipeline
- Must not compete with Audit for primary conversion
- Strategy docs must stay separate from product runtime code
- Discover remains a support/acquisition surface rather than a standalone product scope

### Architecture / approach

- Next.js portfolio app + `docs/strategy/` governance layer
- Qualification route for scoped professional review requests
- Cross-links to Audit sample report and Audit start as primary product path
- Project role matrix in `docs/strategy/PROJECT_ROLES.md`
- Discover acquisition flow inside the same application and Admin

### Production evidence

| Item | Status |
|---|---|
| Live domain | `alirezasafaeisystems.ir` |
| Strategy docs in repo | `docs/strategy/`, `docs/projects/` |
| Qualification / inquiry route | `/qualification` |
| Analytics client (consent-aware) | `src/lib/analytics/client.ts` |
| Discover acquisition implementation | PR-gated; production rollout not implied |

### What was measured

- Measurement not yet public-safe for traffic, conversion, or inquiry volume
- Discover events/UTM attribution create the instrumentation needed for future evidence; they do not justify traffic or conversion claims before real production data exists

### What is not claimed

- No revenue figures
- No customer count or logo wall
- No invented Discover traffic/conversion numbers
- No "we are hiring" unless owner explicitly approves

### Links

- Live: https://alirezasafaeisystems.ir/
- Repo: https://github.com/alirezasafaei-dev/alirezasafaeisystems
- Primary product: https://audit.alirezasafaeisystems.ir/sample-report

### CTA

Professional review and project inquiries → qualification form; product evaluation → ASDEV Audit sample report.
