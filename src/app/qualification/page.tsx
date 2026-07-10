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
    title: isEn ? 'Request ASDEV Audit Assessment' : 'درخواست ارزیابی ASDEV Audit',
    description: isEn
      ? 'Send your live website and current issue to request a scoped ASDEV Audit assessment.'
      : 'آدرس سایت و مشکل فعلی را بفرستید تا درخواست ارزیابی ASDEV Audit ثبت شود.',
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
  const title = lang === 'en' ? 'Request ASDEV Audit Assessment' : 'درخواست ارزیابی ASDEV Audit'
  const desc =
    lang === 'en'
      ? 'Send the live URL, the main visible issue, and your preferred contact channel. The first response qualifies whether Entry Audit, Full Technical Audit, Audit + Implementation, or Monthly Monitoring fits.'
      : 'آدرس سایت زنده، مشکل اصلی و راه ارتباطی را بفرستید. پاسخ اولیه مشخص می‌کند Entry Audit، Full Technical Audit، Audit + Implementation یا Monthly Monitoring مناسب است یا نه.'
  const trust =
    lang === 'en'
      ? ['Scoped Audit offer', 'Initial response within one business day', 'No public pricing before owner approval']
      : ['پیشنهاد Audit با دامنه مشخص', 'پاسخ اولیه حداکثر تا یک روز کاری', 'بدون قیمت عمومی تا تأیید مالک']
  const back = lang === 'en' ? 'Back to home' : 'بازگشت به خانه'
  const auditPrimaryTitle =
    lang === 'en' ? 'Start with ASDEV Audit (recommended)' : 'ابتدا ASDEV Audit (مسیر اصلی)'
  const auditPrimaryDesc =
    lang === 'en'
      ? 'Review the sample report, then submit one request assessment path with attribution.'
      : 'نمونه گزارش را ببینید، سپس از یک مسیر واحد درخواست ارزیابی ثبت کنید.'
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
              href="https://audit.alirezasafaeisystems.ir/sample-report?source=portfolio&placement=qualification&offer=sample_report"
              className="inline-flex rounded-full border border-border/70 bg-card/70 px-4 py-2 text-sm font-medium hover:bg-card"
              target="_blank"
              rel="noopener noreferrer"
            >
              {lang === 'en' ? 'View sample report' : 'مشاهده نمونه گزارش'}
            </a>
            <a
              href="https://audit.alirezasafaeisystems.ir/qualification?source=portfolio&placement=qualification&offer=request_assessment"
              className="inline-flex rounded-full border border-border/70 bg-card/70 px-4 py-2 text-sm font-medium hover:bg-card"
              target="_blank"
              rel="noopener noreferrer"
            >
              {lang === 'en' ? 'Request assessment' : 'درخواست ارزیابی'}
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
