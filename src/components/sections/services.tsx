import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowRight, ServerCog, Boxes, ShieldCheck, GitBranch, ClipboardCheck } from 'lucide-react'
import { getRequestLanguage } from '@/lib/i18n/server'
import { Reveal } from '@/components/ui/reveal'

function withLocale(path: string, lang: 'fa' | 'en') {
  return `/${lang}${path}`
}

function getCapabilities(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      {
        title: 'Software Architecture & System Design',
        detail: 'Architecture decisions, service boundaries, and delivery constraints aligned with business goals.',
        icon: Boxes,
      },
      {
        title: 'End-to-End Build & Production Readiness',
        detail: 'From concept to production release with quality gates, observability, and rollback safety.',
        icon: ServerCog,
      },
      {
        title: 'Project Rescue & Dependency Stabilization',
        detail: 'Recover stalled projects, reduce dependency risk, and harden runtime reliability.',
        icon: ShieldCheck,
      },
    ]
  }

  return [
    {
      title: 'معماری نرم افزار و طراحی سیستم',
      detail:
        'تحلیل وضعیت، تصمیم های معماری، و مرزبندی سرویس ها بر اساس نیاز واقعی کسب وکار.',
      icon: Boxes,
    },
    {
      title: 'طراحی و توسعه صفر تا صد تا آمادگی تولید',
      detail:
        'از ایده تا انتشار نهایی با گیت های کیفیت، رصدپذیری و قابلیت rollback.',
      icon: ServerCog,
    },
    {
      title: 'نجات پروژه و پایدارسازی وابستگی ها',
      detail:
        'تکمیل پروژه های نیمه کاره، کاهش وابستگی های خارجی، و مقاوم سازی عملیات.',
      icon: ShieldCheck,
    },
  ]
}

function getDeliveryFlow(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      { title: 'Discovery', detail: 'Business context, risk map, and technical baseline.' },
      { title: 'Design', detail: 'Architecture blueprint and executable roadmap.' },
      { title: 'Build', detail: 'Implementation with QA and governance controls.' },
      { title: 'Operate', detail: 'Production readiness, handover, and stabilization.' },
    ]
  }

  return [
    { title: 'Discovery', detail: 'شناخت مسئله، تحلیل ریسک، و تعیین خط مبنای فنی.' },
    { title: 'Design', detail: 'طراحی معماری و نقشه اجرایی مرحله بندی شده.' },
    { title: 'Build', detail: 'پیاده سازی کنترل شده با QA و استانداردهای تحویل.' },
    { title: 'Operate', detail: 'آمادگی تولید، تحویل عملیاتی، و پایدارسازی.' },
  ]
}

function getExecutionSignals(lang: 'fa' | 'en') {
  if (lang === 'en') {
    return [
      { title: 'Release Reliability', value: 'Governed gates + rollback readiness' },
      { title: 'Operational Ownership', value: 'Clear runbook and handover path' },
      { title: 'Sanctions Resilience', value: 'Local-first critical service strategy' },
    ]
  }

  return [
    { title: 'پایداری انتشار', value: 'گیت های کنترل شده + آمادگی rollback' },
    { title: 'مالکیت عملیاتی', value: 'Runbook و مسیر handover شفاف' },
    { title: 'تاب آوری در محدودیت ها', value: 'راهبرد local-first برای سرویس های حیاتی' },
  ]
}

export async function Services() {
  const lang = await getRequestLanguage()
  const capabilities = getCapabilities(lang)
  const deliveryFlow = getDeliveryFlow(lang)
  const executionSignals = getExecutionSignals(lang)

  const eyebrow = lang === 'en' ? 'Step 2' : 'مرحله ۲'
  const title = lang === 'en' ? 'How I Can Help Your Team' : 'مهارت ها و حوزه هایی که می توانم کمک کنم'
  const subtitle =
    lang === 'en'
      ? 'Practical collaboration model for predictable delivery, stable infrastructure, and production-ready execution.'
      : 'مدل همکاری عملی برای تحویل قابل پیش بینی، زیرساخت پایدار، و اجرای آماده تولید.'
  const flowTitle = lang === 'en' ? 'How Collaboration Moves Forward' : 'جریان همکاری چگونه پیش می رود'
  const signalTitle = lang === 'en' ? 'Execution Quality Signals' : 'شاخص های کیفیت اجرا'
  const ctaProgram = lang === 'en' ? 'View Full Service Program' : 'مشاهده برنامه کامل خدمات'
  const ctaAssessment = lang === 'en' ? 'Request Qualification' : 'درخواست ارزیابی و Qualification'
  const ctaCases = lang === 'en' ? 'See Real Case Studies' : 'مشاهده نمونه کارهای واقعی'

  return (
    <section id="services" className="section-block-soft bg-muted/30 relative overflow-hidden subtle-grid">
      <div className="absolute inset-0 bg-gradient-to-bl from-background via-background/70 to-muted/20 pointer-events-none" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="section-surface aurora-shell p-6 md:p-8">
          <div className="mx-auto max-w-3xl text-center space-y-4 mb-10">
            <p className="text-sm font-semibold text-primary">{eyebrow}</p>
            <h2 className="headline-tight text-3xl md:text-4xl font-bold">{title}</h2>
            <p className="text-muted-foreground text-copy">{subtitle}</p>
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            {capabilities.map((item, index) => (
              <Reveal key={item.title} delayMs={index * 70}>
                <Card className="h-full card-hover relative overflow-hidden border-border/70">
                  <div className="pointer-events-none absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-primary/80 via-accent/80 to-primary/60" />
                  <CardHeader className="space-y-3">
                    <div className="inline-flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10 text-primary">
                      <item.icon className="h-5 w-5" />
                    </div>
                    <CardTitle className="text-lg text-ui">{item.title}</CardTitle>
                  </CardHeader>
                  <CardContent className="text-sm text-muted-foreground text-copy">{item.detail}</CardContent>
                </Card>
              </Reveal>
            ))}
          </div>

          <div className="mt-8 rounded-xl border border-border/70 bg-card/70 p-5 md:p-6">
            <h3 className="text-base md:text-lg font-semibold mb-4">{flowTitle}</h3>
            <div className="grid gap-3 md:grid-cols-4">
              {deliveryFlow.map((item, index) => (
                <div key={item.title} className="rounded-lg border border-border/60 bg-background/70 p-3">
                  <p className="inline-flex items-center gap-2 text-sm font-semibold mb-1">
                    <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-primary/12 text-xs text-primary">{index + 1}</span>
                    {item.title}
                  </p>
                  <p className="text-xs md:text-sm text-muted-foreground text-ui">{item.detail}</p>
                </div>
              ))}
            </div>

            <div className="mt-4 flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
              <span className="inline-flex items-center gap-1"><GitBranch className="h-3.5 w-3.5" /> {lang === 'en' ? 'Structured release flow' : 'جریان انتشار ساختاریافته'}</span>
              <span className="inline-flex items-center gap-1"><ClipboardCheck className="h-3.5 w-3.5" /> {lang === 'en' ? 'Measurable delivery evidence' : 'شواهد تحویل قابل سنجش'}</span>
              <span className="inline-flex items-center gap-1"><ShieldCheck className="h-3.5 w-3.5" /> {lang === 'en' ? 'Sanctions-resilient planning' : 'طراحی مقاوم در برابر محدودیت های خارجی'}</span>
            </div>
          </div>

          <div className="mt-5 rounded-xl border border-primary/20 bg-primary/5 p-5">
            <p className="mb-3 text-sm font-semibold">{signalTitle}</p>
            <div className="grid gap-3 md:grid-cols-3">
              {executionSignals.map((item) => (
                <div key={item.title} className="rounded-lg border border-border/60 bg-background/70 px-4 py-3">
                  <p className="text-sm font-semibold">{item.title}</p>
                  <p className="mt-1 text-xs md:text-sm text-muted-foreground text-ui">{item.value}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-10 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
            <Button asChild size="lg" className="gap-2 shine-effect">
              <Link href={withLocale('/services/infrastructure-localization', lang)}>
                {ctaProgram}
                <ArrowRight className="h-4 w-4" />
              </Link>
            </Button>
            <Button asChild size="lg" variant="outline" className="gap-2 card-hover">
              <Link href={withLocale('/qualification', lang)}>{ctaAssessment}</Link>
            </Button>
            <Button asChild size="lg" variant="ghost" className="gap-2 card-hover">
              <Link href={withLocale('/case-studies', lang)}>{ctaCases}</Link>
            </Button>
          </div>
        </div>
      </div>
    </section>
  )
}
