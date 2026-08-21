import { describe, expect, it } from 'vitest'
import {
  appendDiscoverAttribution,
  discoverCreateSchema,
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
    expect(discoverUpdateSchema.safeParse({
      id: 'discover_12345',
      publishedEn: true,
    }).success).toBe(false)
  })

  it('accepts explicit null English fields while English publication is disabled', () => {
    expect(discoverCreateSchema.parse({
      slug: 'null-english-discover-item',
      title: 'عنوان فارسی',
      description: 'توضیح فارسی',
      content: 'محتوای فارسی',
      externalUrl: 'https://example.com/tool',
      category: 'ai',
      tags: ['AI'],
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
      publishedEn: false,
    })).toMatchObject({
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
      publishedEn: false,
    })
  })

  it('rejects missing null and blank English fields for English publication', () => {
    const variants = [
      { name: 'missing title', fields: { descriptionEn: 'English description', contentEn: 'English content' } },
      { name: 'missing description', fields: { titleEn: 'English title', contentEn: 'English content' } },
      { name: 'missing content', fields: { titleEn: 'English title', descriptionEn: 'English description' } },
      { name: 'null title', fields: { titleEn: null, descriptionEn: 'English description', contentEn: 'English content' } },
      { name: 'null description', fields: { titleEn: 'English title', descriptionEn: null, contentEn: 'English content' } },
      { name: 'null content', fields: { titleEn: 'English title', descriptionEn: 'English description', contentEn: null } },
      { name: 'blank title', fields: { titleEn: ' ', descriptionEn: 'English description', contentEn: 'English content' } },
      { name: 'blank description', fields: { titleEn: 'English title', descriptionEn: ' ', contentEn: 'English content' } },
      { name: 'blank content', fields: { titleEn: 'English title', descriptionEn: 'English description', contentEn: ' ' } },
    ]
    const schemas = [
      {
        name: 'create',
        schema: discoverCreateSchema,
        fields: {
          slug: 'english-publication-create',
          title: 'عنوان فارسی',
          description: 'توضیح فارسی',
          content: 'محتوای فارسی',
          externalUrl: 'https://example.com/tool',
          category: 'ai',
          tags: ['AI'],
        },
      },
      {
        name: 'update',
        schema: discoverUpdateSchema,
        fields: { id: 'discover_12345' },
      },
    ]

    for (const variant of variants) {
      for (const schema of schemas) {
        expect(schema.schema.safeParse({ ...schema.fields, ...variant.fields, publishedEn: true }).success, schema.name + ': ' + variant.name).toBe(false)
      }
    }
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

  it('normalizes only registered categories in create payloads', () => {
    const input = {
      slug: 'canonical-category-item',
      title: 'عنوان فارسی',
      description: 'توضیح فارسی',
      content: 'محتوای فارسی',
      externalUrl: 'https://example.com/tool',
      category: 'AI',
      tags: ['AI'],
    }

    expect(discoverCreateSchema.parse(input).category).toBe('ai')
    expect(discoverCreateSchema.safeParse({ ...input, category: 'made-up' }).success).toBe(false)
  })

  it('requires complete trimmed English content before English publication on create', () => {
    const input = {
      slug: 'english-discover-item',
      title: 'عنوان فارسی',
      description: 'توضیح فارسی',
      content: 'محتوای فارسی',
      externalUrl: 'https://example.com/tool',
      category: 'ai',
      tags: ['AI'],
      titleEn: ' English title ',
      descriptionEn: ' English description ',
      contentEn: ' English content ',
      publishedEn: true,
    }

    expect(discoverCreateSchema.parse(input)).toMatchObject({
      titleEn: 'English title',
      descriptionEn: 'English description',
      contentEn: 'English content',
      publishedEn: true,
    })

    expect(discoverCreateSchema.safeParse({ ...input, titleEn: ' ' }).success).toBe(false)
    expect(discoverCreateSchema.safeParse({ ...input, descriptionEn: ' ' }).success).toBe(false)
    expect(discoverCreateSchema.safeParse({ ...input, contentEn: ' ' }).success).toBe(false)
  })

  it('allows absent English content while English publication is disabled', () => {
    expect(discoverCreateSchema.parse({
      slug: 'persian-discover-item',
      title: 'عنوان فارسی',
      description: 'توضیح فارسی',
      content: 'محتوای فارسی',
      externalUrl: 'https://example.com/tool',
      category: 'ai',
      tags: ['AI'],
      publishedEn: false,
    })).toMatchObject({ publishedEn: false })
  })

  it('requires complete English content before English publication on update', () => {
    const input = {
      id: 'discover_12345',
      titleEn: 'English title',
      descriptionEn: 'English description',
      contentEn: 'English content',
      publishedEn: true,
    }

    expect(discoverUpdateSchema.parse(input)).toMatchObject(input)
    expect(discoverUpdateSchema.safeParse({ ...input, contentEn: ' ' }).success).toBe(false)
  })

})
