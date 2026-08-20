import type { MetadataRoute } from 'next'
import { db } from '@/lib/db'
import { getSiteUrl } from '@/lib/site-config'
import manifest from '@/generated/sitemap-manifest.json'

export const dynamic = 'force-dynamic'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = getSiteUrl()
  const staticEntries: MetadataRoute.Sitemap = (manifest as Array<{
    route: string
    lastModified: string
    priority: number
    changeFrequency: 'weekly' | 'monthly'
  }>).map((entry) => {
    const faPath = entry.route
    const enPath = entry.route.replace(/^\/fa(?=\/|$)/, '/en')
    return {
      url: `${baseUrl}${faPath}`,
      lastModified: entry.lastModified,
      changeFrequency: entry.changeFrequency,
      priority: entry.priority,
      alternates: {
        languages: {
          'fa-IR': `${baseUrl}${faPath}`,
          'en-US': `${baseUrl}${enPath}`,
          'x-default': `${baseUrl}${faPath}`,
        },
      },
    }
  })

  if (!process.env.DATABASE_URL || process.env.ASDEV_BUILD_SKIP_DYNAMIC_DB === '1') {
    return staticEntries
  }

  try {
    const discoverItems = await db.discoverItem.findMany({
      where: { OR: [{ published: true }, { publishedEn: true }] },
      select: { slug: true, published: true, publishedEn: true, updatedAt: true },
      orderBy: { updatedAt: 'desc' },
    })

    const discoverEntries: MetadataRoute.Sitemap = discoverItems.flatMap((item) => {
      const faPath = `/fa/discover/${item.slug}`
      const enPath = `/en/discover/${item.slug}`
      const languages: Record<string, string> = {}
      if (item.published) languages['fa-IR'] = `${baseUrl}${faPath}`
      if (item.publishedEn) languages['en-US'] = `${baseUrl}${enPath}`
      if (item.published) languages['x-default'] = `${baseUrl}${faPath}`
      return [
        ...(item.published ? [{
          url: `${baseUrl}${faPath}`,
          lastModified: item.updatedAt,
          changeFrequency: 'weekly' as const,
          priority: 0.78,
          alternates: { languages },
        }] : []),
        ...(item.publishedEn ? [{
          url: `${baseUrl}${enPath}`,
          lastModified: item.updatedAt,
          changeFrequency: 'weekly' as const,
          priority: 0.78,
          alternates: { languages },
        }] : []),
      ]
    })

    return [...staticEntries, ...discoverEntries]
  } catch {
    // A build without a reachable content database must still expose the static sitemap.
    return staticEntries
  }
}
