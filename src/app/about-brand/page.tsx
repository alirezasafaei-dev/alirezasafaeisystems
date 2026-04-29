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
    title: `About ${brand.ownerName}`,
    description: `${brand.ownerName} profile, engineering principles, and execution model.`,
    alternates: {
      canonical: `${siteUrl}/${lang}/about-brand`,
    },
  }
}

export default async function AboutBrandPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => `/${lang}${path}`
  const copy = {
    eyebrow: lang === 'en' ? 'Engineering Profile' : 'پروفایل مهندسی',
    title: `${brand.ownerName}`,
    positioning: lang === 'en' ? brand.positioningEn : brand.positioningFa,
    missionTitle: lang === 'en' ? 'Mission' : 'ماموریت',
    missionBody:
      lang === 'en'
        ? 'Build web systems end-to-end, from architecture to production readiness, with measurable stability and clear release ownership.'
        : 'ساخت سیستم‌های وب از صفر تا آمادگی تولید، با پایداری قابل اندازه‌گیری و مالکیت شفاف انتشار.',
    principlesTitle: lang === 'en' ? 'Operating Principles' : 'اصول اجرایی',
    principles: lang === 'en'
      ? [
          'Architecture decisions are documented before scale work starts.',
          'Delivery quality is tracked with clear acceptance criteria.',
          'Persian UX quality is treated as a product requirement, not decoration.',
          'Production readiness means observability, rollback, and recovery are defined.',
        ]
      : [
          'تصمیم‌های معماری قبل از توسعه مقیاس ثبت و شفاف می‌شوند.',
          'کیفیت تحویل با معیار پذیرش روشن سنجیده می‌شود.',
          'کیفیت تجربه کاربری فارسی یک الزام محصول است، نه تزئین.',
          'آمادگی تولید یعنی مشاهده‌پذیری، Rollback و بازیابی از قبل تعریف شده باشد.',
        ],
    workTitle: lang === 'en' ? 'Work With Me' : 'همکاری',
    workBody:
      lang === 'en'
        ? 'If you need software architecture, idea-to-product execution, or project rescue to production, start with the assessment flow.'
        : 'اگر برای معماری نرم‌افزار، تبدیل ایده به محصول، یا نجات پروژه تا رسیدن به تولید نیاز به همکاری دارید، از مسیر ارزیابی شروع کنید.',
    cta: lang === 'en' ? 'Request Infrastructure Risk Assessment' : 'درخواست ارزیابی ریسک زیرساخت',
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
          <Link href={withLocale('/services/infrastructure-localization#assessment')}>
            {copy.cta}
          </Link>
        </Button>
      </section>
    </main>
  )
}
