import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const discoverItemMock = vi.hoisted(() => ({ findUnique: vi.fn(), findMany: vi.fn() }))
const languageMock = vi.hoisted(() => ({ getRequestLanguage: vi.fn() }))
const notFoundMock = vi.hoisted(() => vi.fn(() => { throw new Error('NOT_FOUND') }))

vi.mock('@/lib/db', () => ({ db: { discoverItem: discoverItemMock } }))
vi.mock('@/lib/i18n/server', () => languageMock)
vi.mock('next/navigation', () => ({ notFound: notFoundMock }))

const bilingualItem = {
  id: 'resource-1', slug: 'deepseek-gidbot', title: 'بات غیررسمی دیپ‌سیک', description: 'راهنمای فارسی', content: 'این بات رسمی DeepSeek نیست.',
  titleEn: 'Unofficial DeepSeek bot', descriptionEn: 'An editorial guide to a third-party bot.', contentEn: 'This is not the official DeepSeek bot.',
  published: true, publishedEn: true, category: 'telegram', tags: 'DeepSeek,Telegram', featured: false,
  imageUrl: null, externalUrl: 'https://t.me/deepseek_gidbot', telegramGuideUrl: 'https://t.me/example/1', instagramUrl: null,
  publishedAt: new Date('2026-08-20T12:00:00Z'), updatedAt: new Date('2026-08-20T12:00:00Z'), createdAt: new Date('2026-08-20T12:00:00Z'), order: 1,
}

describe('Discover detail locale publication and SEO', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    vi.stubEnv('NODE_ENV', 'test')
    process.env.NEXT_PUBLIC_SITE_URL = 'https://alirezasafaeisystems.ir'
    discoverItemMock.findMany.mockResolvedValue([])
  })

  it('does not publish or advertise an English page when only Persian is published', async () => {
    languageMock.getRequestLanguage.mockResolvedValue('en')
    discoverItemMock.findUnique.mockResolvedValue({ ...bilingualItem, publishedEn: false, titleEn: null, descriptionEn: null, contentEn: null })
    const { default: DiscoverDetailPage, generateMetadata } = await import('@/app/discover/[slug]/page')

    await expect(DiscoverDetailPage({ params: Promise.resolve({ slug: 'deepseek-gidbot' }), searchParams: Promise.resolve({}) })).rejects.toThrow('NOT_FOUND')
    await expect(generateMetadata({ params: Promise.resolve({ slug: 'deepseek-gidbot' }) })).resolves.toEqual(expect.objectContaining({
      robots: { index: false, follow: false },
    }))
  })

  it('treats published English with blank required content as unavailable and excludes invalid related links', async () => {
    languageMock.getRequestLanguage.mockResolvedValue('en')
    discoverItemMock.findUnique.mockResolvedValue({ ...bilingualItem, titleEn: ' ', descriptionEn: 'English description', contentEn: 'English guide' })
    const { default: DiscoverDetailPage, generateMetadata } = await import('@/app/discover/[slug]/page')

    await expect(DiscoverDetailPage({ params: Promise.resolve({ slug: 'deepseek-gidbot' }), searchParams: Promise.resolve({}) })).rejects.toThrow('NOT_FOUND')
    await expect(generateMetadata({ params: Promise.resolve({ slug: 'deepseek-gidbot' }) })).resolves.toEqual(expect.objectContaining({
      robots: { index: false, follow: false },
    }))

    discoverItemMock.findUnique.mockResolvedValue(bilingualItem)
    discoverItemMock.findMany.mockResolvedValue([{ ...bilingualItem, id: 'related-1', slug: 'incomplete-related', titleEn: ' ', descriptionEn: 'English description', contentEn: 'English guide' }])
    render(await DiscoverDetailPage({ params: Promise.resolve({ slug: 'deepseek-gidbot' }), searchParams: Promise.resolve({}) }))
    expect(screen.queryByText('English description')).not.toBeInTheDocument()
  })

  it('uses effective English content with reciprocal canonical language alternates', async () => {
    languageMock.getRequestLanguage.mockResolvedValue('en')
    discoverItemMock.findUnique.mockResolvedValue(bilingualItem)
    const { default: DiscoverDetailPage, generateMetadata } = await import('@/app/discover/[slug]/page')

    const metadata = await generateMetadata({ params: Promise.resolve({ slug: 'deepseek-gidbot' }) })
    expect(metadata).toEqual(expect.objectContaining({
      title: 'Unofficial DeepSeek bot | Discover',
      description: 'An editorial guide to a third-party bot.',
      alternates: expect.objectContaining({
        canonical: '/en/discover/deepseek-gidbot',
        languages: {
          'fa-IR': 'https://alirezasafaeisystems.ir/discover/deepseek-gidbot',
          'en-US': 'https://alirezasafaeisystems.ir/en/discover/deepseek-gidbot',
          'x-default': 'https://alirezasafaeisystems.ir/discover/deepseek-gidbot',
        },
      }),
    }))

    const { container } = render(await DiscoverDetailPage({ params: Promise.resolve({ slug: 'deepseek-gidbot' }), searchParams: Promise.resolve({}) }))
    expect(screen.getByRole('heading', { name: 'Unofficial DeepSeek bot' })).toBeInTheDocument()
    expect(screen.queryByText('بات غیررسمی دیپ‌سیک')).not.toBeInTheDocument()
    expect(screen.getByText('This is not the official DeepSeek bot.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Open resource' })).toHaveAttribute('href', 'https://t.me/deepseek_gidbot')
    expect(screen.getByRole('link', { name: 'Full tutorial / file on Telegram' })).toHaveAttribute('href', 'https://t.me/example/1')
    const schemas = Array.from(container.querySelectorAll('script[type="application/ld+json"]')).map((node) => JSON.parse(node.textContent || '{}'))
    expect(schemas).toContainEqual(expect.objectContaining({
      '@type': 'Article',
      headline: 'Unofficial DeepSeek bot',
      url: 'https://alirezasafaeisystems.ir/en/discover/deepseek-gidbot',
      author: expect.objectContaining({ '@type': 'Person', name: 'Alireza Safaei' }),
      publisher: expect.objectContaining({ '@type': 'Organization', name: 'AliReza Safaei' }),
    }))
  })

  it('keeps a draft out of both locale detail routes', async () => {
    languageMock.getRequestLanguage.mockResolvedValue('fa')
    discoverItemMock.findUnique.mockResolvedValue({ ...bilingualItem, published: false, publishedEn: false })
    const { default: DiscoverDetailPage, generateMetadata } = await import('@/app/discover/[slug]/page')

    await expect(DiscoverDetailPage({ params: Promise.resolve({ slug: 'deepseek-gidbot' }), searchParams: Promise.resolve({}) })).rejects.toThrow('NOT_FOUND')
    await expect(generateMetadata({ params: Promise.resolve({ slug: 'deepseek-gidbot' }) })).resolves.toEqual(expect.objectContaining({
      robots: { index: false, follow: false },
    }))
  })
})
