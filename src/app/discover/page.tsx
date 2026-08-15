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
    title: isEn ? 'Discover Useful Apps, Tools and Services' : 'Discover | ابزارها، برنامه‌ها و سرویس‌های کاربردی',
    description: isEn
      ? 'Apps, AI tools, online services and platforms introduced by Alireza Safaei, with short guidance and official links.'
      : 'ابزارها، برنامه‌ها، سرویس‌ها و پلتفرم‌هایی که در محتوای علیرضا صفایی معرفی می‌شوند؛ همراه با توضیح کوتاه و لینک رسمی.',
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
        eyebrow: 'From social discovery to useful context',
        title: 'Everything I introduce on Instagram, collected here with the real link',
        description: 'Apps, AI tools, online services and useful platforms I share on social media—without the one-link limitation. Open an item to get a short practical explanation, the official link, and related ASDEV resources.',
        note: 'Discover is curated, not a paid ranking. External tools belong to their respective owners.',
        home: 'Back to home',
      }
    : {
        eyebrow: 'از معرفی در اینستاگرام تا توضیح و لینک واقعی',
        title: 'چیزهایی که در اینستاگرام معرفی می‌کنم، اینجا کامل‌تر ببین',
        description: 'برنامه‌ها، ابزارهای هوش مصنوعی، سرویس‌های آنلاین و پلتفرم‌های کاربردی که در محتوای اینستاگرام معرفی می‌کنم؛ بدون محدودیت لینک. هر مورد یک توضیح کوتاه و کاربردی، لینک رسمی و مسیرهای مرتبط در ASDEV دارد.',
        note: 'Discover یک مجموعهٔ منتخب است، نه رتبه‌بندی پولی. مالکیت سرویس‌های خارجی متعلق به ارائه‌دهندگان خودشان است.',
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
