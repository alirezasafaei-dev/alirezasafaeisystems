import type { Metadata } from 'next'
import Link from 'next/link'
import { JsonLd } from '@/components/seo/json-ld'
import { getSiteUrl } from '@/lib/site-config'
import { generateBreadcrumbSchema } from '@/lib/seo'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export const metadata: Metadata = {
  title: 'Case Studies',
  description: 'Selected delivery case studies with measurable outcomes, constraints, and operational evidence.',
  alternates: { canonical: `${siteUrl}/case-studies` },
}

function getCases(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      {
        title: 'alirezasafaeisystems.ir Portfolio System',
        sector: 'Consulting / Acquisition',
        outcome: 'Visitor → Lead funnel with DB-backed qualification, strict QA gates, and VPS-ready deployment',
        href: '/case-studies/alirezasafaeidev-portfolio',
      },
      {
        title: 'PersianToolbox Platform',
        sector: 'Consumer Utilities',
        outcome: 'Local-first product delivery with disciplined UX, SEO, and release operations',
        href: '/case-studies/asdev-persiantoolbox-platform',
      },
      {
        title: 'Infrastructure Localization Rescue',
        sector: 'B2B SaaS',
        outcome: 'MTTR reduced from 180 minutes to 55 minutes in 6 weeks',
        href: '/case-studies/infrastructure-localization-rescue',
      },
      {
        title: 'Legacy Next.js Replatform',
        sector: 'FinTech',
        outcome: 'Release failure rate reduced by 58% in 5 weeks',
        href: '/case-studies/legacy-nextjs-replatform',
      },
      {
        title: 'CI/CD Governance Hardening',
        sector: 'Enterprise B2B',
        outcome: 'Zero emergency rollback over 30 days',
        href: '/case-studies/ci-cd-governance-hardening',
      },
    ]
  }

  return [
    {
      title: 'سیستم پورتفولیو alirezasafaeisystems.ir',
      sector: 'جذب پروژه',
      outcome: 'قیف Visitor → Lead با ذخیره در DB، گیت‌های کیفیت سخت‌گیرانه، و آمادگی VPS',
      href: '/case-studies/alirezasafaeidev-portfolio',
    },
    {
      title: 'پلتفرم PersianToolbox',
      sector: 'محصول مصرفی',
      outcome: 'تحویل محصول local-first با UX منسجم، SEO، و عملیات انتشار production-grade',
      href: '/case-studies/asdev-persiantoolbox-platform',
    },
    {
      title: 'نجات بومی‌سازی زیرساخت',
      sector: 'SaaS سازمانی',
      outcome: 'کاهش MTTR از ۱۸۰ دقیقه به ۵۵ دقیقه در ۶ هفته',
      href: '/case-studies/infrastructure-localization-rescue',
    },
    {
      title: 'بازپلتفرم Next.js قدیمی',
      sector: 'فین‌تک',
      outcome: 'کاهش نرخ شکست انتشار به میزان ۵۸٪ در ۵ هفته',
      href: '/case-studies/legacy-nextjs-replatform',
    },
    {
      title: 'سخت‌سازی حاکمیت CI/CD',
      sector: 'B2B سازمانی',
      outcome: 'صفر rollback اضطراری در ۳۰ روز',
      href: '/case-studies/ci-cd-governance-hardening',
    },
  ]
}

export default async function CaseStudiesPage() {
  const lang = await getRequestLanguage()
  const cases = getCases(lang)
  const withLocale = (path: string) => `/${lang}${path}`

  const copy = {
    breadcrumbHome: lang === 'en' ? 'Home' : 'خانه',
    breadcrumbCases: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    schemaName: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    schemaDesc:
      lang === 'en'
        ? 'Selected delivery case studies with measurable outcomes and operational evidence.'
        : 'مطالعات موردی منتخب با خروجی قابل اندازه‌گیری و شواهد اجرایی.',
    eyebrow: lang === 'en' ? 'Proof-Backed Delivery' : 'تحویل مبتنی بر شواهد',
    title: lang === 'en' ? 'Case Studies' : 'مطالعات موردی',
    desc:
      lang === 'en'
        ? 'Each case includes context, constraints, actions, outcomes, and accepted evidence.'
        : 'هر مورد شامل زمینه، محدودیت‌ها، اقدام‌ها، خروجی‌ها و شواهد قابل قبول است.',
    featured: lang === 'en' ? 'Featured Product' : 'محصول نمونه‌کار',
    open: lang === 'en' ? 'Open Full Case' : 'مشاهده کامل',
  }

  const collectionSchema = {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: copy.schemaName,
    description: copy.schemaDesc,
    url: `${siteUrl}/case-studies`,
  }

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <JsonLd data={generateBreadcrumbSchema([
        { name: copy.breadcrumbHome, url: siteUrl },
        { name: copy.breadcrumbCases, url: `${siteUrl}/case-studies` },
      ])} />
      <JsonLd data={collectionSchema} />
      <section className="mx-auto max-w-5xl space-y-8 section-surface aurora-shell p-6 md:p-8">
        <header className="space-y-3">
          <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
          <h1 className="headline-tight text-3xl font-bold md:text-5xl">{copy.title}</h1>
          <p className="text-muted-foreground leading-8">{copy.desc}</p>
        </header>

        <div className="grid gap-4 md:grid-cols-2">
          {cases.map((item, index) => (
            <article key={item.title} className="rounded-xl border bg-card p-6 card-hover reveal-up" style={{ animationDelay: `${index * 70}ms` }}>
              <div className="flex items-center justify-between gap-3">
                <p className="text-xs font-medium text-primary">{item.sector}</p>
                {index === 0 ? (
                  <span className="rounded-full border border-primary/40 bg-primary px-2 py-1 text-[10px] font-semibold text-primary-foreground">
                    {copy.featured}
                  </span>
                ) : null}
              </div>
              <h2 className="mt-2 text-xl font-semibold">{item.title}</h2>
              <p className="mt-2 text-sm text-muted-foreground">{item.outcome}</p>
              <Link href={withLocale(item.href)} className="mt-4 inline-flex rounded-md border px-4 py-2 text-sm hover:bg-muted card-hover">
                {copy.open}
              </Link>
            </article>
          ))}
        </div>
      </section>
    </main>
  )
}
