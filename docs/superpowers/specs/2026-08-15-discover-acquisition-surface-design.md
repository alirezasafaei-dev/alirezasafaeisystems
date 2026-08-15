# Discover Acquisition Surface — Design

**Date:** 2026-08-15  
**Repository:** `alirezasafaei-dev/alirezasafaeisystems`  
**Public surface:** `https://alirezasafaeisystems.ir/discover`

## Product role

Discover is an ASDEV acquisition surface, not a second portfolio and not a standalone service. Its job is to turn social audience—especially Instagram traffic—into owned website traffic, brand discovery, engagement with ASDEV properties, and qualified leads.

Primary funnel:

`Instagram / Search / Direct → /discover → /discover/[slug] → official tool link and/or ASDEV internal CTA → qualification / Audit / case studies → lead`

This makes Discover compatible with the current Focus Policy because it directly serves acquisition, conversion, lead generation, and measurable revenue-supporting traffic.

## User experience

### `/discover`

The landing page must:

- explain that the items are apps, services, tools, and platforms introduced in ASDEV social content;
- support search by title, description, category, and tags;
- support category filtering;
- place featured items first, then explicit order, then newest items;
- send the primary card action to the internal detail route, never directly off-site;
- preserve approved UTM parameters when moving from the landing page to a detail page;
- work in Persian and English site shells, while allowing content itself to remain Persian when no English editorial copy exists;
- remain useful with zero items and with JavaScript disabled except for interactive search/filter behavior.

### `/discover/[slug]`

Each item detail page must provide:

- title, short description, category, tags, and optional image;
- a short editorial guide stored in the site database;
- an explicit official/external-link CTA;
- an optional link back to the Instagram post/reel that introduced the item;
- related Discover items from the same category;
- internal ASDEV CTAs to relevant owned surfaces such as case studies, Audit readiness, services, or qualification;
- canonical metadata, hreflang, breadcrumb structured data, and noindex behavior for drafts because drafts must never resolve publicly.

The external CTA may point to the third-party product, but UTM parameters from the ASDEV acquisition session must not be copied onto third-party URLs.

## Data architecture

Discover gets its own Prisma model in the existing SQLite database. No second database, service, auth system, runtime, CDN, or repository is introduced.

```prisma
model DiscoverItem {
  id           String    @id @default(cuid())
  slug         String    @unique
  title        String
  description  String
  content      String
  externalUrl  String
  category     String
  tags         String
  imageUrl     String?
  instagramUrl String?
  featured     Boolean   @default(false)
  published    Boolean   @default(false)
  order        Int       @default(0)
  publishedAt  DateTime?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt

  @@index([published, featured, order])
  @@index([category, published])
}
```

### Legacy compatibility

The existing `Project.contentType = "discover"` implementation is historical state and must not be deleted in this change.

The migration creates `DiscoverItem` and copies existing Discover Project rows into it so live content is not silently lost. For copied rows:

- `id` is prefixed with `legacy-`;
- `slug` is `legacy-<project id>` to guarantee uniqueness without unsafe title transliteration;
- `title`, `description`, `longDescription`, tags, image, featured, order, publication state, and timestamps are preserved where possible;
- `externalUrl` uses `liveUrl`, then `githubUrl`, otherwise the ASDEV home URL as a safe fallback;
- category is `Legacy` so the owner can reclassify it from Admin;
- original Project rows remain untouched for rollback/history.

New Discover content is created only in `DiscoverItem`.

## Admin architecture

The existing Admin session and access controls remain the only admin authentication mechanism.

A separate **Discover** tab is added to the current Admin dashboard. It must support:

- list and search;
- create and edit;
- slug editing with validation;
- category and tags;
- short description and guide content;
- external HTTPS URL;
- optional Instagram HTTPS URL and image HTTPS URL;
- Draft / Published state;
- Featured state;
- numeric ordering;
- delete with explicit confirmation;
- public preview link for published items.

The existing Projects manager remains for portfolio content and must no longer be the primary editor for new Discover items.

## Admin API

Create `/api/admin/discover` using the existing `enforceAdminAccess`, rate limiting, common API headers, logging, sanitization, and Zod conventions.

Supported methods:

- `GET` — list all Discover items with optional `published`, `category`, and search filters;
- `POST` — create a Discover item;
- `PATCH` — update an existing item by id;
- `DELETE` — delete by id.

Validation requirements:

- slug: lowercase ASCII letters, digits, and hyphens only; 2–100 characters; no leading/trailing hyphen;
- title: 1–140 chars;
- description: 1–400 chars;
- content: 1–8000 chars;
- category: 1–60 chars;
- tags: normalized and deduplicated, max 20 tags, each max 40 chars;
- external URL: required HTTPS without embedded username/password;
- Instagram URL: optional HTTPS without credentials and hostname ending in `instagram.com`;
- image URL: optional HTTPS without credentials;
- order: non-negative integer;
- publish transition: setting `published=true` sets `publishedAt` when it is currently null; unpublishing does not erase publication history.

Slug conflicts return HTTP 409 instead of a generic 500.

## Attribution and analytics

Only campaign attribution needed for acquisition analysis is propagated internally:

- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_content`

Values are length-bounded and treated as opaque campaign text. No email, IP, username, Instagram account identifier, or arbitrary query string is copied into Discover analytics metadata.

Discover uses the existing consent-gated `trackEvent` client and `/api/analytics/events` endpoint.

Required events:

- `discover_landing_view` — landing viewed;
- `discover_item_view` — detail viewed;
- `discover_external_click` — official external CTA clicked;
- `discover_internal_cta_click` — Audit/services/case-study/qualification CTA clicked.

Metadata may include only safe fields such as `slug`, `category`, `target`, and approved UTM values.

Internal qualification links preserve the approved UTM values so existing Lead UTM capture can attribute downstream submissions.

## SEO and discovery

- `/discover` remains in the static sitemap manifest.
- Published detail routes are added to the runtime sitemap output from `DiscoverItem` data if the existing sitemap architecture supports dynamic DB entries; otherwise the detail route remains crawlable through internal links in this iteration and a follow-up issue is opened rather than inventing a parallel sitemap system.
- Each published detail page has unique title, description, canonical, hreflang, breadcrumb JSON-LD, and useful visible editorial copy.
- Drafts are neither linked publicly nor returned by the public detail query.
- Category/search UI must not create indexable duplicate query-page variants.

## Security and privacy

- No new secrets or external runtime dependencies.
- No HTML/Markdown renderer that allows raw HTML is introduced in this iteration; guide content is rendered as safe text paragraphs.
- All admin mutations require the existing admin access enforcement and rate limiting.
- Public queries select only fields required by the public UI.
- Third-party links use `target="_blank"` with `rel="noopener noreferrer"`.
- Analytics remain consent-gated and UI behavior does not depend on telemetry success.

## Scope boundaries

Included:

- separate Discover data model and migration;
- public landing and detail pages;
- category/search filtering;
- Admin CRUD;
- attribution propagation and Discover analytics events;
- internal conversion CTAs;
- SEO metadata and accessibility coverage;
- tests and documentation.

Not included:

- production deployment;
- public pricing or payment activation;
- Instagram API ingestion or automated scraping;
- affiliate-link monetization;
- rich WYSIWYG/Markdown CMS;
- automated translation;
- separate Discover service, database, or domain.

## Definition of Done

1. Existing Discover Project content is preserved by migration and original Project rows remain unchanged.
2. New content can be created, edited, published, unpublished, featured, ordered, previewed, and deleted from Admin.
3. `/discover` lists only published `DiscoverItem` records and links internally to `/discover/[slug]`.
4. `/discover/[slug]` returns only published records and presents guide, official link, related items, and ASDEV CTAs.
5. Search/category filtering works accessibly on mobile and desktop.
6. UTM parameters survive internal Discover navigation and qualification CTAs without being leaked to third-party URLs.
7. Consent-gated Discover funnel events are emitted with bounded non-PII metadata.
8. Slugs and URLs are validated server-side and slug conflicts return 409.
9. Focused unit/integration tests, type-check, lint, full Vitest suite, build, and relevant E2E/a11y checks are green in protected CI before merge.
10. No production deployment or production DB migration is performed by this implementation without a separate explicit owner approval.
