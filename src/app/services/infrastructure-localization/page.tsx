import type { Metadata } from 'next'
import Link from 'next/link'
import { InfrastructureLeadForm } from '@/components/sections/infrastructure-lead-form'
import { getSiteUrl } from '@/lib/site-config'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: lang === 'fa'
      ? 'برنامه بومی‌سازی زیرساخت و تاب‌آوری عملیاتی'
      : 'Infrastructure Localization & Operational Resilience Program',
    description:
      lang === 'fa'
        ? 'برنامه مشاوره ۴ هفته‌ای برای ارزیابی ریسک زیرساخت، طراحی معماری مقاوم در برابر تحریم، سخت‌سازی حکمرانی و تحویل اجرایی.'
        : '4-week consulting program for infrastructure risk audit, sanction-resilient architecture design, governance hardening, and executive delivery.',
    alternates: {
      canonical: `${siteUrl}/${lang}/services/infrastructure-localization`,
    },
    openGraph: {
      title: lang === 'fa'
        ? 'برنامه بومی‌سازی زیرساخت و تاب‌آوری عملیاتی'
        : 'Infrastructure Localization & Operational Resilience Program',
      description:
        lang === 'fa'
          ? 'ارزیابی وابستگی‌ها، کاهش شکنندگی عملیاتی و ایجاد پایداری تولید با یک برنامه ساختاریافته ۴ هفته‌ای.'
          : 'Audit dependencies, reduce operational fragility, and build production stability with a structured 4-week program.',
      url: `${siteUrl}/${lang}/services/infrastructure-localization`,
      type: 'website',
    },
  }
}

function getWeeklyPlan(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      {
        title: 'Week 1 — Risk & Dependency Audit',
        items: ['External dependency mapping', 'Single point of failure identification', 'Deployment structure review'],
      },
      {
        title: 'Week 2 — Localization Architecture Design',
        items: ['Sanction-resilient architecture blueprint', 'Environment separation and failover design', 'Self-hosted alternatives mapping'],
      },
      {
        title: 'Week 3 — Governance & Automation',
        items: ['Release/deploy standardization', 'Manual-risk reduction', 'Policy and ownership framework'],
      },
      {
        title: 'Week 4 — Documentation & Executive Report',
        items: ['Executive-ready risk report', 'Final architecture diagrams', 'Implementation roadmap'],
      },
    ]
  }

  return [
    {
      title: 'هفته ۱: ممیزی ریسک و وابستگی‌ها',
      items: ['نقشه وابستگی‌های بیرونی', 'شناسایی SPOF', 'بررسی ساختار استقرار'],
    },
    {
      title: 'هفته ۲: طراحی معماری بومی‌سازی',
      items: ['بلوپرینت معماری مقاوم به محدودیت', 'جداسازی محیط‌ها و طراحی failover', 'نقشه جایگزین‌های self-hosted'],
    },
    {
      title: 'هفته ۳: حاکمیت و اتوماسیون',
      items: ['استانداردسازی release/deploy', 'کاهش ریسک دستی', 'چارچوب policy و ownership'],
    },
    {
      title: 'هفته ۴: مستندسازی و گزارش مدیریتی',
      items: ['گزارش ریسک آماده ارائه به مدیران', 'دیاگرام‌های نهایی معماری', 'نقشه راه پیاده‌سازی'],
    },
  ]
}

export default async function InfrastructureLocalizationServicePage() {
  const lang = await getRequestLanguage()
  const weeklyPlan = getWeeklyPlan(lang)
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
  const copy = {
    eyebrow: lang === 'en' ? 'Flagship Consulting Offer' : 'پیشنهاد اصلی',
    title: lang === 'en' ? 'Infrastructure Localization & Operational Resilience Program' : 'برنامه بومی‌سازی زیرساخت و تاب‌آوری عملیاتی',
    intro:
      lang === 'en'
        ? 'A 4-week program to reduce operational risk, remove fragile dependencies, and build real production stability.'
        : 'برنامه 4 هفته‌ای برای کاهش ریسک عملیاتی، حذف وابستگی‌های آسیب‌پذیر در برابر تحریم، و ایجاد پایداری واقعی در محیط production.',
    investment:
      lang === 'en'
        ? 'Investment range: 60–120M IRR (depending on scope and complexity)'
        : 'بازه سرمایه‌گذاری: 60 تا 120 میلیون تومان (بسته به دامنه و پیچیدگی)',
    deliverablesTitle: lang === 'en' ? 'Deliverables' : 'خروجی‌ها',
    deliverables:
      lang === 'en'
        ? ['Dependency Risk Map', 'Architecture Blueprint', 'Governance Policy Document', 'Disaster Recovery Plan', 'Executive Summary Report']
        : ['نقشه ریسک وابستگی‌ها', 'بلوپرینت معماری', 'سند policy حاکمیت', 'برنامه بازیابی (DR)', 'گزارش مدیریتی'],
    scopeNote:
      lang === 'en'
        ? 'Scope excludes feature development and daily support operations unless explicitly added by amendment.'
        : 'دامنه شامل توسعه فیچر و پشتیبانی روزانه نیست مگر اینکه به صورت صریح به قرارداد اضافه شود.',
    assessmentTitle: lang === 'en' ? 'Request Infrastructure Risk Assessment' : 'درخواست ارزیابی ریسک زیرساخت',
    assessmentDesc: lang === 'en' ? 'Fill the form below to schedule the initial review and discovery.' : 'فرم زیر را کامل کنید تا ارزیابی اولیه و جلسه Discovery برنامه‌ریزی شود.',
    backHome: lang === 'en' ? 'Back to home' : 'بازگشت به صفحه اصلی',
  }

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <div className="mx-auto max-w-5xl space-y-12">
        <section className="section-surface aurora-shell p-6 md:p-8 space-y-4">
          <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
          <h1 className="headline-tight text-3xl font-bold md:text-5xl">{copy.title}</h1>
          <p className="text-lg text-muted-foreground leading-8">{copy.intro}</p>
          <div className="rounded-lg border bg-muted/40 p-4 text-sm card-hover">
            {copy.investment}
          </div>
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          {weeklyPlan.map((week, index) => (
            <article key={week.title} className="rounded-xl border bg-card p-6 card-hover reveal-up" style={{ animationDelay: `${index * 80}ms` }}>
              <h2 className="text-xl font-semibold">{week.title}</h2>
              <ul className="mt-4 list-disc space-y-1 ps-5 text-sm text-muted-foreground">
                {week.items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </article>
          ))}
        </section>

        <section className="space-y-4 rounded-xl border bg-card p-6 card-hover">
          <h2 className="text-2xl font-semibold">{copy.deliverablesTitle}</h2>
          <ul className="list-disc space-y-1 ps-5 text-sm text-muted-foreground">
            {copy.deliverables.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
          <p className="text-sm text-muted-foreground">
            {copy.scopeNote}
          </p>
        </section>

        <section id="assessment" className="space-y-4 section-surface p-5 md:p-6">
          <h2 className="text-2xl font-semibold">{copy.assessmentTitle}</h2>
          <p className="text-sm text-muted-foreground">
            {copy.assessmentDesc}
          </p>
          <InfrastructureLeadForm />
        </section>

        <section className="text-sm text-muted-foreground">
          <Link className="underline" href={withLocale('/')}>
            {copy.backHome}
          </Link>
        </section>
      </div>
    </main>
  )
}
