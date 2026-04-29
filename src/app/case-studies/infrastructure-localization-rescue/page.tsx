import type { Metadata } from 'next'
import Link from 'next/link'
import { JsonLd } from '@/components/seo/json-ld'
import { getSiteUrl } from '@/lib/site-config'
import { generateArticleSchema, generateBreadcrumbSchema, generateProjectSchema } from '@/lib/seo'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: 'Case Study: Infrastructure Localization Rescue',
    description: 'How a high-risk deployment stack was stabilized with local-first architecture and governance gates.',
    alternates: {
      canonical: `${siteUrl}/${lang}/case-studies/infrastructure-localization-rescue`,
    },
  }
}

function getOutcomes(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      'Mean incident recovery time reduced from 180m to 55m',
      'Zero emergency rollback in the final 21-day window',
      'Executive delivery report accepted without rework',
    ]
  }
  return [
    'کاهش میانگین زمان بازیابی رخداد از ۱۸۰ دقیقه به ۵۵ دقیقه',
    'صفر rollback اضطراری در پنجره ۲۱ روزه پایانی',
    'پذیرش گزارش مدیریتی بدون نیاز به بازکاری',
  ]
}

export default async function InfrastructureLocalizationRescueCaseStudyPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => `/${lang}${path}`
  const outcomes = getOutcomes(lang)
  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbCases: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    eyebrow: lang === 'en' ? 'Case Study' : 'مطالعه موردی',
    title: lang === 'en' ? 'Infrastructure Localization Rescue' : 'نجات بومی‌سازی زیرساخت',
    context:
      lang === 'en'
        ? 'Context: sanctions exposure, fragile delivery flow, and limited operational observability.'
        : 'زمینه: ریسک تحریم، مسیر تحویل شکننده، و مشاهده‌پذیری محدود.',
    hProblem: lang === 'en' ? 'Problem' : 'مسئله',
    pProblem:
      lang === 'en'
        ? 'Core delivery depended on fragile external services and ad-hoc deployment decisions. Incidents escalated slowly due to weak observability and unclear rollback ownership.'
        : 'مسیر اصلی تحویل به سرویس‌های بیرونی شکننده و تصمیم‌های استقرار ad-hoc وابسته بود. رخدادها به دلیل مشاهده‌پذیری ضعیف و مالکیت نامشخص rollback دیر کنترل می‌شدند.',
    hSolution: lang === 'en' ? 'Solution' : 'راهکار',
    solutionItems:
      lang === 'en'
        ? [
            'Dependency risk map and blast-radius review',
            'Localization-first architecture with controlled fallback paths',
            'Release governance gates and handover checklist rollout',
          ]
        : [
            'نقشه ریسک وابستگی‌ها و بررسی blast radius',
            'معماری localization-first با مسیرهای fallback کنترل‌شده',
            'گیت‌های حاکمیت انتشار و rollout چک‌لیست تحویل/تحویل‌گیری',
          ],
    hOutcomes: lang === 'en' ? 'Measured Outcomes' : 'خروجی‌های قابل اندازه‌گیری',
    hRole: lang === 'en' ? 'Role' : 'نقش',
    pRole:
      lang === 'en'
        ? 'Infrastructure and release governance lead, responsible for risk prioritization, architecture redesign, and deployment guardrails.'
        : 'مسئول حاکمیت زیرساخت و انتشار: اولویت‌بندی ریسک، بازطراحی معماری، و گاردریل‌های استقرار.',
    hStack: lang === 'en' ? 'Tech Stack' : 'تکنولوژی‌ها',
    pStack: 'Next.js, TypeScript, Prisma, Nginx, PM2, Playwright, Lighthouse CI.',
    hProof: lang === 'en' ? 'Proof' : 'شواهد',
    pProof:
      lang === 'en'
        ? 'Weekly incident trend snapshots, release evidence logs, and governance checklist completion records were delivered to stakeholders.'
        : 'اسنپ‌شات‌های روند رخداد، لاگ‌های شواهد انتشار، و وضعیت تکمیل چک‌لیست حاکمیت به صورت هفتگی ارائه شد.',
    hLessons: lang === 'en' ? 'Lessons & Tradeoffs' : 'درس‌ها و tradeoffها',
    pLessons:
      lang === 'en'
        ? 'Local-first resilience required tighter operational discipline and more explicit ownership, but dramatically reduced outage exposure and release anxiety.'
        : 'تاب‌آوری local-first نیاز به نظم عملیاتی سخت‌گیرانه‌تر و مالکیت صریح‌تر داشت، اما ریسک قطعی و استرس انتشار را به شکل چشمگیر کاهش داد.',
    back: lang === 'en' ? 'Back to case studies' : 'بازگشت به مطالعات موردی',
  }

  const pageUrl = `${siteUrl}/${lang}/case-studies/infrastructure-localization-rescue`
  const projectSchema = generateProjectSchema({
    name: 'Infrastructure Localization Rescue',
    description: 'Stabilization of a high-risk deployment stack under localization constraints.',
    url: `/${lang}/case-studies/infrastructure-localization-rescue`,
    technologies: ['Next.js', 'TypeScript', 'Prisma', 'Nginx', 'PM2'],
  })
  const articleSchema = generateArticleSchema({
    title: 'Case Study: Infrastructure Localization Rescue',
    description: 'How a high-risk deployment stack was stabilized with local-first architecture and governance gates.',
    publishDate: '2026-02-14',
    modifiedDate: '2026-02-16',
    author: 'Alireza Safaei',
  })

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <JsonLd data={generateBreadcrumbSchema([
        { name: copy.breadcrumbHome, url: siteUrl },
        { name: copy.breadcrumbCases, url: `${siteUrl}/${lang}/case-studies` },
        { name: copy.title, url: pageUrl },
      ])} />
      <JsonLd data={projectSchema} />
      <JsonLd data={{ ...articleSchema, url: pageUrl }} />
      <article className="mx-auto max-w-4xl space-y-8">
        <header className="space-y-3 section-surface aurora-shell p-6 md:p-8">
          <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
          <h1 className="headline-tight text-3xl font-bold md:text-5xl">{copy.title}</h1>
          <p className="text-muted-foreground leading-8">{copy.context}</p>
        </header>

        <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
          <h2 className="text-xl font-semibold">{copy.hProblem}</h2>
          <p className="text-sm text-muted-foreground">{copy.pProblem}</p>
        </section>

        <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
          <h2 className="text-xl font-semibold">{copy.hSolution}</h2>
          <ul className="list-disc space-y-1 ps-5 text-sm text-muted-foreground">
            {copy.solutionItems.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>

        <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
          <h2 className="text-xl font-semibold">{copy.hOutcomes}</h2>
          <ul className="list-disc space-y-1 ps-5 text-sm text-muted-foreground">
            {outcomes.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          <div className="space-y-3 rounded-xl border bg-card p-6 card-hover">
            <h2 className="text-xl font-semibold">{copy.hRole}</h2>
            <p className="text-sm text-muted-foreground">{copy.pRole}</p>
          </div>
          <div className="space-y-3 rounded-xl border bg-card p-6 card-hover">
            <h2 className="text-xl font-semibold">{copy.hStack}</h2>
            <p className="text-sm text-muted-foreground">{copy.pStack}</p>
          </div>
        </section>

        <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
          <h2 className="text-xl font-semibold">{copy.hProof}</h2>
          <p className="text-sm text-muted-foreground">{copy.pProof}</p>
        </section>

        <section className="space-y-3 rounded-xl border bg-card p-6 card-hover">
          <h2 className="text-xl font-semibold">{copy.hLessons}</h2>
          <p className="text-sm text-muted-foreground">{copy.pLessons}</p>
        </section>

        <footer className="text-sm text-muted-foreground">
          <Link href={withLocale('/case-studies')} className="underline">
            {copy.back}
          </Link>
        </footer>
      </article>
    </main>
  )
}
