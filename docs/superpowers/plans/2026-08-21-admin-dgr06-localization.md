# Admin DGR-06 Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Localize the complete Admin login, dashboard shell, lead/message/analytics views, and portfolio project manager for Persian and English while preserving canonical stored keys and responsive behavior.

**Architecture:** Extend the existing `translations` tree under `admin` with string-only login/dashboard/projects dictionaries so all client components can consume them through `useI18n().t()`. Server Admin pages resolve request language through `getRequestLanguage()` for localized metadata/fallback copy. Stored lead status, organization, budget, project content type, and API payload values remain unchanged; only presentation labels, direction, dates, errors, and controls are localized.

**Tech Stack:** Next.js 16, React 19, TypeScript, Tailwind CSS 4, Vitest, Testing Library, Playwright.

**Spec:** GitHub Issue #191, DGR-05 inventory and DGR-06 acceptance criteria.

## Global Constraints

- Preserve canonical DB/status/category keys and API payload values.
- Persian UI uses RTL; English UI uses LTR.
- URL, email, UTM, and other identifier values remain visually readable and are not translated.
- No schema, migration, authentication, or production-data mutation.
- Use existing `I18nProvider` / `useI18n().t()` translation contract.
- Acceptance requires FA/EN component coverage and mobile layout coverage.

---

### Task 1: Admin translation contract

**Files:**
- Create: `src/lib/i18n/admin-copy.ts`
- Modify: `src/lib/i18n/translations.ts`
- Modify: `src/__tests__/lib/i18n-translations.test.ts`

**Interfaces:**
- Consumes: `translations.en.admin.discover` and `translations.fa.admin.discover` existing dictionaries.
- Produces: `translations.{fa,en}.admin.login`, `translations.{fa,en}.admin.dashboard`, and `translations.{fa,en}.admin.projects`, all string-only and addressable through `t('admin....')`.

- [ ] **Step 1: Write the failing translation parity and representative-copy tests**

Add assertions proving both locales contain the new Admin sections and representative keys:

```ts
expect(translations.en.admin.login.title).toBe('Admin Login')
expect(translations.fa.admin.login.title).toBe('ورود مدیریت')
expect(translations.en.admin.dashboard.status.qualified).toBe('Qualified')
expect(translations.fa.admin.dashboard.status.qualified).toBe('واجد شرایط')
expect(translations.en.admin.projects.save).toBe('Save project')
expect(translations.fa.admin.projects.save).toBe('ذخیره پروژه')
```

- [ ] **Step 2: Run the focused test and verify RED**

Run: `pnpm vitest run src/__tests__/lib/i18n-translations.test.ts`

Expected: FAIL because `login`, `dashboard`, and `projects` do not exist under `admin`.

- [ ] **Step 3: Add string-only FA/EN Admin dictionaries**

Create `src/lib/i18n/admin-copy.ts` exporting `ADMIN_COPY_EN` and `ADMIN_COPY_FA`. Include every audited login/dashboard/projects string: headings, descriptions, tabs, loading/empty states, status/filter labels, actions, dialogs/detail labels, toast/error labels, analytics labels, project editor/list labels, and accessible delete labels.

- [ ] **Step 4: Compose dictionaries into the existing translations tree**

Change:

```ts
admin: { discover: DISCOVER_ADMIN_COPY_EN }
```

to:

```ts
admin: { ...ADMIN_COPY_EN, discover: DISCOVER_ADMIN_COPY_EN }
```

and the Persian equivalent with `ADMIN_COPY_FA`.

- [ ] **Step 5: Run focused translation tests and verify GREEN**

Run: `pnpm vitest run src/__tests__/lib/i18n-translations.test.ts src/__tests__/lib/i18n-context.test.tsx`

Expected: PASS with bidirectional key parity intact.

- [ ] **Step 6: Commit**

```bash
git add src/lib/i18n/admin-copy.ts src/lib/i18n/translations.ts src/__tests__/lib/i18n-translations.test.ts
git commit -m "feat(admin): add bilingual shell copy"
```

---

### Task 2: Localized Admin login and metadata

**Files:**
- Modify: `src/app/admin/login/page.tsx`
- Modify: `src/app/admin/page.tsx`
- Modify: `src/components/admin/admin-login-form.tsx`
- Create: `src/__tests__/components/admin-login-form.test.tsx`

**Interfaces:**
- Consumes: `t('admin.login.*')`, `getRequestLanguage()`, `translations[lang].admin.login`.
- Produces: request-locale metadata/fallback and client login form with locale-correct direction/copy.

- [ ] **Step 1: Write failing FA/EN login component tests**

Render with `I18nProvider initialLanguage="fa"` and `"en"`, clearing the lang cookie first. Assert:

```ts
expect(screen.getByRole('heading', { name: 'ورود مدیریت' })).toBeInTheDocument()
expect(screen.getByRole('button', { name: 'ورود' })).toBeInTheDocument()
expect(screen.getByTestId('admin-login-form')).toHaveAttribute('dir', 'rtl')
```

and English equivalents with `dir="ltr"`.

- [ ] **Step 2: Run focused login test and verify RED**

Run: `pnpm vitest run src/__tests__/components/admin-login-form.test.tsx`

Expected: FAIL on hard-coded English copy/direction.

- [ ] **Step 3: Replace login literals with `t()` keys**

Use:

```ts
const { language, t } = useI18n()
const dir = language === 'fa' ? 'rtl' : 'ltr'
```

Map failed-login/network/configuration messages to localized generic copy instead of surfacing server English strings.

- [ ] **Step 4: Localize server metadata and Suspense fallback**

Use `generateMetadata()` with `getRequestLanguage()` on `/admin` and `/admin/login`, and resolve login fallback text from `translations[lang].admin.login.loading`.

- [ ] **Step 5: Run focused tests and type-check**

Run: `pnpm vitest run src/__tests__/components/admin-login-form.test.tsx && pnpm run type-check`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/app/admin/login/page.tsx src/app/admin/page.tsx src/components/admin/admin-login-form.tsx src/__tests__/components/admin-login-form.test.tsx
git commit -m "feat(admin): localize login shell"
```

---

### Task 3: Localized dashboard, leads, messages, and analytics

**Files:**
- Modify: `src/components/admin/admin-dashboard.tsx`
- Create: `src/__tests__/components/admin-dashboard-localization.test.tsx`

**Interfaces:**
- Consumes: `t('admin.dashboard.*')`, `language` from `useI18n()`.
- Produces: localized shell/tabs/status/actions/dialogs/toasts/dates while API values remain canonical.

- [ ] **Step 1: Write failing bilingual dashboard tests**

Mock `/api/admin/leads` and `/api/admin/messages` with one canonical lead (`status: 'qualified'`) and one message. Assert Persian rendering uses localized shell/status/action copy and RTL; English rendering uses English copy and LTR. Assert raw status value remains unchanged in the PATCH request when clicking the localized archive action.

- [ ] **Step 2: Run focused dashboard test and verify RED**

Run: `pnpm vitest run src/__tests__/components/admin-dashboard-localization.test.tsx`

Expected: FAIL because the dashboard is hard-coded English.

- [ ] **Step 3: Replace static dashboard copy with translation keys**

Use `const { language, t } = useI18n()`. Replace visible literals across header, cards, tabs, lead filters/table, detail dialog, messages, and analytics. Render canonical statuses with:

```ts
t(`admin.dashboard.status.${lead.status}`)
```

while PATCH continues to send `lead.status` enum values.

- [ ] **Step 4: Make direction/date/layout locale-aware**

Set the dashboard section `dir` from language. Use `fa-IR` for Persian dates and `en-US` for English dates. Replace physical directional utilities such as `mr-2`, `ml-2`, `left-*`, `pl-*`, and `text-right` with logical `me-*`, `ms-*`, `start-*`, `ps-*`, and `text-end` where they affect localized layout.

- [ ] **Step 5: Run focused tests and lint**

Run: `pnpm vitest run src/__tests__/components/admin-dashboard-localization.test.tsx && pnpm run lint`

Expected: PASS with no new lint errors.

- [ ] **Step 6: Commit**

```bash
git add src/components/admin/admin-dashboard.tsx src/__tests__/components/admin-dashboard-localization.test.tsx
git commit -m "feat(admin): localize dashboard operations"
```

---

### Task 4: Localized portfolio project manager

**Files:**
- Modify: `src/components/admin/project-manager.tsx`
- Create: `src/__tests__/components/project-manager-localization.test.tsx`

**Interfaces:**
- Consumes: `t('admin.projects.*')`, `language` from `useI18n()`.
- Produces: localized editor/list/errors/toasts/actions without changing `contentType: 'portfolio'` or request payloads.

- [ ] **Step 1: Write failing FA/EN project-manager tests**

Mock project GET and assert Persian heading/labels/status/buttons with `dir="rtl"`; assert English equivalents with `dir="ltr"`. Submit a project and prove the request body still contains:

```ts
{ contentType: 'portfolio' }
```

- [ ] **Step 2: Run focused project test and verify RED**

Run: `pnpm vitest run src/__tests__/components/project-manager-localization.test.tsx`

Expected: FAIL on hard-coded English copy.

- [ ] **Step 3: Replace project-manager literals with translation keys**

Localize loading/errors/editor/list/status/toasts/confirm/action labels. Do not surface raw API English errors to users; use localized generic failure copy.

- [ ] **Step 4: Preserve logical direction for fields and identifiers**

Set wrapper direction by locale; keep URL inputs LTR. Keep `contentType` and API fields canonical.

- [ ] **Step 5: Run focused tests**

Run: `pnpm vitest run src/__tests__/components/project-manager-localization.test.tsx`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/components/admin/project-manager.tsx src/__tests__/components/project-manager-localization.test.tsx
git commit -m "feat(admin): localize project manager"
```

---

### Task 5: Mobile acceptance and full verification

**Files:**
- Modify: `e2e/discover-v2.spec.ts`

**Interfaces:**
- Consumes: existing disposable Admin authentication helper in `e2e/discover-v2.spec.ts`.
- Produces: hosted-browser proof for 390×844 Admin FA/EN layout and direction.

- [ ] **Step 1: Add mobile Admin localization acceptance**

At a 390×844 viewport, authenticate with the existing disposable test token, set `lang=fa`, open `/admin`, and assert RTL Persian shell plus no horizontal overflow:

```ts
expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true)
```

Repeat with `lang=en`, assert LTR English shell, and open the Projects tab to verify localized project-manager copy remains within the mobile viewport.

- [ ] **Step 2: Run targeted browser acceptance**

Run: `pnpm exec playwright test e2e/discover-v2.spec.ts`

Expected: PASS including both locale/mobile checks.

- [ ] **Step 3: Run full required local gate set**

Run:

```bash
pnpm run type-check
pnpm run lint
pnpm run test
pnpm run build
```

Expected: all commands exit 0.

- [ ] **Step 4: Commit**

```bash
git add e2e/discover-v2.spec.ts
git commit -m "test(admin): cover bilingual mobile layout"
```

- [ ] **Step 5: Open a dedicated DGR-06 PR**

PR scope must remain Admin localization only. Do not merge because `src/**` merge-to-main auto-triggers production deploy and requires the repository production approval gate.
