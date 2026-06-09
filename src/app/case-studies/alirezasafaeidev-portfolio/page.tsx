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
    title: 'Case Study: alirezasafaeisystems.ir Portfolio System',
    description:
      'How this portfolio was engineered as a production-grade lead acquisition system with strict QA gates and local-first deployment constraints.',
    alternates: { canonical: `${siteUrl}/${lang}/case-studies/alirezasafaeidev-portfolio` },
  }
}

export default async function PortfolioCaseStudyPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbCases: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    eyebrow: lang === 'en' ? 'Case Study' : 'مطالعه موردی',
    title: 'alirezasafaeisystems.ir Portfolio System',
    intro:
      lang === 'en'
        ? 'This site was built as an engineering proof: not just a skills page, but a visitor→lead conversion system with measurable quality.'
        : 'این سایت به عنوان یک نمونه‌کار مهندسی ساخته شد که هدفش صرفا نمایش مهارت نباشد؛ بلکه Visitor را به Lead تبدیل کند و کیفیت تحویل را اثبات کند.',
    hProblem: lang === 'en' ? 'Problem' : 'مسئله',
    pProblem:
      lang === 'en'
        ? 'Typical portfolios lack conversion: unclear positioning, shallow proof, weak CTA, and no reliable lead capture or follow-up path.'
        : 'پورتفولیوهای معمولی مسیر تبدیل ندارند: پیام مبهم، نمونه‌کار ناقص، CTA نامشخص، و هیچ سیستمی برای ثبت و پیگیری Lead وجود ندارد.',
    hSolution: lang === 'en' ? 'Solution' : 'راهکار',
    solutionItems:
      lang === 'en'
        ? [
            'Simple IA: Home → Services → Case Studies → Qualification Form → Thank You',
            'Production-grade lead capture: validation, honeypot, rate limit, DB storage, admin dashboard',
            'Baseline SEO: metadata/OG/sitemap/robots/schema (Person/Org/WebSite/Article/FAQ)',
            'Quality gates: lint/type/unit/integration/e2e-smoke/Lighthouse CI/secret scan',
            'Local-first readiness for VPS and restricted internet environments',
          ]
        : [
            'IA ساده: Home → Services → Case Studies → Qualification Form → Thank You',
            'Lead capture production-grade: validation، honeypot، rate limit، ذخیره در DB، و ادمین پنل',
            'SEO پایه: metadata/OG/sitemap/robots/schema (Person/Org/WebSite/Article/FAQ)',
            'Quality gates: lint/type/unit/integration/e2e smoke/Lighthouse CI/secret scan',
            'Local-first readiness برای VPS و محدودیت اینترنت ایران',
          ],
    hResult: lang === 'en' ? 'Result' : 'نتیجه',
    pResult:
      lang === 'en'
        ? 'A reliable acquisition system for qualifying projects, backed by evidence-driven case studies, and deployable on VPS without runtime external dependencies.'
        : 'یک سیستم قابل اتکا برای جذب و qualify کردن پروژه‌ها با شواهد اجرایی (case studies)، و آماده برای استقرار روی VPS بدون وابستگی runtime خارجی.',
    hRole: lang === 'en' ? 'Role' : 'نقش',
    pRole:
      lang === 'en'
        ? 'End-to-end: product copy, system design, security baseline, QA automation, and deployment readiness.'
        : 'End-to-end: product copy, system design, security baseline, QA automation, and deployment readiness.',
    hProof: lang === 'en' ? 'Proof' : 'شواهد',
    pProof:
      lang === 'en'
        ? 'Admin dashboards for Leads/Messages, health endpoint, and a full quality gate that runs before deployment.'
        : 'ادمین پنل برای Lead/Messages، health endpoint، و گیت کیفیت سراسری قبل از deploy.',
    back: lang === 'en' ? 'Back to case studies' : 'بازگشت به مطالعات موردی',
  }

  const pageUrl = `${siteUrl}/${lang}/case-studies/alirezasafaeidev-portfolio`

  const projectSchema = generateProjectSchema({
    name: 'alirezasafaeisystems.ir Portfolio System',
    description: 'A portfolio that functions as a measurable visitor-to-lead conversion system with production readiness.',
    url: lang === 'fa' ? '/case-studies/alirezasafaeidev-portfolio' : `/${lang}/case-studies/alirezasafaeidev-portfolio`,
    technologies: ['Next.js', 'TypeScript', 'Tailwind CSS', 'Prisma', 'Playwright', 'Lighthouse CI'],
  })

  const articleSchema = generateArticleSchema({
    title: 'Case Study: alirezasafaeisystems.ir Portfolio System',
    description:
      'Building a portfolio as a production-grade funnel: clear positioning, evidence-driven case studies, and secure lead capture.',
    publishDate: '2026-02-16',
    modifiedDate: '2026-02-16',
    author: 'Alireza Safaei',
  })

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <JsonLd
        data={generateBreadcrumbSchema([
          { name: copy.breadcrumbHome, url: siteUrl },
          { name: copy.breadcrumbCases, url: `${siteUrl}/${lang}/case-studies` },
          { name: 'alirezasafaeisystems.ir Portfolio System', url: pageUrl },
        ])}
      />
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
            <h3 className="font-semibold">{copy.hProof}</h3>
            <p className="text-sm text-muted-foreground">{copy.pProof}</p>
          </div>
        </section>

        <footer>
          <Link href={withLocale('/case-studies')} className="underline text-sm text-muted-foreground">
            {copy.back}
          </Link>
        </footer>
      </article>
    </main>
  )
}
