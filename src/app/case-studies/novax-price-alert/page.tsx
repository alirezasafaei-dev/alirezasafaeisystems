import type { Metadata } from 'next'
import Link from 'next/link'
import { JsonLd } from '@/components/seo/json-ld'
import { getSiteUrl } from '@/lib/site-config'
import { generateArticleSchema, generateBreadcrumbSchema, generateProjectSchema } from '@/lib/seo'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()
const novaxUrl = 'https://novax.alirezasafaeisystems.ir'

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: 'Case Study: Novax Price Alert',
    description:
      'Production-grade Telegram price alert system for Iranian users with Binance USDT + TGJU Toman, hardened backend, rich TWA, and VPS co-deploy.',
    alternates: {
      canonical: `${siteUrl}/${lang}/case-studies/novax-price-alert`,
      languages: {
        'fa-IR': `${siteUrl}/fa/case-studies/novax-price-alert`,
        'en-US': `${siteUrl}/en/case-studies/novax-price-alert`,
      },
    },
  }
}

export default async function NovaxPriceAlertPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => `/${lang}${path}`
  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbCases: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    eyebrow: lang === 'en' ? 'Case Study' : 'مطالعه موردی',
    title: 'Novax Price Alert',
    intro:
      lang === 'en'
        ? 'A production Telegram bot + rich TWA for real-time price alerts on Iranian markets (crypto via Binance USDT, fiat/gold via TGJU Toman) with explicit staged flows, reliability hardening, and zero-downtime VPS deployment alongside other live sites.'
        : 'یک بات تلگرام production-grade + TWA غنی برای هشدار قیمت در بازار ایران (کریپتو از Binance با USDT، ارز و طلا از TGJU با تومان) با جریان‌های مرحله‌ای صریح، سخت‌سازی قابلیت اعتماد، و دیپلوی VPS بدون اختلال در کنار سایت‌های زنده دیگر.',
    hProblem: lang === 'en' ? 'Problem' : 'مسئله',
    pProblem:
      lang === 'en'
        ? 'Users needed reliable price monitoring and alerts without ambiguity in asset selection, unit (Toman primary), stale data, or duplicate notifications. The system had to coexist safely with other production sites on the same VPS.'
        : 'کاربران نیاز به رصد قیمت و هشدار قابل اعتماد بدون ابهام در انتخاب دارایی، واحد (تومان به عنوان اصلی)، داده قدیمی یا اعلان تکراری داشتند. سیستم باید بدون خطر با سایت‌های production دیگر روی همان VPS همزیستی می‌کرد.',
    hSolution: lang === 'en' ? 'Solution' : 'راهکار',
    solutionItems:
      lang === 'en'
        ? [
            'Explicit 6-step staged alert flow with confirmation gate (per improvement report)',
            'Canonical asset identity + display snapshots at creation time',
            'Atomic claim + idempotency + freshness policy enforcement in evaluator/dispatcher',
            'Rich TWA (tabbed: Prices, My Assets, Alerts, Advanced Charts, Create) with smart suggestions and portfolio demo',
            'VPS deploy with PM2 (api+worker on 8001), nginx per-subdomain, safe rsync, healthchecks, backups',
            'Policies codified in domain/policies.py and documented',
          ]
        : [
            'جریان ساخت هشدار ۶ مرحله‌ای صریح با گیت تایید (طبق گزارش بهبود)',
            'هویت کانونیکال دارایی + اسنپ‌شات نمایش در زمان ایجاد',
            'claim اتمیک + idempotency + سیاست freshness در evaluator و dispatcher',
            'TWA غنی (تب‌دار: قیمت‌ها، دارایی‌های من، هشدارها، چارت پیشرفته، ایجاد) با پیشنهادهای هوشمند و دمو پورتفولیو',
            'دیپلوی VPS با PM2 (api+worker روی ۸۰۰۱)، nginx ساب‌دامین اختصاصی، rsync ایمن، healthcheck و بک‌آپ',
            'سیاست‌ها در domain/policies.py کدبندی و مستند شدند',
          ],
    hResult: lang === 'en' ? 'Result' : 'نتیجه',
    pResult:
      lang === 'en'
        ? 'Production system live at novax.alirezasafaeisystems.ir with hardened alerts (no dups, freshness respected), rich client UX, co-existing safely with 3 other live sites. All report phases (0-4 + growth) completed and deployed.'
        : 'سیستم production در novax.alirezasafaeisystems.ir با هشدارهای سخت‌شده (بدون تکرار، رعایت freshness)، UX کلاینت غنی، و همزیستی ایمن با ۳ سایت زنده دیگر. تمام فازهای گزارش (۰-۴ + رشد) کامل و دیپلوی شد.',
    hRole: lang === 'en' ? 'Role' : 'نقش',
    pRole:
      lang === 'en'
        ? 'Full-stack product engineering: architecture, backend (FastAPI + worker + policies), TWA (Next-like single-file rich app), ops (PM2/nginx/VPS), docs alignment with report.'
        : 'Product engineering کامل: معماری، بک‌اند (FastAPI + worker + policies)، TWA (اپ غنی تک‌فایل)، عملیات (PM2/nginx/VPS)، هم‌ترازی مستندات با گزارش.',
    hStack: lang === 'en' ? 'Tech Stack' : 'تکنولوژی‌ها',
    pStack: 'Python/FastAPI, SQLAlchemy/Alembic, Redis, PostgreSQL, Telegram Bot API + CF Worker relay, Next.js-style TWA (Tailwind + Chart.js), PM2, nginx, certbot, GitHub Actions for price ingest.',
    hProof: lang === 'en' ? 'Proof' : 'شواهد',
    pProof:
      lang === 'en'
        ? 'Live subdomain with health 200, TWA fully functional (tabs, My Assets, suggestions, charts), worker evaluating alerts, safe multi-site VPS, all per report + production checklist executed.'
        : 'ساب‌دامین زنده با health ۲۰۰، TWA کاملاً عملیاتی (تب‌ها، دارایی‌های من، پیشنهادها، چارت‌ها)، ورکر در حال ارزیابی هشدارها، VPS چندسایتی ایمن، همه طبق گزارش و چک‌لیست تولید اجرا شده.',
    visit: lang === 'en' ? 'Visit novax.alirezasafaeisystems.ir' : 'مشاهده novax.alirezasafaeisystems.ir',
    hLessons: lang === 'en' ? 'Lessons & Tradeoffs' : 'درس‌ها و tradeoffها',
    pLessons:
      lang === 'en'
        ? 'Explicit contracts and staged UX + atomic hardening in critical paths delivered trust without over-engineering. Co-deploy discipline (rsync excludes, dedicated PM2/ports) allowed safe addition of new production asset.'
        : 'قراردادهای صریح و UX مرحله‌ای + hardening اتمیک در مسیرهای حیاتی اعتماد ایجاد کرد بدون over-engineering. دیسیپلین co-deploy (rsync excludes، PM2/پورت اختصاصی) امکان افزودن asset production جدید را به صورت ایمن فراهم کرد.',
    back: lang === 'en' ? 'Back to case studies' : 'بازگشت به مطالعات موردی',
  }

  const pageUrl = `${siteUrl}/${lang}/case-studies/novax-price-alert`

  const projectSchema = generateProjectSchema({
    name: 'Novax Price Alert',
    description: 'Production Telegram price alert bot + rich TWA for Iranian markets with full hardening and safe VPS deployment.',
    url: withLocale('/case-studies/novax-price-alert'),
    technologies: ['FastAPI', 'Telegram', 'TWA', 'PM2', 'nginx', 'PostgreSQL', 'Redis'],
  })

  const articleSchema = generateArticleSchema({
    title: 'Case Study: Novax Price Alert',
    description:
      'Complete delivery of a production-ready Telegram price alert system following explicit contracts, reliability hardening, and rich client UX for Iranian users.',
    publishDate: '2026-06-05',
    modifiedDate: '2026-06-05',
    author: 'Alireza Safaei',
  })

  return (
    <div className="container py-12">
      <JsonLd data={generateBreadcrumbSchema([
        { name: copy.breadcrumbHome, url: siteUrl },
        { name: copy.breadcrumbCases, url: `${siteUrl}/${lang}/case-studies` },
        { name: copy.title, url: pageUrl },
      ])} />
      <JsonLd data={projectSchema} />
      <JsonLd data={{ ...articleSchema, url: pageUrl }} />

      <nav className="mb-8 text-sm text-muted-foreground">
        <Link href={withLocale('/')}>{copy.breadcrumbHome}</Link>
        <span className="mx-2">/</span>
        <Link href={withLocale('/case-studies')}>{copy.breadcrumbCases}</Link>
        <span className="mx-2">/</span>
        <span>Novax Price Alert</span>
      </nav>

      <div className="mb-8">
        <div className="text-sm text-muted-foreground">{copy.eyebrow}</div>
        <h1 className="mt-2 text-4xl font-semibold tracking-tight">{copy.title}</h1>
        <p className="mt-3 max-w-3xl text-lg text-muted-foreground">{copy.intro}</p>
      </div>

      <div className="grid gap-8 md:grid-cols-2">
        <section>
          <h2 className="text-xl font-semibold">{copy.hProblem}</h2>
          <p className="mt-3 text-muted-foreground">{copy.pProblem}</p>
        </section>

        <section>
          <h2 className="text-xl font-semibold">{copy.hSolution}</h2>
          <ul className="mt-3 list-disc space-y-1 pl-5 text-muted-foreground">
            {copy.solutionItems.map((item, i) => (
              <li key={i}>{item}</li>
            ))}
          </ul>
        </section>

        <section>
          <h2 className="text-xl font-semibold">{copy.hResult}</h2>
          <p className="mt-3 text-muted-foreground">{copy.pResult}</p>
          <p className="mt-2">
            <a href={novaxUrl} className="underline" target="_blank" rel="noopener">
              {copy.visit}
            </a>
          </p>
        </section>

        <section>
          <h2 className="text-xl font-semibold">{copy.hRole}</h2>
          <p className="mt-3 text-muted-foreground">{copy.pRole}</p>
        </section>

        <section>
          <h2 className="text-xl font-semibold">{copy.hStack}</h2>
          <p className="mt-3 text-muted-foreground">{copy.pStack}</p>
        </section>

        <section>
          <h2 className="text-xl font-semibold">{copy.hProof}</h2>
          <p className="mt-3 text-muted-foreground">{copy.pProof}</p>
        </section>
      </div>

      <section className="mt-10">
        <h2 className="text-xl font-semibold">{copy.hLessons}</h2>
        <p className="mt-3 text-muted-foreground">{copy.pLessons}</p>
      </section>

      <div className="mt-10">
        <Link href={withLocale('/case-studies')} className="text-sm underline">
          {copy.back}
        </Link>
      </div>
    </div>
  )
}
