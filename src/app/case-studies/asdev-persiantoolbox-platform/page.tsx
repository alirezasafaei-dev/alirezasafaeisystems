import type { Metadata } from 'next'
import Link from 'next/link'
import { JsonLd } from '@/components/seo/json-ld'
import { getSiteUrl } from '@/lib/site-config'
import { generateArticleSchema, generateBreadcrumbSchema, generateProjectSchema } from '@/lib/seo'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()
const persianToolboxUrl = 'https://persiantoolbox.ir'

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: lang === 'fa' ? 'کیس استادی: پلتفرم PersianToolbox' : 'Case Study: PersianToolbox Platform',
    description:
      lang === 'fa'
        ? 'یک پلتفرم ابزار فارسی بومی‌اول که برای سرعت، قابلیت اطمینان و سادگی عمدی برای کاربران روزمره مهندسی شده است.'
        : 'A local-first Persian utility platform engineered to be fast, reliable, and intentionally simple for everyday users.',
    alternates: {
      canonical: `${siteUrl}/${lang}/case-studies/asdev-persiantoolbox-platform`,
    },
  }
}

export default async function AsdevPersianToolboxPlatformPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbCases: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    eyebrow: lang === 'en' ? 'Case Study' : 'مطالعه موردی',
    title: lang === 'en' ? 'PersianToolbox Platform' : 'پلتفرم PersianToolbox',
    intro:
      lang === 'en'
        ? 'A local-first Persian utility platform engineered to be fast, reliable, and intentionally simple for everyday users.'
        : 'یک پلتفرم ابزار فارسی local-first که باید همزمان سریع، قابل‌اعتماد، و ساده برای کاربر نهایی می‌بود.',
    hProblem: lang === 'en' ? 'Problem' : 'مسئله',
    pProblem:
      lang === 'en'
        ? 'The platform had to ship a suite of practical tools with a minimal UX and without fragile operational dependencies, while still meeting SEO and release quality requirements.'
        : 'نیاز اصلی، ارائه مجموعه‌ای از ابزارهای کاربردی با تجربه کاربری خلوت و بدون وابستگی عملیاتی شکننده بود؛ در عین حال باید معیارهای SEO و کیفیت انتشار هم رعایت می‌شد.',
    hSolution: lang === 'en' ? 'Solution' : 'راهکار',
    solutionItems:
      lang === 'en'
        ? [
            'A unified design language based on tokens and reusable components',
            'Fast tool flows with low friction and clear navigation',
            'Strict quality gates: lint, type-check, tests, e2e, Lighthouse CI',
            'Local-first runtime with reduced external runtime dependencies',
          ]
        : [
            'ایجاد زبان طراحی یکپارچه مبتنی بر design token و کامپوننت‌های قابل‌استفاده مجدد',
            'ساخت مسیرهای سریع ابزارها با حداقل friction و ناوبری واضح',
            'سخت‌گیری روی quality gates شامل lint/type/test/e2e/lighthouse',
            'تمرکز بر local-first runtime و کاهش وابستگی‌های خارجی',
          ],
    hResult: lang === 'en' ? 'Result' : 'نتیجه',
    pResult:
      lang === 'en'
        ? 'The product shipped with stable release operations, predictable UX, and a clear foundation for expanding new tools without UX fragmentation.'
        : 'محصول با الگوی انتشار پایدار، UX قابل‌اعتماد، و مسیر رشد روشن برای توسعه ابزارهای جدید به بهره‌برداری رسید.',
    hRole: lang === 'en' ? 'Role' : 'نقش',
    pRole:
      lang === 'en'
        ? 'Product engineering lead: architecture, frontend system design, QA governance, and operational deployment readiness.'
        : 'Product engineering lead: معماری، frontend system design، QA governance و استقرار عملیاتی.',
    hStack: lang === 'en' ? 'Tech Stack' : 'تکنولوژی‌ها',
    pStack: 'Next.js, TypeScript, Tailwind CSS, Playwright, Lighthouse CI, Node.js.',
    hProof: lang === 'en' ? 'Proof' : 'شواهد',
    pProof:
      lang === 'en'
        ? 'A live product, operational docs, and per-release quality gate logs were produced and shared with stakeholders.'
        : 'خروجی زنده محصول، اسناد طراحی و عملیات، و لاگ‌های quality gate برای هر انتشار در دسترس تیم قرار گرفت.',
    visit: lang === 'en' ? 'Visit persiantoolbox.ir' : 'مشاهده persiantoolbox.ir',
    hLessons: lang === 'en' ? 'Lessons & Tradeoffs' : 'درس‌ها و tradeoffها',
    pLessons:
      lang === 'en'
        ? 'Keeping the UI simple while expanding scope required strict component discipline and continuous removal of unnecessary complexity.'
        : 'حفظ سادگی UI در کنار گستردگی قابلیت‌ها نیازمند discipline بالا در طراحی کامپوننت و حذف مداوم پیچیدگی غیرضروری است.',
    back: lang === 'en' ? 'Back to case studies' : 'بازگشت به مطالعات موردی',
    ctaAudit: lang === 'en' ? 'Start Free Audit' : 'شروع Audit رایگان',
    ctaAuditDesc: lang === 'en'
      ? 'Want a similar assessment for your site? Start with a free audit.'
      : 'ارزیابی مشابهی برای سایت خود می‌خواهید؟ با یک Audit رایگان شروع کنید.',
  }

  const pageUrl = `${siteUrl}/${lang}/case-studies/asdev-persiantoolbox-platform`

  const projectSchema = generateProjectSchema({
    name: 'PersianToolbox Platform',
    description: 'A local-first Persian utility platform engineered for speed, clarity, and reliable operations.',
    url: withLocale('/case-studies/asdev-persiantoolbox-platform'),
    technologies: ['Next.js', 'TypeScript', 'Tailwind CSS', 'Playwright', 'Lighthouse CI'],
  })

  const articleSchema = generateArticleSchema({
    title: 'Case Study: PersianToolbox Platform',
    description:
      'Design and delivery of a high-utility Persian platform with consistent UX language and production-grade release governance.',
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
          { name: 'PersianToolbox Platform', url: pageUrl },
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
            <h3 className="font-semibold">{copy.hStack}</h3>
            <p className="text-sm text-muted-foreground">{copy.pStack}</p>
          </div>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-2 card-hover">
          <h2 className="text-xl font-semibold">{copy.hProof}</h2>
          <p className="text-sm text-muted-foreground">{copy.pProof}</p>
          <div className="pt-2">
            <a
              href={persianToolboxUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex rounded-md border px-4 py-2 text-sm hover:bg-muted"
            >
              {copy.visit}
            </a>
          </div>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-2 card-hover">
          <h2 className="text-xl font-semibold">{copy.hLessons}</h2>
          <p className="text-sm text-muted-foreground">{copy.pLessons}</p>
        </section>

        <section className="rounded-xl border bg-card p-6 space-y-3 card-hover text-center">
          <h2 className="text-xl font-semibold">{copy.ctaAudit}</h2>
          <p className="text-sm text-muted-foreground">{copy.ctaAuditDesc}</p>
          <a
            href="https://audit.alirezasafaeisystems.ir/audit?utm_source=portfolio&utm_medium=case_study&utm_campaign=asdev_audit"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex rounded-md bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground hover:bg-primary/90 transition-colors"
          >
            {copy.ctaAudit}
          </a>
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
