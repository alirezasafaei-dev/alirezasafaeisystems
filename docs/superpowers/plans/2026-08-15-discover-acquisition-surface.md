# Discover Acquisition Surface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `/discover` into a measurable Instagram/search acquisition surface with a dedicated content model, internal detail pages, Admin CRUD, UTM preservation, and conversion analytics.

**Architecture:** Keep Discover inside the existing Next.js app, SQLite/Prisma database, Admin auth, analytics endpoint, and release pipeline. Introduce a dedicated `DiscoverItem` model while preserving legacy `Project(contentType=discover)` rows through a non-destructive migration. Public list/detail routes read only published `DiscoverItem` records; Admin manages Discover independently from Portfolio.

**Tech Stack:** Next.js 16 App Router, React 19, TypeScript 5.9, Prisma 6/SQLite, Zod 4, Vitest 4, Playwright, Tailwind 4, existing ASDEV analytics/auth primitives.

## Global Constraints

- Branch: `agent/discover-acquisition-surface-20260815`; never implement on `main`.
- No production deployment, production DB migration, server mutation, public pricing, or payment activation.
- No new runtime service, database, auth system, third-party CMS, or Instagram API integration.
- Preserve legacy `Project` rows and current Portfolio behavior.
- All new third-party URLs must be HTTPS and credential-free.
- Analytics remain consent-gated and must not store arbitrary query strings or PII.
- TDD: behavior tests are committed before production implementation and CI must demonstrate the expected red state before the green implementation commit.
- Final gates: `pnpm lint`, `pnpm type-check`, `pnpm test`, `pnpm build`, relevant Playwright/a11y checks, and GitHub Actions green.

---

### Task 1: Discover data contract and migration

**Files:**
- Create: `src/lib/discover.ts`
- Create: `src/__tests__/lib/discover.test.ts`
- Modify: `prisma/schema.prisma`
- Create: `prisma/migrations/20260815190000_add_discover_items/migration.sql`

**Interfaces:**
- Produces `discoverSlugSchema`, `discoverTagsSchema`, `discoverUrlSchema`, `discoverInstagramUrlSchema`, `extractDiscoverAttribution`, `appendDiscoverAttribution`.
- Produces Prisma model `DiscoverItem` consumed by API and public routes.

- [ ] **Step 1: Add failing contract tests** proving valid/invalid slugs, deduplicated tags with max 20 items, HTTPS-only URLs, Instagram host restriction, bounded extraction of `utm_source|utm_medium|utm_campaign|utm_content`, and propagation of only those parameters.
- [ ] **Step 2: Run `pnpm test src/__tests__/lib/discover.test.ts`** and confirm failure because `@/lib/discover` does not exist.
- [ ] **Step 3: Add `DiscoverItem` to Prisma schema** exactly as specified in the approved design, including indexes on publication/order and category/publication.
- [ ] **Step 4: Add a non-destructive SQLite migration** that creates `DiscoverItem`, creates unique/indexes, and copies legacy `Project.contentType='discover'` rows using `legacy-<Project.id>` ids/slugs while leaving Project untouched.
- [ ] **Step 5: Implement `src/lib/discover.ts`** with Zod contracts and UTM helper functions. `appendDiscoverAttribution('/qualification', attrs)` must return a relative path with encoded approved parameters only.
- [ ] **Step 6: Run focused tests and Prisma validation/generation**: `pnpm test src/__tests__/lib/discover.test.ts`, `pnpm exec prisma validate`, `pnpm db:generate`.

### Task 2: Authenticated Discover Admin API

**Files:**
- Create: `src/app/api/admin/discover/route.ts`
- Create: `src/__tests__/api/admin-discover.integration.test.ts`

**Interfaces:**
- `GET /api/admin/discover?published=all|true|false&category=<text>&q=<text>` → `{ items: DiscoverItem[] }`.
- `POST /api/admin/discover` → `{ item }`, HTTP 201.
- `PATCH /api/admin/discover` body includes `id` plus partial editable fields → `{ item }`.
- `DELETE /api/admin/discover?id=<id>` → `{ success: true }`.

- [ ] **Step 1: Add failing API tests** for auth enforcement, GET ordering/filter construction, POST validation, credential-bearing URL rejection, Instagram-host rejection, slug conflict 409, publish timestamp creation, PATCH update, and DELETE.
- [ ] **Step 2: Run `pnpm test src/__tests__/api/admin-discover.integration.test.ts`** and confirm failure because the route does not exist.
- [ ] **Step 3: Implement the route** reusing `enforceAdminAccess`, `checkRateLimit`, `withCommonApiHeaders`, `logger`, `sanitizeInput`, and contracts from `src/lib/discover.ts`.
- [ ] **Step 4: Handle Prisma unique-slug conflicts** as HTTP 409 without exposing database details.
- [ ] **Step 5: Verify focused API tests** and existing Admin API tests remain green.

### Task 3: Dedicated Discover Admin manager

**Files:**
- Create: `src/components/admin/discover-manager.tsx`
- Modify: `src/components/admin/admin-dashboard.tsx`
- Create: `src/__tests__/components/discover-manager.test.tsx`

**Interfaces:**
- `DiscoverManager` is a client component that owns list/search/editor state and talks only to `/api/admin/discover`.
- Admin dashboard adds `activeTab='discover'` and renders `<DiscoverManager />`.

- [ ] **Step 1: Add failing component tests** proving the manager renders draft/published state, exposes required fields, submits create as JSON, can load an item into edit mode, and confirms delete.
- [ ] **Step 2: Run the focused component test** and confirm failure because the component does not exist.
- [ ] **Step 3: Implement `DiscoverManager`** with title, slug, category, description, guide content, external URL, Instagram URL, image URL, tags, order, Featured, Published, Save, Cancel, Edit, Preview, Delete, loading/error/empty states, and Admin toasts.
- [ ] **Step 4: Add a dedicated Discover tab** to the existing dashboard without removing Projects, Leads, Messages, or Analytics.
- [ ] **Step 5: Verify component tests and type-check**.

### Task 4: Public Discover landing and detail routes

**Files:**
- Replace: `src/app/discover/page.tsx`
- Create: `src/app/discover/[slug]/page.tsx`
- Create: `src/components/discover/discover-grid.tsx`
- Create: `src/components/discover/discover-telemetry.tsx`
- Create: `src/components/discover/discover-link.tsx`
- Create: `src/__tests__/components/discover-grid.test.tsx`
- Create: `src/__tests__/lib/discover-public.test.ts`

**Interfaces:**
- Landing server query: `where: { published: true }`, order by featured desc/order asc/publishedAt desc/createdAt desc.
- Detail server query: `findUnique({ where: { slug } })`, then 404 unless `published === true`.
- `DiscoverGrid` receives serializable public item summaries and attribution, performs client search/category filtering, and creates internal detail hrefs with attribution.
- `DiscoverTelemetry` emits consent-gated events through existing `trackEvent`.
- `DiscoverLink` emits click telemetry before navigation/open while never blocking navigation.

- [ ] **Step 1: Add failing tests** for filtering, category options, UTM-preserving detail hrefs, published-only public query helpers, and safe public shape.
- [ ] **Step 2: Run focused tests** and confirm the missing public components/helpers fail.
- [ ] **Step 3: Rebuild `/discover` positioning** around social discovery: Persian copy states that tools/services introduced in Instagram are collected here with short guidance and official links. The primary card action is an internal detail link.
- [ ] **Step 4: Implement `/discover/[slug]`** with metadata, breadcrumbs, safe paragraph rendering, official external CTA, optional Instagram source CTA, related same-category items, and ASDEV conversion CTAs.
- [ ] **Step 5: Preserve approved UTM parameters** across landing → detail and detail → internal ASDEV CTAs. Never append them to third-party URLs.
- [ ] **Step 6: Emit `discover_landing_view`, `discover_item_view`, `discover_external_click`, and `discover_internal_cta_click`** with slug/category/target/approved UTM metadata only.
- [ ] **Step 7: Run focused tests and type-check**.

### Task 5: Dynamic sitemap, accessibility, and operational docs

**Files:**
- Modify: `src/app/sitemap.ts`
- Modify: `src/__tests__/seo/sitemap.test.ts`
- Modify: `e2e/a11y.spec.ts`
- Modify: `docs/operations/DISCOVER_LOCAL_RUNBOOK.md`
- Modify: `docs/projects/alirezasafaeisystems.md`
- Modify: `docs/strategy/FOCUS_POLICY.md`

**Interfaces:**
- Sitemap becomes async and appends published Discover detail URLs while preserving current manifest entries and language alternates.

- [ ] **Step 1: Add/adjust sitemap test** proving published Discover items generate detail URLs and drafts do not.
- [ ] **Step 2: Update sitemap implementation** to query only `slug`/`updatedAt` for published Discover items; if DB is unavailable during build, preserve manifest sitemap rather than failing the whole build.
- [ ] **Step 3: Add representative Discover detail route coverage to accessibility smoke** using a deterministic seeded/test route only when test data exists; otherwise keep landing coverage and verify component accessibility in Vitest.
- [ ] **Step 4: Update Discover runbook** with migration rehearsal, Admin CRUD lifecycle, UTM smoke path, analytics consent smoke, and rollback note that legacy Projects remain untouched.
- [ ] **Step 5: Record Discover as an official ASDEV acquisition surface** in project/focus documentation so future agents do not freeze it as unrelated portfolio work.

### Task 6: Full verification and pull request

**Files:** no new production files; verification and PR metadata only.

- [ ] **Step 1: Run full repository gates in CI**: lint, type-check, Vitest, build, E2E smoke/a11y, security, Lighthouse as configured by repository workflows.
- [ ] **Step 2: Review the complete diff** for unrelated changes, secrets, destructive migration statements, external URLs, and accidental production actions.
- [ ] **Step 3: Open a focused PR** titled `feat: turn Discover into an acquisition surface` with design/spec links, migration behavior, analytics events, verification evidence, and explicit note that production deploy/migration remains owner-gated.
- [ ] **Step 4: Resolve feature-caused CI failures without weakening checks.**
- [ ] **Step 5: Do not merge or deploy until the final CI state and diff have been reviewed.**
