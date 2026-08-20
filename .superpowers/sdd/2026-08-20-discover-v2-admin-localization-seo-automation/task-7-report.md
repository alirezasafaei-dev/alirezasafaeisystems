# Task 7 — Discover detail localization and SEO

## RED evidence

Command:

```bash
pnpm vitest run src/__tests__/seo/discover-detail-seo.test.ts src/__tests__/seo/sitemap.test.ts
```

Initial result: 2 files failed, 4 of 8 tests failed. The failures proved that an English route rendered a Persian-only item, English metadata reused Persian title and description, the sitemap advertised an unavailable English alternate, and it omitted locale-specific reciprocal URLs.

## GREEN evidence

- Detail publication now requires the effective locale content: Persian uses base fields and English requires `publishedEn` plus English title, description, and guide. No indexable English detail page falls back to Persian content.
- Canonical and hreflang values advertise only public locales. Sitemap emits one entry per public locale and only reciprocal alternates that exist.
- The primary external CTA is neutral: `باز کردن منبع` / `Open resource`. The Telegram tutorial/file CTA remains separate; Instagram remains provenance.
- DeepSeek's existing non-official disclosure is preserved in the article body and rendered as a visible note. JSON-LD identifies ASDEV's editorial Article and does not claim ownership of the third-party resource.

Focused GREEN command result: PASS — 2 files, 8 tests.

## Gates

- `pnpm type-check`: PASS.
- `pnpm test`: PASS — 57 files, 367 tests.
- `pnpm lint`: PASS with 2 pre-existing warnings in `scripts/telegram-bot/bot.js`; no Task 7 warnings/errors.
- `git diff --check`: PASS.

## Review fix round 1 — effective English availability and Persian canonical URL

### RED evidence

`pnpm vitest run src/__tests__/seo/discover-detail-seo.test.ts src/__tests__/seo/sitemap.test.ts` failed 4 of 10 tests. The failures showed blank English editorial fields could still produce a public detail page and sitemap entry, while dynamic sitemap URLs used `/fa/discover/...` even though `withLocale(path, 'fa')` establishes unprefixed Persian URLs.

### GREEN evidence

- `isDiscoverEnglishPublic` is the single trimmed-field predicate for English publication. Detail rendering/metadata, hreflang, sitemap entries and alternates, and English related cards use it.
- Persian Discover detail URLs are consistently `/discover/<slug>` in metadata, hreflang, and sitemap; English remains `/en/discover/<slug>`.

- Focused SEO: PASS — 2 files, 10 tests.
- `pnpm type-check`: PASS.
- `pnpm test`: PASS — 57 files, 369 tests.
- `pnpm lint`: PASS with the same 2 pre-existing warnings in `scripts/telegram-bot/bot.js`; no Task 7 warnings/errors.
- `git diff --check`: PASS.
