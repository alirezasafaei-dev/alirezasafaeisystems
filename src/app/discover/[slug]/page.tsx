import type { Metadata } from 'next'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { ArrowLeft, ArrowRight, ExternalLink, Instagram, Sparkles } from 'lucide-react'
import { db } from '@/lib/db'
import {
  appendDiscoverAttribution,
  discoverAnalyticsMetadata,
  extractDiscoverAttribution,
} from '@/lib/discover'
import { env } from '@/lib/env'
import { getRequestLanguage } from '@/lib/i18n/server'
import { generateBreadcrumbSchema } from '@/lib/seo'
import { getSiteUrl } from '@/lib/site-config'
import { DiscoverLink } from '@/components/discover/discover-link'
import { DiscoverTelemetry } from '@/components/discover/discover-telemetry'
import { JsonLd } from '@/components/seo/json-ld'

const siteUrl = getSiteUrl()

type DiscoverDetailProps = {
  params: Promise<{ slug: string }>
  searchParams: Promise<Record<string, string | string[] | undefined>>
}

export async function generateMetadata({ params }: Pick<DiscoverDetailProps, 'params'>): Promise<Metadata> {
  const { slug } = await params
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'
  const item = await db.discoverItem.findUnique({
    where: { slug },
    select: { title: true, description: true, published: true },
  })

  if (!item?.published) {
    return {
      title: 'Discover',
      robots: { index: false, follow: false },
    }
  }

  const canonicalPath = isEn ? `/en/discover/${slug}` : `/discover/${slug}`
  return {
    title: `${item.title} | Discover`,
    description: item.description,
    alternates: {
      canonical: canonicalPath,
      languages: {
        'fa-IR': `${siteUrl}/discover/${slug}`,
        'en-US': `${siteUrl}/en/discover/${slug}`,
        'x-default': `${siteUrl}/discover/${slug}`,
      },
    },
    openGraph: {
      title: item.title,
      description: item.description,
      url: `${siteUrl}${canonicalPath}`,
      type: 'article',
    },
  }
}

export default async function DiscoverDetailPage({ params, searchParams }: DiscoverDetailProps) {
  const [{ slug }, query, lang] = await Promise.all([params, searchParams, getRequestLanguage()])
  const isEn = lang === 'en'
  const attribution = extractDiscoverAttribution(query)
  const item = await db.discoverItem.findUnique({ where: { slug } })

  if (!item?.published) notFound()

  const related = await db.discoverItem.findMany({
    where: {
      published: true,
      category: item.category,
      id: { not: item.id },
    },
    select: { slug: true, title: true, description: true },
    orderBy: [{ featured: 'desc' }, { order: 'asc' }, { publishedAt: 'desc' }],
    take: 3,
  })

  const canonicalPath = isEn ? `/en/discover/${slug}` : `/discover/${slug}`
  const tags = item.tags.split(',').map((tag) => tag.trim()).filter(Boolean)
  const paragraphs = item.content
    .split(/\n{2,}/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean)

  const discoverBack = appendDiscoverAttribution(isEn ? '/en/discover' : '/discover', attribution)
  const qualificationHref = appendDiscoverAttribution(isEn ? '/en/qualification' : '/qualification', attribution)
  const auditHref = appendDiscoverAttribution(isEn ? '/en/audit-readiness' : '/audit-readiness', attribution)
  const caseStudiesHref = appendDiscoverAttribution(isEn ? '/en/case-studies' : '/case-studies', attribution)
  const telegramChannelUrl = env.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL
  const telegramGroupUrl = env.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL
  const locale = isEn ? 'en' : 'fa'

  const copy = isEn
    ? {
        back: 'Back to Discover',
        guide: 'Quick practical guide',
        official: 'Open official website',
        telegramGuide: 'Full tutorial / file on Telegram',
        telegramChannel: 'Browse the Telegram channel',
        telegramGroup: 'Ask a question in the Telegram group',
        instagram: 'View the Instagram post',
        related: 'Related Discover items',
        featured: 'Featured',
        asdev: 'Continue inside ASDEV',
        asdevDescription: 'If this resource was useful, you can also explore the systems I build, case studies, and the technical audit path for real websites.',
        audit: 'Website Audit readiness',
        cases: 'View case studies',
        qualify: 'Start a project inquiry',
        disclosure: 'External products belong to their respective owners. This page provides editorial context and the official destination link.',
      }
    : {
        back: 'بازگشت به Discover',
        guide: 'راهنمای کوتاه و کاربردی',
        official: 'باز کردن سایت رسمی',
        telegramGuide: 'آموزش کامل / فایل در تلگرام',
        telegramChannel: 'مشاهده کانال تلگرام',
        telegramGroup: 'پرسش در گروه تلگرام',
        instagram: 'دیدن پست اینستاگرام',
        related: 'موارد مشابه در Discover',
        featured: 'منتخب',
        asdev: 'ادامه در ASDEV',
        asdevDescription: 'اگر این منبع برایت مفید بود، می‌توانی سیستم‌هایی که می‌سازم، Case Studyها و مسیر بررسی فنی سایت را هم ببینی.',
        audit: 'بررسی آمادگی سایت برای Audit',
        cases: 'دیدن Case Studyها',
        qualify: 'شروع درخواست همکاری',
        disclosure: 'مالکیت سرویس خارجی متعلق به ارائه‌دهندهٔ آن است. این صفحه فقط توضیح تحریری و لینک مقصد رسمی را ارائه می‌کند.',
      }

  const BackIcon = isEn ? ArrowLeft : ArrowRight
  const telemetryMetadata = discoverAnalyticsMetadata(attribution, {
    slug: item.slug,
    category: item.category,
  })

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <JsonLd data={generateBreadcrumbSchema([
        { name: isEn ? 'Home' : 'خانه', url: siteUrl },
        { name: 'Discover', url: `${siteUrl}${isEn ? '/en/discover' : '/discover'}` },
        { name: item.title, url: `${siteUrl}${canonicalPath}` },
      ])} />
      <DiscoverTelemetry name="discover_item_view" locale={locale} metadata={telemetryMetadata} />

      <article className="mx-auto max-w-4xl space-y-8">
        <Link href={discoverBack} className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground">
          <BackIcon className="h-4 w-4" />
          {copy.back}
        </Link>

        <header className="section-surface aurora-shell overflow-hidden">
          {item.imageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={item.imageUrl} alt="" className="max-h-[420px] w-full border-b object-cover" />
          ) : null}
          <div className="space-y-5 p-6 md:p-10">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full border px-3 py-1 text-xs text-muted-foreground">{item.category}</span>
              {item.featured ? (
                <span className="inline-flex items-center gap-1 text-xs font-semibold text-primary">
                  <Sparkles className="h-3.5 w-3.5" /> {copy.featured}
                </span>
              ) : null}
            </div>
            <h1 className="headline-tight text-3xl font-bold md:text-5xl">{item.title}</h1>
            <p className="text-base leading-8 text-muted-foreground md:text-lg">{item.description}</p>
            <div className="flex flex-wrap gap-2">
              {tags.map((tag) => (
                <span key={tag} className="rounded-full bg-muted px-2.5 py-1 text-xs text-muted-foreground">#{tag}</span>
              ))}
            </div>
          </div>
        </header>

        <section className="section-surface space-y-5 p-6 md:p-8">
          <h2 className="text-2xl font-bold">{copy.guide}</h2>
          <div className="space-y-4 text-[15px] leading-8 text-muted-foreground">
            {paragraphs.map((paragraph, index) => (
              <p key={`${item.slug}-paragraph-${index}`}>{paragraph}</p>
            ))}
          </div>

          <div className="flex flex-wrap gap-3 pt-2">
            <DiscoverLink
              href={item.externalUrl}
              external
              locale={locale}
              eventName="discover_external_click"
              metadata={{ ...telemetryMetadata, target: 'official' }}
              className="inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:opacity-90"
            >
              {copy.official}
              <ExternalLink className="h-4 w-4" />
            </DiscoverLink>

            {item.telegramGuideUrl ? (
              <DiscoverLink
                href={item.telegramGuideUrl}
                external
                locale={locale}
                eventName="discover_telegram_guide_click"
                metadata={{ ...telemetryMetadata, target: 'telegram_guide' }}
                className="inline-flex items-center gap-2 rounded-xl border border-primary/40 bg-primary/5 px-5 py-3 text-sm font-semibold transition hover:bg-primary/10"
              >
                {copy.telegramGuide}
                <ExternalLink className="h-4 w-4" />
              </DiscoverLink>
            ) : null}

            {telegramChannelUrl ? (
              <DiscoverLink
                href={telegramChannelUrl}
                external
                locale={locale}
                eventName="discover_telegram_channel_click"
                metadata={{ ...telemetryMetadata, target: 'telegram_channel' }}
                className="inline-flex items-center gap-2 rounded-xl border px-5 py-3 text-sm font-semibold transition hover:bg-muted"
              >
                {copy.telegramChannel}
                <ExternalLink className="h-4 w-4" />
              </DiscoverLink>
            ) : null}

            {telegramGroupUrl ? (
              <DiscoverLink
                href={telegramGroupUrl}
                external
                locale={locale}
                eventName="discover_telegram_group_click"
                metadata={{ ...telemetryMetadata, target: 'telegram_group' }}
                className="inline-flex items-center gap-2 rounded-xl border px-5 py-3 text-sm font-semibold transition hover:bg-muted"
              >
                {copy.telegramGroup}
                <ExternalLink className="h-4 w-4" />
              </DiscoverLink>
            ) : null}

            {item.instagramUrl ? (
              <DiscoverLink
                href={item.instagramUrl}
                external
                locale={locale}
                eventName="discover_external_click"
                metadata={{ ...telemetryMetadata, target: 'instagram_source' }}
                className="inline-flex items-center gap-2 rounded-xl border px-5 py-3 text-sm font-semibold transition hover:bg-muted"
              >
                <Instagram className="h-4 w-4" />
                {copy.instagram}
              </DiscoverLink>
            ) : null}
          </div>
          <p className="text-xs leading-6 text-muted-foreground">{copy.disclosure}</p>
        </section>

        {related.length > 0 ? (
          <section className="space-y-4">
            <h2 className="text-xl font-bold">{copy.related}</h2>
            <div className="grid gap-3 md:grid-cols-3">
              {related.map((relatedItem) => {
                const href = appendDiscoverAttribution(
                  isEn ? `/en/discover/${relatedItem.slug}` : `/discover/${relatedItem.slug}`,
                  attribution,
                )
                return (
                  <Link key={relatedItem.slug} href={href} className="rounded-xl border bg-card p-4 transition hover:bg-muted/50">
                    <h3 className="font-semibold">{relatedItem.title}</h3>
                    <p className="mt-2 line-clamp-2 text-xs leading-6 text-muted-foreground">{relatedItem.description}</p>
                  </Link>
                )
              })}
            </div>
          </section>
        ) : null}

        <section className="rounded-2xl border border-dashed bg-muted/20 p-6 md:p-8">
          <h2 className="text-lg font-semibold">{copy.asdev}</h2>
          <p className="mt-3 max-w-3xl text-sm leading-7 text-muted-foreground">{copy.asdevDescription}</p>
          <div className="mt-5 flex flex-wrap gap-3">
            <DiscoverLink
              href={auditHref}
              locale={locale}
              eventName="discover_internal_cta_click"
              metadata={{ ...telemetryMetadata, target: 'audit_readiness' }}
              className="rounded-xl border px-4 py-2.5 text-sm font-semibold hover:bg-muted"
            >
              {copy.audit}
            </DiscoverLink>
            <DiscoverLink
              href={caseStudiesHref}
              locale={locale}
              eventName="discover_internal_cta_click"
              metadata={{ ...telemetryMetadata, target: 'case_studies' }}
              className="rounded-xl border px-4 py-2.5 text-sm font-semibold hover:bg-muted"
            >
              {copy.cases}
            </DiscoverLink>
            <DiscoverLink
              href={qualificationHref}
              locale={locale}
              eventName="discover_internal_cta_click"
              metadata={{ ...telemetryMetadata, target: 'qualification' }}
              className="rounded-xl border px-4 py-2.5 text-sm font-semibold hover:bg-muted"
            >
              {copy.qualify}
            </DiscoverLink>
          </div>
        </section>
      </article>
    </main>
  )
}
