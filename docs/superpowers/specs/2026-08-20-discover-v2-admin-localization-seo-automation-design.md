# Discover v2 — Admin UX, Localization, SEO and Self-Hosted Automation Design

**Date:** 2026-08-20  
**Repository:** `alirezasafaei-dev/alirezasafaeisystems`  
**Tracker:** #189  
**Related growth loop:** #188  
**Status:** Owner-approved direction; written design awaiting final owner review before implementation planning

## 1. Context

Discover is already production-complete and must remain an owned resource hub inside the existing ASDEV Next.js application. The current foundation is intentionally retained:

- Next.js 16 / React 19 / TypeScript / Tailwind 4;
- existing authenticated Admin;
- existing Prisma-backed `DiscoverItem` CRUD;
- existing analytics and consent model;
- existing `/discover` and `/discover/[slug]` routes;
- existing deployment, migration, rollback and live-verification contracts;
- zero-deploy editorial updates for normal resource content.

This design does **not** create a parallel CMS, service, worker or database.

The upgrade exists because the current implementation is functionally correct but operationally and editorially immature in four areas:

1. the Discover Admin form is visually raw and mixes RTL Persian content with LTR URLs/identifiers poorly;
2. Persian and English Discover routes currently share the same resource title/description/content fields;
3. category values are displayed as raw database strings, so English labels such as `AI` leak into the Persian interface;
4. public Discover UI, SEO semantics and content-ingestion workflow can be made substantially more usable and repeatable without paid services or unavailable social APIs.

## 2. Product goals

This work directly supports the ASDEV Audit focus by improving acquisition and trust: social traffic reaches a credible owned resource page, users get the promised resource quickly, and qualified users can continue into ASDEV surfaces without the resource experience feeling like a lead trap.

Primary goals:

1. Make publishing a high-quality Discover resource fast and difficult to get wrong.
2. Make Persian the first-class experience while preserving a genuinely localized English surface.
3. Make `/discover` look and behave like a professional resource hub rather than a generic card list.
4. Improve organic search quality without creating thin, duplicated or misleading pages.
5. Automate deterministic parts of the workflow with repository-local tooling and existing infrastructure.
6. Avoid Meta API, Instagram automation dependencies, ManyChat, Zapier, Make, paid design/AI services, or any runtime SaaS dependency for the core workflow.

## 3. Non-goals

This iteration does not introduce:

- a WYSIWYG/Markdown execution engine;
- a media upload/storage platform;
- a generic page builder;
- multiple Admin roles or a new auth system;
- automatic Instagram scraping;
- automatic translation by a paid/external AI API;
- Telegram Bot API integration;
- a separate content service;
- a new database;
- a new analytics vendor;
- arbitrary user-defined category creation in production.

These are intentionally excluded until real usage proves a requirement.

## 4. UI/UX design intelligence source

The project will use the open-source `nextlevelbuilder/ui-ux-pro-max-skill` as an implementation-time design-intelligence source.

### 4.1 Pinned upstream

The initial vendored reference is pinned to upstream commit:

`bc826e2267a36d98a2dcf5231e16c30ff546770f`

Repository:

`https://github.com/nextlevelbuilder/ui-ux-pro-max-skill`

License: MIT.

### 4.2 Vendoring strategy

Do not globally install the UI UX Pro Max CLI and do not add a runtime dependency.

Vendor only the open-source core skill needed by agents under:

`.agents/skills/ui-ux-pro-max/`

The vendored snapshot contains the upstream skill's `SKILL.md`, local searchable data, references and Python scripts plus:

- copied MIT `LICENSE`;
- `UPSTREAM.md` recording upstream repository, exact commit and acquisition date;
- a deterministic checksum/provenance manifest for the vendored files.

The skill's search script uses Python standard library only. Agent usage therefore remains local/offline after vendoring.

### 4.3 Required design queries during implementation

Before implementing public Discover or Discover Admin visual changes, Codex must use the vendored local skill to generate and inspect a coherent design direction, then supplement it with focused queries for:

- accessible forms and inline validation;
- RTL/LTR resilient text layout;
- search/filter/chip interaction;
- responsive cards and resource-detail hierarchy;
- keyboard/focus behavior;
- Next.js implementation guidance.

Persist the chosen design system in-repo so it becomes durable design Source of Truth. Page-specific overrides are expected for:

- Discover Admin;
- Discover landing;
- Discover detail.

The generated guidance is advisory and never overrides repository governance or accessibility/security requirements.

## 5. Information architecture and Persian navigation

The Persian public navigation must not leak English labels when a clear Persian equivalent exists.

Approved Persian primary navigation labels:

| Route | Persian label |
| --- | --- |
| `/` | خانه |
| `/services` | خدمات |
| `/case-studies` | مطالعات موردی |
| `/discover` | **ابزارها و منابع** |
| `/audit-readiness` | آمادگی ارزیابی فنی |
| `/qualification` | تماس |

The English navigation remains English.

The same terminology must be used in Header, mobile navigation, Footer quick links, breadcrumbs and Discover copy. `Discover` may remain an internal route/product identifier, but it is not the visible Persian navigation label.

All Discover user-facing copy should move into the existing i18n Source of Truth instead of accumulating page-local Persian/English ternaries.

## 6. Bilingual content model

### 6.1 Backward-compatible fields

Persian remains the base editorial language because existing production content already occupies the current fields.

Retain current fields:

- `title` — Persian/base title;
- `description` — Persian/base short description;
- `content` — Persian/base practical guide;
- `published` — Persian/base publication state.

Add nullable/additive English fields:

- `titleEn String?`
- `descriptionEn String?`
- `contentEn String?`
- `publishedEn Boolean @default(false)`

No existing production content is rewritten or deleted by this migration.

### 6.2 Publication rules

Persian publication:

- requires current Persian/base fields and `published = true`;
- behaves exactly like the current production contract after migration.

English publication:

- requires non-empty `titleEn`, `descriptionEn`, `contentEn`;
- requires `publishedEn = true`;
- `/en/discover/[slug]` returns 404 for an item that is not English-published;
- English sitemap/structured-data entries include only English-published resources.

This avoids serving Persian content as if it were an English page and avoids thin/duplicated English SEO surfaces.

Admin may show English completeness status even when `publishedEn` is false.

### 6.3 Shared fields

The following remain locale-neutral:

- `slug`;
- `externalUrl`;
- `instagramUrl`;
- `telegramGuideUrl`;
- `imageUrl`;
- `category` canonical key;
- `tags` for the current iteration;
- `featured`;
- `order`.

A separate translated-tag model is not introduced in this iteration. Search may match shared tags plus localized title/description/category labels.

## 7. Category architecture

The `category` database field becomes a **canonical machine key**, not display copy.

Initial allowed registry:

| Key | Persian | English |
| --- | --- | --- |
| `ai` | هوش مصنوعی | AI |
| `productivity` | بهره‌وری | Productivity |
| `developer-tools` | ابزار توسعه | Developer Tools |
| `automation` | اتوماسیون | Automation |
| `research` | تحقیق و پژوهش | Research |
| `image-video` | تصویر و ویدیو | Image & Video |
| `telegram` | تلگرام | Telegram |
| `general` | عمومی | General |

The exact list may be reduced during implementation if current real content does not need every key, but agents must not invent category labels ad hoc in Admin.

### 7.1 Legacy normalization

A safe migration/backfill maps known legacy values such as `AI` to `ai`.

Unknown legacy category values must not be silently destroyed. Migration logic must either map them through an explicit reviewed alias table or preserve them until manually resolved.

### 7.2 Category Source of Truth

A typed registry such as `src/lib/discover-categories.ts` owns:

- allowed keys;
- Persian label;
- English label;
- optional icon identifier from the existing Lucide icon set;
- deterministic display order.

Admin uses a select/combobox from this registry instead of a free-text category field.

Adding a brand-new category is allowed to require a code deploy; ordinary resource additions remain zero-deploy.

## 8. Discover Admin v2

The Discover manager remains the only authenticated editorial control surface.

### 8.1 Layout

Desktop:

- structured editor area plus a live preview/status rail;
- clear card/section grouping rather than one long undifferentiated form.

Mobile/tablet:

- one-column flow;
- preview becomes a collapsible section or secondary tab;
- all controls meet touch-target requirements.

### 8.2 Form sections

1. **وضعیت انتشار** — Persian/English publish state, Featured, sort order, completeness.
2. **محتوای فارسی** — title, description, practical guide.
3. **English content** — title, description, practical guide and English readiness.
4. **دسته‌بندی و برچسب‌ها** — canonical category selector and tags.
5. **لینک‌ها و منبع** — official URL, Instagram source, Telegram exact guide/file, image URL.
6. **پیش‌نمایش و SEO** — slug/canonical preview, search-result preview, public route links.

### 8.3 Directionality

Discover Admin is Persian-first and uses RTL layout by default.

Force `dir="ltr"` and left alignment for:

- slug;
- HTTPS URLs;
- Telegram handles/URLs;
- Instagram URLs;
- machine identifiers.

Persian textareas remain RTL. English fields are LTR.

This directionality must be semantic, not achieved by inserting Unicode direction hacks into stored data.

### 8.4 Validation and feedback

- Visible label for every field; no placeholder-only fields.
- Inline field-level errors near the failing input.
- Server validation remains authoritative.
- Unsaved/saving/saved state is visible.
- Publish controls explain why a locale cannot be published when required fields are missing.
- Destructive delete retains explicit confirmation.
- Slug conflict feedback remains specific.
- URL fields clearly identify allowed destination semantics.

### 8.5 Local draft recovery

Use browser `localStorage` only for non-sensitive unsaved Discover form state.

Rules:

- store no Admin session/token/secret;
- key drafts by new-item vs item id;
- surface a clear "بازیابی پیش‌نویس ذخیره‌نشده" choice;
- clear the recovered draft after a successful authoritative save;
- do not silently overwrite newer server data.

This provides failure recovery without external services.

### 8.6 Preview

Live preview shows the effective Persian or English card/detail copy before saving.

For a saved/published item, Admin also exposes explicit links to the corresponding public FA/EN routes only when that locale is published.

### 8.7 JSON import/export

Add a safe deterministic editorial acceleration path:

- **Import JSON** parses a resource manifest in the browser and populates the form; it does not bypass server validation or silently publish.
- **Export JSON** emits the current normalized resource payload for review/versioning/reuse.

This enables ChatGPT/Codex to prepare a validated payload that the owner can import in seconds without giving an external service direct Admin access.

## 9. Resource manifest automation

### 9.1 Manifest purpose

Repository resource manifests are optional operational artifacts, not runtime content storage. Production content remains in the existing database.

Suggested location:

`docs/discover/resources/<slug>.json`

A manifest mirrors the Admin/API payload and may include evidence-only metadata in a separate non-persisted section, such as source Reel URL or verification notes.

### 9.2 Validation

Use the existing Zod Discover schemas as the single validation contract.

Add a focused Vitest-based manifest validation command that scans repository manifests and parses their persisted payload through the production schema. This avoids adding a new CLI framework or validation dependency.

Expected script surface:

`pnpm discover:validate`

The command must be deterministic and network-free.

### 9.3 No automatic social scraping

The automation contract explicitly does **not** depend on Instagram/Meta APIs or scraping.

A new resource can originate from:

- owner-provided Reel/post URL and copy;
- authoritative public website/bot URL;
- repository evidence;
- manual Admin content.

Agents may research public authoritative sources when available, but missing social API access is never a blocker for the core system.

## 10. Public Discover v2 — landing

The landing page remains `/discover`; no new public hub route is introduced.

### 10.1 Hierarchy

1. concise resource-hub hero;
2. prominent search;
3. localized category filters;
4. optional Featured resources hierarchy when real featured items exist;
5. full result grid/list;
6. restrained secondary ASDEV continuation.

The page should answer within the first viewport:

- where am I?
- how do I find the tool mentioned on Instagram?
- is this ASDEV's explanation or the third party's official product?

### 10.2 Search/filter behavior

- Search matches effective localized title/description, localized category label and shared tags.
- Category chips use localized labels, never raw DB values.
- Active filter state is programmatically exposed.
- Search/filter result count is announced accessibly without noisy updates.
- Clear/reset state is obvious when filters are active.
- No horizontal-scroll dependency for core category access.
- Empty state offers a useful reset action.

### 10.3 Resource cards

Cards prioritize:

- title;
- concise description;
- localized category;
- optional Featured state;
- image when available;
- restrained tags;
- one unambiguous CTA to open the internal guide.

The full card need not become a giant clickable region if doing so harms semantics; however the primary action must have a sufficiently large touch target.

Use Lucide/SVG icons, not emoji icons.

### 10.4 Visual direction

Preserve the ASDEV dark visual language but move Discover toward a content-first, high-trust editorial/tool-library feel:

- restrained surfaces and depth;
- strong hierarchy rather than decorative gradients;
- readable typography and generous line-height;
- subtle interaction feedback;
- no generic AI-purple/pink visual cliché;
- no heavy animation;
- no style mixing that makes cards/admin feel like separate products.

The persisted UI UX Pro Max design system may refine tokens/layout after repository-local queries, but it cannot violate these product constraints.

## 11. Public Discover v2 — detail

Detail hierarchy:

1. breadcrumb/back context;
2. resource identity and localized category;
3. editorial disclosure/trust context when relevant;
4. concise description and practical guide;
5. primary official-resource CTA;
6. optional exact Telegram guide/file CTA;
7. Instagram source/provenance;
8. related resources;
9. visually subordinate ASDEV continuation.

### 11.1 Third-party disclosure

Resource pages must make it clear when ASDEV is describing a third-party product.

Do not imply that ASDEV owns DeepSeek, Telegram bots, tools or services it merely reviews/recommends.

The DeepSeek G.Media bot resource is an important acceptance case: visible copy must retain that it is **not the official DeepSeek bot**.

### 11.2 CTA semantics

- `externalUrl` = actual resource destination;
- `telegramGuideUrl` = exact ASDEV tutorial/file message when present, not the bot/channel homepage;
- `instagramUrl` = source post/reel;
- internal ASDEV attribution is not appended to external/Telegram/Instagram destinations.

CTA labels should adapt to destination semantics where practical. For example a Telegram bot resource should not say "باز کردن سایت رسمی" if the destination is a bot; use a neutral "باز کردن منبع" / "Open resource" or a validated destination-specific label.

## 12. SEO v2

### 12.1 Locale correctness

- Persian published resources have canonical Persian URLs.
- English alternates are emitted only when the English locale is actually published.
- English detail pages do not exist/index until English content is complete and `publishedEn` is true.
- `x-default` remains Persian/base.

This prevents misleading hreflang pairs.

### 12.2 Metadata

Landing and detail metadata use effective locale-specific copy.

For detail pages:

- localized title;
- localized description;
- canonical;
- conditional hreflang;
- Open Graph title/description/url;
- safe image when available, otherwise existing site default;
- robots noindex for unpublished/non-resolvable locale variants.

Dedicated editable SEO title/description fields are intentionally not introduced yet. Editorial title/description are the Source of Truth until real data proves that separate SEO copy is needed.

### 12.3 Structured data

Landing:

- `CollectionPage` and/or truthful `ItemList` describing published resource detail URLs.

Detail:

- Breadcrumb structured data;
- editorial `WebPage`/`Article`-appropriate schema describing the ASDEV guide page.

Do **not** use a schema type that falsely represents ASDEV as the producer/owner of a third-party product.

Structured data must not claim ratings, price, official affiliation or capabilities that have not been verified.

### 12.4 Sitemap

- Persian sitemap entries require `published`.
- English resource entries require `publishedEn` and complete English copy.
- no draft or incomplete locale entry appears.
- dynamic sitemap behavior remains exact and production-tested.

### 12.5 Performance and accessibility SEO gates

Retain existing Lighthouse CI and axe/Playwright gates.

Discover v2 acceptance additionally checks:

- no horizontal overflow at supported widths;
- contrast >= 4.5:1 for normal text;
- visible keyboard focus;
- minimum practical touch target around 44x44px for primary interactive controls;
- reduced-motion preference respected;
- images reserve layout space to avoid avoidable CLS;
- no broken structured data/canonical/hreflang after localization changes.

## 13. Analytics and attribution

Retain current consent-aware Discover events and safe allowlisted UTM behavior.

The v2 work must not add a third-party analytics dependency.

Existing funnel remains measurable:

`discover_landing_view → discover_item_view → discover_external_click / Telegram clicks / internal CTA click`

Add locale/category semantics to analysis only through existing safe metadata policy. Do not store external URLs, Telegram usernames, arbitrary query strings or PII in telemetry.

Admin actions are not required to become analytics events in this iteration.

## 14. Testing strategy

### 14.1 Unit/integration

Cover at minimum:

- bilingual create/update validation;
- `publishedEn` completeness rules;
- category registry and legacy normalization;
- localized effective-content selection;
- conditional hreflang;
- sitemap locale rules;
- JSON manifest import normalization;
- local draft recovery helpers where logic is non-trivial;
- existing attribution/external-link safety regression.

### 14.2 Component tests

Cover:

- Admin field directions RTL/LTR;
- inline validation/accessibility semantics;
- locale tabs/sections and completeness state;
- category localized labels;
- landing filter/search behavior;
- detail CTA labels and disclosure behavior.

### 14.3 Browser tests

Playwright must cover desktop and mobile for:

- `/admin` Discover create/edit flow;
- Persian landing and detail;
- English landing and English-published detail;
- English-unpublished detail not resolving/indexing;
- search and localized category filter;
- hard refresh;
- keyboard navigation;
- no horizontal overflow;
- exact external/Telegram hrefs;
- sitemap presence rules.

A11y tests run on Admin Discover plus public FA/EN surfaces.

### 14.4 Quality/security gates

For runtime changes, the relevant final gate includes at least:

- lint;
- type-check;
- Vitest suite;
- build;
- E2E smoke;
- a11y;
- Lighthouse CI;
- high/critical dependency audit;
- secret scan;
- existing repository security checks.

No gate is weakened to make the change pass.

## 15. Migration, deployment and rollback

Schema changes are additive only.

Before production migration:

- production DB snapshot under existing deployment contract;
- Prisma validate/generate/migrate status;
- migration replay test;
- explicit zero-drift evidence.

Migration must not delete or rewrite legacy Discover content except explicitly reviewed category normalization.

Production deployment remains governed by the exact repository approval gates. This design approval is **not** itself permission to bypass a production-deployment or migration gate.

Rollback uses the existing release/snapshot contract. If an application rollback targets a version that predates the additive columns, the database remains forward-compatible because added fields are nullable/defaulted and non-destructive.

## 16. Automation operating loop after v2

Normal resource workflow becomes:

1. owner supplies Reel/post/source and resource identity;
2. agent researches authoritative destination and prepares a resource manifest;
3. `pnpm discover:validate` validates repository manifests offline when committed;
4. owner imports JSON into Discover Admin or edits directly;
5. Admin shows locale completeness, preview and validation;
6. owner publishes Persian immediately and English when complete;
7. no code deploy is required for ordinary resource edits/publish/unpublish;
8. public smoke verifies route, CTA, sitemap and telemetry as appropriate;
9. Growth Loop #188 compares real content/traffic behavior and chooses the next experiment.

No Meta/Instagram API is required for this loop.

## 17. Implementation sequencing

Implementation should proceed in dependency order, not as one giant patch:

1. vendor/pin UI UX Pro Max core skill and persist design-system evidence;
2. localization/category foundations and tests;
3. additive bilingual Prisma/API model and migration tests;
4. Discover Admin v2;
5. public landing v2;
6. public detail v2;
7. SEO/sitemap/structured-data hardening;
8. manifest import/export and offline validation;
9. full regression/security/accessibility/performance verification;
10. production rollout under approval gates;
11. exact live browser verification and durable evidence;
12. resume Growth Loop #188 with the DeepSeek Telegram bot as an acceptance resource.

Each phase must preserve a working system and may be split into focused PRs.

## 18. Definition of Done

Discover v2 is complete only when all of the following are objectively proven:

- Persian navigation displays **ابزارها و منابع** and no avoidable English labels in the approved Persian navigation/category surfaces;
- current production resources remain intact after migration;
- Admin is Persian-first, directionally correct, responsive, accessible and materially faster/safer to use;
- Persian and English resource publication are genuinely separated with correct content/SEO behavior;
- canonical category keys render localized labels consistently;
- public landing/detail meet approved information hierarchy and responsive/accessibility requirements;
- SEO canonical/hreflang/sitemap/structured data are correct for each locale publication state;
- UI UX Pro Max is vendored at a pinned upstream commit with MIT license/provenance and actually used to produce durable design guidance;
- manifest import/export and repository validation work without paid/external services;
- ordinary Discover content additions remain zero-deploy;
- all required CI/security/a11y/Lighthouse gates pass;
- production migration/deploy, if required, follows approval gates and has exact SHA/release/rollback evidence;
- two consecutive live browser verification passes cover Admin/public critical routes after production rollout;
- #189 records final evidence and only then closes;
- Growth Loop #188 can continue using the upgraded system.

## 19. Acceptance resource

The first real resource used to validate the upgraded editorial flow is:

`deepseek-telegram-bot`

Source Reel:

`https://www.instagram.com/p/Db9O3I-M6Dy/`

Verified destination:

`https://t.me/deepseek_gidbot`

Its disclosure that the bot is third-party/non-official must remain intact during any content migration or UI redesign.
