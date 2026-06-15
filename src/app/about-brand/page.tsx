import type { Metadata } from 'next'
import Link from 'next/link'
import { brand } from '@/lib/brand'
import { getSiteUrl } from '@/lib/site-config'
import { Button } from '@/components/ui/button'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: lang === 'fa' ? `درباره ${brand.ownerName}` : `About ${brand.ownerName}`,
    description:
      lang === 'fa'
        ? `پروفایل ${brand.ownerName}، اصول مهندسی و مدل اجرایی.`
        : `${brand.ownerName} profile, engineering principles, and execution model.`,
    alternates: {
      canonical: `${siteUrl}/${lang}/about-brand`,
    },
  }
}

export default async function AboutBrandPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
  const copy = {
    eyebrow: lang === 'en' ? 'Engineering Profile' : 'پروفایل مهندسی',
    title: `${brand.ownerName}`,
    positioning: lang === 'en' ? brand.positioningEn : brand.positioningFa,
    missionTitle: lang === 'en' ? 'Mission' : 'ماموریت',
    missionBody:
      lang === 'en'
        ? 'Build real, resilient web systems end-to-end from architecture to production readiness, with measurable stability, before/after evidence, and clear release ownership — focused on infrastructure localization and operational resilience under real constraints.'
        : 'ساخت سیستم‌های وب واقعی و پایدار از صفر تا آمادگی تولید، با تمرکز بر بومی‌سازی زیرساخت، تاب‌آوری عملیاتی تحت محدودیت‌ها، و تحویل قابل اندازه‌گیری با شواهد قبل/بعد و مالکیت شفاف.',
    principlesTitle: lang === 'en' ? 'Operating Principles' : 'اصول اجرایی',
    principles: lang === 'en'
      ? [
          'Architecture decisions are documented and risk-aware before scale.',
          'Delivery quality is measured with clear gates and acceptance criteria.',
          'Persian UX quality is a core product requirement, not decoration.',
          'Production readiness means observability, ready rollback, and fast recovery are defined upfront.',
          'Business impact first: trust, speed, leads, and launch/handover confidence.',
        ]
      : [
          'تصمیم‌های معماری مستند، شفاف و مبتنی بر ریسک قبل از اجرا.',
          'کیفیت تحویل با گیت‌های کیفیت واقعی و معیارهای پذیرش روشن سنجیده می‌شود.',
          'تجربه کاربری فارسی یک الزام محصول است، نه تزئین.',
          'آمادگی تولید یعنی مشاهده‌پذیری کامل، rollback آماده، و بازیابی سریع از قبل تعریف شده.',
          'اولویت با تاثیر کسب‌وکار: اعتماد، سرعت، لید، و آمادگی لانچ یا تحویل.',
        ],
    workTitle: lang === 'en' ? 'Work With Me' : 'همکاری',
    workBody:
      lang === 'en'
        ? 'If you have a live site or app and need a precise technical review plus fast fixes for the highest-impact issues (trust, speed, leads, or launch readiness) in a fixed-scope sprint, start here.'
        : 'اگر سایت یا اپ فعالی دارید و نیاز به بررسی دقیق فنی + رفع سریع مهم‌ترین ایرادها (اعتماد، سرعت، لید یا لانچ) در اسپرینت ثابت دارید، از اینجا شروع کنید.',
    cta: lang === 'en' ? 'Get the one-page Audit + Quick Fix scope' : 'دریافت اسکوپ یک‌صفحه‌ای بررسی فنی + Quick Fix',
  }

  return (
    <main className="container mx-auto px-4 py-24 max-w-4xl space-y-10 subtle-grid">
      <header className="space-y-3 section-surface aurora-shell p-6 md:p-8">
        <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
        <h1 className="headline-tight text-3xl md:text-4xl font-bold">
          {copy.title}
        </h1>
        <p className="text-muted-foreground leading-8">{copy.positioning}</p>
      </header>

      <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
        <h2 className="text-2xl font-semibold">{copy.missionTitle}</h2>
        <p className="text-muted-foreground leading-8">{copy.missionBody}</p>
      </section>

      <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
        <h2 className="text-2xl font-semibold">{copy.principlesTitle}</h2>
        <ul className="list-disc pl-5 text-muted-foreground space-y-2">
          {copy.principles.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>

      <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
        <h2 className="text-2xl font-semibold">{copy.workTitle}</h2>
        <p className="text-muted-foreground leading-8">{copy.workBody}</p>
        <Button asChild className="shine-effect">
          <Link href="/offers/Audit-QuickFix-Offer-OnePage.pdf">
            {copy.cta}
          </Link>
        </Button>
        <p className="text-xs text-muted-foreground mt-2">یا <Link href={withLocale('/services/infrastructure-localization#assessment')} className="underline">ارزیابی ریسک زیرساخت</Link> را شروع کنید.</p>
      </section>
    </main>
  )
}
