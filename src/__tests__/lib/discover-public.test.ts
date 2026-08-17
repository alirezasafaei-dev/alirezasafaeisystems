import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'

function source(path: string): string {
  return readFileSync(path, 'utf8')
}

describe('Discover public data contract', () => {
  it('queries only published items for the landing and exposes a bounded public card shape', () => {
    const landing = source('src/app/discover/page.tsx')

    expect(landing).toContain('where: { published: true }')
    expect(landing).toContain('slug: true')
    expect(landing).toContain('title: true')
    expect(landing).toContain('description: true')
    expect(landing).toContain('category: true')
    expect(landing).toContain('tags: true')
    expect(landing).toContain('featured: true')
    expect(landing).toContain('imageUrl: true')
    expect(landing).not.toContain('externalUrl: true')
    expect(landing).not.toContain('content: true')
  })

  it('404s unpublished detail items and keeps related-item queries published-only', () => {
    const detail = source('src/app/discover/[slug]/page.tsx')
    const lookupIndex = detail.indexOf('const item = await db.discoverItem.findUnique({ where: { slug } })')
    const publishedGuardIndex = detail.indexOf('if (!item?.published) notFound()', lookupIndex)
    const relatedIndex = detail.indexOf('const related = await db.discoverItem.findMany', publishedGuardIndex)
    const relatedPublishedIndex = detail.indexOf('published: true', relatedIndex)

    expect(lookupIndex).toBeGreaterThan(-1)
    expect(publishedGuardIndex).toBeGreaterThan(lookupIndex)
    expect(relatedIndex).toBeGreaterThan(publishedGuardIndex)
    expect(relatedPublishedIndex).toBeGreaterThan(relatedIndex)
  })

  it('keeps external destinations separate from internal UTM propagation', () => {
    const detail = source('src/app/discover/[slug]/page.tsx')

    expect(detail).toContain('href={item.externalUrl}')
    expect(detail).toContain('href={item.instagramUrl}')
    expect(detail).toContain("appendDiscoverAttribution(isEn ? '/en/qualification' : '/qualification', attribution)")
    expect(detail).not.toContain('appendDiscoverAttribution(item.externalUrl')
    expect(detail).not.toContain('appendDiscoverAttribution(item.instagramUrl')
  })
})
