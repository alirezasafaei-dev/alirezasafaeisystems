import { describe, expect, it } from 'vitest'
import { discoverCreateSchema, discoverUpdateSchema } from '@/lib/discover'
import {
  normalizeDiscoverCreateInput,
  normalizeDiscoverUpdateInput,
} from '@/lib/discover-service'

describe('Discover persistence service', () => {
  it('sanitizes text, normalizes a legacy category, keeps nullable English fields, and preserves external URLs', () => {
    const input = discoverCreateSchema.parse({
      slug: 'notebooklm',
      title: '<NotebookLM>',
      description: '<Research assistant for your own sources>',
      content: '<Upload your sources and study them.>',
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
      externalUrl: 'https://notebooklm.google.com/path?ref=discover',
      category: 'AI',
      tags: ['AI', 'research'],
      publishedEn: false,
    })

    expect(normalizeDiscoverCreateInput(input)).toMatchObject({
      title: 'NotebookLM',
      description: 'Research assistant for your own sources',
      content: 'Upload your sources and study them.',
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
      externalUrl: 'https://notebooklm.google.com/path?ref=discover',
      category: 'ai',
      tags: 'AI,research',
      publishedEn: false,
      publishedAt: null,
    })
  })

  it('persists bilingual publication and assigns publishedAt only for a first Persian publication', () => {
    const input = discoverCreateSchema.parse({
      slug: 'bilingual-notebooklm',
      title: 'نوت‌بوک‌ال‌ام',
      description: 'دستیار پژوهش',
      content: 'منابع خود را بارگذاری کنید.',
      titleEn: 'NotebookLM',
      descriptionEn: 'Research assistant',
      contentEn: 'Upload your sources.',
      externalUrl: 'https://notebooklm.google.com/',
      category: 'ai',
      tags: ['AI'],
      published: true,
      publishedEn: true,
    })

    expect(normalizeDiscoverCreateInput(input)).toMatchObject({
      titleEn: 'NotebookLM',
      descriptionEn: 'Research assistant',
      contentEn: 'Upload your sources.',
      published: true,
      publishedEn: true,
      publishedAt: expect.any(Date),
    })
  })

  it('clears English fields only in an unpublished English update and preserves an existing publishedAt', () => {
    const input = discoverUpdateSchema.parse({
      id: 'discover_12345',
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
      publishedEn: false,
      published: true,
    })
    const publishedAt = new Date('2026-08-20T00:00:00.000Z')

    expect(normalizeDiscoverUpdateInput(input, { publishedAt })).toEqual({
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
      publishedEn: false,
      published: true,
    })
  })
})
