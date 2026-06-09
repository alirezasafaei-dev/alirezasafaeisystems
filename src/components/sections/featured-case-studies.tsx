import Link from 'next/link'
import { ArrowUpRight, TrendingUp } from 'lucide-react'
import { getRequestLanguage } from '@/lib/i18n/server'
import { Reveal } from '@/components/ui/reveal'

type CaseStudyItem = {
  title: string
  summary: string
  href: string
  metric: string
  external?: boolean
}

function getCaseStudies(lang: 'fa' | 'en'): CaseStudyItem[] {
  if (lang === 'en') {
    return [
      {
        title: 'alirezasafaeisystems.ir Portfolio System',
        summary: 'Built this portfolio as a measurable visitor→lead system with QA gates and VPS-ready deployment.',
        href: '/case-studies/alirezasafaeidev-portfolio',
        metric: 'Portfolio as a production funnel',
      },
      {
        title: 'PersianToolbox Platform',
        summary: 'Built and scaled a local-first Persian utility platform with high UX clarity and reliability standards.',
        href: '/case-studies/asdev-persiantoolbox-platform',
        metric: 'Live product with production governance',
      },
      {
        title: 'Novax Price Alert (Telegram Bot + TWA)',
        summary: 'Production Telegram price alert for Iranian markets (Binance USDT + TGJU Toman) with staged 6-step flows, atomic hardening, rich tabbed TWA (My Assets, suggestions, portfolio, advanced charts), PWA, and safe co-deploy on VPS.',
        href: '/case-studies/novax-price-alert',
        metric: 'Hardened alerts • Zero dups • Rich TWA live',
      },
      {
        title: 'Audit Systems Platform',
        summary: 'Launched a practical website audit system for technical SEO, performance, and security with actionable outputs.',
        href: 'https://audit.alirezasafaeisystems.ir/?utm_source=portfolio&utm_medium=case_studies&utm_campaign=alireza_safaei_network&utm_content=audit_case_card',
        metric: 'Live audit product in production',
        external: true,
      },
      {
        title: 'Infrastructure Localization Rescue',
        summary: 'Stabilized a fragile production stack under localization constraints and cut incident recovery time by 69%.',
        href: '/case-studies/infrastructure-localization-rescue',
        metric: 'MTTR: 180m → 55m',
      },
      {
        title: 'Legacy Next.js Replatform',
        summary: 'Migrated a risk-prone monolith to a governed Next.js architecture with cleaner release boundaries.',
        href: '/case-studies/legacy-nextjs-replatform',
        metric: 'Release failure rate: -58%',
      },
      {
        title: 'CI/CD Governance Hardening',
        summary: 'Introduced release gates, rollback drills, and evidence-based operations for executive reporting.',
        href: '/case-studies/ci-cd-governance-hardening',
        metric: 'Emergency rollback: 0 in 30 days',
      },
    ]
  }

  return [
    {
      title: 'سیستم پورتفولیو alirezasafaeisystems.ir',
      summary: 'ساخت این سایت به عنوان سیستم Visitor→Lead با گیت‌های کیفیت و آمادگی استقرار روی VPS.',
      href: '/case-studies/alirezasafaeidev-portfolio',
      metric: 'پورتفولیو به عنوان قیف تولیدی',
    },
    {
      title: 'پلتفرم PersianToolbox',
      summary: 'ساخت و رشد پلتفرم ابزارهای فارسی local-first با استاندارد بالا در سادگی تجربه و پایداری.',
      href: '/case-studies/asdev-persiantoolbox-platform',
      metric: 'محصول زنده با حاکمیت تولید',
    },
    {
      title: 'Novax Price Alert (بات تلگرام + TWA)',
      summary: 'سیستم هشدار قیمت تلگرام production برای بازار ایران (Binance USDT + TGJU تومان) با جریان ۶ مرحله‌ای، hardening اتمیک، TWA تب‌دار غنی (دارایی‌های من، پیشنهادها، پورتفولیو، چارت پیشرفته)، PWA و دیپلوی امن هم‌زمان روی VPS.',
      href: '/case-studies/novax-price-alert',
      metric: 'هشدارهای سخت‌شده • بدون تکرار • TWA غنی زنده',
    },
    {
      title: 'پلتفرم Audit Systems',
      summary: 'راه‌اندازی پلتفرم ارزیابی سایت برای سئو فنی، عملکرد و امنیت با خروجی عملی و قابل اجرا.',
      href: 'https://audit.alirezasafaeisystems.ir/?utm_source=portfolio&utm_medium=case_studies&utm_campaign=alireza_safaei_network&utm_content=audit_case_card',
      metric: 'محصول ارزیابی زنده در تولید',
      external: true,
    },
    {
      title: 'نجات بومی‌سازی زیرساخت',
      summary: 'پایدارسازی استک شکننده تحت محدودیت‌های بومی‌سازی و کاهش زمان بازیابی رخدادها.',
      href: '/case-studies/infrastructure-localization-rescue',
      metric: 'MTTR: ۱۸۰ → ۵۵ دقیقه',
    },
    {
      title: 'بازپلتفرم Next.js قدیمی',
      summary: 'مهاجرت یک مونولیت پرریسک به معماری governed در Next.js با مرزهای انتشار تمیزتر.',
      href: '/case-studies/legacy-nextjs-replatform',
      metric: 'کاهش نرخ شکست انتشار: ۵۸٪',
    },
    {
      title: 'سخت‌سازی حاکمیت CI/CD',
      summary: 'ایجاد گیت‌های انتشار، تمرین‌های rollback، و عملیات مبتنی بر شواهد برای گزارش مدیریتی.',
      href: '/case-studies/ci-cd-governance-hardening',
      metric: 'Rollback اضطراری: ۰ در ۳۰ روز',
    },
  ]
}

function withLocale(path: string, lang: 'fa' | 'en') {
  return lang === 'fa' ? path : `/${lang}${path}`
}

export async function FeaturedCaseStudies() {
  const lang = await getRequestLanguage()
  const caseStudies = getCaseStudies(lang)
  const [featuredCase, ...otherCases] = caseStudies
  const eyebrow = lang === 'en' ? 'Step 3 | Execution Proof' : 'مرحله ۳ | نمونه کارهای واقعی'
  const title = lang === 'en' ? 'Featured Case Studies' : 'مطالعات موردی منتخب'
  const desc =
    lang === 'en'
      ? 'Each case shows problem context, architecture decisions, and measurable outcomes.'
      : 'هر کیس شامل مسئله واقعی، تصمیم معماری، و خروجی قابل اندازه گیری است.'
  const openCta = lang === 'en' ? 'Open Case Study' : 'مشاهده کیس‌استادی'
  const allCta = lang === 'en' ? 'View All Case Studies' : 'مشاهده همه مطالعات موردی'
  const evidenceTitle = lang === 'en' ? 'Delivery Evidence Snapshot' : 'نمای سریع شواهد تحویل'
  const networkTitle = lang === 'en' ? 'Live Product Network' : 'شبکه محصولات زنده'
  const networkAuditLabel = lang === 'en' ? 'Audit Systems Platform' : 'پلتفرم Audit Systems'
  const networkToolboxLabel = lang === 'en' ? 'PersianToolbox Platform' : 'پلتفرم PersianToolbox'
  const networkNovaxLabel = lang === 'en' ? 'Novax Price Alert' : 'Novax Price Alert'
  const evidenceItems =
    lang === 'en'
      ? [
          'Documented architecture decisions',
          'Release governance and rollback readiness',
          'Production-focused measurement and reporting',
        ]
      : [
          'تصمیم های معماری مستند و قابل ارجاع',
          'حاکمیت انتشار و آمادگی rollback',
          'اندازه گیری و گزارش دهی مبتنی بر تولید',
        ]

  return (
    <section id="case-studies" className="section-block-soft subtle-grid">
      <div className="container mx-auto px-4">
        <div className="section-surface aurora-shell p-6 md:p-8">
          <div className="mx-auto max-w-3xl text-center space-y-4 mb-10">
            <p className="text-sm font-semibold text-primary">{eyebrow}</p>
            <h2 className="headline-tight text-3xl md:text-4xl font-bold">{title}</h2>
            <p className="text-muted-foreground text-copy">{desc}</p>
          </div>

          <Reveal>
            <article className="rounded-xl border bg-card p-6 md:p-7 card-hover relative overflow-hidden">
              <div className="pointer-events-none absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-accent/70 via-primary/75 to-accent/70" />
              <div className="flex flex-wrap items-center gap-3">
                <p className="text-xs font-medium text-primary inline-flex items-center gap-1.5">
                  <TrendingUp className="h-3.5 w-3.5" />
                  {featuredCase.metric}
                </p>
              </div>
              <h3 className="mt-3 text-2xl md:text-3xl font-semibold headline-tight">{featuredCase.title}</h3>
              <p className="mt-3 text-sm md:text-base text-muted-foreground text-copy max-w-3xl">{featuredCase.summary}</p>
              <Link
                href={featuredCase.external ? featuredCase.href : withLocale(featuredCase.href, lang)}
                target={featuredCase.external ? '_blank' : undefined}
                rel={featuredCase.external ? 'noopener noreferrer' : undefined}
                className="mt-5 inline-flex items-center gap-2 text-sm font-medium hover:text-primary transition-colors"
              >
                {openCta}
                <ArrowUpRight className="h-4 w-4" />
              </Link>
            </article>
          </Reveal>

          <div className="mt-4 grid gap-4 md:grid-cols-2">
            {otherCases.map((item, index) => (
              <Reveal key={item.title} delayMs={index * 75}>
                <article className="rounded-xl border bg-card p-6 h-full flex flex-col card-hover relative overflow-hidden">
                  <div className="pointer-events-none absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-accent/70 via-primary/75 to-accent/70" />
                  <p className="text-xs font-medium text-primary inline-flex items-center gap-1.5">
                    <TrendingUp className="h-3.5 w-3.5" />
                    {item.metric}
                  </p>
                  <h3 className="mt-3 text-xl font-semibold">{item.title}</h3>
                  <p className="mt-2 text-sm text-muted-foreground flex-1 text-ui">{item.summary}</p>
                  <Link
                    href={item.external ? item.href : withLocale(item.href, lang)}
                    target={item.external ? '_blank' : undefined}
                    rel={item.external ? 'noopener noreferrer' : undefined}
                    className="mt-4 inline-flex items-center gap-2 text-sm font-medium hover:text-primary transition-colors"
                  >
                    {openCta}
                    <ArrowUpRight className="h-4 w-4" />
                  </Link>
                </article>
              </Reveal>
            ))}
          </div>

          <div className="mt-5 rounded-xl border border-border/70 bg-card/70 p-4 md:p-5">
            <p className="text-sm font-semibold mb-3">{evidenceTitle}</p>
            <div className="grid gap-2 md:grid-cols-3">
              {evidenceItems.map((item) => (
                <p key={item} className="rounded-lg border border-border/60 bg-background/70 px-3 py-2 text-xs md:text-sm text-muted-foreground text-ui">
                  {item}
                </p>
              ))}
            </div>
          </div>

          <div className="mt-5 rounded-xl border border-border/70 bg-card/70 p-4 md:p-5">
            <p className="text-sm font-semibold mb-3">{networkTitle}</p>
            <div className="flex flex-wrap gap-2">
              <a
                href="https://audit.alirezasafaeisystems.ir/?utm_source=portfolio&utm_medium=cross_site&utm_campaign=alireza_safaei_network&utm_content=featured_case_network"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex rounded-md border px-3 py-2 text-xs md:text-sm hover:bg-muted transition-colors"
              >
                {networkAuditLabel}
              </a>
              <a
                href="https://persiantoolbox.ir/?utm_source=portfolio&utm_medium=cross_site&utm_campaign=alireza_safaei_network&utm_content=featured_case_network"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex rounded-md border px-3 py-2 text-xs md:text-sm hover:bg-muted transition-colors"
              >
                {networkToolboxLabel}
              </a>
              <a
                href="https://novax.alirezasafaeisystems.ir/?utm_source=portfolio&utm_medium=cross_site&utm_campaign=alireza_safaei_network&utm_content=featured_case_network"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex rounded-md border px-3 py-2 text-xs md:text-sm hover:bg-muted transition-colors"
              >
                {networkNovaxLabel}
              </a>
            </div>
          </div>

          <div className="mt-8 text-center">
            <Link href={withLocale('/case-studies', lang)} className="inline-flex rounded-md border px-4 py-2 text-sm hover:bg-muted card-hover">
              {allCta}
            </Link>
          </div>
        </div>
      </div>
    </section>
  )
}
