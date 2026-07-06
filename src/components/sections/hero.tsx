'use client'

import { useEffect, useMemo, useSyncExternalStore } from 'react'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n-context'
import { brand } from '@/lib/brand'
import { withLocale } from '@/lib/locale-utils'
import { ArrowRight, Github, Linkedin, Twitter, Instagram, Send, ShieldCheck, Wrench, Rocket, Handshake, CircleUserRound, MapPin } from 'lucide-react'
import { useRouter } from 'next/navigation'
import { trackEvent } from '@/lib/analytics/client'
import { pickDeterministicBucket, pickHeroVariant, type HeroVariant } from '@/lib/analytics/experiments'

type IntentRoute = {
  key: 'audit' | 'toolbox' | 'execution'
  title: string
  detail: string
  href: string
  external: boolean
  cta: string
}

export function Hero() {
  const { t, language } = useI18n()
  const router = useRouter()
  const variant = useSyncExternalStore(
    () => () => undefined,
    () => {
      if (typeof navigator === 'undefined') return 'authority' as HeroVariant
      return pickHeroVariant(navigator.userAgent || 'authority')
    },
    () => 'authority' as HeroVariant,
  )
  const intentVariant = useSyncExternalStore(
    () => () => undefined,
    () => {
      if (typeof navigator === 'undefined') return 'audit_first' as const
      return pickDeterministicBucket(`${navigator.userAgent}_intent_router`) < 50 ? 'audit_first' : 'execution_first'
    },
    () => 'audit_first' as const,
  )

  useEffect(() => {
    void trackEvent({
      name: 'hero_impression',
      category: 'engagement',
      locale: language,
      variant,
    })
  }, [language, variant])

  const socialLinks = [
    { href: brand.githubUrl, icon: Github, label: 'GitHub' },
    { href: brand.linkedinUrl, icon: Linkedin, label: 'LinkedIn' },
    { href: brand.telegramUrl, icon: Send, label: 'Telegram' },
    { href: brand.instagramUrl, icon: Instagram, label: 'Instagram' },
    { href: brand.twitterUrl, icon: Twitter, label: 'X' },
  ].filter((item) => Boolean(item.href))

  const variantCopy = useMemo(() => {
    if (language === 'en') {
      if (variant === 'risk') {
        return {
          title: 'Stabilize your web system before the next incident',
          description:
            'I review architecture, release flow, and production dependencies to reduce operational risk and improve delivery confidence.',
          primaryCta: 'Start Discovery',
        }
      }
      return {
        title: 'Alireza Safaei | Web Systems Engineer',
        description:
          'From system design to production delivery. I help teams build stable, independent, and measurable web systems.',
        primaryCta: 'Request Project Assessment',
      }
    }

    if (variant === 'risk') {
      return {
        title: 'قبل از بحران بعدی، سیستم وب را پایدار کنید',
        description:
          'معماری، جریان انتشار و وابستگی های تولید را بازبینی می کنم تا ریسک عملیاتی کاهش پیدا کند و تحویل قابل اتکا بماند.',
        primaryCta: 'شروع جلسه Discovery',
      }
    }

    return {
      title: 'علیرضا صفایی | مهندس سیستم های وب',
      description:
        'بررسی فنی سایت + رفع مهم‌ترین ایرادهایی که روی اعتماد، سرعت، لید یا لانچ اثر می‌گذارند — در اسپرینت ثابت و کوتاه. از معماری و بومی‌سازی زیرساخت تا تحویل آماده تولید با شواهد قبل/بعد و گیت‌های کیفیت واقعی.',
      primaryCta: 'درخواست ارزیابی پروژه',
    }
  }, [language, variant])

  const capabilities =
    language === 'en'
      ? [
          { icon: ShieldCheck, label: 'Software architecture and delivery quality' },
          { icon: Rocket, label: 'From idea to production-ready product' },
          { icon: Wrench, label: 'Rescue and completion of incomplete projects' },
          { icon: Handshake, label: 'Collaboration with startups, private and public orgs' },
        ]
      : [
          { icon: ShieldCheck, label: 'معماری نرم افزار، طراحی سیستم و بهبود کیفیت تحویل' },
          { icon: Rocket, label: 'تبدیل ایده به محصول و آماده سازی کامل برای تولید' },
          { icon: Wrench, label: 'تکمیل پروژه های نیمه کاره و پایدارسازی وب سایت ها' },
          { icon: Handshake, label: 'همکاری با استارتاپ ها و سازمان های خصوصی و دولتی' },
        ]

  const collaborationFlow =
    language === 'en'
      ? ['Project context review', 'Architecture and roadmap', 'Execution and delivery hardening', 'Production handover and support']
      : ['شناخت دقیق مسئله و محدودیت ها', 'طراحی معماری و نقشه اجرای شفاف', 'پیاده سازی و کنترل کیفیت تحویل', 'آماده سازی تولید و پشتیبانی پس از تحویل']

  const pageRoadmap =
    language === 'en'
      ? ['Who I am', 'How I can help', 'Real case studies', 'Operational stabilization scope', 'Start your request']
      : ['معرفی من', 'مهارت ها و نحوه کمک', 'نمونه کارهای واقعی', 'دامنه پایدارسازی عملیاتی', 'ثبت درخواست همکاری']

  const trustPoints =
    language === 'en'
      ? ['Production-ready delivery path', 'Risk-aware architecture decisions', 'Localization and sanctions resilience']
      : ['مسیر تحویل آماده تولید', 'تصمیم های معماری مبتنی بر ریسک', 'بومی سازی زیرساخت و تاب آوری در محدودیت ها']
  const intentRoutes = useMemo<IntentRoute[]>(() => {
    const routesFa: Record<IntentRoute['key'], IntentRoute> = {
      audit: {
        key: 'audit',
        title: 'اول می خواهم وضعیت سایت را دقیق بررسی کنم + سریع فیکس کنم',
        detail: 'از Audit Systems گزارش عملی بگیرید و مهم‌ترین ایرادها را در اسپرینت ثابت ۵-۷ روزه برطرف کنید (با before/after واقعی).',
        href: '/offers/Audit-QuickFix-Offer-OnePage.pdf',
        external: false,
        cta: 'دریافت اسکوپ یک‌صفحه‌ای بررسی فنی + Quick Fix',
      },
      toolbox: {
        key: 'toolbox',
        title: 'الان ابزار فارسی سریع و امن لازم دارم',
        detail: 'برای کارهای روزمره از PersianToolbox با پردازش local-first استفاده کنید.',
        href: 'https://persiantoolbox.ir/?utm_source=portfolio&utm_medium=intent_router&utm_campaign=alireza_safaei_network&utm_content=hero_route',
        external: true,
        cta: 'ورود به PersianToolbox',
      },
      execution: {
        key: 'execution',
        title: 'برای اجرا و توسعه مستقیم کمک می خواهم',
        detail: 'فرم Qualification را باز کنید یا مستقیم اسکوپ ثابت Quick Fix Sprint را درخواست کنید (دانلود PDF) تا مسیر دقیق و سریع مشخص شود.',
        href: withLocale('/qualification', language),
        external: false,
        cta: 'شروع Qualification',
      },
    }
    const routesEn: Record<IntentRoute['key'], IntentRoute> = {
      audit: {
        key: 'audit',
        title: 'I need a technical audit + quick fixes first',
        detail: 'Get a practical report from Audit Systems and fix the highest-impact issues in a fixed 5-7 day sprint (with real before/after).',
        href: '/offers/Audit-QuickFix-Offer-OnePage.pdf',
        external: false,
        cta: 'Get the one-page Audit + Quick Fix scope',
      },
      toolbox: {
        key: 'toolbox',
        title: 'I need practical Persian tools',
        detail: 'Use PersianToolbox for local-first utilities without signup friction.',
        href: 'https://persiantoolbox.ir/?utm_source=portfolio&utm_medium=intent_router&utm_campaign=alireza_safaei_network&utm_content=hero_route',
        external: true,
        cta: 'Open PersianToolbox',
      },
      execution: {
        key: 'execution',
        title: 'I need direct execution support',
        detail: 'Start qualification or request the fixed-scope Quick Fix Sprint directly (PDF available) for a clear, fast path.',
        href: withLocale('/qualification', language),
        external: false,
        cta: 'Start Qualification',
      },
    }

    const source = language === 'en' ? routesEn : routesFa
    const order: IntentRoute['key'][] = intentVariant === 'execution_first' ? ['execution', 'audit', 'toolbox'] : ['audit', 'toolbox', 'execution']
    return order.map((key) => source[key])
  }, [intentVariant, language])

  useEffect(() => {
    void trackEvent({
      name: 'intent_router_impression',
      category: 'engagement',
      locale: language,
      variant: intentVariant,
      metadata: {
        section: 'hero',
      },
    })
  }, [intentVariant, language])

  return (
    <section id="home" className="relative overflow-hidden section-block subtle-grid">
      <div className="absolute inset-0 bg-gradient-to-b from-background via-background/70 to-background/95 pointer-events-none" />

      <div className="container mx-auto px-4 relative z-10">
        <div className="mx-auto max-w-6xl section-surface aurora-shell p-7 md:p-10 space-y-8">
          <div className="flex flex-wrap items-center gap-3">
            <p className="inline-flex items-center gap-2 rounded-full border border-border/70 bg-card/70 px-4 py-2 text-sm font-semibold">
              <CircleUserRound className="h-4 w-4 text-primary" />
              {language === 'en' ? 'Alireza Safaei | Web Systems Engineer' : 'علیرضا صفایی | مهندس سیستم های وب'}
            </p>
            <p className="inline-flex items-center gap-2 rounded-full border border-primary/25 bg-primary/10 px-4 py-2 text-sm font-medium">
              <span className="h-2 w-2 rounded-full bg-primary" />
              <span>{language === 'en' ? `Step 1 | ${t('hero.available')}` : `مرحله ۱ | ${t('hero.available')}`}</span>
            </p>
            <p className="inline-flex items-center gap-1 rounded-full border border-border/70 bg-card/70 px-4 py-2 text-sm text-muted-foreground">
              <MapPin className="h-3.5 w-3.5 text-primary" />
              {language === 'en' ? 'Tehran / Remote (Iran)' : 'تهران / همکاری ریموت در سراسر ایران'}
            </p>
          </div>

          <div className="space-y-4">
            <h1 className="headline-tight max-w-4xl text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight leading-tight">
              {variantCopy.title}
            </h1>
            <p className="max-w-3xl text-base md:text-lg text-muted-foreground text-copy">
              {variantCopy.description}
            </p>
            <p className="max-w-3xl text-sm text-muted-foreground/80 text-copy italic">
              {language === 'en'
                ? 'I build web systems that stay stable during crises, outages, sanctions, and user growth spikes.'
                : 'سایت و نرم‌افزار شما را طوری پایدار، امن و آماده رشد می‌کنم که در بحران، قطعی، تحریم یا افزایش کاربر از کار نیفتد.'}
            </p>
          </div>

          <div className="rounded-2xl border border-border/70 bg-card/60 p-4 md:p-5">
            <p className="text-sm font-semibold mb-3">
              {language === 'en' ? 'Page Roadmap' : 'مسیر این صفحه'}
            </p>
            <div className="grid gap-2 md:grid-cols-5">
              {pageRoadmap.map((item, index) => (
                <p key={item} className="rounded-lg border border-border/60 bg-background/70 px-3 py-2 text-xs md:text-sm text-muted-foreground inline-flex items-center gap-2">
                  <span className="inline-flex h-5 w-5 items-center justify-center rounded-full bg-primary/12 text-[11px] font-semibold text-primary">
                    {index + 1}
                  </span>
                  <span>{item}</span>
                </p>
              ))}
            </div>
          </div>

          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {capabilities.map((item) => (
              <div key={item.label} className="rounded-xl border border-border/70 bg-card/70 px-4 py-3 text-sm text-ui card-hover">
                <p className="inline-flex items-start gap-2">
                  <item.icon className="mt-0.5 h-4 w-4 text-primary" />
                  <span>{item.label}</span>
                </p>
              </div>
            ))}
          </div>

          <div className="rounded-xl border border-primary/20 bg-primary/5 p-4 text-sm text-muted-foreground text-copy">
            {language === 'en'
              ? 'Focused on infrastructure localization, production reliability, and practical resilience against external sanctions constraints.'
              : 'تمرکز اصلی: بومی سازی زیرساخت، پایداری عملیاتی تولید، و مقابله عملی با محدودیت های ناشی از تحریم های خارجی علیه ایران.'}
          </div>

          <div className="grid gap-2 md:grid-cols-3">
            {trustPoints.map((point) => (
              <p key={point} className="rounded-lg border border-border/70 bg-card/70 px-3 py-2 text-xs md:text-sm text-muted-foreground text-ui">
                {point}
              </p>
            ))}
          </div>

          {/* User Path Cards */}
          <div className="rounded-xl border border-border/70 bg-card/60 p-4 md:p-5 space-y-3">
            <p className="text-sm font-semibold">
              {language === 'en' ? 'What do you need?' : 'دقیقاً چه کمکی نیاز دارید؟'}
            </p>
            <div className="grid gap-3 md:grid-cols-3">
              <article className="rounded-lg border border-border/60 bg-background/75 p-4 text-sm">
                <h3 className="font-semibold text-foreground">
                  {language === 'en' ? 'My site is slow or unstable' : 'سایت کند یا ناپایدار دارم'}
                </h3>
                <p className="mt-1 text-muted-foreground text-ui">
                  {language === 'en' ? 'Get a quick technical audit and fix the most critical issues.' : 'دریافت Audit سریع و رفع مهم‌ترین ایرادها در اسپرینت ثابت.'}
                </p>
                <a
                  className="mt-3 inline-flex rounded-md border border-primary/40 bg-primary/10 px-3 py-1.5 text-xs font-semibold text-primary hover:bg-primary/20 transition-colors"
                  href="/offers/Audit-QuickFix-Offer-OnePage.pdf"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {language === 'en' ? 'Quick Audit' : 'دریافت گزارش سریع'}
                </a>
              </article>
              <article className="rounded-lg border border-border/60 bg-background/75 p-4 text-sm">
                <h3 className="font-semibold text-foreground">
                  {language === 'en' ? 'My project is half-done' : 'پروژه نیمه‌کاره دارم'}
                </h3>
                <p className="mt-1 text-muted-foreground text-ui">
                  {language === 'en' ? 'Code review, architecture analysis, and completion plan.' : 'بررسی کد، تحلیل معماری و برنامه تکمیل پروژه.'}
                </p>
                <a
                  className="mt-3 inline-flex rounded-md border border-primary/40 bg-primary/10 px-3 py-1.5 text-xs font-semibold text-primary hover:bg-primary/20 transition-colors"
                  href={withLocale('/qualification', language)}
                >
                  {language === 'en' ? 'Start Qualification' : 'شروع بررسی'}
                </a>
              </article>
              <article className="rounded-lg border border-border/60 bg-background/75 p-4 text-sm">
                <h3 className="font-semibold text-foreground">
                  {language === 'en' ? 'I want a new product' : 'محصول جدید می‌خواهم'}
                </h3>
                <p className="mt-1 text-muted-foreground text-ui">
                  {language === 'en' ? 'From idea to production-ready with architecture and delivery.' : 'از ایده تا آمادگی تولید با معماری و تحویل حرفه‌ای.'}
                </p>
                <a
                  className="mt-3 inline-flex rounded-md border border-primary/40 bg-primary/10 px-3 py-1.5 text-xs font-semibold text-primary hover:bg-primary/20 transition-colors"
                  href={withLocale('/qualification', language)}
                >
                  {language === 'en' ? 'Discovery Meeting' : 'جلسه Discovery'}
                </a>
              </article>
            </div>
          </div>

          <div className="space-y-3">
            <p className="text-sm font-semibold">
              {language === 'en' ? 'Collaboration Roadmap' : 'مسیر همکاری از شروع تا تحویل'}
            </p>
            <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
              {collaborationFlow.map((step, index) => (
                <div key={step} className="flex items-start gap-3 rounded-lg border border-border/70 bg-card/70 p-3">
                  <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-primary/12 text-xs font-semibold text-primary">
                    {index + 1}
                  </span>
                  <p className="text-sm text-muted-foreground text-ui">{step}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <Button
                size="lg"
                className="gap-2 shine-effect"
                onClick={() => {
                  void trackEvent({
                    name: 'hero_primary_click',
                    category: 'conversion',
                    locale: language,
                    variant,
                  })
                  router.push(withLocale('/qualification', language))
                }}
              >
                {variantCopy.primaryCta}
                <ArrowRight className={`h-4 w-4 ${language === 'fa' ? 'rotate-180' : ''}`} />
              </Button>

              <Button
                size="lg"
                variant="outline"
                className="gap-2 card-hover"
                onClick={() => {
                  void trackEvent({
                    name: 'hero_secondary_click',
                    category: 'engagement',
                    locale: language,
                    variant,
                  })
                  router.push(withLocale('/case-studies', language))
                }}
              >
                {t('hero.viewWork')}
              </Button>
            </div>

            <div className="flex flex-wrap gap-2">
              {socialLinks.map((social) => (
                <Button
                  key={social.label}
                  asChild
                  variant="ghost"
                  size="icon"
                  className="rounded-full hover:bg-primary/10 h-10 w-10 card-hover"
                >
                  <a href={social.href} target="_blank" rel="noopener noreferrer" aria-label={social.label}>
                    <social.icon className="h-4 w-4" />
                  </a>
                </Button>
              ))}
            </div>
          </div>

          <div id="intent-router" className="rounded-xl border border-border/70 bg-card/75 p-4 md:p-5 space-y-3">
            <p className="text-sm font-semibold">
              {language === 'en' ? 'Choose Your Fastest Path' : 'مسیر مناسب شما از همین‌جا'}
            </p>
            <div className="grid gap-3 md:grid-cols-3">
              {intentRoutes.map((route) => (
                <article key={route.title} className="rounded-lg border border-border/60 bg-background/75 p-3 text-sm">
                  <h3 className="font-semibold text-foreground">{route.title}</h3>
                  <p className="mt-1 text-muted-foreground text-ui">{route.detail}</p>
                  <a
                    className="mt-3 inline-flex rounded-md border border-border px-3 py-1.5 text-xs font-semibold hover:bg-muted transition-colors"
                    href={route.href}
                    target={route.external ? '_blank' : undefined}
                    rel={route.external ? 'noopener noreferrer' : undefined}
                    onClick={() => {
                      void trackEvent({
                        name: 'intent_router_click',
                        category: route.key === 'execution' ? 'conversion' : 'engagement',
                        locale: language,
                        variant: intentVariant,
                        metadata: {
                          route: route.key,
                          destination: route.external ? 'external' : 'internal',
                        },
                      })
                    }}
                  >
                    {route.cta}
                  </a>
                </article>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
