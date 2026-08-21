import type { Metadata } from 'next'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { ArrowLeft, ArrowRight, ExternalLink, Instagram, Sparkles } from 'lucide-react'
import { db } from '@/lib/db'
import {
  appendDiscoverAttribution,
  discoverAnalyticsMetadata,
  extractDiscoverAttribution,
  isDiscoverEnglishPublic,
} from '@/lib/discover'
import { env } from '@/lib/env'
import { getRequestLanguage } from '@/lib/i18n/server'
import { translations } from '@/lib/i18n/translations'
import { getSafeDiscoverCategoryLabel } from '@/lib/discover-categories'
import { generateBreadcrumbSchema, generateDiscoverEditorialSchema } from '@/lib/seo'
import { getSiteUrl } from '@/lib/site-config'
import { DiscoverLink } from '@/components/discover/discover-link'
import { DiscoverTelemetry } from '@/components/discover/discover-telemetry'
import { JsonLd } from '@/components/seo/json-ld'

const siteUrl = getSiteUrl()

type DiscoverDetailProps = {
  params: Promise<{ slug: string }>
  searchParams: Promise<Record<string, string | string[] | undefined>>
}

function getEffectiveDetailContent(item: {
  title: string
  description: string
  content: string
  published: boolean
  titleEn: string | null
  descriptionEn: string | null
  contentEn: string | null
  publishedEn: boolean
}, isEn: boolean) {
  if (!isEn) {
    return item.published ? { title: item.title, description: item.description, content: item.content } : null
  }

  if (!isDiscoverEnglishPublic(item)) return null
  return { title: item.titleEn, description: item.descriptionEn, content: item.contentEn }
}

export async function generateMetadata({ params }: Pick<DiscoverDetailProps, 'params'>): Promise<Metadata> {
  const { slug } = await params
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'
  const item = await db.discoverItem.findUnique({
    where: { slug },
    select: { title: true, description: true, content: true, published: true, titleEn: true, descriptionEn: true, contentEn: true, publishedEn: true },
  })

  const content = item && getEffectiveDetailContent(item, isEn)
  if (!content) {
    return {
      title: 'Discover',
      robots: { index: false, follow: false },
    }
  }

  const canonicalPath = isEn ? `/en/discover/${slug}` : `/discover/${slug}`
  const { title, description } = content
  const englishPublic = isDiscoverEnglishPublic(item)
  const languages: Record<string, string> = {}
  if (item.published) languages['fa-IR'] = `${siteUrl}/discover/${slug}`
  if (englishPublic) languages['en-US'] = `${siteUrl}/en/discover/${slug}`
  if (item.published) languages['x-default'] = `${siteUrl}/discover/${slug}`
  return {
    title: `${title} | Discover`,
    description,
    alternates: {
      canonical: canonicalPath,
      languages,
    },
    openGraph: {
      title,
      description,
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

  const effectiveContent = item && getEffectiveDetailContent(item, isEn)
  if (!item || !effectiveContent) notFound()

  const { title, description, content } = effectiveContent

  const related = (await db.discoverItem.findMany({
    where: {
      ...(isEn ? { publishedEn: true } : { published: true }),
      category: item.category,
      id: { not: item.id },
    },
    select: { slug: true, title: true, description: true, titleEn: true, descriptionEn: true, contentEn: true, publishedEn: true },
    orderBy: [{ featured: 'desc' }, { order: 'asc' }, { publishedAt: 'desc' }],
    take: isEn ? 12 : 3,
  })).filter((relatedItem) => !isEn || isDiscoverEnglishPublic(relatedItem)).slice(0, 3)

  const canonicalPath = isEn ? `/en/discover/${slug}` : `/discover/${slug}`
  const tags = item.tags.split(',').map((tag) => tag.trim()).filter(Boolean)
  const paragraphs = content
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

  const copy = translations[lang].discover.detail
  const editorialSchema = generateDiscoverEditorialSchema({
    title,
    description,
    url: `${siteUrl}${canonicalPath}`,
    publishDate: (item.publishedAt || item.createdAt).toISOString(),
    modifiedDate: item.updatedAt.toISOString(),
    language: isEn ? 'en-US' : 'fa-IR',
  })

  const BackIcon = isEn ? ArrowLeft : ArrowRight
  const telemetryMetadata = discoverAnalyticsMetadata(attribution, {
    slug: item.slug,
    category: item.category,
  })

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <JsonLd data={generateBreadcrumbSchema([
        { name: isEn ? 'Home' : 'خانه', url: siteUrl },
        { name: copy.breadcrumb, url: `${siteUrl}${isEn ? '/en/discover' : '/discover'}` },
        { name: title, url: `${siteUrl}${canonicalPath}` },
      ])} />
      <JsonLd data={editorialSchema} />
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
              <span className="rounded-full border px-3 py-1 text-xs text-muted-foreground">{getSafeDiscoverCategoryLabel(item.category, locale)}</span>
              {item.featured ? (
                <span className="inline-flex items-center gap-1 text-xs font-semibold text-primary">
                  <Sparkles className="h-3.5 w-3.5" /> {copy.featured}
                </span>
              ) : null}
            </div>
            <h1 className="headline-tight text-3xl font-bold md:text-5xl">{title}</h1>
            <p className="text-base leading-8 text-muted-foreground md:text-lg">{description}</p>
            <div className="flex flex-wrap gap-2">
              {tags.map((tag) => (
                <span key={tag} className="rounded-full bg-muted px-2.5 py-1 text-xs text-muted-foreground">#{tag}</span>
              ))}
            </div>
          </div>
        </header>

        <section className="section-surface space-y-5 p-6 md:p-8">
          <h2 className="text-2xl font-bold">{copy.guide}</h2>
          <div className="space-y-4 text-[15px] leading-8 text-muted-foreground" dir={isEn ? 'ltr' : 'rtl'}>
            {paragraphs.map((paragraph, index) => (
              <p key={`${item.slug}-paragraph-${index}`} role={/official DeepSeek|رسمی DeepSeek نیست/.test(paragraph) ? 'note' : undefined} className={/official DeepSeek|رسمی DeepSeek نیست/.test(paragraph) ? 'font-medium text-foreground' : undefined}>{paragraph}</p>
            ))}
          </div>

          <div className="flex flex-wrap gap-3 pt-2">
            <DiscoverLink
              href={item.externalUrl}
              external
              locale={locale}
              eventName="discover_external_click"
              metadata={{ ...telemetryMetadata, target: 'external_resource' }}
              className="inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:opacity-90"
            >
              {copy.openResource}
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
                    <h3 className="font-semibold">{isEn ? relatedItem.titleEn || '' : relatedItem.title}</h3>
                    <p className="mt-2 line-clamp-2 text-xs leading-6 text-muted-foreground">{isEn ? relatedItem.descriptionEn || '' : relatedItem.description}</p>
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
