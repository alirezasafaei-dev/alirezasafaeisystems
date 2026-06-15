import type { Metadata } from 'next'
import Link from 'next/link'
import { JsonLd } from '@/components/seo/json-ld'
import { getRequestLanguage } from '@/lib/i18n/server'
import { getSiteUrl } from '@/lib/site-config'
import { brand } from '@/lib/brand'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'

  return {
    title: isEn ? 'Technical Review + Quick Fix Sprint' : 'بررسی فنی + اسپرینت رفع سریع',
    description: isEn
      ? 'A focused technical review and quick fix sprint for Iranian businesses that need visible production improvements without a long project.'
      : 'بررسی فنی متمرکز و اسپرینت رفع سریع برای کسب‌وکارهایی که بدون پروژه طولانی، به بهبود قابل مشاهده در سایت یا سیستم نیاز دارند.',
    alternates: {
      canonical: `${siteUrl}/${lang}/services/quick-fix-sprint`,
      languages: {
        'fa-IR': `${siteUrl}/fa/services/quick-fix-sprint`,
        'en-US': `${siteUrl}/en/services/quick-fix-sprint`,
      },
    },
  }
}

export default async function QuickFixSprintPage() {
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)

  const copy = {
    eyebrow: isEn ? 'Fast revenue-safe technical help' : 'کمک فنی سریع و درآمدمحور',
    title: isEn ? 'Technical Review + Quick Fix Sprint' : 'بررسی فنی + اسپرینت رفع سریع',
    subtitle: isEn
      ? 'For teams that have a live website, store, or web system and need a practical diagnosis plus fixes that reduce visible friction in days, not months.'
      : 'برای تیم‌هایی که سایت، فروشگاه یا سیستم وب فعال دارند و به تشخیص عملی + رفع مشکلات قابل مشاهده در چند روز نیاز دارند، نه یک پروژه چندماهه.',
    primaryCta: isEn ? 'Request Sprint Review' : 'درخواست بررسی اسپرینت',
    secondaryCta: isEn ? 'See Proof' : 'مشاهده شواهد',
    bestForTitle: isEn ? 'Best first clients' : 'بهترین مشتری‌های شروع',
    bestFor: isEn
      ? [
          'Service businesses with a live website but weak lead conversion',
          'Small stores or content businesses losing trust because of slow or broken pages',
          'Teams that already paid for development but still have launch or stability issues',
        ]
      : [
          'کسب‌وکارهای خدماتی که سایت فعال دارند اما ورودی/اعتماد کافی نمی‌گیرند',
          'فروشگاه‌ها یا رسانه‌های کوچک که کندی، خطا یا ظاهر نامطمئن به فروششان آسیب می‌زند',
          'تیم‌هایی که قبلاً هزینه توسعه داده‌اند اما هنوز مشکل لانچ، پایداری یا اعتماد دارند',
        ],
    includedTitle: isEn ? 'What is included' : 'چه چیزی شامل می‌شود',
    included: isEn
      ? [
          'Technical review of one live website or focused web flow',
          'Priority list of revenue-impacting issues',
          'Up to one focused quick-fix sprint for agreed high-impact items',
          'Before/after evidence and a short owner-friendly handoff',
        ]
      : [
          'بررسی فنی یک سایت زنده یا یک مسیر مهم کاربر',
          'لیست اولویت‌دار مشکلاتی که روی فروش، اعتماد یا عملیات اثر دارند',
          'یک اسپرینت محدود برای رفع موارد پراثر و توافق‌شده',
          'شواهد قبل/بعد و تحویل کوتاه قابل فهم برای مالک کسب‌وکار',
        ],
    notIncludedTitle: isEn ? 'What is not included' : 'چه چیزی شامل نمی‌شود',
    notIncluded: isEn
      ? [
          'Full redesign or rebrand',
          'Building a new SaaS, dashboard, or portal',
          'Unlimited bug fixing or open-ended maintenance',
          'Large migrations without separate scoping',
        ]
      : [
          'طراحی کامل یا برندینگ مجدد',
          'ساخت SaaS، داشبورد یا پنل جدید',
          'رفع باگ نامحدود یا نگهداری باز',
          'مهاجرت‌های بزرگ بدون اسکوپ جداگانه',
        ],
    processTitle: isEn ? 'Simple delivery flow' : 'فرآیند ساده تحویل',
    process: isEn
      ? [
          ['1', 'Intake', 'You send the live URL, current pain, and access boundaries.'],
          ['2', 'Review', 'I inspect the critical flow and identify high-leverage fixes.'],
          ['3', 'Fix', 'We execute the agreed quick fixes without expanding scope.'],
          ['4', 'Handoff', 'You receive evidence, notes, and next-step recommendations.'],
        ]
      : [
          ['۱', 'ورودی', 'آدرس سایت، مسئله فعلی و سطح دسترسی قابل ارائه مشخص می‌شود.'],
          ['۲', 'بررسی', 'مسیر مهم کاربر و ریسک‌های پراثر بررسی می‌شود.'],
          ['۳', 'رفع سریع', 'موارد توافق‌شده بدون بزرگ‌کردن دامنه اجرا می‌شود.'],
          ['۴', 'تحویل', 'شواهد، توضیح کوتاه و پیشنهاد قدم بعدی تحویل می‌شود.'],
        ],
    pricingTitle: isEn ? 'Initial pricing posture' : 'مدل قیمت‌گذاری شروع',
    pricing: isEn
      ? 'Fixed-scope, low-friction entry. Final price depends on access, stack, and fix depth after a short discovery.'
      : 'پکیج محدود و کم‌ریسک برای شروع. قیمت نهایی بعد از یک بررسی کوتاه، بر اساس سطح دسترسی، استک و عمق رفع مشخص می‌شود.',
    proofTitle: isEn ? 'Minimum proof available now' : 'حداقل شواهد آماده فعلی',
    proof: isEn
      ? [
          'Three live production assets under current operation',
          'Case studies for infrastructure, platform, and delivery hardening',
          'Direct Telegram, phone, and email contact channels',
        ]
      : [
          'سه دارایی زنده در production',
          'مطالعات موردی درباره زیرساخت، پلتفرم و سخت‌سازی تحویل',
          'مسیر ارتباط مستقیم از تلگرام، تلفن و ایمیل',
        ],
    fitTitle: isEn ? 'This is a fit if' : 'این پیشنهاد مناسب است اگر',
    fit: isEn
      ? [
          'You already have something live',
          'You want useful fixes before a big rebuild',
          'You can provide limited access or coordinate with your developer',
        ]
      : [
          'همین حالا سایت یا سیستم زنده دارید',
          'قبل از بازطراحی یا پروژه بزرگ، رفع عملی و سریع می‌خواهید',
          'می‌توانید دسترسی محدود بدهید یا با توسعه‌دهنده فعلی هماهنگ کنید',
        ],
  }

  const serviceSchema = {
    '@context': 'https://schema.org',
    '@type': 'Service',
    name: copy.title,
    provider: {
      '@type': 'Person',
      name: brand.ownerName,
      url: siteUrl,
    },
    areaServed: 'IR',
    serviceType: isEn
      ? 'Technical review and quick fix sprint'
      : 'بررسی فنی و اسپرینت رفع سریع',
    offers: {
      '@type': 'Offer',
      priceCurrency: 'IRR',
      availability: 'https://schema.org/InStock',
    },
  }

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <JsonLd data={serviceSchema} />

      <section className="mx-auto max-w-5xl space-y-8">
        <header className="section-surface aurora-shell p-6 md:p-8 space-y-5">
          <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
          <div className="space-y-4">
            <h1 className="headline-tight text-3xl font-bold md:text-5xl">{copy.title}</h1>
            <p className="max-w-3xl text-muted-foreground leading-8">{copy.subtitle}</p>
          </div>
          <div className="flex flex-col gap-3 sm:flex-row">
            <Link href={withLocale('/qualification')} className="inline-flex rounded-md bg-primary px-4 py-2 text-primary-foreground">
              {copy.primaryCta}
            </Link>
            <Link href={withLocale('/case-studies')} className="inline-flex rounded-md border px-4 py-2">
              {copy.secondaryCta}
            </Link>
          </div>
        </header>

        <div className="grid gap-4 md:grid-cols-3">
          <section className="rounded-xl border bg-card p-5 space-y-3">
            <h2 className="text-xl font-semibold">{copy.bestForTitle}</h2>
            <ul className="space-y-2 text-sm text-muted-foreground">
              {copy.bestFor.map((item) => <li key={item}>• {item}</li>)}
            </ul>
          </section>
          <section className="rounded-xl border bg-card p-5 space-y-3">
            <h2 className="text-xl font-semibold">{copy.fitTitle}</h2>
            <ul className="space-y-2 text-sm text-muted-foreground">
              {copy.fit.map((item) => <li key={item}>• {item}</li>)}
            </ul>
          </section>
          <section className="rounded-xl border bg-primary/5 p-5 space-y-3">
            <h2 className="text-xl font-semibold">{copy.pricingTitle}</h2>
            <p className="text-sm text-muted-foreground leading-7">{copy.pricing}</p>
          </section>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <section className="rounded-xl border bg-card p-6 space-y-3">
            <h2 className="text-xl font-semibold">{copy.includedTitle}</h2>
            <ul className="space-y-2 text-sm text-muted-foreground">
              {copy.included.map((item) => <li key={item}>✓ {item}</li>)}
            </ul>
          </section>
          <section className="rounded-xl border bg-card p-6 space-y-3">
            <h2 className="text-xl font-semibold">{copy.notIncludedTitle}</h2>
            <ul className="space-y-2 text-sm text-muted-foreground">
              {copy.notIncluded.map((item) => <li key={item}>× {item}</li>)}
            </ul>
          </section>
        </div>

        <section className="rounded-xl border bg-card p-6 space-y-4">
          <h2 className="text-xl font-semibold">{copy.processTitle}</h2>
          <div className="grid gap-3 md:grid-cols-4">
            {copy.process.map(([number, title, detail]) => (
              <article key={number} className="rounded-lg border border-border/70 bg-background/60 p-4">
                <p className="mb-3 inline-flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm text-primary-foreground">
                  {number}
                </p>
                <h3 className="font-semibold">{title}</h3>
                <p className="mt-2 text-sm text-muted-foreground leading-6">{detail}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-3">
          <h2 className="text-xl font-semibold">{copy.proofTitle}</h2>
          <ul className="grid gap-2 text-sm text-muted-foreground md:grid-cols-3">
            {copy.proof.map((item) => <li key={item}>• {item}</li>)}
          </ul>
          <div className="pt-2 text-sm">
            <a href="/offers/Audit-QuickFix-Offer-OnePage.pdf" className="underline hover:no-underline" target="_blank" rel="noopener">
              {isEn ? 'Download one-page scope (PDF)' : 'دانلود اسکوپ یک‌صفحه‌ای (PDF)'}
            </a>
            {' · '}
            <a href="/offers/Sample-Audit-Report-Anonymized.pdf" className="underline hover:no-underline" target="_blank" rel="noopener">
              {isEn ? 'Download sample anonymized report (PDF)' : 'دانلود نمونه گزارش anonymized (PDF)'}
            </a>
          </div>
        </section>

        <section className="rounded-xl border border-primary/20 bg-primary/5 p-6 md:flex md:items-center md:justify-between md:gap-6">
          <div className="space-y-2">
            <h2 className="text-xl font-semibold">{copy.primaryCta}</h2>
            <p className="text-sm text-muted-foreground">
              {isEn ? 'Send the URL and the current pain. Scope stays small until paid validation.' : 'آدرس سایت و مسئله فعلی را بفرستید. دامنه کار تا قبل از اعتبارسنجی پولی کوچک می‌ماند.'}
            </p>
          </div>
          <Link href={withLocale('/qualification')} className="mt-4 inline-flex rounded-md bg-primary px-4 py-2 text-primary-foreground md:mt-0">
            {copy.primaryCta}
          </Link>
        </section>
      </section>
    </main>
  )
}
