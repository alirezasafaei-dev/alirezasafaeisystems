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
    title: lang === 'fa' ? 'کیس استادی: بازسازی Legacy Next.js' : 'Case Study: Legacy Next.js Replatform',
    description:
      lang === 'fa'
        ? 'چگونه قابلیت اطمینان انتشار از طریق مرزهای معماری و دروازه‌های تحویل سخت بازیابی شد.'
        : 'How release reliability was restored through architecture boundaries and hard delivery gates.',
    alternates: {
      canonical: `${siteUrl}/${lang}/case-studies/legacy-nextjs-replatform`,
    },
  }
}

export default async function LegacyNextjsReplatformPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbCases: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    eyebrow: lang === 'en' ? 'Case Study' : 'مطالعه موردی',
    title: lang === 'en' ? 'Legacy Next.js Replatform' : 'بازپلتفرم Next.js قدیمی',
    intro:
      lang === 'en'
        ? 'A high-risk migration where uptime constraints blocked full rewrites.'
        : 'یک مهاجرت پرریسک که محدودیت uptime اجازه بازنویسی کامل را نمی‌داد.',
    hProblem: lang === 'en' ? 'Problem' : 'مسئله',
    pProblem:
      lang === 'en'
        ? 'Deployment breaks, weak module boundaries, and unowned release decisions caused frequent hotfix cycles.'
        : 'شکست‌های مکرر deploy، مرزبندی ضعیف ماژول‌ها، و تصمیم‌های انتشار بدون مالک باعث چرخه‌های hotfix می‌شد.',
    hSolution: lang === 'en' ? 'Solution' : 'راهکار',
    solutionItems:
      lang === 'en'
        ? [
            'Defined domain boundaries and migration sequence',
            'Introduced release checklist with build, smoke, and rollback gates',
            'Shifted risky integrations behind feature flags and staged rollout',
          ]
        : [
            'تعریف مرزهای دامنه و توالی مهاجرت',
            'ایجاد چک‌لیست انتشار با گیت‌های build/smoke/rollback',
            'قرار دادن یکپارچه‌سازی‌های پرریسک پشت feature flag و rollout مرحله‌ای',
          ],
    hResult: lang === 'en' ? 'Result' : 'نتیجه',
    pResult:
      lang === 'en'
        ? 'Release failure rate dropped by 58% in 5 weeks. Production freeze windows were removed for standard releases.'
        : 'نرخ شکست انتشار ۵۸٪ در ۵ هفته کاهش یافت. پنجره‌های freeze برای انتشارهای استاندارد حذف شد.',
    hRole: lang === 'en' ? 'Role' : 'نقش',
    pRole:
      lang === 'en'
        ? 'Architecture lead, release governance design, migration execution support.'
        : 'رهبر معماری، طراحی حاکمیت انتشار، و پشتیبانی از اجرای مهاجرت.',
    hStack: lang === 'en' ? 'Tech Stack' : 'تکنولوژی‌ها',
    pStack: 'Next.js, TypeScript, PostgreSQL, Redis, Nginx, GitHub Actions.',
    hProof: lang === 'en' ? 'Proof' : 'شواهد',
    pProof:
      lang === 'en'
        ? 'Release reports, incident logs, and gate compliance records were delivered to stakeholders weekly.'
        : 'گزارش‌های انتشار، لاگ رخدادها، و وضعیت رعایت گیت‌ها به صورت هفتگی ارائه شد.',
    hLessons: lang === 'en' ? 'Lessons & Tradeoffs' : 'درس‌ها و tradeoffها',
    pLessons:
      lang === 'en'
        ? 'A phased migration took longer than a big-bang rewrite, but preserved uptime and reduced organizational risk.'
        : 'مهاجرت مرحله‌ای از بازنویسی big-bang طولانی‌تر است، اما uptime را حفظ و ریسک سازمانی را کاهش می‌دهد.',
    back: lang === 'en' ? 'Back to case studies' : 'بازگشت به مطالعات موردی',
  }

  const pageUrl = `${siteUrl}/${lang}/case-studies/legacy-nextjs-replatform`
  const projectSchema = generateProjectSchema({
    name: 'Legacy Next.js Replatform',
    description: 'Migration from a fragile legacy codebase to a governed Next.js architecture.',
    url: lang === 'fa' ? '/case-studies/legacy-nextjs-replatform' : `/${lang}/case-studies/legacy-nextjs-replatform`,
    technologies: ['Next.js', 'TypeScript', 'PostgreSQL', 'Redis', 'Nginx'],
  })

  const articleSchema = generateArticleSchema({
    title: 'Case Study: Legacy Next.js Replatform',
    description: 'How release reliability was restored through architecture boundaries and hard delivery gates.',
    publishDate: '2026-02-12',
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
