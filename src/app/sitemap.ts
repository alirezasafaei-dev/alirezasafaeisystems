import type { MetadataRoute } from 'next'
import { db } from '@/lib/db'
import { getSiteUrl } from '@/lib/site-config'
import manifest from '@/generated/sitemap-manifest.json'

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

  if (!process.env.DATABASE_URL) return staticEntries

  try {
    const discoverItems = await db.discoverItem.findMany({
      where: { published: true },
      select: { slug: true, updatedAt: true },
      orderBy: { updatedAt: 'desc' },
    })

    const discoverEntries: MetadataRoute.Sitemap = discoverItems.map((item) => {
      const faPath = `/fa/discover/${item.slug}`
      const enPath = `/en/discover/${item.slug}`
      return {
        url: `${baseUrl}${faPath}`,
        lastModified: item.updatedAt,
        changeFrequency: 'weekly',
        priority: 0.78,
        alternates: {
          languages: {
            'fa-IR': `${baseUrl}${faPath}`,
            'en-US': `${baseUrl}${enPath}`,
            'x-default': `${baseUrl}${faPath}`,
          },
        },
      }
    })

    return [...staticEntries, ...discoverEntries]
  } catch {
    // A build without a reachable content database must still expose the static sitemap.
    return staticEntries
  }
}
