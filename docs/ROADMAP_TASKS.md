# نقشه راه و تسک‌بندی اولویت‌بندی‌شده

**تاریخ به‌روزرسانی:** 2026-06-16
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

- [x] `P0-2` **مهاجرت ناوبری به مسیر واقعی (Route-first)** ✅  
  مالک: `FE`  
  شرح: اصلاح `src/components/layout/header.tsx` برای لینک‌های واقعی صفحه‌ها.  
  خروجی: فایل‌های تغییر یافته و Evidence route-refresh سالم.  
  پذیرش: هر لینک منو روی Refresh پاسخ می‌دهد و مسیر ثابت می‌ماند.  
  **تاریخ اتمام:** 2026-06-15 — هدر از مسیرهای واقعی `/services`, `/case-studies`, `/qualification` استفاده می‌کند.

- [x] `P0-3` **بازنویسی Hero و پیام برند سازمانی** ✅  
  مالک: `FE + Product`  
  شرح: حذف آمار غیرمستند، افزودن پیام outcome-driven و proof chips.  
  خروجی: به‌روزرسانی `src/components/sections/hero.tsx` و ترجمه‌ها.  
  پذیرش: پیام ۳ ثانیه اول صفحه، authority + local stability + trust را منتقل کند.  
  **تاریخ اتمام:** 2026-06-15 — Hero شامل intent router، capabilities و collaboration flow است.

- [x] `P0-4` **هم‌راستاسازی بخش تماس و microcopy اعتماد** ✅  
  مالک: `FE`  
  شرح: حذف `Remote / Global`، جایگزینی با `تهران / ریموت (سراسر ایران)` و افزودن microcopyهای اعتماد.  
  خروجی: `src/components/sections/contact.tsx`.  
  پذیرش: متن `Remote / Global` حذف شده و microcopyها روی صفحه قابل مشاهده باشند.  
  **تاریخ اتمام:** 2026-06-15 — microcopy NDA/SLA اضافه شد.

- [x] `P0-5` **اصلاح فوری Sitemap** ✅  
  مالک: `FE`  
  شرح: جایگزینی `lastModified=now` با تاریخ واقعی به‌روزرسانی مسیرها.  
  خروجی: `src/app/sitemap.ts` و تایید تست ساختار sitemap.  
  پذیرش: `pnpm run test`/`build` بدون regression در sitemap.  
  **تاریخ اتمام:** 2026-06-15 — Sitemap از `sitemap-manifest.json` با تاریخ واقعی git استفاده می‌کند.

### P1 — کوتاه‌مدت (هفته اول تا دوم)
- [x] `P1-1` **مهاجرت مسیریابی locale-centered (`/fa`)** ✅  
  مالک: `FE`  
  شرح: پیاده‌سازی `src/proxy.ts` (middleware) و مسیریابی locale-aware.  
  خروجی: routeهای locale-first در production-safe.  
  پذیرش: canonical/hreflang قابل تولید براساس locale باشد.  
  **تاریخ اتمام:** 2026-06-15 — proxy.ts شامل language detection، admin protection، security headers.

- [x] `P1-2` **بازطراحی Metadata و canonical per-locale** ✅  
  مالک: `FE + SEO`  
  شرح: تنظیم `generateMetadata` پویا در تمام صفحات و مدیریت self-reference/alternate.  
  خروجی: بهبود schema متا برای فارسی و انگلیسی.  
  پذیرش: canonical، `fa-IR` و `en-US` در مسیرهای مرتبط صحیح.  
  **تاریخ اتمام:** 2026-06-15 — تمام ۱۲ صفحه متادیتای پویا و دوزبانه دارند.

- [x] `P1-3` **اصلاح inLanguage در Schema** ✅  
  مالک: `FE`  
  شرح: پارامتری‌سازی `inLanguage` در `src/lib/seo.ts`.  
  خروجی: `src/lib/seo.ts` و تست اعتبار خروجی JSON-LD.  
  پذیرش: محتوای فارسی به‌درستی با `fa-IR` خروجی شود.  
  **تاریخ اتمام:** 2026-06-15 — `inLanguage` پویا در Person, WebSite, Organization schemas.

- [x] `P1-4` **به‌روزرسانی مسیرهای LHCI مطابق مسیر نهایی** ✅  
  مالک: `FE`  
  شرح: هم‌سو سازی `lighthouserc.json` با مسیرهای جدید و اصلی سایت.  
  خروجی: تنظیمات بهینه‌شده Lighthouse budget/route set.  
  پذیرش: اجرای `pnpm run lighthouse:ci` بدون false-fail مرتبط با مسیر.  
  **تاریخ اتمام:** 2026-06-15 — مسیرهای qualification و about-brand اضافه شد، آستانه‌ها افزایش یافت.

### P2 — میانه‌مدت (هفته دوم تا چهارم)
- [x] `P2-1` **حاکمیت Design Token** ✅
  مالک: `FE Lead`
  شرح: Freeze tokenها برای رنگ/typography/spacing/radius/elevation و رفع hard-codeهای UI.
  خروجی: `docs/DESIGN_TOKEN_REGISTRY.md` + به‌روزرسانی `src/app/globals.css` و کامپوننت‌ها.
  پذیرش: رفرنس‌گذاری استاندارد در قالب tokenهای رسمی.
  **تاریخ اتمام:** 2026-06-16 — audit کامل انجام شد، 0 hard-coded color در کامپوننت‌ها.

- [x] `P2-2` **افزودن A11y gate به Playwright** ✅  
  مالک: `QA + FE`  
  شرح: افزودن تست‌های accessibility برای مسیرهای اصلی با Axe.  
  خروجی: `e2e/a11y.spec.ts` و اسکریپت اجرا در CI.  
  پذیرش: عدم وجود critical violations در صفحه اصلی و Qualification.  
  **تاریخ اتمام:** 2026-06-15 — ۹ صفحه تست می‌شوند، شامل heading hierarchy، skip-link، lang/dir attrs، form labels.

- [x] `P2-3` **فرم دو مرحله‌ای Qualification** ✅  
  مالک: `FE + Product`  
  شرح: دو مرحله‌ای‌سازی فرم با ذخیره‌ی پیش‌نویس.  
  خروجی: فرم step1/step2 و رفتار بازگشت‌پذیر در خطای submit.  
  پذیرش: بهبود completion نسبت به baseline فعلی + تست e2e مسیر فرم.  
  **تاریخ اتمام:** 2026-06-15 — فرم شامل ۲ مرحله، draft saving با localStorage، progress bar ARIA.

## تسک‌های راهبردی باز از بک‌لاگ (P1/P2)
- [x] `STRAT-1` Freeze نقش/هدف هر دامنه + KPI اصلی + ۳ KPI پشتیبان. ✅
- [x] `STRAT-2` تعریف taxonomy مشترک eventها (`source`, `stage`, `intent`, `outcome`). ✅
- [x] `STRAT-3` تعریف acceptance criteria برای `qualified lead`. ✅
- [x] `STRAT-4` اجرای baseline فنی/UX/SEO (network readiness, metadata, link integrity) و گزارش `critical/high/medium`. ✅
- [x] `STRAT-5` حذف مسیرهای intent تکراری و dead-end در IA. ✅
- [x] `STRAT-6` استانداردسازی microcopy فرم/خطا/موفقیت و glossary اصطلاحات فنی فارسی. ✅
- [x] `STRAT-7` اجرای segment و consistency های SEO (canonical/hreflang/meta/schema) و بهینه‌سازی internal linking. ✅
- [x] `STRAT-8` Define SLO/availability budget + اعتبارسنجی incident rollback readiness. ✅

## بهبودهای فنی انجام شده (این جلسه - 2026-06-16)

### حاکمیت و مستندات
- [x] حاکمیت Design Token اجرا و freeze شد (P2-1)
- [x] Domain KPIs برای تمام دامنه‌ها تعریف شد (STRAT-1)
- [x] Event taxonomy مشترک تعریف شد (STRAT-2)
- [x] Lead qualification criteria تعریف شد (STRAT-3)
- [x] SLO و availability budget تعریف شد (STRAT-8)
- [x] Baseline گزارش کامل فنی/UX/SEO ایجاد شد (STRAT-4)

### مستندات جدید
- `docs/DOMAIN_KPIS.md` - KPIهای هر دامنه
- `docs/EVENT_TAXONOMY.md` - taxonomy مشترک eventها
- `docs/LEAD_QUALIFICATION_CRITERIA.md` - معیارهای qualified lead
- `docs/SLO_AVAILABILITY_BUDGET.md` - SLO و availability budget
- `docs/runtime/BASELINE_REPORT_2026-06-16.md` - گزارش baseline

### کیفیت کد
- [x] حذف `withLocale` تکراری → `locale-utils.ts` مشترک
- [x] `api-schemas.ts` مشترک برای Zod validation
- [x] حذف ۴۸ کامپوننت بی‌استفاده (۳۹ UI + ۹ section)
- [x] حذف ۳۳ پکیج بی‌استفاده (framer-motion, Radix unused, recharts, cmdk, ...)
- [x] `prisma` به devDependencies منتقل شد
- [x] `console.*` در service-worker با logger جایگزین شد

### SEO
- [x] متادیتای تمام ۱۲ صفحه دوزبانه شد
- [x] Schema.org تکراری حذف شد → single @graph
- [x] OG Image مabsolute شد
- [x] x-default hreflang اضافه شد
- [x] proficiencyLevel Expert شد
- [x] inLanguage پویا در schemas

### UI/UX
- [x] `scroll-padding-top` برای رفع overlap هدر
- [x] Redirect فرم تماس به `/thank-you`
- [x] خطای فرم تماس به کاربر نمایش داده می‌شود
- [x] RTL ArrowRight اصلاح شد
- [x] `loading.tsx` و `not-found.tsx` اضافه شد
- [x] progress bar ARIA attributes

### امنیت
- [x] `dangerouslyAllowSVG: false`
- [x] `.env.example` پاکسازی شده
- [x] Rate limiting روی تمام API endpoints

### عملکرد
- [x] حذف Turbopack (نابالغ)
- [x] حذف `tailwindcss-animate` plugin (tw-animate-css جایگزین)
- [x] CSS self-referencing variable حذف شد
- [x] Comment گمراه‌کننده اصلاح شد

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
