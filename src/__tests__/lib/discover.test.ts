import { describe, expect, it } from 'vitest'
import {
  appendDiscoverAttribution,
  discoverInstagramUrlSchema,
  discoverSlugSchema,
  discoverTagsSchema,
  discoverUpdateSchema,
  discoverUrlSchema,
  extractDiscoverAttribution,
} from '@/lib/discover'

describe('Discover content contracts', () => {
  it('accepts SEO-safe slugs and rejects ambiguous slug formats', () => {
    expect(discoverSlugSchema.parse('notebooklm-guide')).toBe('notebooklm-guide')
    expect(discoverSlugSchema.safeParse('Notebook LM').success).toBe(false)
    expect(discoverSlugSchema.safeParse('-notebooklm').success).toBe(false)
    expect(discoverSlugSchema.safeParse('notebooklm-').success).toBe(false)
  })

  it('normalizes and deduplicates tags and caps the list at 20', () => {
    expect(discoverTagsSchema.parse(' AI, productivity, AI,  tools ')).toEqual([
      'AI',
      'productivity',
      'tools',
    ])

    const tooMany = Array.from({ length: 21 }, (_, index) => `tag-${index}`)
    expect(discoverTagsSchema.safeParse(tooMany).success).toBe(false)
  })

  it('requires credential-free HTTPS external URLs', () => {
    expect(discoverUrlSchema.parse('https://example.com/tool')).toBe('https://example.com/tool')
    expect(discoverUrlSchema.safeParse('http://example.com/tool').success).toBe(false)
    expect(discoverUrlSchema.safeParse('https://user:password@example.com/tool').success).toBe(false)
  })

  it('accepts only Instagram HTTPS URLs for the optional source post', () => {
    expect(discoverInstagramUrlSchema.parse('https://www.instagram.com/reel/abc/')).toBe(
      'https://www.instagram.com/reel/abc/'
    )
    expect(discoverInstagramUrlSchema.safeParse('https://example.com/reel/abc').success).toBe(false)
  })

  it('accepts and clears the optional exact Telegram guide URL', () => {
    expect(discoverUpdateSchema.parse({
      id: 'discover_12345',
      telegramGuideUrl: 'https://t.me/asdev/123',
    })).toEqual({
      id: 'discover_12345',
      telegramGuideUrl: 'https://t.me/asdev/123',
    })

    expect(discoverUpdateSchema.parse({
      id: 'discover_12345',
      telegramGuideUrl: '',
    })).toEqual({
      id: 'discover_12345',
      telegramGuideUrl: null,
    })
  })

  it('does not inject create defaults into partial updates', () => {
    expect(discoverUpdateSchema.parse({
      id: 'discover_12345',
      published: true,
    })).toEqual({
      id: 'discover_12345',
      published: true,
    })
  })

  it('extracts only bounded approved UTM values', () => {
    const params = new URLSearchParams({
      utm_source: ' instagram ',
      utm_medium: 'social',
      utm_campaign: 'notebooklm-launch',
      utm_content: 'reel-42',
      email: 'should-not-copy@example.com',
      arbitrary: 'nope',
    })

    expect(extractDiscoverAttribution(params)).toEqual({
      utm_source: 'instagram',
      utm_medium: 'social',
      utm_campaign: 'notebooklm-launch',
      utm_content: 'reel-42',
    })
  })

  it('preserves only approved attribution on internal paths', () => {
    const href = appendDiscoverAttribution('/qualification?ref=discover', {
      utm_source: 'instagram',
      utm_medium: 'social',
      utm_campaign: 'ai-tools',
    })

    const parsed = new URL(href, 'https://alirezasafaeisystems.ir')
    expect(parsed.pathname).toBe('/qualification')
    expect(parsed.searchParams.get('ref')).toBe('discover')
    expect(parsed.searchParams.get('utm_source')).toBe('instagram')
    expect(parsed.searchParams.get('utm_medium')).toBe('social')
    expect(parsed.searchParams.get('utm_campaign')).toBe('ai-tools')
  })
})
