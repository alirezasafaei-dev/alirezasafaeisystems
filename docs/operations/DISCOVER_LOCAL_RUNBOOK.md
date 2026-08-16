# Discover — Local Windows 11 Runbook

## Scope

این runbook برای اجرای local **Discover Acquisition Surface** داخل سایت شخصی است. Discover یک سرویس جدا نیست و از همان Next.js app، Admin session، Prisma/SQLite و analytics موجود استفاده می‌کند. هیچ دستور این سند production را تغییر نمی‌دهد.

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

## Database and migration rehearsal

Discover جدید جدول مستقل `DiscoverItem` دارد. migration اصلی عمداً non-destructive است: رکوردهای قدیمی `Project` با `contentType=discover` را به جدول جدید copy می‌کند و ردیف‌های Project را حذف یا overwrite نمی‌کند. migration دوم فقط ستون nullable `Lead.utmContent` را اضافه می‌کند تا attribution سطح Reel/content تا Lead نهایی حفظ شود.

قبل از migration از دیتابیس local backup بگیرید و سپس:

```powershell
pnpm exec prisma migrate dev
```

بعد از migration بررسی کنید:

1. جدول `DiscoverItem` ایجاد شده باشد.
2. Discoverهای قدیمی در صورت وجود با slug نوع `legacy-<project-id>` کپی شده باشند.
3. Projectهای قبلی همچنان موجود باشند.
4. ستون nullable `utmContent` در `Lead` اضافه شده باشد و Leadهای قبلی دست‌نخورده باشند.
5. فایل DB و backup وارد Git نشوند.

## Verification

```powershell
pnpm lint
pnpm type-check
pnpm test
pnpm build
pnpm dev
```

در browser این مسیرها را بررسی کنید:

- `http://localhost:3000/discover`
- `http://localhost:3000/en/discover`
- `http://localhost:3000/admin`

## Admin CRUD smoke

از تب مستقل **Discover** در Admin، با یک رکورد موقت این چرخه را اجرا کنید:

1. Create به‌صورت Draft با title، slug، category، description، short guide و official HTTPS URL.
2. Edit و اضافه‌کردن tags، optional Instagram URL و image URL.
3. Publish و مشاهده کارت در `/discover`.
4. بازکردن `/discover/<slug>` و بررسی guide، official link و ASDEV CTAs.
5. تغییر Featured و order و بررسی ترتیب landing.
6. Unpublish و اطمینان از حذف از landing و 404 شدن detail public.
7. Publish مجدد و بررسی اینکه lifecycle بدون deploy کار می‌کند.
8. Delete و اطمینان از حذف از Admin و public query.

پس از تست، رکورد موقت را حذف کنید.

## Instagram / UTM smoke

این URL نمونه را local باز کنید:

```text
http://localhost:3000/discover?utm_source=instagram&utm_medium=social&utm_campaign=discover-smoke&utm_content=reel-test
```

بررسی کنید:

1. کلیک کارت به `/discover/<slug>` چهار UTM مجاز را حفظ کند.
2. CTA داخلی Qualification/Audit/Case Studies همان UTMهای مجاز را حفظ کند.
3. لینک رسمی third-party و Instagram destination هیچ UTM داخلی را به مقصد خارجی append نکند.
4. پارامترهای نامرتبط مثل email یا query دلخواه propagate نشوند.
5. پس از ثبت Qualification، Lead ذخیره‌شده `utmSource=instagram`، campaign مربوط و `utmContent=reel-test` را حفظ کند.

## Analytics smoke

Analytics فقط با consent فعال ثبت می‌شود. پس از دادن consent در محیط local:

- landing باید `discover_landing_view` ثبت کند؛
- detail باید `discover_item_view` ثبت کند؛
- official link باید `discover_external_click` ثبت کند؛
- ASDEV CTA باید `discover_internal_cta_click` ثبت کند؛
- eventهای یک browser session باید `sessionId` یکسان داشته باشند تا funnel قابل correlation باشد.

Metadata فقط شامل slug/category/target و UTMهای مجاز است و نباید PII یا query string کامل داشته باشد. شکست telemetry نباید navigation را متوقف کند.

## SEO and media smoke

- `/discover` باید canonical و hreflang داشته باشد.
- detail Published باید metadata و breadcrumb JSON-LD داشته باشد.
- Draft نباید public resolve شود.
- sitemap در صورت دسترسی DB باید فقط detailهای Published را اضافه کند.
- نبود DB هنگام build نباید sitemap استاتیک را از کار بیندازد.
- یک `imageUrl` معتبر HTTPS باید بدون CSP violation در کارت/detail render شود.

## Rollback principle

اگر migration یا rollout نیاز به rollback داشت، Projectهای legacy همچنان history/backup داخلی را نگه می‌دارند. migration attribution فقط یک ستون nullable به Lead اضافه می‌کند و داده قبلی را بازنویسی نمی‌کند. این feature مجاز نیست برای rollback یا cleanup ردیف‌های Project یا Lead قدیمی را حذف کند.

## Failure handling

- خطای Prisma: ابتدا `pnpm db:generate`، `pnpm exec prisma validate` و `DATABASE_URL` را بررسی کنید.
- خطای Admin 401: فقط از credential/session محلی Admin استفاده کنید؛ secret را چاپ نکنید.
- خطای slug conflict: slug دیگری انتخاب کنید؛ API عمداً 409 می‌دهد.
- خطای URL: فقط HTTPS بدون username/password پذیرفته می‌شود؛ Instagram URL باید روی `instagram.com` باشد.
- خطای build/type/test: root cause را اصلاح کنید؛ gate را حذف یا ضعیف نکنید.
- هر deployment یا migration روی production نیازمند تأیید صریح جداگانهٔ owner است.
