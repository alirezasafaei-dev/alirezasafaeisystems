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
    title: lang === 'fa' ? 'کیس استادی: سخت‌سازی حکمرانی CI/CD' : 'Case Study: CI/CD Governance Hardening',
    description:
      lang === 'fa'
        ? 'چگونه کیفیت انتشار و مالکیت از طریق دروازه‌های سیاست CI/CD قابل اجرا پایدار شد.'
        : 'How release quality and ownership were stabilized through enforceable CI/CD policy gates.',
    alternates: {
      canonical: `${siteUrl}/${lang}/case-studies/ci-cd-governance-hardening`,
    },
  }
}

export default async function CiCdGovernanceHardeningPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbCases: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    eyebrow: lang === 'en' ? 'Case Study' : 'مطالعه موردی',
    title: lang === 'en' ? 'CI/CD Governance Hardening' : 'سخت‌سازی حاکمیت CI/CD',
    intro:
      lang === 'en'
        ? 'Delivery quality was inconsistent due to manual exceptions and unclear ownership.'
        : 'کیفیت تحویل به خاطر استثناهای دستی و مالکیت نامشخص یکسان و قابل اتکا نبود.',
    hProblem: lang === 'en' ? 'Problem' : 'مسئله',
    pProblem:
      lang === 'en'
        ? 'Releases bypassed test gates, incident handoffs lacked structure, and postmortems were not actionable.'
        : 'انتشارها از گیت‌های تست عبور می‌کردند، handoff رخداد ساختار نداشت، و postmortemها به اقدام عملی تبدیل نمی‌شدند.',
    hSolution: lang === 'en' ? 'Solution' : 'راهکار',
    solutionItems:
      lang === 'en'
        ? [
            'Made lint, type-check, integration, smoke, and Lighthouse gates blocking',
            'Defined rollback drill cadence and release ownership model',
            'Standardized release report and incident evidence templates',
          ]
        : [
            'مسدودکننده کردن گیت‌های lint/type-check/integration/smoke/Lighthouse',
            'تعریف cadence تمرین rollback و مدل مالکیت انتشار',
            'استانداردسازی قالب گزارش انتشار و شواهد رخداد',
          ],
    hResult: lang === 'en' ? 'Result' : 'نتیجه',
    pResult:
      lang === 'en'
        ? 'No emergency rollback over 30 days and mean release lead-time reduced by 34%.'
        : 'صفر rollback اضطراری در ۳۰ روز و کاهش میانگین lead-time انتشار به میزان ۳۴٪.',
    hRole: lang === 'en' ? 'Role' : 'نقش',
    pRole:
      lang === 'en'
        ? 'Pipeline governance design, standards implementation, and release enablement.'
        : 'طراحی حاکمیت pipeline، پیاده‌سازی استانداردها، و توانمندسازی تیم برای release.',
    hStack: lang === 'en' ? 'Tech Stack' : 'تکنولوژی‌ها',
    pStack: 'GitHub Actions, Playwright, Lighthouse CI, Node.js, Nginx.',
    hProof: lang === 'en' ? 'Proof' : 'شواهد',
    pProof:
      lang === 'en'
        ? 'Release dashboard snapshots, CI pass/fail history, and drill evidence were shared in weekly governance reviews.'
        : 'اسنپ‌شات داشبورد انتشار، تاریخچه پاس/فیل CI، و شواهد drill در جلسات هفتگی حاکمیت ارائه شد.',
    hLessons: lang === 'en' ? 'Lessons & Tradeoffs' : 'درس‌ها و tradeoffها',
    pLessons:
      lang === 'en'
        ? 'Stricter gates slightly increased pre-release effort but removed far larger post-release firefighting costs.'
        : 'گیت‌های سخت‌گیرانه کمی هزینه قبل از انتشار را بالا برد اما هزینه‌های بسیار بزرگ‌تر بعد از انتشار را حذف کرد.',
    back: lang === 'en' ? 'Back to case studies' : 'بازگشت به مطالعات موردی',
  }

  const pageUrl = `${siteUrl}/${lang}/case-studies/ci-cd-governance-hardening`
  const projectSchema = generateProjectSchema({
    name: 'CI/CD Governance Hardening',
    description: 'Operational and governance hardening for high-stakes release pipelines.',
    url: lang === 'fa' ? '/case-studies/ci-cd-governance-hardening' : `/${lang}/case-studies/ci-cd-governance-hardening`,
    technologies: ['GitHub Actions', 'Playwright', 'Lighthouse CI', 'Nginx', 'Node.js'],
  })

  const articleSchema = generateArticleSchema({
    title: 'Case Study: CI/CD Governance Hardening',
    description: 'How release quality and ownership were stabilized through enforceable CI/CD policy gates.',
    publishDate: '2026-02-10',
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

      <article className="mx-auto max-w-4xl space-y-6">
        <header className="space-y-3 section-surface aurora-shell p-6 md:p-8">
          <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
          <h1 className="headline-tight text-3xl font-bold md:text-5xl">{copy.title}</h1>
          <p className="text-muted-foreground leading-8">{copy.intro}</p>
        </header>

        <section className="rounded-xl border bg-card p-6 space-y-2 card-hover">
          <h2 className="text-xl font-semibold">{copy.hProblem}</h2>
          <p className="text-sm text-muted-foreground">{copy.pProblem}</p>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-2 card-hover">
          <h2 className="text-xl font-semibold">{copy.hSolution}</h2>
          <ul className="list-disc ps-5 text-sm text-muted-foreground space-y-1">
            {copy.solutionItems.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-2 card-hover">
          <h2 className="text-xl font-semibold">{copy.hResult}</h2>
          <p className="text-sm text-muted-foreground">{copy.pResult}</p>
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          <div className="rounded-xl border bg-card p-6 space-y-2 card-hover">
            <h3 className="font-semibold">{copy.hRole}</h3>
            <p className="text-sm text-muted-foreground">{copy.pRole}</p>
          </div>
          <div className="rounded-xl border bg-card p-6 space-y-2 card-hover">
            <h3 className="font-semibold">{copy.hStack}</h3>
            <p className="text-sm text-muted-foreground">{copy.pStack}</p>
          </div>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-2 card-hover">
          <h2 className="text-xl font-semibold">{copy.hProof}</h2>
          <p className="text-sm text-muted-foreground">{copy.pProof}</p>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-2 card-hover">
          <h2 className="text-xl font-semibold">{copy.hLessons}</h2>
          <p className="text-sm text-muted-foreground">{copy.pLessons}</p>
        </section>

        <footer>
          <Link href={withLocale('/case-studies')} className="underline text-sm text-muted-foreground">{copy.back}</Link>
        </footer>
      </article>
    </main>
  )
}
