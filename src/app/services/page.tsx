import type { Metadata } from 'next'
import Link from 'next/link'
import { JsonLd } from '@/components/seo/json-ld'
import { getSiteUrl } from '@/lib/site-config'
import { generateBreadcrumbSchema } from '@/lib/seo'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: 'Services',
    description: 'Practical engineering services for software architecture, production readiness, project rescue, and stable local-first operations.',
    alternates: { canonical: `${siteUrl}/${lang}/services` },
  }
}

function getOffers(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      {
        title: 'Technical Review + Quick Fix Sprint',
        summary: 'Focused diagnosis plus agreed fixes for live websites and web systems.',
        deliverable: 'Priority review + quick-fix sprint + before/after evidence',
        href: '/services/quick-fix-sprint',
      },
      {
        title: 'Infrastructure Localization Blueprint',
        summary: 'Design a sanction-resilient, local-first runtime architecture.',
        deliverable: 'Architecture blueprint + dependency replacement map',
      },
      {
        title: 'CI/CD Governance Hardening',
        summary: 'Enforce quality gates and release ownership discipline.',
        deliverable: 'Blocking pipeline policy + release checklist standard',
      },
      {
        title: 'Project Rescue to Production',
        summary: 'Stabilize incomplete or failing projects and ship safely.',
        deliverable: 'Rescue roadmap + production readiness baseline',
      },
      {
        title: 'Operational Observability Setup',
        summary: 'Create incident visibility and measurable runtime telemetry.',
        deliverable: 'Core observability dashboard + alerting policy',
      },
      {
        title: 'Executive Delivery Reporting',
        summary: 'Translate technical progress into decision-ready reporting.',
        deliverable: 'Weekly executive report template + evidence pack',
      },
    ]
  }

  return [
    {
      title: 'بررسی فنی + اسپرینت رفع سریع',
      summary: 'تشخیص متمرکز + رفع موارد توافق‌شده برای سایت‌ها و سیستم‌های زنده.',
      deliverable: 'بررسی اولویت‌دار + اسپرینت رفع سریع + شواهد قبل/بعد',
      href: '/services/quick-fix-sprint',
    },
    {
      title: 'بلوپرینت بومی‌سازی زیرساخت',
      summary: 'طراحی معماری local-first و مقاوم به محدودیت و تحریم.',
      deliverable: 'نقشه معماری + نقشه جایگزینی وابستگی‌ها',
    },
    {
      title: 'سخت‌سازی حاکمیت CI/CD',
      summary: 'اجرای quality gate و نظم مالکیت release و deploy.',
      deliverable: 'Policy مسدودکننده pipeline + چک‌لیست استاندارد انتشار',
    },
    {
      title: 'نجات پروژه تا رسیدن به تولید',
      summary: 'پایدارسازی پروژه‌های نیمه‌تمام/شکست‌خورده و تحویل امن.',
      deliverable: 'نقشه نجات + baseline آمادگی تولید',
    },
    {
      title: 'راه‌اندازی مشاهده‌پذیری عملیاتی',
      summary: 'ساخت دید رخداد و تله‌متری قابل اندازه‌گیری برای عملیات.',
      deliverable: 'داشبورد هسته‌ای + policy هشدار',
    },
    {
      title: 'گزارش‌دهی مدیریتی تحویل',
      summary: 'ترجمه پیشرفت فنی به گزارش تصمیم‌پذیر برای مدیران.',
      deliverable: 'قالب گزارش هفتگی + بسته شواهد تحویل',
    },
  ]
}

export default async function ServicesPage() {
  const lang = await getRequestLanguage()
  const offers = getOffers(lang)
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)

  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbServices: lang === 'en' ? 'Services' : 'خدمات',
    eyebrow: lang === 'en' ? 'AliReza Safaei | Web Systems Engineering' : 'علیرضا صفایی | مهندسی سیستم‌های وب',
    title: lang === 'en' ? 'Services' : 'خدمات',
    desc:
      lang === 'en'
        ? 'Execution-focused services for software architecture, system design, delivery quality, and production stability.'
        : 'خدمات اجرایی برای معماری نرم‌افزار، طراحی سیستم، بهبود کیفیت تحویل، پایداری واقعی در تولید، و مقابله عملی با تحریم‌های خارجی علیه ایران.',
    deliverableLabel: lang === 'en' ? 'Deliverable:' : 'خروجی قابل تحویل:',
    cta: lang === 'en' ? 'Start Qualification' : 'شروع ارزیابی و Qualification',
    proofLinePrefix: lang === 'en' ? 'Need proof first? Review ' : 'اگر اول شواهد می‌خواهید: ',
    proofLink: lang === 'en' ? 'case studies' : 'مطالعات موردی',
    proofLineSuffix: lang === 'en' ? ' and then submit qualification.' : ' را ببینید و سپس فرم را ارسال کنید.',
  }

  const faqSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: [
      {
        '@type': 'Question',
        name: lang === 'en' ? 'How fast can we start?' : 'چقدر سریع می‌توانیم شروع کنیم؟',
        acceptedAnswer: {
          '@type': 'Answer',
          text:
            lang === 'en'
              ? 'Qualification usually starts within 24-72 hours after form submission.'
              : 'معمولا ظرف ۲۴ تا ۷۲ ساعت بعد از ارسال فرم، مرحله ارزیابی شروع می‌شود.',
        },
      },
      {
        '@type': 'Question',
        name: lang === 'en' ? 'What engagement model do you use?' : 'مدل همکاری چگونه است؟',
        acceptedAnswer: {
          '@type': 'Answer',
          text:
            lang === 'en'
              ? 'Fixed-scope milestones with explicit deliverables and evidence-based reporting.'
              : 'مایلستون‌های محدوده‌دار با خروجی‌های شفاف و گزارش‌دهی مبتنی بر شواهد.',
        },
      },
      {
        '@type': 'Question',
        name: lang === 'en' ? 'Do you support local-first deployment constraints?' : 'آیا محدودیت‌های local-first را پوشش می‌دهید؟',
        acceptedAnswer: {
          '@type': 'Answer',
          text:
            lang === 'en'
              ? 'Yes. Delivery prioritizes local-first runtime, reduced external dependencies, and resilient operations.'
              : 'بله. اولویت با runtime local-first، کاهش وابستگی‌های خارجی، و عملیات resilient است.',
        },
      },
    ],
  }

  return (
    <main className="container mx-auto px-4 py-28">
      <JsonLd data={generateBreadcrumbSchema([
        { name: copy.breadcrumbHome, url: siteUrl },
        { name: copy.breadcrumbServices, url: `${siteUrl}/${lang}/services` },
      ])} />
      <JsonLd data={faqSchema} />

      <section className="mx-auto max-w-5xl space-y-8">
        <header className="space-y-3">
          <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
          <h1 className="text-3xl font-bold md:text-5xl">{copy.title}</h1>
          <p className="text-muted-foreground">{copy.desc}</p>
        </header>

        <div className="grid gap-4 md:grid-cols-2">
          {offers.map((offer) => (
            <article key={offer.title} className="rounded-xl border bg-card p-6 space-y-3">
              <h2 className="text-xl font-semibold">{offer.title}</h2>
              <p className="text-sm text-muted-foreground">{offer.summary}</p>
              <div className="rounded-md bg-muted/50 p-3 text-sm">
                <span className="font-medium">{copy.deliverableLabel}</span> {offer.deliverable}
              </div>
              {offer.href ? (
                <Link href={withLocale(offer.href)} className="inline-flex text-sm font-medium text-primary underline">
                  {lang === 'en' ? 'View focused offer' : 'مشاهده پیشنهاد متمرکز'}
                </Link>
              ) : null}
            </article>
          ))}
        </div>

        <div className="space-y-3">
          <Link href={withLocale('/qualification')} className="inline-flex rounded-md bg-primary px-4 py-2 text-primary-foreground">
            {copy.cta}
          </Link>
          <p className="text-sm text-muted-foreground">
            {copy.proofLinePrefix}
            <Link href={withLocale('/case-studies')} className="underline">{copy.proofLink}</Link>
            {copy.proofLineSuffix}
          </p>
        </div>
      </section>
    </main>
  )
}
