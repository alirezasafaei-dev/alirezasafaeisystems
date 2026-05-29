import type { Metadata } from 'next'
import Link from 'next/link'
import { InfrastructureLeadForm } from '@/components/sections/infrastructure-lead-form'
import { getSiteUrl } from '@/lib/site-config'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'
  const canonicalPath = `/${lang}/qualification`
  return {
    title: isEn ? 'Request Review + Quick Fix' : 'درخواست بررسی + رفع سریع',
    description: isEn
      ? 'Send your live website and current issue to request a focused technical review and quick fix sprint.'
      : 'آدرس سایت و مشکل فعلی را بفرستید تا بررسی فنی متمرکز و اسپرینت رفع سریع شروع شود.',
    alternates: {
      canonical: canonicalPath,
      languages: {
        'fa-IR': `${siteUrl}/fa/qualification`,
        'en-US': `${siteUrl}/en/qualification`,
      },
    },
  }
}

export default async function QualificationPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => `/${lang}${path}`
  const title = lang === 'en' ? 'Request Technical Review + Quick Fix' : 'درخواست بررسی فنی + رفع سریع'
  const desc =
    lang === 'en'
      ? 'Send the live URL, the main visible issue, and your preferred contact channel. The first response focuses on whether a small paid sprint can create a useful result quickly.'
      : 'آدرس سایت زنده، مشکل اصلی و راه ارتباطی را بفرستید. پاسخ اولیه مشخص می‌کند آیا یک اسپرینت کوچک و پولی می‌تواند سریع نتیجه قابل استفاده بسازد یا نه.'
  const trust =
    lang === 'en'
      ? ['Fixed-scope starter', 'Initial response within one business day', 'Before/after evidence when fixes are delivered']
      : ['شروع با دامنه محدود', 'پاسخ اولیه حداکثر تا یک روز کاری', 'تحویل شواهد قبل/بعد در صورت اجرای رفع']
  const back = lang === 'en' ? 'Back to home' : 'بازگشت به خانه'

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <section className="mx-auto max-w-3xl space-y-5">
        <div className="section-surface aurora-shell p-6 md:p-8 space-y-4">
          <h1 className="headline-tight text-3xl font-bold md:text-5xl">{title}</h1>
          <p className="text-muted-foreground leading-8">{desc}</p>
          <div className="flex flex-wrap gap-2">
            {trust.map((item) => (
              <span key={item} className="rounded-full border border-border/70 bg-card/70 px-3 py-1 text-xs text-muted-foreground">
                {item}
              </span>
            ))}
          </div>
        </div>
        <InfrastructureLeadForm />
        <div className="text-sm text-muted-foreground">
          <Link href={withLocale('/')} className="underline">
            {back}
          </Link>
        </div>
      </section>
    </main>
  )
}
