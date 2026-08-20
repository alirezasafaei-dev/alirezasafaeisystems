# Discover Resource Hub — Local Windows 11 Runbook

## Scope

این runbook برای اجرای local **Discover Resource Hub** داخل سایت ASDEV است. Discover سرویس جدا نیست و از همان Next.js app، Admin session، Prisma/SQLite، analytics، SEO و deployment contract موجود استفاده می‌کند. هیچ دستور این سند Production را تغییر نمی‌دهد.

هدف فعلی Discover این است که کاربر اینستاگرام یا Search با یک لینک ثابت به منبع درست برسد:

`Instagram reel/post → /discover → /discover/[slug] → quick guide → official URL و/یا exact Telegram tutorial/file → optional Telegram group`

Audit، Case Studies و Qualification مسیرهای ثانویه‌اند و نباید قبل از تحویل منبع اصلی مزاحم کاربر شوند.

## Prerequisites

- Windows 11
- Node.js 20 تا 22 مطابق `package.json`
- pnpm نسخهٔ تعریف‌شده در `package.json`
- Git و دسترسی local به repository

## Setup

```powershell
cd C:\Users\ASDEV\Documents\alirezasafaeisystems-discover-work
pnpm install --frozen-lockfile
pnpm db:generate
```

مقادیر واقعی secret را در فایل commit‌شده قرار ندهید. برای local از environment محلی مطابق `.env.example` استفاده کنید.

## Telegram configuration

سه مقصد مستقل وجود دارد:

1. `DiscoverItem.telegramGuideUrl` — لینک مستقیم همان پیام/فایل/آموزش کامل برای یک آیتم؛ از Admin قابل تغییر و zero-deploy است.
2. `NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL` — لینک عمومی کانال منابع؛ اختیاری.
3. `NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL` — لینک عمومی گروه پرسش‌وپاسخ؛ اختیاری.

هر سه مقصد Discover باید URL امن `https://t.me/...` باشند. `telegram.me`، HTTP، URL دارای username/password و hostهای دیگر پذیرفته نمی‌شوند. متغیر قدیمی `NEXT_PUBLIC_TELEGRAM_URL` یک social-profile عمومی است و برای Discover repurpose نمی‌شود.

اگر channel/group تنظیم نشده باشند، CTA مربوطه اصلاً render نمی‌شود. placeholder یا handle حدسی وارد Production نکنید.

## Database and migration rehearsal

Discover جدول مستقل `DiscoverItem` دارد. migrationهای قبلی legacy content را non-destructive به این جدول منتقل کرده‌اند. Resource Hub فقط ستون nullable زیر را به آن اضافه می‌کند:

```text
telegramGuideUrl TEXT NULL
```

migration رسمی:

```text
20260819080000_add_discover_telegram_guide
```

SQL آن additive است و هیچ backfill، DELETE، DROP یا table rebuild انجام نمی‌دهد.

قبل از migration local از دیتابیس backup بگیرید و سپس:

```powershell
pnpm exec prisma validate
pnpm run db:generate
pnpm exec prisma migrate dev
pnpm exec prisma migrate status
```

بعد از migration بررسی کنید:

1. جدول `DiscoverItem` موجود باشد.
2. ستون nullable `telegramGuideUrl` اضافه شده باشد.
3. Discoverهای قبلی بدون Telegram URL همچنان معتبر باشند.
4. ردیف‌های `Project`، `Lead` و analytics بازنویسی یا حذف نشده باشند.
5. فایل DB و backup وارد Git نشوند.

برای verification زنجیره migration روی SQLite disposable از تست `tests/ci/prisma-migration-chain.test.ts` استفاده کنید؛ این تست replay، status و zero-drift را بررسی می‌کند.

## Verification

```powershell
pnpm exec prisma validate
pnpm run db:generate
pnpm run type-check
pnpm run lint
pnpm run test
pnpm run build
pnpm exec playwright test e2e/smoke.spec.mjs
pnpm exec playwright test e2e/a11y.spec.ts
```

در browser این مسیرها را بررسی کنید:

- `http://localhost:3000/discover`
- `http://localhost:3000/en/discover`
- `http://localhost:3000/admin`

## Resource manifest import

برای آماده‌سازی یک منبع Discover از این جریان استفاده کنید:

`manifest → validate → Admin Import JSON → review → save draft/publish → live verify`

Manifest فقط artifact محلی برای آماده‌سازی import است و production storage نیست. بخش `evidence` آن برای یادداشت‌های منبع است و نباید در Admin Import JSON وارد شود؛ فقط `payload` که با schema create سازگار است را import کنید. این جریان هیچ authentication Admin را bypass نمی‌کند؛ ورود و مجوزهای معمول Admin همچنان لازم‌اند.

قبل از Import، تنها validation محلی و بدون network را اجرا کنید:

```powershell
pnpm discover:validate
```

پس از PASS، `payload` را به Admin Import JSON منتقل کنید، محتوا و مقصدها را review کنید، ابتدا draft را ذخیره کنید یا در صورت تأیید publish کنید، و سپس detail public را live verify کنید.

برای manifestی که English editorial copy ندارد، `publishedEn` را در payload وارد نکنید. قرارداد create مقدار persisted پیش‌فرض `publishedEn=false` را اعمال می‌کند؛ بنابراین نتیجهٔ مؤثر انگلیسی منتشرنشده است، بدون افزودن field ناشناخته یا bypass کردن contract.

## Content operating workflow

برای هر Reel/Post که یک ابزار یا منبع را معرفی می‌کند:

1. در Admin یک Discover item بسازید یا آیتم موجود را edit کنید.
2. title، slug، category، tags و short description را کامل کنید.
3. در `content` یک راهنمای کوتاه و کاربردی بنویسید؛ صفحه نباید thin redirect باشد.
4. `externalUrl` را روی مقصد رسمی واقعی و HTTPS بگذارید.
5. اگر آموزش طولانی/فایل لازم است، آن را در Telegram Channel قرار دهید.
6. URL دقیق همان پیام Telegram را در `telegramGuideUrl` قرار دهید؛ homepage کانال را جای deep link نگذارید.
7. آیتم را Publish کنید و public detail را بررسی کنید.
8. CTA اینستاگرام را ساده نگه دارید: `لینک بیو → Discover → نام ابزار را جستجو کن`.
9. Telegram Group فقط برای سؤال/گفتگو است؛ archive فایل اصلی نیست.

## Admin CRUD smoke

از تب مستقل **Discover** در Admin با یک رکورد موقت این چرخه را اجرا کنید:

1. Create به‌صورت Draft با title، slug، category، description، short guide و official HTTPS URL.
2. یک `https://t.me/<channel>/<message-id>` معتبر به **Telegram full guide / file URL** اضافه کنید.
3. Publish و مشاهده کارت در `/discover`.
4. `/discover/<slug>` را باز کنید و ترتیب Resource-first را بررسی کنید: quick guide → official link → exact Telegram guide → optional channel/group → related items → secondary ASDEV links.
5. Edit کنید و Telegram URL را تغییر دهید؛ تغییر باید بدون deploy ذخیره شود.
6. Telegram URL را خالی کنید؛ API باید آن را `NULL` کند و CTA public حذف شود.
7. Featured و order را تغییر دهید و ترتیب landing را بررسی کنید.
8. Unpublish کنید؛ آیتم باید از landing حذف و detail public به 404 تبدیل شود.
9. Publish مجدد و سپس Delete را بررسی کنید.

پس از تست رکورد موقت را حذف کنید.

## Instagram / UTM smoke

این URL نمونه را local باز کنید:

```text
http://localhost:3000/discover?utm_source=instagram&utm_medium=social&utm_campaign=discover-smoke&utm_content=reel-test
```

بررسی کنید:

1. کلیک کارت به `/discover/<slug>` چهار UTM مجاز را حفظ کند.
2. CTA داخلی Qualification/Audit/Case Studies همان UTMهای مجاز را حفظ کند.
3. official URL، Instagram source، exact Telegram guide، Telegram channel و Telegram group هیچ ASDEV UTM داخلی دریافت نکنند.
4. پارامترهای نامرتبط مثل email یا query دلخواه propagate نشوند.
5. در صورت ثبت Qualification، Lead فقط attribution مجاز را حفظ کند.

## Analytics smoke

Analytics فقط با consent فعال ثبت می‌شود. پس از consent:

- landing: `discover_landing_view`
- detail: `discover_item_view`
- official: `discover_external_click`
- exact Telegram guide: `discover_telegram_guide_click`
- Telegram channel: `discover_telegram_channel_click`
- Telegram group: `discover_telegram_group_click`
- internal ASDEV CTA: `discover_internal_cta_click`

Telegram clickها eventهای `engagement` هستند. Metadata فقط شامل فیلدهای امن مثل `slug`، `category`، `target` و UTMهای allowlisted است؛ URL کامل Telegram، username، PII یا query string کامل نباید در telemetry ذخیره شود. شکست telemetry نباید navigation را متوقف کند.

## Playwright fixture safety

Browser tests یک fixture deterministic با slug زیر دارند:

```text
playwright-discover-resource
```

اسکریپت `scripts/test/seed-playwright-discover.mjs` فقط وقتی اجرا می‌شود که `DATABASE_URL` دقیقاً به `test-results/playwright.db` اشاره کند. در غیر این صورت fail-closed است. `playwright.config.mjs` نیز webServer را صراحتاً روی همین DB disposable اجرا می‌کند.

این fixture نباید در development DB یا Production ساخته شود.

## SEO and media smoke

- `/discover` canonical و hreflang داشته باشد.
- detail Published metadata و breadcrumb JSON-LD داشته باشد.
- Draft public resolve نشود.
- sitemap در صورت دسترسی DB فقط detailهای Published را اضافه کند.
- نبود DB هنگام build نباید static sitemap را از کار بیندازد.
- detail page باید محتوای مفید قابل‌مشاهده داشته باشد؛ Telegram integration نباید صفحه را به redirect thin تبدیل کند.

## Rollback principle

migration Resource Hub additive و nullable است. Production همچنان از snapshot/preflight/migrate/status/zero-drift/rollback contract موجود استفاده می‌کند. rollback یا cleanup مجاز نیست برای حذف داده‌های legacy، `Project`، `Lead` یا analytics از مسیر destructive استفاده کند.

## Production completion gate

Merged source یا CI سبز به‌تنهایی به معنی Production-complete نیست. پس از approval و rollout باید evidence زیر ثبت شود:

1. exact deployed commit SHA؛
2. `/api/ready` سالم؛
3. `/discover` سالم؛
4. حداقل یک published detail سالم؛
5. `prisma migrate status` clean و schema drift صفر؛
6. اگر یک Production item عمداً `telegramGuideUrl` دارد، href دقیق Telegram بدون UTM append شده باشد؛
7. live verification workflow و required smokeها PASS باشند.

نبود Telegram URL روی Production item نباید deployment را fail کند؛ Telegram CTA اختیاری است.

## Task 10 local acceptance evidence — 2026-08-20

روی `LOCAL_PC` و branch `feat/discover-v2-189` در head `a23c2649959d99b9301ffe8992bb1b4f0c9f538f`، lint با 0 error و 2 warning موجود، type-check، build، 371 تست unit/integration، `pnpm discover:validate`، audit high/critical و secret scan PASS شدند. Manifest `deepseek-telegram-bot.json` معتبر گزارش شد.

SQLite disposable با URL دقیق `file:/tmp/asdev-task10-discover-v2-189.sqlite` از صفر ساخته شد؛ `prisma migrate deploy` هر 9 migration را اعمال کرد، `prisma migrate status` schema را up to date گزارش کرد و `prisma migrate diff --exit-code` با `No difference detected.` و exit 0 پایان یافت. هیچ Production DB یا host تغییر نکرد.

Browser evidence هنوز PASS نیست: smoke و a11y پیش از اجرای page به‌دلیل نبود `libnspr4.so` در WSL متوقف شدند و Lighthouse بعد از build/start نتوانست به Windows Chrome DevTools متصل شود (`0x2740` سپس `ECONNREFUSED`). fixture موجود نیز Admin authenticated و bilingual detail واقعی را پوشش نمی‌دهد. بنابراین verdict فعلی `DEPLOY_BLOCKED_NOT_VERIFIED` است و هیچ Browser، Lighthouse، Admin، Production، publish/import یا telemetry PASS ادعا نمی‌شود.

PR merge به `main` workflowهای `Deploy VPS` و `Release` را trigger می‌کند. migration Production فقط با `APPROVE_CRITICAL_SITE_MIGRATION` و app deploy فقط با `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` مجاز است.

Draft PR `#190` روی exact head `113cbeba22851c5eb20d99eee9b0efc55c09f5ea` برای review باز شد. همه checkهای گزارش‌شده روی همان head PASS شدند: CI run `32397663850`، CI Router `32397663842`، CodeQL `32397663854`، E2E Smoke `32397663851`، Lighthouse Budget `32397663859` و Security Audit `32397663815`. PR در این checkpoint review/comment نداشت و merge یا deploy نشد.

## Failure handling

- خطای Prisma: `pnpm run db:generate`، `pnpm exec prisma validate` و `DATABASE_URL` را بررسی کنید.
- خطای Admin 401: فقط credential/session محلی Admin را بررسی کنید؛ secret را چاپ نکنید.
- خطای slug conflict: slug دیگری انتخاب کنید؛ API عمداً 409 می‌دهد.
- خطای Telegram URL: فقط credential-free `https://t.me/...` پذیرفته می‌شود.
- خطای build/type/test: root cause را اصلاح کنید؛ gate را حذف یا ضعیف نکنید.
- هر deployment یا migration روی Production نیازمند تأیید صریح جداگانهٔ owner است.
