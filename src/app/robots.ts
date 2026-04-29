import type { MetadataRoute } from 'next'
import { getSiteUrl } from '@/lib/site-config'

export default function robots(): MetadataRoute.Robots {
  const baseUrl = getSiteUrl()
  const host = new URL(baseUrl).host

  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/api/', '/admin/', '/private/'],
    },
    sitemap: `${baseUrl}/sitemap.xml`,
    host,
  }
}
