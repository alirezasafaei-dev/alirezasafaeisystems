# Discover v2 — Admin UX, Localization, SEO and Self-Hosted Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the existing production Discover Resource Hub into a professional bilingual, SEO-correct, accessible and largely self-hosted publishing workflow while preserving zero-deploy ordinary resource publishing.

**Architecture:** Keep the current Next.js/Prisma/Admin/analytics foundation. Add backward-compatible English editorial fields and canonical category keys, refactor Discover validation/service boundaries, rebuild Admin and public Discover UI on the same API/data model, then add repository-local manifest validation and a pinned vendored UI UX Pro Max design-intelligence snapshot. Production migration/deployment remains governed by exact approval gates.

**Tech Stack:** Next.js 16, React 19, TypeScript 5.9, Tailwind CSS 4, Radix/shadcn-style components, Prisma 6 + SQLite production contract, Zod 4, Vitest 4, Playwright 1.58, Lighthouse CI, axe-core.

**Spec:** `docs/superpowers/specs/2026-08-20-discover-v2-admin-localization-seo-automation-design.md`

## Global Constraints

- Persian public navbar label for `/discover` is exactly **`ابزارها و منابع`**.
- Persian UI must use localized category labels; raw canonical DB keys are never public display copy.
- Existing Persian/base `title`, `description`, `content`, `published` remain backward compatible.
- English detail routes are indexable only when English content is complete and `publishedEn = true`.
- No parallel CMS, service, worker, database or analytics vendor.
- No Meta API, Instagram automation dependency, ManyChat, Zapier, Make or paid runtime SaaS.
- Ordinary resource additions remain zero-deploy through authenticated Admin/API.
- `slug`, URLs, Telegram handles and machine identifiers are semantic LTR fields; Persian editorial fields are RTL; English editorial fields are LTR.
- External/Telegram/Instagram destinations never receive internal ASDEV UTM parameters.
- UI UX Pro Max is vendored from upstream commit `bc826e2267a36d98a2dcf5231e16c30ff546770f`, MIT licensed, with provenance/checksums; no global install or runtime dependency.
- Use `t()` for user-facing reusable UI copy; do not add new page-local bilingual ternaries when translation keys are appropriate.
- Database changes are additive, migration-safe and rollback-verifiable.
- Do not trigger a production migration or production deployment without the repository's exact approval phrase required for that gate.
- Do not claim completion without exact live production evidence tied to the deployed SHA.

---

## File Structure and Boundaries

Create or evolve these focused units instead of making `discover-manager.tsx` and page components own all logic:

- `.agents/skills/ui-ux-pro-max/` — pinned vendored design skill, license, provenance, checksums.
- `design-system/asdev-discover/MASTER.md` — persisted design-system guidance.
- `design-system/asdev-discover/pages/admin.md` — Admin overrides.
- `design-system/asdev-discover/pages/landing.md` — Discover landing overrides.
- `design-system/asdev-discover/pages/detail.md` — Discover detail overrides.
- `src/lib/discover-categories.ts` — canonical category registry and localization helpers.
- `src/lib/discover.ts` — Zod payload schemas, attribution and locale-content helpers only.
- `src/lib/discover-service.ts` — server-side normalization/persistence helpers used by Admin API and manifest tests.
- `src/components/admin/discover/` — focused Admin editor, status, preview, import/export and draft-recovery components.
- `src/components/discover/` — public search/filter/cards/detail primitives.
- `docs/discover/resources/*.json` — optional validated operational manifests; never runtime content storage.
- `scripts/discover/validate-manifests.ts` — deterministic network-free manifest validator using production Zod schemas.

---

### Task 1: Vendor and Pin UI UX Pro Max, Then Persist the Discover Design System

**Files:**
- Create: `.agents/skills/ui-ux-pro-max/**`
- Create: `.agents/skills/ui-ux-pro-max/LICENSE`
- Create: `.agents/skills/ui-ux-pro-max/UPSTREAM.md`
- Create: `.agents/skills/ui-ux-pro-max/SHA256SUMS`
- Create: `design-system/asdev-discover/MASTER.md`
- Create: `design-system/asdev-discover/pages/admin.md`
- Create: `design-system/asdev-discover/pages/landing.md`
- Create: `design-system/asdev-discover/pages/detail.md`
- Test: repository provenance/checksum verification command run locally

**Interfaces:**
- Consumes: upstream `nextlevelbuilder/ui-ux-pro-max-skill` commit `bc826e2267a36d98a2dcf5231e16c30ff546770f`.
- Produces: local offline skill root `.agents/skills/ui-ux-pro-max/` and persisted Discover design guidance.

- [ ] **Step 1: Fetch only the exact upstream snapshot into a temporary directory**

```bash
set -euo pipefail
TMP_DIR="$(mktemp -d)"
git -C "$TMP_DIR" init upstream
git -C "$TMP_DIR/upstream" remote add origin https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git
git -C "$TMP_DIR/upstream" fetch --depth=1 origin bc826e2267a36d98a2dcf5231e16c30ff546770f
git -C "$TMP_DIR/upstream" checkout --detach FETCH_HEAD
test "$(git -C "$TMP_DIR/upstream" rev-parse HEAD)" = "bc826e2267a36d98a2dcf5231e16c30ff546770f"
```

Expected: exact SHA equality and exit code 0.

- [ ] **Step 2: Copy only the core skill and license into the repository**

```bash
rm -rf .agents/skills/ui-ux-pro-max
mkdir -p .agents/skills/ui-ux-pro-max
cp -R "$TMP_DIR/upstream/.claude/skills/ui-ux-pro-max/." .agents/skills/ui-ux-pro-max/
cp "$TMP_DIR/upstream/LICENSE" .agents/skills/ui-ux-pro-max/LICENSE
```

- [ ] **Step 3: Record provenance and deterministic checksums**

Create `.agents/skills/ui-ux-pro-max/UPSTREAM.md` with exact upstream repository, commit, MIT license and acquisition date `2026-08-20`, then run:

```bash
find .agents/skills/ui-ux-pro-max -type f ! -name SHA256SUMS -print0 \
  | sort -z \
  | xargs -0 sha256sum > .agents/skills/ui-ux-pro-max/SHA256SUMS
sha256sum --check .agents/skills/ui-ux-pro-max/SHA256SUMS
```

Expected: every entry `OK`.

- [ ] **Step 4: Run local design queries for the three target surfaces**

```bash
python .agents/skills/ui-ux-pro-max/scripts/search.py "AI resource hub editorial trust" --design-system -p "ASDEV Discover" --variance 5 --motion 3 --density 5 --persist --output-dir .
python .agents/skills/ui-ux-pro-max/scripts/search.py "accessible form inline validation rtl ltr" --domain ux
python .agents/skills/ui-ux-pro-max/scripts/search.py "search filter chips keyboard focus" --domain ux
python .agents/skills/ui-ux-pro-max/scripts/search.py "responsive cards resource library" --stack nextjs
```

Expected: non-empty relevant results. If one search is off-topic, retry once with a narrower explicit domain per the vendored skill contract.

- [ ] **Step 5: Persist page-specific overrides without overwriting the approved master constraints**

Create `admin.md`, `landing.md`, `detail.md` that capture only differences from `MASTER.md`, including RTL/LTR directionality, content-first card hierarchy, subtle motion, focus visibility, touch targets >=44px and no AI-purple/pink cliché.

- [ ] **Step 6: Commit**

```bash
git add .agents/skills/ui-ux-pro-max design-system/asdev-discover
git commit -m "chore(design): vendor UI UX Pro Max for Discover v2"
```

---

### Task 2: Add the Bilingual Data Contract and Canonical Category Registry

**Files:**
- Modify: `prisma/schema.prisma`
- Create: `prisma/migrations/<generated>_discover_v2_localization/migration.sql`
- Create: `src/lib/discover-categories.ts`
- Modify: `src/lib/discover.ts`
- Test: `src/__tests__/lib/discover-categories.test.ts`
- Test: `src/__tests__/lib/discover.test.ts`

**Interfaces:**
- Produces: `DiscoverCategoryKey`, `DISCOVER_CATEGORIES`, `getDiscoverCategoryLabel(key, locale)`, `normalizeDiscoverCategory(value)`, English payload fields `titleEn`, `descriptionEn`, `contentEn`, `publishedEn`.

- [ ] **Step 1: Write failing category registry tests**

```ts
expect(normalizeDiscoverCategory('AI')).toBe('ai')
expect(getDiscoverCategoryLabel('ai', 'fa')).toBe('هوش مصنوعی')
expect(getDiscoverCategoryLabel('ai', 'en')).toBe('AI')
expect(() => normalizeDiscoverCategory('made-up')).toThrow()
```

- [ ] **Step 2: Run the focused tests and confirm failure**

```bash
pnpm vitest run src/__tests__/lib/discover-categories.test.ts
```

Expected: FAIL because registry helpers do not exist.

- [ ] **Step 3: Implement the typed canonical registry**

Use this public shape:

```ts
export const DISCOVER_CATEGORIES = {
  ai: { fa: 'هوش مصنوعی', en: 'AI', order: 10 },
  productivity: { fa: 'بهره‌وری', en: 'Productivity', order: 20 },
  'developer-tools': { fa: 'ابزار توسعه', en: 'Developer Tools', order: 30 },
  automation: { fa: 'اتوماسیون', en: 'Automation', order: 40 },
  research: { fa: 'تحقیق و پژوهش', en: 'Research', order: 50 },
  'image-video': { fa: 'تصویر و ویدیو', en: 'Image & Video', order: 60 },
  telegram: { fa: 'تلگرام', en: 'Telegram', order: 70 },
  general: { fa: 'عمومی', en: 'General', order: 80 },
} as const
```

Add an explicit alias table including at least `AI -> ai`; unknown values must throw rather than silently mutate.

- [ ] **Step 4: Add English fields to Prisma**

Add to `DiscoverItem`:

```prisma
titleEn       String?
descriptionEn String?
contentEn     String?
publishedEn   Boolean @default(false)
```

- [ ] **Step 5: Generate an additive migration and inspect SQL before applying locally**

```bash
pnpm exec prisma migrate dev --name discover_v2_localization --create-only
cat prisma/migrations/*discover_v2_localization/migration.sql
```

Expected SQL: additive columns plus explicit reviewed category normalization only; no DROP TABLE/data-destructive statements.

- [ ] **Step 6: Extend Zod create/update schemas with English publication invariants**

Rules:

```ts
publishedEn === true
```

requires trimmed non-empty `titleEn`, `descriptionEn`, `contentEn`. English fields remain nullable/optional while `publishedEn` is false.

- [ ] **Step 7: Run focused tests**

```bash
pnpm vitest run src/__tests__/lib/discover-categories.test.ts src/__tests__/lib/discover.test.ts
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add prisma/schema.prisma prisma/migrations src/lib/discover-categories.ts src/lib/discover.ts src/__tests__/lib
git commit -m "feat(discover): add bilingual content and category registry"
```

---

### Task 3: Centralize Discover Persistence and Extend the Admin API

**Files:**
- Create: `src/lib/discover-service.ts`
- Modify: `src/app/api/admin/discover/route.ts`
- Modify: `src/__tests__/api/admin-discover.integration.test.ts`
- Test: `src/__tests__/lib/discover-service.test.ts`

**Interfaces:**
- Produces:

```ts
normalizeDiscoverCreateInput(input: DiscoverCreateInput): Prisma.DiscoverItemCreateInput
normalizeDiscoverUpdateInput(input: DiscoverUpdateInput, current: { publishedAt: Date | null }): Prisma.DiscoverItemUpdateInput
```

- [ ] **Step 1: Add failing service tests for sanitization, category normalization and English publication**

Test `AI` normalizes to `ai`, `publishedEn` persists, nullable English fields remain null, and external URLs remain unchanged.

- [ ] **Step 2: Run tests and confirm failure**

```bash
pnpm vitest run src/__tests__/lib/discover-service.test.ts
```

- [ ] **Step 3: Implement the service helpers**

Keep Zod parsing in `src/lib/discover.ts`; service helpers only normalize validated values into Prisma-safe data and preserve current `publishedAt` semantics.

- [ ] **Step 4: Refactor POST/PATCH to use service helpers**

Do not change authentication, rate limiting, unique-slug 409 behavior, logger use, DELETE semantics or security headers.

- [ ] **Step 5: Extend integration tests**

Add cases for:
- POST Persian-only draft;
- POST bilingual published item;
- reject `publishedEn=true` without complete English fields;
- normalize legacy category alias `AI` to `ai`;
- PATCH clears optional English fields only when English is unpublished;
- GET returns English fields and canonical category key.

- [ ] **Step 6: Run integration tests**

```bash
pnpm vitest run src/__tests__/api/admin-discover.integration.test.ts src/__tests__/lib/discover-service.test.ts
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/lib/discover-service.ts src/app/api/admin/discover/route.ts src/__tests__/api/admin-discover.integration.test.ts src/__tests__/lib/discover-service.test.ts
git commit -m "refactor(discover): centralize resource persistence"
```

---

### Task 4: Rebuild Discover Admin as a Professional Persian-First Editor

**Files:**
- Replace/refactor: `src/components/admin/discover-manager.tsx`
- Create: `src/components/admin/discover/discover-editor.tsx`
- Create: `src/components/admin/discover/discover-editor-status.tsx`
- Create: `src/components/admin/discover/discover-preview.tsx`
- Create: `src/components/admin/discover/discover-import-export.tsx`
- Create: `src/components/admin/discover/discover-draft-recovery.ts`
- Test: `src/__tests__/components/discover-editor.test.tsx`
- Test: `src/__tests__/components/discover-import-export.test.tsx`

**Interfaces:**
- Consumes: Admin API contract and category registry from Tasks 2–3.
- Produces: Persian-first editor with semantic RTL/LTR, inline validation, preview, import/export and local recovery.

- [ ] **Step 1: Write failing component tests for directionality and publish readiness**

Assert:
- root editor is `dir="rtl"`;
- Persian text fields are RTL;
- `slug`, URL and English fields are `dir="ltr"`;
- English publish control is disabled with an accessible reason until English fields are complete;
- category selector displays `هوش مصنوعی` while storing `ai`.

- [ ] **Step 2: Run focused tests and confirm failure**

```bash
pnpm vitest run src/__tests__/components/discover-editor.test.tsx
```

- [ ] **Step 3: Implement the sectioned editor shell**

Use the approved sections:
1. وضعیت انتشار
2. محتوای فارسی
3. English content
4. دسته‌بندی و برچسب‌ها
5. لینک‌ها و منبع
6. پیش‌نمایش و SEO

Keep every visible input label persistent; helper/error copy must be adjacent to the field.

- [ ] **Step 4: Implement save-state and inline server-error mapping**

Show `ذخیره‌نشده`, `در حال ذخیره…`, `ذخیره شد` states. Preserve toast as supplemental feedback only; validation errors must also be visible in-form.

- [ ] **Step 5: Implement local draft recovery**

Public contract:

```ts
const DISCOVER_DRAFT_PREFIX = 'asdev:discover:draft:'
```

Store only form content, never credentials/session values. Key by `new` or item id. On load, if a local draft is newer than the last server-loaded snapshot, offer explicit restore/discard choices; never auto-overwrite server state.

- [ ] **Step 6: Implement normalized JSON import/export**

Import parses JSON in-browser, validates through the same Discover Zod schema, populates the form and never auto-publishes beyond the payload's explicit state. Export downloads/copies the normalized payload only—no auth/session data.

- [ ] **Step 7: Add live card/detail preview and public-route links**

Show FA/EN preview tabs. Public route link appears only when the corresponding locale is published.

- [ ] **Step 8: Run component tests**

```bash
pnpm vitest run src/__tests__/components/discover-editor.test.tsx src/__tests__/components/discover-import-export.test.tsx
```

Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add src/components/admin/discover-manager.tsx src/components/admin/discover src/__tests__/components
git commit -m "feat(admin): professionalize Discover editor"
```

---

### Task 5: Localize Navigation, Categories and Discover Copy Through the Existing i18n Source of Truth

**Files:**
- Modify: `src/lib/i18n/translations.ts`
- Modify: `src/components/layout/header.tsx` only if structural changes are required after using translation keys
- Modify: `src/components/layout/footer.tsx`
- Modify: Discover components/pages to consume translation keys
- Test: `src/__tests__/components/header.test.tsx` or nearest existing navigation test
- Test: `src/__tests__/lib/i18n.test.ts` or nearest existing i18n test

**Interfaces:**
- Produces translation keys for Discover navigation, filters, states, CTAs, disclosures and Admin labels.

- [ ] **Step 1: Add failing translation/navigation tests**

Required Persian values include:

```ts
nav.discover = 'ابزارها و منابع'
```

and Persian UI must not render raw `AI` for category key `ai`.

- [ ] **Step 2: Move reusable Discover copy into `translations.ts`**

Add structured keys for `discover.*` and `admin.discover.*`; keep English equivalents complete.

- [ ] **Step 3: Replace visible Persian `Discover` leakage**

Header, mobile nav, footer quick links, breadcrumbs and public copy must use `ابزارها و منابع` in Persian. Internal route names remain `/discover`.

- [ ] **Step 4: Run focused tests**

```bash
pnpm vitest run src/__tests__/components src/__tests__/lib --testNamePattern="Discover|navigation|translation|i18n"
```

Expected: relevant tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/lib/i18n/translations.ts src/components/layout src/app/discover src/components/discover src/__tests__
git commit -m "feat(i18n): localize Discover navigation and copy"
```

---

### Task 6: Build the Discover v2 Landing Experience

**Files:**
- Modify: `src/app/discover/page.tsx`
- Refactor: `src/components/discover/discover-grid.tsx`
- Create as needed: `src/components/discover/discover-search.tsx`
- Create as needed: `src/components/discover/discover-card.tsx`
- Test: `src/__tests__/components/discover-grid.test.tsx`
- Test: `src/__tests__/seo/discover-metadata.test.ts`

**Interfaces:**
- Consumes canonical category registry and locale publication fields.
- Produces locale-correct landing data and accessible search/filter behavior.

- [ ] **Step 1: Write failing tests for localized filtering and English publication exclusion**

Persian landing query selects `published=true`; English landing query selects `publishedEn=true`. Search matches localized title/description/category label plus shared tags.

- [ ] **Step 2: Implement locale-specific record projection**

Return an effective view model:

```ts
type DiscoverGridItem = {
  slug: string
  title: string
  description: string
  categoryKey: DiscoverCategoryKey
  categoryLabel: string
  tags: string[]
  featured: boolean
  imageUrl: string | null
}
```

- [ ] **Step 3: Implement content-first hero/search/filter hierarchy**

First viewport must expose purpose, search and localized categories. Preserve approved attribution only on internal Discover links.

- [ ] **Step 4: Implement accessible filter behavior**

Use pressed state, visible focus, result count with polite live region, obvious reset action and no required horizontal-scroll interaction.

- [ ] **Step 5: Implement responsive cards using persisted design system**

No emoji icons. Preserve readable line heights, 44px primary action target, stable image aspect ratio/CLS behavior and subtle reduced-motion-safe interaction.

- [ ] **Step 6: Add truthful landing structured data**

Generate `CollectionPage` + `ItemList` from only the resources actually shown for that locale. Keep existing breadcrumb schema.

- [ ] **Step 7: Run focused tests**

```bash
pnpm vitest run src/__tests__/components/discover-grid.test.tsx src/__tests__/seo/discover-metadata.test.ts
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add src/app/discover/page.tsx src/components/discover src/__tests__/components src/__tests__/seo
git commit -m "feat(discover): redesign localized resource landing"
```

---

### Task 7: Upgrade Discover Detail Pages and SEO Locale Semantics

**Files:**
- Modify: `src/app/discover/[slug]/page.tsx`
- Modify: `src/app/sitemap.ts`
- Modify/Create: `src/lib/seo.ts` helpers if required
- Test: `src/__tests__/seo/discover-detail-seo.test.ts`
- Test: `src/__tests__/seo/sitemap.test.ts`

**Interfaces:**
- Produces locale-correct 404/indexing/canonical/hreflang behavior and truthful structured data.

- [ ] **Step 1: Add failing SEO tests**

Required cases:
- Persian-published + English-unpublished item: FA detail indexable; EN detail 404/no sitemap alternate.
- Bilingual published item: both canonical URLs valid and reciprocal hreflang emitted.
- Draft: neither locale public.

- [ ] **Step 2: Implement effective locale content selection**

Persian uses base fields. English uses `titleEn/descriptionEn/contentEn` only and requires `publishedEn=true`; do not silently fall back to Persian for an indexable English page.

- [ ] **Step 3: Fix CTA semantics**

Primary label becomes neutral `باز کردن منبع` / `Open resource` unless a validated destination-specific label is derived safely. `telegramGuideUrl` remains a separate exact tutorial/file CTA. Instagram remains provenance.

- [ ] **Step 4: Preserve third-party disclosure and make it visually clear**

The DeepSeek G.Media acceptance case must visibly retain that it is not the official DeepSeek bot.

- [ ] **Step 5: Update sitemap locale rules**

For each resource:
- include Persian URL only when `published=true`;
- include English alternate only when `publishedEn=true`;
- never advertise an unavailable English alternate.

- [ ] **Step 6: Add/adjust OpenGraph and structured data**

Metadata uses effective localized copy. JSON-LD must describe ASDEV's editorial page truthfully and never imply third-party ownership.

- [ ] **Step 7: Run focused SEO tests**

```bash
pnpm vitest run src/__tests__/seo/discover-detail-seo.test.ts src/__tests__/seo/sitemap.test.ts
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add src/app/discover/[slug]/page.tsx src/app/sitemap.ts src/lib/seo.ts src/__tests__/seo
git commit -m "feat(seo): make Discover locale indexing truthful"
```

---

### Task 8: Add Network-Free Resource Manifest Validation and Admin-Compatible Import Artifacts

**Files:**
- Create: `scripts/discover/validate-manifests.ts`
- Modify: `package.json`
- Create: `docs/discover/resources/deepseek-telegram-bot.json`
- Test: `src/__tests__/lib/discover-manifests.test.ts`
- Modify: `docs/operations/DISCOVER_LOCAL_RUNBOOK.md`

**Interfaces:**
- Produces command `pnpm discover:validate`.
- Manifest persisted payload matches the same Discover create schema; evidence metadata is outside the persisted payload.

- [ ] **Step 1: Write failing manifest test**

Test that every `docs/discover/resources/*.json` file has:

```ts
{
  "payload": { /* discover create payload */ },
  "evidence": { /* non-persisted source notes */ }
}
```

and `payload` parses with `discoverCreateSchema`.

- [ ] **Step 2: Create the DeepSeek G.Media manifest from verified evidence**

Use:
- slug `deepseek-telegram-bot`;
- official destination `https://t.me/deepseek_gidbot`;
- source Reel `https://www.instagram.com/p/Db9O3I-M6Dy/`;
- canonical category key `ai`;
- Persian title explicitly marking the bot unofficial;
- no fabricated Telegram guide message link;
- `publishedEn=false` unless real English editorial copy is included and reviewed.

- [ ] **Step 3: Implement the validator with project-local TypeScript tooling**

The script reads local JSON only and returns non-zero on parse/schema failure. It must not fetch the network.

- [ ] **Step 4: Add package script**

```json
"discover:validate": "tsx scripts/discover/validate-manifests.ts"
```

If `tsx` is not already a project-local dependency, do **not** add it solely for this task; instead implement the validator as `.mjs` using a small exported JSON-safe validation boundary or run it through an already-present project-local TypeScript execution mechanism. Prefer zero new dependency.

- [ ] **Step 5: Update the runbook**

Document `manifest → validate → Admin Import JSON → review → save draft/publish → live verify`. Explicitly state that manifests are not production storage and do not bypass Admin authentication.

- [ ] **Step 6: Run validation**

```bash
pnpm discover:validate
```

Expected: PASS with the DeepSeek manifest listed as valid.

- [ ] **Step 7: Commit**

```bash
git add scripts/discover package.json docs/discover/resources docs/operations/DISCOVER_LOCAL_RUNBOOK.md src/__tests__/lib/discover-manifests.test.ts
git commit -m "feat(discover): add offline resource manifest validation"
```

---

### Task 9: Expand Automated Browser Coverage for Admin, RTL/LTR, Accessibility and Locale SEO

**Files:**
- Modify: `e2e/a11y.spec.ts`
- Modify: `e2e/smoke.spec.mjs`
- Create: `e2e/discover-v2.spec.ts`
- Modify: `lighthouserc.json` if Discover/Admin coverage is currently absent

**Interfaces:**
- Produces repeatable browser evidence for FA/EN landing/detail and authenticated Admin where test credentials/fixture mechanism already exists.

- [ ] **Step 1: Add Playwright coverage for Persian navigation and localized category display**

Assert visible `ابزارها و منابع`; assert no raw canonical category key leaks to the Persian filter/card.

- [ ] **Step 2: Add RTL/LTR Admin assertions**

Check editor root RTL, URL/slug LTR, English fields LTR and minimum usable mobile layout at 390x844.

- [ ] **Step 3: Add locale SEO/browser assertions**

For a test fixture with English unpublished, assert EN detail is unavailable. For bilingual fixture, assert FA/EN title/canonical/hreflang correspond to each locale.

- [ ] **Step 4: Add accessibility assertions**

Run axe against landing, detail and Admin editor; verify keyboard focus reaches search, category controls, card CTA and editor controls without focus loss.

- [ ] **Step 5: Run browser suite**

```bash
pnpm test:e2e:smoke
pnpm test:e2e:a11y
pnpm exec playwright test e2e/discover-v2.spec.ts
```

Expected: PASS.

- [ ] **Step 6: Run Lighthouse CI**

```bash
pnpm lighthouse:ci
```

Expected: configured budgets pass; no Discover regression accepted merely for visual polish.

- [ ] **Step 7: Commit**

```bash
git add e2e lighthouserc.json
git commit -m "test(discover): cover v2 admin locales and accessibility"
```

---

### Task 10: Full Quality Gate, Migration Evidence, PR Review and Production-Gated Acceptance

**Files:**
- Modify as evidence requires: `docs/operations/DISCOVER_LOCAL_RUNBOOK.md`
- Modify: `docs/memory/ASDEV_CURRENT_STATE.md`
- Modify: `docs/automation/ASDEV_MEMORY.md`
- Update: Issue #189 with exact evidence

**Interfaces:**
- Produces final merge/deploy evidence and repeatable zero-deploy resource workflow.

- [ ] **Step 1: Run the full local quality/security stack before opening the runtime PR**

```bash
pnpm lint
pnpm type-check
pnpm test
pnpm build
pnpm discover:validate
pnpm test:e2e:smoke
pnpm test:e2e:a11y
pnpm lighthouse:ci
pnpm audit:high
pnpm scan:secrets
```

Expected: all PASS.

- [ ] **Step 2: Verify the migration locally against a disposable database**

Use a copied/disposable SQLite database; run migration deploy/status and Prisma schema diff. Expected: migration applies cleanly and resulting schema has no drift.

- [ ] **Step 3: Open a focused PR tied to #189 and wait for exact-head CI/security results**

Do not merge while required checks are pending or failing. Resolve review findings with tests.

- [ ] **Step 4: Stop at any exact production migration/deployment approval gate**

If repository governance requires `APPROVE_CRITICAL_SITE_MIGRATION` and/or `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY`, request the exact phrase and do not substitute informal approval.

- [ ] **Step 5: After gate approval, deploy only the exact reviewed merge SHA**

Verify release id, DB backup/snapshot, migration count/status, zero schema drift, health/readiness and rollback target before declaring the release healthy.

- [ ] **Step 6: Publish/import the DeepSeek acceptance resource through authenticated Admin/API**

Use the validated manifest. Persian may publish immediately; English publishes only if reviewed English copy is complete. Do not invent missing content to force bilingual publication.

- [ ] **Step 7: Run two consecutive live Chromium verification passes**

Required routes/surfaces include:
- `/admin` Discover editor;
- `/discover`;
- `/en/discover`;
- `/discover/deepseek-telegram-bot`;
- `/en/discover/deepseek-telegram-bot` only if English-published;
- `/sitemap.xml`;
- `/api/ready`.

Verify desktop and mobile, zero console/page/request failures apart from explicitly classified harmless Next.js RSC prefetch aborts under the existing verifier policy.

- [ ] **Step 8: Verify the real conversion/telemetry path**

With consent enabled, confirm `discover_landing_view`, `discover_item_view`, official-resource click and applicable internal CTA events contain safe slug/category/allowlisted attribution only. External Telegram/Instagram URLs must contain no ASDEV UTM leakage.

- [ ] **Step 9: Record durable evidence and close #189 only if Definition of Done is objectively met**

Record exact PR, merge SHA, workflow/run ids, release id, DB snapshot/rollback target, migration/drift evidence, test counts, Lighthouse/a11y result, published resource id/routes and live verification artifact. Keep #188 open for the ongoing growth loop unless its separate Definition of Done is also met.

- [ ] **Step 10: Commit evidence-only documentation if needed**

```bash
git add docs/operations/DISCOVER_LOCAL_RUNBOOK.md docs/memory/ASDEV_CURRENT_STATE.md docs/automation/ASDEV_MEMORY.md
git commit -m "docs(discover): record v2 production evidence"
```

---

## Self-Review Results

- **Spec coverage:** Admin UX, bilingual model, localized categories/nav, public landing/detail, SEO, vendored UI UX Pro Max, manifest automation, zero-deploy editorial workflow, tests, migration safety and production live evidence all map to explicit tasks.
- **Placeholder scan:** no `TBD`, `TODO`, unspecified error-handling step or generic "write tests" step remains.
- **Type consistency:** canonical category keys flow from `discover-categories.ts` through Zod/service/API/Admin/public UI; English fields consistently use `titleEn`, `descriptionEn`, `contentEn`, `publishedEn`.
- **Governance:** design approval does not bypass exact production migration/deployment gates.

## Definition of Done

The plan is complete only when all ten tasks are checked, exact-head CI is green, required production approval gates have been honored, the reviewed SHA is deployed, migration/drift and rollback evidence are captured, Admin and Discover FA/EN are live-verified on desktop/mobile, and the real DeepSeek resource proves the zero-deploy workflow end-to-end.