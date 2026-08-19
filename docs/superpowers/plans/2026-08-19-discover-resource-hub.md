# Discover Resource Hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evolve `/discover` into the ASDEV-owned resource hub for Instagram/search traffic, with exact Telegram tutorial/file deep links, optional global Telegram community links, resource-first UX, destination-specific analytics, and zero-deploy per-item editorial control.

**Architecture:** Keep the existing Next.js 16 App Router + Prisma/SQLite + authenticated Admin architecture. Extend `DiscoverItem` additively with one nullable `telegramGuideUrl`, add shared strict `t.me` validation, expose the field through existing Admin CRUD, and render Telegram actions in the existing detail page without propagating ASDEV UTM parameters. Global Telegram channel/group destinations are optional public environment configuration, not database content.

**Tech Stack:** Next.js 16, React 19, TypeScript 5.9, Prisma 6 + SQLite, Zod 4, Vitest 4, Playwright 1.58, existing ASDEV analytics/Admin/deploy contracts.

**Spec:** `docs/superpowers/specs/2026-08-19-discover-resource-hub-design.md`

**GitHub roadmap:** #174 with implementation issues #175–#182.

## Global Constraints

- Reuse the existing application, database, Admin authentication, rate limiting, analytics client, sitemap and deploy/rollback system.
- Do not add Instagram API automation, comment/DM automation, Telegram Bot API, webhook/polling workers, new services, databases, repositories or paid dependencies.
- `telegramGuideUrl` is optional and must be a credential-free HTTPS URL with canonical hostname `t.me`.
- Existing Discover rows remain valid with `telegramGuideUrl = NULL`; migration is additive and non-destructive.
- Existing `NEXT_PUBLIC_TELEGRAM_URL` is not repurposed or tightened because it is a general social-profile setting and may contain legacy `telegram.me` values.
- Add dedicated optional config names: `NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL` and `NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL`.
- ASDEV attribution (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`) is propagated only across internal ASDEV navigation; never append it to official, Instagram or Telegram URLs.
- Telegram click analytics must contain no Telegram username, full external URL, user identifier, arbitrary query string or PII.
- The official product CTA remains first in the primary action cluster; exact Telegram tutorial/file is next when configured; global channel/group are continuation actions.
- The Audit/qualification block remains available but becomes structurally secondary to resource resolution.
- Use TDD for every behavioral change and make small reviewable commits.
- Do not declare production rollout complete until live route, migration status and Discover smoke evidence are verified after deployment.

---

## File Structure Map

### New files

- `src/lib/telegram.ts` — shared strict `t.me` URL validation used by Discover content and environment configuration.
- `src/__tests__/lib/telegram.test.ts` — validator contract tests.
- `prisma/migrations/20260819080000_add_discover_telegram_guide/migration.sql` — additive nullable-column migration.
- `src/__tests__/components/discover-link.test.tsx` — click analytics/navigation contract for Discover links.
- `scripts/seed-playwright-discover.mjs` — deterministic Playwright-only Discover fixture with one published Telegram-backed item.

### Existing files modified

- `prisma/schema.prisma` — add nullable `telegramGuideUrl` to `DiscoverItem`.
- `src/lib/discover.ts` — add Telegram guide field to create/update schemas using shared validator.
- `src/app/api/admin/discover/route.ts` — persist/clear Telegram guide URL.
- `src/components/admin/discover-manager.tsx` — edit Telegram guide URL in existing Admin UI.
- `src/lib/env.ts` — validate optional Discover-specific global Telegram URLs.
- `.env.example` — document the two new public Discover Telegram settings.
- `src/components/discover/discover-link.tsx` — accept three new destination-specific Telegram analytics events.
- `src/app/discover/[slug]/page.tsx` — resource-first CTA hierarchy and optional Telegram actions.
- `src/app/discover/page.tsx` — update landing promise/copy from conversion-first to resource-hub-first.
- `src/__tests__/lib/discover.test.ts` — Discover schema coverage.
- `src/__tests__/api/admin-discover.integration.test.ts` — API lifecycle coverage.
- `src/__tests__/components/discover-manager.test.tsx` — Admin form lifecycle coverage.
- `src/__tests__/lib/env.test.ts` — global Telegram config validation coverage.
- `src/__tests__/lib/discover-public.test.ts` — public source/data boundary and external URL contract.
- `src/__tests__/lib/discover-acquisition-contract.test.ts` — CTA hierarchy/analytics source contract where appropriate.
- `playwright.config.mjs` — seed the disposable Playwright SQLite DB before starting the app.
- `e2e/smoke.spec.mjs` — resource-hub copy and Telegram-backed detail smoke.
- `e2e/a11y.spec.ts` — Discover detail accessibility coverage with the seeded item.
- `tests/ci/prisma-migration-chain.test.ts` — ensure new migration is represented in migration-chain expectations.
- `tests/ci/deploy-discover-smoke.test.ts` — retain rollout requirement and optional Telegram-detail smoke contract if implemented by the existing shell path.
- `docs/operations/DISCOVER_LOCAL_RUNBOOK.md` — content workflow, Telegram setup, local verification, rollout evidence.
- `docs/projects/alirezasafaeisystems.md` — update Discover product role/status after implementation.

---

### Task 1: Add the Telegram URL contract and additive database field

**GitHub issue:** #175

**Files:**
- Create: `src/lib/telegram.ts`
- Create: `src/__tests__/lib/telegram.test.ts`
- Modify: `src/lib/discover.ts`
- Modify: `src/__tests__/lib/discover.test.ts`
- Modify: `prisma/schema.prisma`
- Create: `prisma/migrations/20260819080000_add_discover_telegram_guide/migration.sql`
- Modify: `tests/ci/prisma-migration-chain.test.ts`

**Interfaces:**
- Produces: `telegramUrlSchema: ZodType<string>` and `optionalTelegramUrlSchema` returning `string | null | undefined`.
- Produces: `DiscoverItem.telegramGuideUrl: string | null` in Prisma client.
- Produces: `discoverCreateSchema.telegramGuideUrl` and `discoverUpdateSchema.telegramGuideUrl`.
- Consumes: existing Discover URL safety semantics (HTTPS, no credentials, max 2000 chars).

- [ ] **Step 1: Write the failing shared validator test**

Create `src/__tests__/lib/telegram.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import { optionalTelegramUrlSchema, telegramUrlSchema } from '@/lib/telegram'

describe('Telegram public URL contract', () => {
  it('accepts only credential-free HTTPS t.me URLs', () => {
    expect(telegramUrlSchema.parse('https://t.me/asdev/123')).toBe('https://t.me/asdev/123')
    expect(telegramUrlSchema.safeParse('http://t.me/asdev/123').success).toBe(false)
    expect(telegramUrlSchema.safeParse('https://telegram.me/asdev/123').success).toBe(false)
    expect(telegramUrlSchema.safeParse('https://user:pass@t.me/asdev/123').success).toBe(false)
    expect(telegramUrlSchema.safeParse('https://example.com/asdev/123').success).toBe(false)
  })

  it('normalizes blank optional values to null', () => {
    expect(optionalTelegramUrlSchema.parse('')).toBeNull()
    expect(optionalTelegramUrlSchema.parse(undefined)).toBeUndefined()
  })
})
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
pnpm vitest run src/__tests__/lib/telegram.test.ts
```

Expected: FAIL because `@/lib/telegram` does not exist.

- [ ] **Step 3: Implement the shared validator minimally**

Create `src/lib/telegram.ts`:

```ts
import { z } from 'zod'

export const telegramUrlSchema = z
  .string()
  .trim()
  .min(1)
  .max(2000)
  .refine((value) => {
    try {
      const url = new URL(value)
      return url.protocol === 'https:' && !url.username && !url.password && url.hostname.toLowerCase() === 't.me'
    } catch {
      return false
    }
  }, 'Telegram URL must use a credential-free https://t.me/ URL')

export const optionalTelegramUrlSchema = z
  .union([z.literal(''), telegramUrlSchema])
  .optional()
  .transform((value) => (value === '' ? null : value))
```

- [ ] **Step 4: Extend Discover schemas with the shared validator**

In `src/lib/discover.ts` import `optionalTelegramUrlSchema`, then add:

```ts
telegramGuideUrl: optionalTelegramUrlSchema,
```

to both `discoverFieldsSchema` and `discoverUpdateSchema`.

Extend `src/__tests__/lib/discover.test.ts` with:

```ts
it('accepts and clears the optional exact Telegram guide URL', () => {
  expect(discoverUpdateSchema.parse({
    id: 'discover_12345',
    telegramGuideUrl: 'https://t.me/asdev/123',
  })).toEqual({
    id: 'discover_12345',
    telegramGuideUrl: 'https://t.me/asdev/123',
  })

  expect(discoverUpdateSchema.parse({
    id: 'discover_12345',
    telegramGuideUrl: '',
  })).toEqual({
    id: 'discover_12345',
    telegramGuideUrl: null,
  })
})
```

- [ ] **Step 5: Add the nullable Prisma field and migration**

In `DiscoverItem`:

```prisma
telegramGuideUrl String?
```

Create `prisma/migrations/20260819080000_add_discover_telegram_guide/migration.sql`:

```sql
ALTER TABLE "DiscoverItem" ADD COLUMN "telegramGuideUrl" TEXT;
```

Do not backfill or rewrite any row.

- [ ] **Step 6: Extend migration-chain regression coverage**

Update `tests/ci/prisma-migration-chain.test.ts` so the expected migration list/order includes:

```text
20260819080000_add_discover_telegram_guide
```

and assert its SQL contains exactly the additive `ADD COLUMN` operation and no `DROP TABLE`, `DELETE`, or destructive rebuild for `DiscoverItem`.

- [ ] **Step 7: Run schema and focused tests**

```bash
pnpm exec prisma validate
pnpm run db:generate
pnpm vitest run src/__tests__/lib/telegram.test.ts src/__tests__/lib/discover.test.ts tests/ci/prisma-migration-chain.test.ts
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add src/lib/telegram.ts src/lib/discover.ts src/__tests__/lib/telegram.test.ts src/__tests__/lib/discover.test.ts prisma/schema.prisma prisma/migrations/20260819080000_add_discover_telegram_guide/migration.sql tests/ci/prisma-migration-chain.test.ts
git commit -m "feat(discover): add Telegram guide data contract"
```

---

### Task 2: Extend the authenticated Admin API and editor lifecycle

**GitHub issue:** #176

**Files:**
- Modify: `src/app/api/admin/discover/route.ts`
- Modify: `src/__tests__/api/admin-discover.integration.test.ts`
- Modify: `src/components/admin/discover-manager.tsx`
- Modify: `src/__tests__/components/discover-manager.test.tsx`

**Interfaces:**
- Consumes: `discoverCreateSchema`/`discoverUpdateSchema` with `telegramGuideUrl: string | null | undefined` from Task 1.
- Produces: Admin GET/POST/PATCH representations containing `telegramGuideUrl`.
- Produces: zero-deploy create/edit/clear lifecycle from existing Discover manager.

- [ ] **Step 1: Write failing API lifecycle tests**

Add `telegramGuideUrl: 'https://t.me/asdev/123'` to `validItem` in `src/__tests__/api/admin-discover.integration.test.ts` and add assertions:

```ts
expect(discoverItemMock.create).toHaveBeenCalledWith({
  data: expect.objectContaining({
    telegramGuideUrl: 'https://t.me/asdev/123',
  }),
})
```

Add a clear test:

```ts
it('clears a Telegram guide URL to null on PATCH', async () => {
  discoverItemMock.update.mockResolvedValueOnce({ id: 'discover_12345', telegramGuideUrl: null })
  const { PATCH } = await import('@/app/api/admin/discover/route')
  const response = await PATCH(adminRequest('http://localhost:3000/api/admin/discover', {
    method: 'PATCH',
    body: JSON.stringify({ id: 'discover_12345', telegramGuideUrl: '' }),
  }))

  expect(response.status).toBe(200)
  expect(discoverItemMock.update).toHaveBeenCalledWith({
    where: { id: 'discover_12345' },
    data: expect.objectContaining({ telegramGuideUrl: null }),
  })
})
```

Add an invalid-host test using `https://telegram.me/asdev/123` and assert `400` before DB mutation.

- [ ] **Step 2: Run API test and verify RED**

```bash
pnpm vitest run src/__tests__/api/admin-discover.integration.test.ts
```

Expected: FAIL because route persistence does not include the new field.

- [ ] **Step 3: Persist the field in POST/PATCH**

In POST data:

```ts
telegramGuideUrl: input.telegramGuideUrl,
```

In PATCH data:

```ts
...(input.telegramGuideUrl !== undefined ? { telegramGuideUrl: input.telegramGuideUrl ?? null } : {}),
```

Do not add a new endpoint or bypass existing auth/rate limits.

- [ ] **Step 4: Write failing Admin component test**

Extend the Discover manager fixture with:

```ts
telegramGuideUrl: 'https://t.me/asdev/123',
```

Then assert the edit form loads it and a save request contains it. Also clear the input and assert the next request contains `telegramGuideUrl: ''` so the API normalizes it to `null`.

- [ ] **Step 5: Extend the Admin form/types**

Add to `DiscoverItem`:

```ts
telegramGuideUrl: string | null
```

Add to `DiscoverForm` and `emptyForm`:

```ts
telegramGuideUrl: string
```

Add in `toForm`:

```ts
telegramGuideUrl: item.telegramGuideUrl || '',
```

Add one optional input near Instagram/image fields:

```tsx
<label className="space-y-1 text-sm font-medium md:col-span-2">
  Telegram full guide / file URL
  <Input
    type="url"
    placeholder="https://t.me/asdev/123"
    value={form.telegramGuideUrl}
    onChange={(event) => updateForm('telegramGuideUrl', event.target.value)}
  />
  <span className="block text-xs font-normal text-muted-foreground">
    Prefer the exact t.me message link for the tutorial or file, not the channel homepage.
  </span>
</label>
```

- [ ] **Step 6: Run focused API/Admin tests**

```bash
pnpm vitest run src/__tests__/api/admin-discover.integration.test.ts src/__tests__/components/discover-manager.test.tsx
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add src/app/api/admin/discover/route.ts src/__tests__/api/admin-discover.integration.test.ts src/components/admin/discover-manager.tsx src/__tests__/components/discover-manager.test.tsx
git commit -m "feat(discover): manage Telegram guide links in Admin"
```

---

### Task 3: Add optional global Discover Telegram channel/group configuration

**GitHub issue:** #177

**Files:**
- Modify: `src/lib/env.ts`
- Modify: `src/__tests__/lib/env.test.ts`
- Modify: `.env.example`

**Interfaces:**
- Consumes: `telegramUrlSchema` from Task 1.
- Produces: `env.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL?: string`.
- Produces: `env.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL?: string`.

- [ ] **Step 1: Write failing environment validation tests**

In `src/__tests__/lib/env.test.ts`, add:

```ts
it('accepts canonical Discover Telegram channel and group URLs', () => {
  const parsed = parseEnv({
    NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: 'https://t.me/asdev',
    NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL: 'https://t.me/asdev_chat',
  })

  expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL).toBe('https://t.me/asdev')
  expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL).toBe('https://t.me/asdev_chat')
})

it('rejects non-t.me Discover Telegram destinations', () => {
  expect(() => parseEnv({
    NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: 'https://telegram.me/asdev',
  })).toThrow()
})
```

- [ ] **Step 2: Run focused test and verify RED**

```bash
pnpm vitest run src/__tests__/lib/env.test.ts
```

Expected: FAIL because the new fields are not parsed.

- [ ] **Step 3: Extend `envSchema` and process-env mapping**

Import:

```ts
import { telegramUrlSchema } from '@/lib/telegram'
```

Add:

```ts
NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: telegramUrlSchema.optional(),
NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL: telegramUrlSchema.optional(),
```

and map both `process.env` values in `parseEnv(...)` initialization.

Do not modify `NEXT_PUBLIC_TELEGRAM_URL` semantics.

- [ ] **Step 4: Document the optional public values**

In `.env.example` add without inventing real final handles:

```dotenv
# Discover resource hub (optional; canonical t.me URLs only)
NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL=
NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL=
```

- [ ] **Step 5: Run environment tests**

```bash
pnpm vitest run src/__tests__/lib/env.test.ts src/__tests__/lib/telegram.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/lib/env.ts src/__tests__/lib/env.test.ts .env.example
git commit -m "feat(discover): configure optional Telegram community links"
```

---

### Task 4: Extend Discover link telemetry for Telegram destinations

**GitHub issue:** #178

**Files:**
- Modify: `src/components/discover/discover-link.tsx`
- Create: `src/__tests__/components/discover-link.test.tsx`

**Interfaces:**
- Produces event names: `discover_telegram_guide_click`, `discover_telegram_channel_click`, `discover_telegram_group_click`.
- All Telegram events use analytics category `engagement`.
- Navigation remains an ordinary external `<a>` and does not wait for telemetry.

- [ ] **Step 1: Write the failing component telemetry test**

Create a component test that mocks `trackEvent`, renders one external Telegram link, clicks it, and expects:

```ts
expect(trackEventMock).toHaveBeenCalledWith({
  name: 'discover_telegram_guide_click',
  category: 'engagement',
  locale: 'fa',
  metadata: { slug: 'qwen', category: 'AI', target: 'telegram_guide' },
})
```

Also assert rendered anchor attributes:

```ts
expect(link).toHaveAttribute('href', 'https://t.me/asdev/123')
expect(link).toHaveAttribute('target', '_blank')
expect(link).toHaveAttribute('rel', 'noopener noreferrer')
```

- [ ] **Step 2: Run test and verify RED**

```bash
pnpm vitest run src/__tests__/components/discover-link.test.tsx
```

Expected: Type/runtime failure because the event union rejects the Telegram event.

- [ ] **Step 3: Extend the event union without changing navigation semantics**

Use:

```ts
type DiscoverLinkEventName =
  | 'discover_external_click'
  | 'discover_internal_cta_click'
  | 'discover_telegram_guide_click'
  | 'discover_telegram_channel_click'
  | 'discover_telegram_group_click'
```

Keep category selection explicit:

```ts
const category = eventName === 'discover_internal_cta_click' ? 'conversion' : 'engagement'
```

- [ ] **Step 4: Run component test**

```bash
pnpm vitest run src/__tests__/components/discover-link.test.tsx
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/components/discover/discover-link.tsx src/__tests__/components/discover-link.test.tsx
git commit -m "feat(discover): track Telegram resource clicks"
```

---

### Task 5: Make the detail page resource-first and render optional Telegram actions

**GitHub issue:** #179

**Files:**
- Modify: `src/app/discover/[slug]/page.tsx`
- Modify: `src/__tests__/lib/discover-public.test.ts`
- Modify: `src/__tests__/lib/discover-acquisition-contract.test.ts`

**Interfaces:**
- Consumes: `item.telegramGuideUrl` from Task 1.
- Consumes: `env.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL` and `env.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL` from Task 3.
- Consumes: Telegram event names from Task 4.
- Produces visible action order: official product → exact Telegram guide (if present) → Instagram source; then channel/group continuation; then related items; then subordinate ASDEV business navigation.

- [ ] **Step 1: Write failing public-contract assertions**

Extend the public source contract to assert the detail page contains all three event names and that Telegram URLs are passed directly to `DiscoverLink`, never through `appendDiscoverAttribution`.

Add assertions equivalent to:

```ts
expect(detail).toContain('discover_telegram_guide_click')
expect(detail).toContain('discover_telegram_channel_click')
expect(detail).toContain('discover_telegram_group_click')
expect(detail).not.toContain('appendDiscoverAttribution(item.telegramGuideUrl')
```

Also assert the ASDEV continuation section appears after the related/resource sections in source order.

- [ ] **Step 2: Run focused public-contract tests and verify RED**

```bash
pnpm vitest run src/__tests__/lib/discover-public.test.ts src/__tests__/lib/discover-acquisition-contract.test.ts
```

Expected: FAIL because Telegram actions/config do not exist and ASDEV conversion is currently earlier.

- [ ] **Step 3: Add server-side config and localized copy**

Import `env` and suitable existing Lucide icons (`Send`, `MessagesSquare`). Define:

```ts
const telegramChannelUrl = env.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL
const telegramGroupUrl = env.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL
```

Add locale copy keys:

```ts
// English
telegramGuide: 'Open full tutorial / file',
telegramChannel: 'Join the resource channel',
telegramGroup: 'Ask a question / join discussion',
resources: 'Resources and next steps',

// Persian
telegramGuide: 'آموزش کامل / فایل',
telegramChannel: 'عضویت در کانال آموزش‌ها',
telegramGroup: 'پرسش‌وپاسخ و گفتگو',
resources: 'منابع و ادامه مسیر',
```

- [ ] **Step 4: Add item-specific Telegram guide CTA directly after official CTA**

Inside the primary action cluster, after official link:

```tsx
{item.telegramGuideUrl ? (
  <DiscoverLink
    href={item.telegramGuideUrl}
    external
    locale={locale}
    eventName="discover_telegram_guide_click"
    metadata={{ ...telemetryMetadata, target: 'telegram_guide' }}
    className="inline-flex items-center gap-2 rounded-xl border px-5 py-3 text-sm font-semibold transition hover:bg-muted"
  >
    <Send className="h-4 w-4" />
    {copy.telegramGuide}
  </DiscoverLink>
) : null}
```

Do not call `appendDiscoverAttribution` for this URL.

- [ ] **Step 5: Add a separate optional community continuation block**

Render only when at least one global URL exists:

```tsx
{telegramChannelUrl || telegramGroupUrl ? (
  <section className="rounded-2xl border bg-card p-6 md:p-8">
    <h2 className="text-2xl font-bold">{copy.resources}</h2>
    <div className="mt-5 flex flex-wrap gap-3">
      {telegramChannelUrl ? (
        <DiscoverLink
          href={telegramChannelUrl}
          external
          locale={locale}
          eventName="discover_telegram_channel_click"
          metadata={{ ...telemetryMetadata, target: 'telegram_channel' }}
          className="rounded-xl border px-4 py-2.5 text-sm font-semibold hover:bg-muted"
        >
          {copy.telegramChannel}
        </DiscoverLink>
      ) : null}
      {telegramGroupUrl ? (
        <DiscoverLink
          href={telegramGroupUrl}
          external
          locale={locale}
          eventName="discover_telegram_group_click"
          metadata={{ ...telemetryMetadata, target: 'telegram_group' }}
          className="rounded-xl border px-4 py-2.5 text-sm font-semibold hover:bg-muted"
        >
          <MessagesSquare className="me-2 inline h-4 w-4" />
          {copy.telegramGroup}
        </DiscoverLink>
      ) : null}
    </div>
  </section>
) : null}
```

- [ ] **Step 6: Move and visually subordinate the ASDEV conversion section**

Place related Discover items before the ASDEV business continuation. Keep the Audit/case-study/qualification links, but reduce the visual weight from primary resource CTA styling. Do not remove attribution propagation from those internal links.

- [ ] **Step 7: Run public-contract tests**

```bash
pnpm vitest run src/__tests__/lib/discover-public.test.ts src/__tests__/lib/discover-acquisition-contract.test.ts src/__tests__/components/discover-link.test.tsx
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add src/app/discover/[slug]/page.tsx src/__tests__/lib/discover-public.test.ts src/__tests__/lib/discover-acquisition-contract.test.ts
git commit -m "feat(discover): prioritize resource resolution on detail pages"
```

---

### Task 6: Update the Discover landing promise for the bio/resource-hub use case

**GitHub issue:** #180

**Files:**
- Modify: `src/app/discover/page.tsx`
- Modify: `e2e/smoke.spec.mjs`

**Interfaces:**
- No data/API interface changes.
- Produces stable user promise: tools/resources from Instagram live here with official links, short guidance and full resources where available.

- [ ] **Step 1: Update the existing English smoke expectation first**

Replace the current expected H1 with the approved resource-hub promise. Use exact copy:

```text
Find the tools and resources I mention on Instagram
```

Add a Persian source-level expectation through the existing unit/public contract if needed.

- [ ] **Step 2: Run the smoke test and verify RED**

```bash
pnpm playwright test e2e/smoke.spec.mjs -g "Discover keeps English locale"
```

Expected: FAIL because the page still uses the old acquisition copy.

- [ ] **Step 3: Update localized landing copy**

Use:

```ts
// English
{
  eyebrow: 'ASDEV Discover',
  title: 'Find the tools and resources I mention on Instagram',
  description: 'Search the apps, AI tools and services I introduce, then open a short practical guide, the official destination and any full tutorial or file I have published.',
  note: 'Discover is curated editorial guidance. External products belong to their respective owners.',
}

// Persian
{
  eyebrow: 'ASDEV Discover',
  title: 'ابزارها و منابعی که در اینستاگرام معرفی می‌کنم، اینجا پیدا کن',
  description: 'اسم ابزار، هوش مصنوعی یا سرویس موردنظرت را جستجو کن؛ توضیح کوتاه، لینک رسمی و هر آموزش کامل یا فایلی که منتشر کرده‌ام از همین‌جا در دسترس است.',
  note: 'Discover یک مجموعه منتخب و تحریری است. مالکیت سرویس‌های خارجی متعلق به ارائه‌دهندگان خودشان است.',
}
```

Keep existing metadata/canonical/hreflang behavior unless a test proves copy-specific metadata needs updating.

- [ ] **Step 4: Run focused smoke**

```bash
pnpm playwright test e2e/smoke.spec.mjs -g "Discover keeps English locale"
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/app/discover/page.tsx e2e/smoke.spec.mjs
git commit -m "feat(discover): position landing as ASDEV resource hub"
```

---

### Task 7: Add deterministic browser coverage for Telegram-backed Discover content

**GitHub issue:** #181

**Files:**
- Create: `scripts/seed-playwright-discover.mjs`
- Modify: `playwright.config.mjs`
- Modify: `e2e/smoke.spec.mjs`
- Modify: `e2e/a11y.spec.ts`

**Interfaces:**
- Produces deterministic Playwright-only slug: `playwright-discover-resource`.
- Produces item Telegram URL: `https://t.me/asdev_test/123`.
- Does not touch production or developer persistent databases; it runs only against `test-results/playwright.db` through existing Playwright `DATABASE_URL`.

- [ ] **Step 1: Add the Playwright seed script**

Create `scripts/seed-playwright-discover.mjs`:

```js
import { PrismaClient } from '@prisma/client'

const db = new PrismaClient()

try {
  await db.discoverItem.upsert({
    where: { slug: 'playwright-discover-resource' },
    update: {
      title: 'Playwright Discover Resource',
      description: 'Deterministic browser fixture for Discover resource tests.',
      content: 'Open the official destination or the full Telegram tutorial.',
      externalUrl: 'https://example.com/tool',
      telegramGuideUrl: 'https://t.me/asdev_test/123',
      category: 'Testing',
      tags: 'testing,discover',
      featured: false,
      published: true,
      order: 999,
      publishedAt: new Date('2026-08-19T00:00:00.000Z'),
    },
    create: {
      slug: 'playwright-discover-resource',
      title: 'Playwright Discover Resource',
      description: 'Deterministic browser fixture for Discover resource tests.',
      content: 'Open the official destination or the full Telegram tutorial.',
      externalUrl: 'https://example.com/tool',
      telegramGuideUrl: 'https://t.me/asdev_test/123',
      category: 'Testing',
      tags: 'testing,discover',
      featured: false,
      published: true,
      order: 999,
      publishedAt: new Date('2026-08-19T00:00:00.000Z'),
    },
  })
} finally {
  await db.$disconnect()
}
```

- [ ] **Step 2: Run the seed only inside Playwright disposable DB setup**

In `playwright.config.mjs`, change the webServer command ordering to:

```text
pnpm prisma db push --skip-generate --accept-data-loss && node scripts/seed-playwright-discover.mjs && pnpm run build && node scripts/start-playwright-server.mjs
```

Keep the existing `DATABASE_URL` pointing to `test-results/playwright.db`.

- [ ] **Step 3: Add detail-page browser smoke**

In `e2e/smoke.spec.mjs`:

```js
test('Discover detail resolves exact Telegram resource without UTM leakage', async ({ page }) => {
  await page.goto('/discover/playwright-discover-resource?utm_source=instagram&utm_medium=social&utm_campaign=smoke&utm_content=reel-test')

  await expect(page.getByRole('heading', { name: 'Playwright Discover Resource' })).toBeVisible()
  const telegram = page.getByRole('link', { name: /آموزش کامل|full tutorial/i })
  await expect(telegram).toHaveAttribute('href', 'https://t.me/asdev_test/123')
  await expect(telegram).not.toHaveAttribute('href', /utm_/)
  await expect(page.getByRole('link', { name: /باز کردن سایت رسمی|official website/i })).toBeVisible()
})
```

- [ ] **Step 4: Add mobile/a11y coverage for the seeded detail route**

Add the Discover detail route to the existing Axe/a11y route matrix or add one test at mobile viewport `390x844`; require no serious/critical violations and ensure primary resource links are keyboard-accessible.

- [ ] **Step 5: Run browser coverage**

```bash
pnpm playwright test e2e/smoke.spec.mjs
pnpm playwright test e2e/a11y.spec.ts
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/seed-playwright-discover.mjs playwright.config.mjs e2e/smoke.spec.mjs e2e/a11y.spec.ts
git commit -m "test(discover): cover Telegram resource flow in browser"
```

---

### Task 8: Update operations docs, rollout contract, and run the complete verification gate

**GitHub issue:** #182

**Files:**
- Modify: `docs/operations/DISCOVER_LOCAL_RUNBOOK.md`
- Modify: `docs/projects/alirezasafaeisystems.md`
- Modify: `tests/ci/deploy-discover-smoke.test.ts` only if the existing production smoke shell contract needs a new optional resource-detail assertion.

**Interfaces:**
- Produces agent/operator instructions for reel → Discover item → Telegram exact post → Admin deep link → Instagram bio CTA.
- Preserves existing production owner/deploy gates and rollback behavior.

- [ ] **Step 1: Update the local/editorial runbook**

Document this exact operating sequence:

```text
Instagram reel/post
→ create/update Discover item
→ verify official URL
→ write concise quick guide
→ publish long tutorial/file to Telegram when needed
→ copy exact https://t.me/<channel>/<message-id> into Admin
→ publish Discover item
→ verify /discover/<slug>
→ use Instagram caption/pinned comment: Bio → Discover → search item name
→ use Telegram group only for questions/discussion
```

Include local smoke commands from Tasks 1–7 and state that empty Telegram configuration must hide buttons rather than show placeholders.

- [ ] **Step 2: Update project status/architecture documentation**

In `docs/projects/alirezasafaeisystems.md`, change the Discover product flow to:

```text
Instagram / Search / Direct → /discover → /discover/[slug] → quick guide → official destination and/or exact Telegram tutorial/file → optional community discussion
```

Keep ASDEV Audit/qualification as a secondary route, not the primary user task.

- [ ] **Step 3: Preserve deploy smoke as mandatory and add only a non-destructive optional detail assertion**

Read `tests/ci/deploy-discover-smoke.test.ts` and the shell script it protects before editing. Do not make successful deployment depend on Telegram configuration being present.

If the shell already supports optional environment-driven route checks, extend that pattern with an optional resource slug. Otherwise, keep the existing `/discover` rollout smoke unchanged and record the Telegram-backed live-detail check as a post-deploy operator step in the runbook. Do **not** invent a mandatory production slug.

The acceptance rule is:

```text
Core /discover smoke is mandatory.
Telegram detail smoke is performed when an intentionally configured production item exists.
Absence of Telegram config is a supported state, not a deploy failure.
```

- [ ] **Step 4: Run focused regression suites**

```bash
pnpm vitest run src/__tests__/lib/telegram.test.ts src/__tests__/lib/discover.test.ts src/__tests__/lib/env.test.ts src/__tests__/api/admin-discover.integration.test.ts src/__tests__/components/discover-manager.test.tsx src/__tests__/components/discover-link.test.tsx src/__tests__/lib/discover-public.test.ts src/__tests__/lib/discover-acquisition-contract.test.ts tests/ci/prisma-migration-chain.test.ts tests/ci/deploy-discover-smoke.test.ts
```

Expected: PASS.

- [ ] **Step 5: Run repository verification gates**

```bash
pnpm run type-check
pnpm run lint
pnpm run test
pnpm run build
pnpm run test:e2e:smoke
pnpm run test:e2e:a11y
pnpm run audit:high
pnpm run scan:secrets
```

Expected: all required gates PASS with no new high/critical dependency finding and no secret finding.

- [ ] **Step 6: Rehearse the migration against a disposable SQLite database**

Use a disposable file URL, apply the full migration chain, then verify zero drift:

```bash
DATABASE_URL=file:./test-results/discover-resource-hub-migration.db pnpm exec prisma migrate deploy
DATABASE_URL=file:./test-results/discover-resource-hub-migration.db pnpm exec prisma migrate status
DATABASE_URL=file:./test-results/discover-resource-hub-migration.db pnpm exec prisma migrate diff --from-url file:./test-results/discover-resource-hub-migration.db --to-schema-datamodel prisma/schema.prisma --exit-code
```

Expected: migrations applied, status clean, diff exit code 0.

- [ ] **Step 7: Remove disposable verification artifacts**

```bash
rm -f test-results/discover-resource-hub-migration.db test-results/discover-resource-hub-migration.db-wal test-results/discover-resource-hub-migration.db-shm test-results/discover-resource-hub-migration.db-journal
```

Confirm `git status --short` contains only intentional source/docs changes.

- [ ] **Step 8: Commit documentation/contract updates**

```bash
git add docs/operations/DISCOVER_LOCAL_RUNBOOK.md docs/projects/alirezasafaeisystems.md tests/ci/deploy-discover-smoke.test.ts
git commit -m "docs(discover): define resource hub operating model"
```

If `tests/ci/deploy-discover-smoke.test.ts` required no change, omit it from `git add`.

- [ ] **Step 9: Exact-head CI and rollout handoff**

Push the implementation branch and require the repository's normal PR workflows on the exact head. Record the exact SHA and statuses in the PR body. Production deployment/migration is a separate rollout action; after deployment record:

```text
- deployed commit SHA
- prisma migrate status = clean
- /api/ready = healthy
- /discover = healthy
- one published /discover/<slug> = healthy
- Telegram deep link exact and UTM-free when that item is configured
- Admin edit/add/remove Telegram link works without redeploy
- rollback reference/snapshot available under existing deploy contract
```

Do not close the implementation issue as production-complete without this evidence.

---

## Roadmap / Dependency Order

```text
Task 1 / #175 — Data + validation
  ↓
Task 2 / #176 — Admin/API editorial lifecycle
  ↓
Task 3 / #177 — Global Telegram configuration
  ↓
Task 4 / #178 — Destination-specific telemetry
  ↓
Task 5 / #179 — Detail resource UX
  ↓
Task 6 / #180 — Landing resource-hub positioning
  ↓
Task 7 / #181 — Browser + accessibility proof
  ↓
Task 8 / #182 — Ops docs + full verification + rollout evidence
```

Tasks #177 and #178 can be implemented in parallel after #175, but #179 depends on both. #181 depends on #175–#180. #182 is the final integration/verification gate.

## Definition of Ready for Each Agent Task

An agent may start a task only when:

1. all dependency tasks above it are merged into its working branch/worktree;
2. it has read both this plan and the design spec;
3. it uses the repository's existing patterns rather than inventing parallel abstractions;
4. it starts with the specified failing test or an equivalent stronger test;
5. production/server mutation is not required for the task.

## Stop Conditions

Stop and report instead of guessing when any of these occur:

- the real Prisma migration chain conflicts with the migration name/order in this plan;
- production SQLite state is required to continue;
- a change would require Instagram or Telegram API credentials;
- global Telegram channel/group identity has not been supplied and code would otherwise need a placeholder;
- existing CI/deploy contracts contradict the proposed optional smoke behavior;
- a required repository gate fails for a pre-existing unrelated reason that cannot be safely fixed in scope.

## Plan Self-Review Result

- Spec coverage: all data, Admin, public UX, global configuration, analytics, SEO-preservation, security/privacy, migration, testing, content workflow and production-evidence requirements map to Tasks #175–#182.
- Placeholder scan: no implementation step requires a guessed Telegram handle, secret, production slug or future TODO. Optional global destinations remain unset until owner configuration exists.
- Type consistency: the single per-item field is `telegramGuideUrl`; global environment names are `NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL` and `NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL`; Telegram event names are `discover_telegram_guide_click`, `discover_telegram_channel_click`, and `discover_telegram_group_click` throughout.
