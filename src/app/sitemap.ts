import type { MetadataRoute } from 'next'
import { getSiteUrl } from '@/lib/site-config'
import manifest from '@/generated/sitemap-manifest.json'

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = getSiteUrl()

  return (manifest as Array<{
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
}
