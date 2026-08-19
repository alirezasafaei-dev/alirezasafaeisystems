# Discover Resource Hub Evolution — Design

**Date:** 2026-08-19  
**Repository:** `alirezasafaei-dev/alirezasafaeisystems`  
**Public surface:** `https://alirezasafaeisystems.ir/discover`  
**Status:** Owner-approved design; implementation tracked by `docs/superpowers/plans/2026-08-19-discover-resource-hub.md` and roadmap issue #174

## Context

The current Discover implementation is already a production-oriented acquisition surface with:

- a dedicated `DiscoverItem` Prisma model in the existing SQLite database;
- `/discover` and `/discover/[slug]` public routes;
- search and category filtering;
- Admin CRUD with draft/publish, featured and ordering controls;
- official-link and Instagram-source destinations;
- UTM propagation for internal ASDEV navigation;
- consent-aware Discover analytics;
- published-item sitemap support;
- production migration, rollback and post-deploy smoke contracts.

That architecture remains the foundation. This design does not replace Discover, create a new service, or introduce a parallel CMS.

The product role changes from a primarily ASDEV-conversion-oriented acquisition surface into an **owned content and resource hub** whose first responsibility is to help a visitor reach the exact resource they came for from Instagram.

## Product objective

The user-facing contract is:

> A person who discovers a tool, app, AI service or tutorial through ASDEV social content should be able to open one stable ASDEV link and quickly reach the official product, a short practical explanation, the complete tutorial or file, and a place to ask follow-up questions.

Primary funnel:

`Instagram / Search / Direct → /discover → /discover/[slug] → quick guide → official destination and/or exact Telegram tutorial/file → optional community discussion`

Secondary funnel:

`Discover → related ASDEV content / brand surfaces`

The secondary ASDEV funnel must not interrupt the primary resource-retrieval task.

## Design principles

1. **User intent first.** The page prioritizes the resource promised in the social content before portfolio, Audit or qualification CTAs.
2. **One stable bio destination.** `/discover` is suitable as the primary link in the Instagram bio.
3. **Exact deep links, not channel scavenger hunts.** When a complete tutorial or file exists in Telegram, the Discover item links directly to that Telegram message/post whenever possible.
4. **Official sources remain explicit.** Third-party product ownership and the official destination are clearly distinguished from ASDEV editorial guidance.
5. **Zero-deploy editorial updates.** Per-item resource links remain database-managed through the existing Admin interface.
6. **No Instagram automation dependency.** This design does not depend on Instagram APIs, scraping, comment automation, ManyChat-like services or unofficial automation.
7. **No parallel platform.** Existing Next.js, Prisma/SQLite, Admin authentication, analytics and deployment contracts are reused.
8. **Progressive enhancement.** Missing Telegram resources do not break an item; the page simply omits unavailable actions.

## User experience

### `/discover`

The landing page remains the searchable index and must continue to:

- list only published Discover items;
- support title/description/category/tag search;
- support category filtering;
- keep featured/order/newness sorting semantics;
- route cards to the internal detail page rather than directly to an external service;
- preserve approved UTM attribution across internal Discover navigation;
- work in Persian and English site shells;
- remain useful when there are zero published items.

The landing copy should evolve from a generic acquisition message to a clearer resource-hub promise. The user should understand that this is where ASDEV collects links, short guides and full resources referenced from Instagram.

No second landing page is introduced.

### `/discover/[slug]`

The detail page becomes the canonical resolution point for a social-media resource.

The information hierarchy is:

1. **Identity and context** — title, description, category, tags, image and optional featured state.
2. **Quick guide** — the existing safe-text editorial `content` field, optimized for a concise practical explanation.
3. **Primary action cluster** — official destination first, exact full tutorial/file on Telegram when configured, and Instagram source as a secondary provenance link.
4. **Community continuation** — optional global Telegram channel and question/group destinations.
5. **Related Discover items** — same-category or otherwise relevant Discover items.
6. **Secondary ASDEV navigation** — brand/business links remain available but visually subordinate to the resource task.

The existing strong Audit/qualification callout must no longer dominate every Discover item. It can be reduced to a secondary ASDEV section or contextual footer so users looking for a tool are not diverted before reaching it.

### Telegram actions

A Discover detail page may expose three distinct Telegram actions:

- **Exact tutorial/file** — item-specific deep link stored with that `DiscoverItem`, normally pointing to the exact Telegram message containing the complete tutorial, file or resource.
- **Channel** — global public ASDEV education/resource channel destination.
- **Question/group** — global public ASDEV discussion or question destination.

The exact tutorial/file action has higher priority than the global channel action because it fulfills the visitor's immediate intent.

If an item does not have a Telegram deep link, the exact tutorial/file CTA is omitted. If a global channel or group URL is not configured, its CTA is omitted. There are no dead or placeholder buttons.

## Data architecture

The existing `DiscoverItem` model remains authoritative. Add one nullable field:

```prisma
telegramGuideUrl String?
```

The field represents the canonical item-specific Telegram destination for the complete tutorial, file or resource.

No new content table is required in this iteration. The existing fields retain their roles:

- `content` — short practical guide shown on ASDEV;
- `externalUrl` — official third-party destination;
- `instagramUrl` — optional source post/reel;
- `telegramGuideUrl` — optional exact full tutorial/file destination;
- `category`, `tags`, `featured`, `published`, `order` — discovery and editorial controls.

### Why one field is sufficient

A separate attachment model, chapter model, WYSIWYG editor, tutorial collection or generic link table is intentionally not introduced. The immediate product need is one strong direct resource destination per Discover item. A future design can introduce multiple resources only when real content proves that requirement.

## Global Telegram configuration

The global channel and question/group destinations are public configuration, not per-item editorial content.

They should be represented through the existing site configuration/environment pattern as two optional validated public URLs:

- Telegram channel URL
- Telegram group/question URL

The implementation may ship with either global CTA disabled until a valid owner-provided URL is configured. This is preferable to committing placeholder handles or guessing the final Telegram identity.

Changing an item's exact tutorial/file link remains zero-deploy through Admin. Global channel/group identity changes are expected to be rare and may follow the existing production configuration process.

## Validation

### `telegramGuideUrl`

When present:

- must use HTTPS;
- must not contain embedded username/password credentials;
- hostname must be canonical Telegram web host `t.me`;
- URL length must be bounded consistently with existing URL validation policy;
- malformed or unsupported URLs are rejected server-side.

The same public URL validation policy applies to configured global Telegram destinations.

No Discover or campaign query parameters are appended to Telegram URLs.

## Admin UX

The existing Discover manager remains the only editorial control surface.

Add an optional field to the create/edit form:

- **Telegram full guide / file URL**

The helper copy should explain that the preferred value is the direct `t.me/.../<message-id>` link to the exact tutorial or file rather than the channel home page.

Admin behavior continues to support:

- create;
- edit;
- publish/unpublish;
- featured;
- ordering;
- delete confirmation;
- public preview for published items;
- search/filtering of the library.

No new Admin authentication or role system is introduced.

## API contract

The existing `/api/admin/discover` endpoint remains authoritative.

Extend create and update schemas and persistence to support optional `telegramGuideUrl`.

Requirements:

- GET returns the field to authenticated Admin consumers;
- POST validates and stores it;
- PATCH validates updates and supports clearing it to `null`;
- DELETE behavior is unchanged;
- public pages never expose unpublished records;
- slug conflict and current HTTP semantics remain unchanged.

No new public CRUD API is created.

## Attribution and analytics

The existing internal attribution allowlist remains:

- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_content`

These values continue to propagate only across approved internal ASDEV navigation.

They must **not** be copied onto:

- official third-party product URLs;
- Instagram source URLs;
- Telegram tutorial/file URLs;
- Telegram channel URLs;
- Telegram group/question URLs.

### Existing events retained

- `discover_landing_view`
- `discover_item_view`
- `discover_external_click`
- `discover_internal_cta_click`

### New events

Add distinct consent-gated events so the resource funnel can be measured without conflating destinations:

- `discover_telegram_guide_click`
- `discover_telegram_channel_click`
- `discover_telegram_group_click`

Safe metadata may include:

- `slug`
- `category`
- `target`
- approved UTM values

Do not include Telegram usernames, full external URLs, user account identifiers, arbitrary query strings or other PII in analytics metadata.

Telemetry failure must never block navigation.

## SEO

The existing Discover SEO contract remains valid:

- canonical metadata on landing and published detail pages;
- hreflang for Persian/English site shells;
- breadcrumb JSON-LD;
- published-only dynamic sitemap entries;
- drafts absent from public navigation and public detail resolution;
- no indexable query/filter variants.

Telegram integration does not change canonical ownership: the ASDEV detail page remains the canonical editorial page, while Telegram is a resource destination.

The detail page must contain enough useful visible text to stand on its own instead of becoming a thin redirect page.

## Security and privacy

- No new secret is required for Telegram because these are ordinary public links, not Bot API integrations.
- No Telegram Bot API, webhook, polling worker or external automation service is introduced.
- Existing Admin authentication, rate limiting, logging, sanitization and request headers remain mandatory.
- Guide content continues to render as safe text; this iteration does not add raw HTML or Markdown execution.
- External destinations use safe new-tab semantics consistent with the current Discover link component.
- Telegram links receive no internal UTM or sensitive query data.
- The migration is additive and non-destructive.

## Database migration and rollback

Add a single nullable `telegramGuideUrl` column to `DiscoverItem` using Prisma migration.

Migration rules:

1. Existing Discover rows remain valid with `NULL` Telegram links.
2. No existing content is rewritten.
3. No `Project`, `Lead` or analytics rows are deleted or transformed.
4. Production migration uses the existing snapshot/preflight/deploy/status/rollback contract.
5. A migration failure must preserve or restore the previous application/database availability according to the hardened deployment scripts.

No data backfill is required. Telegram resource links can be added incrementally from Admin after deployment.

## Content operating model

For each Instagram reel/post that references a tool or resource, the intended workflow is:

1. Create or update the matching Discover item.
2. Keep the ASDEV quick guide concise and practical.
3. Verify the official destination.
4. Upload the complete tutorial/file to the Telegram channel when a long-form resource is needed.
5. Copy the exact Telegram message URL into `telegramGuideUrl`.
6. Publish the Discover item.
7. In Instagram caption or pinned comment, route the audience to the single `/discover` bio link and tell them what title/category to open.
8. Use the Telegram group/question destination only for discussion, not as the canonical file archive.

This keeps Instagram low-risk, Discover indexable and controlled, Telegram suitable for long-form/file distribution, and each platform responsible for what it handles well.

## Testing strategy

Implementation must use the repository's existing test patterns and TDD workflow.

### Unit/schema tests

Cover:

- valid `https://t.me/...` guide URL;
- invalid protocol;
- invalid hostname;
- credential-bearing URL rejection;
- optional/nullable behavior;
- clearing an existing Telegram link.

### Admin/API tests

Cover:

- create with Telegram guide URL;
- update Telegram guide URL;
- clear Telegram guide URL;
- invalid Telegram URL returns validation error;
- existing authentication/rate-limit behavior remains enforced.

### Public contract tests

Cover:

- guide CTA renders only when configured;
- global channel/group CTAs render only when configured;
- official link remains primary and correct;
- Telegram URLs are not mutated with Discover UTM values;
- unpublished items remain inaccessible;
- ASDEV conversion section is visually/structurally secondary to the resource actions.

### Analytics tests

Cover the three new Telegram click event names, safe metadata contract and navigation independence from telemetry success.

### E2E / smoke

At minimum verify:

- `/discover` loads with a published item;
- detail route renders quick guide and official action;
- item-specific Telegram action appears when configured;
- Telegram action resolves to the stored external destination without appended UTM values;
- no Telegram button appears for missing configuration;
- Admin lifecycle can add/change/remove the Telegram resource link without redeploy;
- Persian mobile layout remains usable;
- existing Discover accessibility expectations stay green.

Production rollout retains the required post-deploy `/discover` smoke contract and should add a non-destructive check for the new detail-page action when a production item with a Telegram guide is intentionally configured.

## Observability and success criteria

The first useful product metrics are behavioral, not vanity metrics.

Track trends for:

- Discover landing → detail open;
- detail → official destination;
- detail → exact Telegram tutorial/file;
- detail → Telegram channel;
- detail → Telegram question/group;
- Discover → secondary ASDEV internal CTA.

The design is successful when users can reliably resolve a social-content promise without DM automation and the exact-resource Telegram click is measurable separately from generic channel joins.

No traffic, conversion or revenue claim should be made until real production data exists.

## Scope boundaries

### Included

- evolve Discover positioning into an owned resource hub;
- one optional item-specific Telegram tutorial/file deep link;
- optional global Telegram channel and question/group links;
- detail-page information hierarchy update;
- Admin/API support for the item-specific Telegram URL;
- destination-specific Telegram analytics events;
- additive Prisma migration;
- focused regression, accessibility and rollout coverage;
- documentation and agent-executable implementation planning after this design is approved.

### Not included

- Instagram API integration;
- Instagram comment/DM automation;
- ManyChat or Iranian ManyChat substitutes;
- Telegram Bot API or automatic channel posting;
- Telegram authentication;
- multiple Telegram resources per Discover item;
- file uploads hosted directly by ASDEV;
- WYSIWYG/Markdown CMS;
- automated translations;
- affiliate monetization;
- a new database, microservice, repository or domain;
- removal of the existing Discover analytics/SEO/admin foundation.

## Definition of Done

1. `DiscoverItem` supports an optional validated `telegramGuideUrl` without breaking existing rows.
2. Admin can create, update and clear the exact Telegram tutorial/file link without deployment.
3. Published detail pages prioritize quick guide and resource actions over business-conversion CTAs.
4. A configured item-specific Telegram link opens the exact stored destination and receives no ASDEV UTM propagation.
5. Optional global channel and question/group CTAs are configuration-driven and absent when not configured.
6. Official product and Instagram source links retain their current safe external-link behavior.
7. Three distinct consent-aware Telegram click events are emitted with bounded non-PII metadata.
8. Existing `/discover` search, category filtering, published-only boundary, SEO, sitemap and internal UTM attribution remain intact.
9. The Prisma migration is additive, non-destructive and covered by the existing production backup/rollback safety contract.
10. Focused unit/API/public/analytics/E2E/a11y tests are green, followed by repository-required CI/security/build gates on the exact implementation head.
11. Production rollout is not declared complete until the deployed route, database migration status and required Discover smoke evidence are verified on the live environment.

## Implementation sequencing recommendation

The approved implementation plan is committed at:

`docs/superpowers/plans/2026-08-19-discover-resource-hub.md`

GitHub execution tracking:

- Roadmap: #174
- Task 1: #175
- Task 2: #176
- Task 3: #177
- Task 4: #178
- Task 5: #179
- Task 6: #180
- Task 7: #181
- Task 8: #182

Dependency order:

`#175 → #176 → (#177 || #178) → #179 → #180 → #181 → #182`

Each slice is designed as an independently reviewable TDD unit with exact file targets, acceptance criteria and stop conditions.