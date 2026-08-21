import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const discoverItemMock = vi.hoisted(() => ({ findMany: vi.fn() }))
const languageMock = vi.hoisted(() => ({ getRequestLanguage: vi.fn() }))

vi.mock('@/lib/db', () => ({ db: { discoverItem: discoverItemMock } }))
vi.mock('@/lib/i18n/server', () => languageMock)

describe('Discover landing locale projection and structured data', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    vi.stubEnv('NODE_ENV', 'test')
    process.env.NEXT_PUBLIC_SITE_URL = 'https://alirezasafaeisystems.ir'
  })

  it('queries and renders only English-published effective English records', async () => {
    languageMock.getRequestLanguage.mockResolvedValue('en')
    discoverItemMock.findMany.mockResolvedValueOnce([
      {
        slug: 'notebooklm', title: 'نوت‌بوک‌ال‌ام', description: 'راهنمای فارسی',
        titleEn: 'NotebookLM', descriptionEn: 'English research guide', category: 'ai', tags: 'research, productivity',
        featured: true, imageUrl: null,
      },
    ])
    const { default: DiscoverPage } = await import('@/app/discover/page')

    render(await DiscoverPage({ searchParams: Promise.resolve({}) }))

    expect(discoverItemMock.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { publishedEn: true },
      select: expect.objectContaining({ titleEn: true, descriptionEn: true }),
    }))
    expect(screen.getByRole('heading', { name: 'NotebookLM' })).toBeInTheDocument()
    expect(screen.queryByText('نوت‌بوک‌ال‌ام')).not.toBeInTheDocument()
  })

  it('uses Persian publication and only Persian effective fields for the Persian landing', async () => {
    languageMock.getRequestLanguage.mockResolvedValue('fa')
    discoverItemMock.findMany.mockResolvedValueOnce([
      {
        slug: 'notebooklm', title: 'نوت‌بوک‌ال‌ام', description: 'راهنمای فارسی',
        titleEn: 'NotebookLM', descriptionEn: 'English research guide', category: 'ai', tags: 'research',
        featured: false, imageUrl: null,
      },
    ])
    const { default: DiscoverPage } = await import('@/app/discover/page')

    render(await DiscoverPage({ searchParams: Promise.resolve({}) }))

    expect(discoverItemMock.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { published: true } }))
    expect(screen.getByRole('heading', { name: 'نوت‌بوک‌ال‌ام' })).toBeInTheDocument()
    expect(screen.queryByText('NotebookLM')).not.toBeInTheDocument()
  })

  it('emits CollectionPage and ItemList JSON-LD only for the shown locale records while keeping breadcrumbs', async () => {
    languageMock.getRequestLanguage.mockResolvedValue('en')
    discoverItemMock.findMany.mockResolvedValueOnce([
      {
        slug: 'notebooklm', title: 'نوت‌بوک‌ال‌ام', description: 'راهنمای فارسی',
        titleEn: 'NotebookLM', descriptionEn: 'English research guide', category: 'ai', tags: 'research',
        featured: false, imageUrl: null,
      },
    ])
    const { default: DiscoverPage } = await import('@/app/discover/page')

    const { container } = render(await DiscoverPage({ searchParams: Promise.resolve({}) }))
    const schemas = Array.from(container.querySelectorAll('script[type="application/ld+json"]')).map((node) => JSON.parse(node.textContent || '{}'))
    const collection = schemas.find((schema) => schema['@type'] === 'CollectionPage')
    const breadcrumbs = schemas.find((schema) => schema['@type'] === 'BreadcrumbList')

    expect(collection).toEqual(expect.objectContaining({
      url: 'https://alirezasafaeisystems.ir/en/discover',
      mainEntity: expect.objectContaining({
        '@type': 'ItemList',
        itemListElement: [expect.objectContaining({ item: 'https://alirezasafaeisystems.ir/en/discover/notebooklm' })],
      }),
    }))
    expect(breadcrumbs).toBeDefined()
  })
})
