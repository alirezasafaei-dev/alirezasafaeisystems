# نقشه راه و تسک‌بندی اولویت‌بندی‌شده

**تاریخ به‌روزرسانی:** 2026-04-29
**منبع:** ترکیب `docs/IMMEDIATE_EXECUTION_MAP_2026-02-20.md` + `docs/ENTERPRISE_EXECUTION_BACKLOG.md` + `docs/runtime/EXECUTION_NOW.md`

## اصول اولویت‌بندی
- **P0**: خط تولید و عملکرد اولیه سایت / ریسک بالا
- **P1**: تاثیر مستقیم روی SEO/مسیریابی/تحلیل و پایداری محصول
- **P2**: بهبود مداوم کیفیت مهندسی و رشد تبدیل
- هر تسک یک مالک، خروجی قابل‌اعتبارسازی، و معیار پذیرش دارد.

## Backlog فعال (اولویت بالا)

### P0 — فوری (72 تا 120 ساعت آینده)
- [ ] `P0-1` **ثبات دسترسی VPS و Edge-Origin**  
  مالک: `DevOps`  
  شرح: رفع timeoutهای دستیابی خارجی و تثبیت مسیر edge→origin (فایروال/نگه‌داری IP allowlist + تست‌های چندمکانی).  
  خروجی: گزارش جدید در `docs/runtime/VPS_ACCESS_CHECK_*.md`.  
  پذیرش: `https://alirezasafaeisystems.ir/` و `/api/ready` پایدار `200`.

- [ ] `P0-2` **مهاجرت ناوبری به مسیر واقعی (Route-first)**  
  مالک: `FE`  
  شرح: اصلاح `src/components/layout/header.tsx` برای لینک‌های واقعی صفحه‌ها (`/`, `/services`, `/case-studies`, `/qualification`) بدون اتکا به hash-only.  
  خروجی: فایل‌های تغییر یافته و Evidence route-refresh سالم.  
  پذیرش: هر لینک منو روی Refresh پاسخ می‌دهد و مسیر ثابت می‌ماند.

- [ ] `P0-3` **بازنویسی Hero و پیام برند سازمانی**  
  مالک: `FE + Product`  
  شرح: حذف آمار غیرمستند، افزودن پیام outcome-driven و proof chips بومی/مهندسی (مثلاً استقرار داخلی، CI/CD و DR).  
  خروجی: به‌روزرسانی `src/components/sections/hero.tsx` و ترجمه‌ها در `src/lib/i18n/translations.ts`.  
  پذیرش: پیام ۳ ثانیه اول صفحه، authority + local stability + trust را منتقل کند.

- [ ] `P0-4` **هم‌راستاسازی بخش تماس و microcopy اعتماد**  
  مالک: `FE`  
  شرح: حذف `Remote / Global`، جایگزینی با `تهران / ریموت (سراسر ایران)` و افزودن microcopyهای اعتماد (NDA/SLA).  
  خروجی: `src/components/sections/contact.tsx`.  
  پذیرش: متن `Remote / Global` حذف شده و microcopyها روی صفحه قابل مشاهده باشند.

- [ ] `P0-5` **اصلاح فوری Sitemap**  
  مالک: `FE`  
  شرح: جایگزینی `lastModified=now` با تاریخ واقعی به‌روزرسانی مسیرها در `src/app/sitemap.ts`.  
  خروجی: `src/app/sitemap.ts` و تایید تست ساختار sitemap.  
  پذیرش: `pnpm run test`/`build` بدون regression در sitemap.

### P1 — کوتاه‌مدت (هفته اول تا دوم)
- [ ] `P1-1` **مهاجرت مسیریابی locale-centered (`/fa`)**  
  مالک: `FE`  
  شرح: پیاده‌سازی `src/middleware.ts` و اسکلت `src/app/[lang]/*` برای canonical پایدار مبتنی بر locale.  
  خروجی: routeهای جدید locale-first در production-safe.  
  پذیرش: canonical/hreflang قابل تولید براساس locale باشد.

- [ ] `P1-2` **بازطراحی Metadata و canonical per-locale**  
  مالک: `FE + SEO`  
  شرح: تنظیم `generateMetadata` پویا در `src/app/layout.tsx` و مدیریت self-reference/alternate.  
  خروجی: بهبود schema متا برای فارسی و انگلیسی.  
  پذیرش: canonical، `fa-IR` و `en-US` در مسیرهای مرتبط صحیح.

- [ ] `P1-3` **اصلاح inLanguage در Schema**  
  مالک: `FE`  
  شرح: پارامتری‌سازی `inLanguage` در `src/lib/seo.ts`.  
  خروجی: `src/lib/seo.ts` و تست اعتبار خروجی JSON-LD.  
  پذیرش: محتوای فارسی به‌درستی با `fa-IR` خروجی شود.

- [ ] `P1-4` **به‌روزرسانی مسیرهای LHCI مطابق مسیر نهایی**  
  مالک: `FE`  
  شرح: هم‌سو سازی `lighthouserc.json` با مسیرهای جدید و اصلی سایت.  
  خروجی: تنظیمات بهینه‌شده Lighthouse budget/route set.  
  پذیرش: اجرای `pnpm run lighthouse:ci` بدون false-fail مرتبط با مسیر.

### P2 — میانه‌مدت (هفته دوم تا چهارم)
- [ ] `P2-1` **حاکمیت Design Token**  
  مالک: `FE Lead`  
  شرح: Freeze tokenها برای رنگ/typography/spacing/radius/elevation و رفع hard-codeهای UI.  
  خروجی: `docs/DESIGN_TOKEN_REGISTRY.md` + به‌روزرسانی `src/app/globals.css` و کامپوننت‌ها.  
  پذیرش: رفرنس‌گذاری استاندارد در قالب tokenهای رسمی.

- [ ] `P2-2` **افزودن A11y gate به Playwright**  
  مالک: `QA + FE`  
  شرح: افزودن تست‌های accessibility برای مسیرهای اصلی با Axe.  
  خروجی: `e2e/a11y.spec.ts` و اسکریپت اجرا در CI.  
  پذیرش: عدم وجود critical violations در صفحه اصلی و Qualification.

- [ ] `P2-3` **فرم دو مرحله‌ای Qualification**  
  مالک: `FE + Product`  
  شرح: دو مرحله‌ای‌سازی فرم `src/components/sections/infrastructure-lead-form.tsx` با ذخیره‌ی پیش‌نویس.  
  خروجی: فرم step1/step2 و رفتار بازگشت‌پذیر در خطای submit.  
  پذیرش: بهبود completion نسبت به baseline فعلی + تست e2e مسیر فرم.

## تسک‌های راهبردی باز از بک‌لاگ (P1/P2)
- [ ] `STRAT-1` Freeze نقش/هدف هر دامنه + KPI اصلی + ۳ KPI پشتیبان.
- [ ] `STRAT-2` تعریف taxonomy مشترک eventها (`source`, `stage`, `intent`, `outcome`).
- [ ] `STRAT-3` تعریف acceptance criteria برای `qualified lead`.
- [ ] `STRAT-4` اجرای baseline فنی/UX/SEO (network readiness, metadata, link integrity) و گزارش `critical/high/medium`.
- [ ] `STRAT-5` حذف مسیرهای intent تکراری و dead-end در IA.
- [ ] `STRAT-6` استانداردسازی microcopy فرم/خطا/موفقیت و glossary اصطلاحات فنی فارسی.
- [ ] `STRAT-7` اجرای segment و consistency های SEO (canonical/hreflang/meta/schema) و بهینه‌سازی internal linking.
- [ ] `STRAT-8` Define SLO/availability budget + اعتبارسنجی incident rollback readiness.

## تعریف Done (برای هر تسک)
- [ ] PR اتمیک و دامنه‌بندی‌شده (یک هدف)
- [ ] مدارک شواهد قبل/بعد اگر UI یا UX تغییر کرده
- [ ] اجرای کامل در CI: `pnpm run verify`
- [ ] اگر مسیر/UX: `pnpm run lighthouse:ci`
- [ ] آپدیت مستندات مرتبط در همان PR

## روش اجرای پیشنهادی روزانه
1. اجرای تسک‌های `P0` به شکل PRهای کوچک (حداکثر ۱-۲ فایل/تغییر مرکزی در هر PR)
2. ثبت خروجی پس از هر PR در `docs/runtime/` یا فایل اثبات اجرایی مربوط
3. بازنگری ۲ روز یک‌بار روی `STRAT-*` و اولویت‌بندی مجدد طبق impact/effort
