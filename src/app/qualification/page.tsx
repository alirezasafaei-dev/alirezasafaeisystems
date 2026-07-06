import type { Metadata } from 'next'
import Link from 'next/link'
import { InfrastructureLeadForm } from '@/components/sections/infrastructure-lead-form'
import { getSiteUrl } from '@/lib/site-config'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'
  const canonicalPath = lang === 'fa' ? '/qualification' : `/${lang}/qualification`
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
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
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
  const auditPrimaryTitle =
    lang === 'en' ? 'Start with ASDEV Audit (recommended)' : 'ابتدا ASDEV Audit (مسیر اصلی)'
  const auditPrimaryDesc =
    lang === 'en'
      ? 'Review the sample report or run a free assessment on your live URL before requesting custom work.'
      : 'قبل از درخواست کار اختصاصی، نمونه گزارش را ببینید یا ارزیابی رایگان روی آدرس سایت زنده انجام دهید.'
  const acceptedTitle = lang === 'en' ? 'What we accept' : 'چه درخواست‌هایی پذیرفته می‌شود'
  const notAcceptedTitle = lang === 'en' ? 'What we do not accept' : 'چه درخواست‌هایی پذیرفته نمی‌شود'
  const accepted =
    lang === 'en'
      ? [
          'Follow-up on ASDEV Audit findings',
          'Technical SEO review for a specific URL',
          'Performance or security review with defined scope',
          'Small fixed-scope implementation sprints',
        ]
      : [
          'پیگیری یافته‌های ASDEV Audit',
          'بررسی سئوی فنی برای URL مشخص',
          'بررسی عملکرد یا امنیت با دامنه محدود',
          'اسپرینت اجرای کوچک با اسکوپ ثابت',
        ]
  const notAccepted =
    lang === 'en'
      ? [
          'Open-ended builds without scope',
          'Bulk hiring applications (no active hiring)',
          'Ranking or revenue guarantees without contract',
          'Site work without a public URL',
        ]
      : [
          'پروژه‌های بدون اسکوپ مشخص',
          'درخواست‌های استخدام گروهی (استخدام فعال نداریم)',
          'تضمین رتبه یا درآمد بدون قرارداد',
          'کار روی سایت بدون URL عمومی',
        ]

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

        <div className="section-surface p-6 md:p-8 space-y-4">
          <h2 className="text-xl font-semibold">{auditPrimaryTitle}</h2>
          <p className="text-muted-foreground leading-7">{auditPrimaryDesc}</p>
          <div className="flex flex-wrap gap-3">
            <a
              href="https://audit.alirezasafaeisystems.ir/sample-report?utm_source=portfolio&utm_medium=qualification&utm_campaign=asdev_audit"
              className="inline-flex rounded-full border border-border/70 bg-card/70 px-4 py-2 text-sm font-medium hover:bg-card"
              target="_blank"
              rel="noopener noreferrer"
            >
              {lang === 'en' ? 'View sample report' : 'مشاهده نمونه گزارش'}
            </a>
            <a
              href="https://audit.alirezasafaeisystems.ir/audit?utm_source=portfolio&utm_medium=qualification&utm_campaign=asdev_audit"
              className="inline-flex rounded-full border border-border/70 bg-card/70 px-4 py-2 text-sm font-medium hover:bg-card"
              target="_blank"
              rel="noopener noreferrer"
            >
              {lang === 'en' ? 'Start free assessment' : 'شروع ارزیابی رایگان'}
            </a>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="section-surface p-5 space-y-3">
            <h3 className="font-semibold">{acceptedTitle}</h3>
            <ul className="list-disc ps-5 text-sm text-muted-foreground space-y-1">
              {accepted.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
          <div className="section-surface p-5 space-y-3">
            <h3 className="font-semibold">{notAcceptedTitle}</h3>
            <ul className="list-disc ps-5 text-sm text-muted-foreground space-y-1">
              {notAccepted.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
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
