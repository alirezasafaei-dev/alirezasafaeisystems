import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowLeft, ArrowRight } from 'lucide-react'
import { db } from '@/lib/db'
import { discoverAnalyticsMetadata, extractDiscoverAttribution } from '@/lib/discover'
import { getRequestLanguage } from '@/lib/i18n/server'
import { getSiteUrl } from '@/lib/site-config'
import { generateBreadcrumbSchema } from '@/lib/seo'
import { DiscoverGrid, type DiscoverGridItem } from '@/components/discover/discover-grid'
import { DiscoverTelemetry } from '@/components/discover/discover-telemetry'
import { JsonLd } from '@/components/seo/json-ld'

const siteUrl = getSiteUrl()

type DiscoverPageProps = {
  searchParams: Promise<Record<string, string | string[] | undefined>>
}

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'
  const canonicalPath = isEn ? '/en/discover' : '/discover'
  return {
    title: isEn ? 'Discover Tools, Guides and Resources' : 'Discover | ابزارها، راهنماها و منابع',
    description: isEn
      ? 'Find the tools and resources mentioned in ASDEV social content, with official destinations, quick guides, and direct full-resource links when available.'
      : 'ابزارها و منابع معرفی‌شده در محتوای ASDEV؛ همراه با مقصد رسمی، راهنمای کوتاه و لینک مستقیم منبع کامل در صورت وجود.',
    alternates: {
      canonical: canonicalPath,
      languages: {
        'fa-IR': `${siteUrl}/discover`,
        'en-US': `${siteUrl}/en/discover`,
        'x-default': `${siteUrl}/discover`,
      },
    },
  }
}

export default async function DiscoverPage({ searchParams }: DiscoverPageProps) {
  const lang = await getRequestLanguage()
  const isEn = lang === 'en'
  const canonicalPath = isEn ? '/en/discover' : '/discover'
  const attribution = extractDiscoverAttribution(await searchParams)
  const records = await db.discoverItem.findMany({
    where: { published: true },
    select: {
      slug: true,
      title: true,
      description: true,
      category: true,
      tags: true,
      featured: true,
      imageUrl: true,
    },
    orderBy: [
      { featured: 'desc' },
      { order: 'asc' },
      { publishedAt: 'desc' },
      { createdAt: 'desc' },
    ],
  })

  const items: DiscoverGridItem[] = records.map((item) => ({
    ...item,
    tags: item.tags.split(',').map((tag) => tag.trim()).filter(Boolean),
  }))

  const copy = isEn
    ? {
        eyebrow: 'ASDEV Resource Hub',
        title: 'Find the tools and resources I mention on Instagram',
        description: 'Search a name, open its real official destination, read the quick guide, and use the full Telegram resource when one is available.',
        note: 'Use this page as the single link in my Instagram bio; no DM automation is required.',
        home: 'Back to home',
      }
    : {
        eyebrow: 'مرکز منابع ASDEV',
        title: 'ابزارها و منابعی که در اینستاگرام معرفی می‌کنم، اینجا پیدا کن',
        description: 'اسم ابزار را جستجو کن، به مقصد رسمی برو، راهنمای کوتاه را بخوان و اگر منبع کامل تلگرام موجود بود مستقیم همان را باز کن.',
        note: 'این صفحه مقصد ثابت لینک بیوی اینستاگرام است و برای دریافت منابع نیازی به اتوماسیون دایرکت نیست.',
        home: 'بازگشت به خانه',
      }

  const BackIcon = isEn ? ArrowLeft : ArrowRight

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <JsonLd data={generateBreadcrumbSchema([
        { name: isEn ? 'Home' : 'خانه', url: siteUrl },
        { name: 'Discover', url: `${siteUrl}${canonicalPath}` },
      ])} />
      <DiscoverTelemetry
        name="discover_landing_view"
        locale={isEn ? 'en' : 'fa'}
        metadata={discoverAnalyticsMetadata(attribution, { surface: 'discover' })}
      />

      <section className="mx-auto max-w-6xl space-y-8">
        <header className="section-surface aurora-shell space-y-4 p-6 md:p-10">
          <p className="text-sm font-semibold text-primary">{copy.eyebrow}</p>
          <h1 className="headline-tight max-w-4xl text-3xl font-bold md:text-5xl">{copy.title}</h1>
          <p className="max-w-4xl text-base leading-8 text-muted-foreground md:text-lg">{copy.description}</p>
          <p className="max-w-4xl text-xs leading-6 text-muted-foreground">{copy.note}</p>
        </header>

        <DiscoverGrid items={items} attribution={attribution} isEn={isEn} />

        <Link
          href={isEn ? '/en/' : '/'}
          className="inline-flex items-center gap-2 text-sm text-muted-foreground underline underline-offset-4"
        >
          <BackIcon className="h-4 w-4" />
          {copy.home}
        </Link>
      </section>
    </main>
  )
}
