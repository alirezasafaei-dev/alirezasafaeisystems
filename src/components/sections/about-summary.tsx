import Link from 'next/link'
import { CheckCircle2, DatabaseZap, FileCheck2, ShieldCheck, Unplug } from 'lucide-react'
import { getRequestLanguage } from '@/lib/i18n/server'
import { Reveal } from '@/components/ui/reveal'

function getPrinciples(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      'Production-first quality gates before every release',
      'Clear delivery evidence for technical and executive stakeholders',
      'Maintainable architecture with explicit operational ownership',
    ]
  }

  return [
    'گیت‌های کیفیت قبل از هر release (نه بعد از وقوع مشکل)',
    'شواهد تحویل شفاف برای تیم فنی و ذی‌نفع مدیریتی',
    'معماری قابل نگهداری با مالکیت عملیاتی صریح',
  ]
}

function getOperationalScope(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      {
        icon: DatabaseZap,
        title: 'Infrastructure Localization',
        detail: 'Move critical services and delivery paths toward local-first, sanctions-resilient operation.',
      },
      {
        icon: Unplug,
        title: 'External Dependency Reduction',
        detail: 'Identify fragile third-party dependencies and redesign architecture for reliable alternatives.',
      },
      {
        icon: FileCheck2,
        title: 'Reporting, Testing, and Delivery Evidence',
        detail: 'Set up test strategy, release checklists, and technical reporting for transparent decision-making.',
      },
      {
        icon: ShieldCheck,
        title: 'Production Hardening',
        detail: 'Operational readiness controls, rollback paths, observability, and incident reduction discipline.',
      },
    ]
  }

  return [
    {
      icon: DatabaseZap,
      title: 'لوکال‌سازی زیرساخت',
      detail: 'مسیرهای حیاتی سرویس و تحویل به سمت الگوی بومی و مقاوم در برابر محدودیت‌های خارجی هدایت می‌شود.',
    },
    {
      icon: Unplug,
      title: 'کاهش وابستگی‌های خارجی',
      detail: 'وابستگی‌های شکننده شناسایی می‌شوند و معماری روی جایگزین‌های قابل اتکا بازطراحی می‌شود.',
    },
    {
      icon: FileCheck2,
      title: 'گزارش‌گیری فنی، تست و شواهد تحویل',
      detail: 'استراتژی تست، چک‌لیست انتشار و گزارش‌های فنی قابل ارجاع برای تصمیم‌گیری ایجاد می‌شود.',
    },
    {
      icon: ShieldCheck,
      title: 'پایدارسازی عملیاتی تولید',
      detail: 'کنترل آمادگی تولید، مسیر Rollback، رصدپذیری و کاهش ریسک رخداد به شکل اجرایی پیاده‌سازی می‌شود.',
    },
  ]
}

export async function AboutSummary() {
  const lang = await getRequestLanguage()
  const principles = getPrinciples(lang)
  const operationalScope = getOperationalScope(lang)
  const eyebrow = lang === 'en' ? 'Step 4 | Operational Execution' : 'مرحله ۴ | اجرای عملیاتی'
  const title = lang === 'en' ? 'Stabilization and Localization Scope' : 'دامنه اجرای لوکال‌سازی و پایدارسازی'
  const desc =
    lang === 'en'
      ? 'After architecture and delivery planning, these are the concrete execution tracks used to reduce operational fragility.'
      : 'بعد از طراحی معماری و برنامه تحویل، این مسیرهای اجرایی برای کاهش شکنندگی عملیات پیاده‌سازی می‌شوند.'
  const sectionLabel = lang === 'en' ? 'Practical Tracks' : 'مسیرهای اجرایی'
  const ctaQual = lang === 'en' ? 'Request Project Qualification' : 'درخواست ارزیابی و Qualification'
  const ctaBrand = lang === 'en' ? 'Read Delivery Standards' : 'مشاهده استانداردهای تحویل'
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)

  return (
    <section id="about" className="section-block-soft bg-muted/30 subtle-grid">
      <div className="container mx-auto px-4">
        <div className="mx-auto max-w-5xl section-surface aurora-shell p-8 md:p-10 space-y-8">
          <p className="text-sm font-semibold text-primary">{eyebrow}</p>
          <h2 className="headline-tight text-3xl md:text-4xl font-bold">{title}</h2>
          <p className="text-muted-foreground text-copy">{desc}</p>

          <div className="space-y-4">
            <p className="text-sm font-semibold text-foreground/80">{sectionLabel}</p>
            <div className="grid gap-3 md:grid-cols-2">
              {operationalScope.map((item, index) => (
                <Reveal key={item.title} delayMs={index * 90}>
                  <div className="rounded-lg border border-border/70 bg-card/75 p-4 card-hover text-sm text-muted-foreground text-ui">
                    <p className="mb-2 inline-flex items-center gap-2 font-semibold text-foreground">
                      <item.icon className="h-4 w-4 text-primary" />
                      <span>{item.title}</span>
                    </p>
                    <p>{item.detail}</p>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>

          <div className="grid gap-3 md:grid-cols-3">
            {principles.map((item, index) => (
              <Reveal key={item} delayMs={index * 90}>
                <div className="rounded-lg border border-border/70 bg-card/75 p-4 card-hover text-sm text-muted-foreground text-ui">
                  <p className="inline-flex items-start gap-2">
                    <CheckCircle2 className="mt-0.5 h-4 w-4 text-primary" />
                    <span>{item}</span>
                  </p>
                </div>
              </Reveal>
            ))}
          </div>

          <div className="flex flex-wrap gap-3">
            <Link href={withLocale('/qualification')} className="inline-flex rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground shine-effect">
              {ctaQual}
            </Link>
            <Link href={withLocale('/about-brand')} className="inline-flex rounded-md border px-4 py-2 text-sm hover:bg-muted card-hover">
              {ctaBrand}
            </Link>
          </div>
        </div>
      </div>
    </section>
  )
}
