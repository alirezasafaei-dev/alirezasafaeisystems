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
    expect(detail).toContain('href={item.telegramGuideUrl}')
    expect(detail).toContain('href={telegramChannelUrl}')
    expect(detail).toContain('href={telegramGroupUrl}')
    expect(detail).toContain("appendDiscoverAttribution(isEn ? '/en/qualification' : '/qualification', attribution)")
    expect(detail).not.toContain('appendDiscoverAttribution(item.externalUrl')
    expect(detail).not.toContain('appendDiscoverAttribution(item.instagramUrl')
    expect(detail).not.toContain('appendDiscoverAttribution(item.telegramGuideUrl')
    expect(detail).not.toContain('appendDiscoverAttribution(telegramChannelUrl')
    expect(detail).not.toContain('appendDiscoverAttribution(telegramGroupUrl')
  })

  it('emits distinct Telegram destination events with resource-first source order', () => {
    const detail = source('src/app/discover/[slug]/page.tsx')

    expect(detail).toContain('discover_telegram_guide_click')
    expect(detail).toContain('discover_telegram_channel_click')
    expect(detail).toContain('discover_telegram_group_click')

    const officialIndex = detail.indexOf('href={item.externalUrl}')
    const telegramGuideIndex = detail.indexOf('href={item.telegramGuideUrl}')
    const relatedHeadingIndex = detail.indexOf('{copy.related}')
    const asdevHeadingIndex = detail.indexOf('{copy.asdev}')

    expect(officialIndex).toBeGreaterThan(-1)
    expect(telegramGuideIndex).toBeGreaterThan(officialIndex)
    expect(relatedHeadingIndex).toBeGreaterThan(telegramGuideIndex)
    expect(asdevHeadingIndex).toBeGreaterThan(relatedHeadingIndex)
  })

  it('localizes the featured badge on the detail page', () => {
    const detail = source('src/app/discover/[slug]/page.tsx')

    expect(detail).toContain("featured: 'Featured'")
    expect(detail).toContain("featured: 'منتخب'")
    expect(detail).toContain('{copy.featured}')
    expect(detail).not.toContain('> Featured\n')
  })
})