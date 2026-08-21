import { beforeEach, describe, expect, it, vi } from 'vitest'

const discoverItemMock = vi.hoisted(() => ({
  findMany: vi.fn(),
}))

vi.mock('@/lib/db', () => ({
  db: { discoverItem: discoverItemMock },
}))

describe('sitemap contract', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    vi.stubEnv('NODE_ENV', 'test')
    process.env.NEXT_PUBLIC_SITE_URL = 'https://alirezasafaeisystems.ir'
    process.env.DATABASE_URL = 'file:./test.db'
    delete process.env.ASDEV_BUILD_SKIP_DYNAMIC_DB
  })

  it('contains only indexable URLs and no hash fragments', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([])
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()
    const expectedBase = new URL('https://alirezasafaeisystems.ir')

    expect(entries.length).toBeGreaterThan(0)
    entries.forEach((entry) => {
      const parsed = new URL(entry.url)
      expect(parsed.hash).toBe('')
      expect(parsed.origin).toBe(expectedBase.origin)
    })
  })

  it('emits the canonical Discover landing with explicit FA, EN, and x-default alternates', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([])
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()

    const canonical = entries.find((entry) => entry.url === 'https://alirezasafaeisystems.ir/discover')

    expect(canonical).toBeDefined()
    expect(entries.some((entry) => entry.url === 'https://alirezasafaeisystems.ir/fa/discover')).toBe(false)
    expect(canonical?.alternates?.languages).toEqual({
      'fa-IR': 'https://alirezasafaeisystems.ir/discover',
      'en-US': 'https://alirezasafaeisystems.ir/en/discover',
      'x-default': 'https://alirezasafaeisystems.ir/discover',
    })
  })

  it('adds only published locale detail routes and does not advertise an unavailable English alternate', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([
      { slug: 'notebooklm', published: true, publishedEn: false, updatedAt: new Date('2026-08-15T20:00:00Z') },
    ])
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()

    const detail = entries.find((entry) => entry.url.endsWith('/discover/notebooklm'))
    expect(detail).toBeDefined()
    expect(detail?.alternates?.languages).toEqual({
      'fa-IR': 'https://alirezasafaeisystems.ir/discover/notebooklm',
      'x-default': 'https://alirezasafaeisystems.ir/discover/notebooklm',
    })
    expect(discoverItemMock.findMany).toHaveBeenCalledWith({
      where: { OR: [{ published: true }, { publishedEn: true }] },
      select: { slug: true, published: true, publishedEn: true, titleEn: true, descriptionEn: true, contentEn: true, updatedAt: true },
      orderBy: { updatedAt: 'desc' },
    })
  })

  it('emits reciprocal alternates only when both detail locales are published', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([
      { slug: 'notebooklm', published: true, publishedEn: true, titleEn: 'NotebookLM', descriptionEn: 'English guide', contentEn: 'English content', updatedAt: new Date('2026-08-15T20:00:00Z') },
      { slug: 'english-only', published: false, publishedEn: true, titleEn: 'English only', descriptionEn: 'English guide', contentEn: 'English content', updatedAt: new Date('2026-08-16T20:00:00Z') },
    ])
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()

    const persian = entries.find((entry) => entry.url.endsWith('/discover/notebooklm'))
    const english = entries.find((entry) => entry.url.endsWith('/en/discover/notebooklm'))
    const englishOnly = entries.find((entry) => entry.url.endsWith('/en/discover/english-only'))
    expect(persian?.alternates?.languages).toEqual(expect.objectContaining({
      'fa-IR': 'https://alirezasafaeisystems.ir/discover/notebooklm',
      'en-US': 'https://alirezasafaeisystems.ir/en/discover/notebooklm',
    }))
    expect(english?.alternates?.languages).toEqual(expect.objectContaining({
      'fa-IR': 'https://alirezasafaeisystems.ir/discover/notebooklm',
      'en-US': 'https://alirezasafaeisystems.ir/en/discover/notebooklm',
    }))
    expect(englishOnly?.alternates?.languages).toEqual({
      'en-US': 'https://alirezasafaeisystems.ir/en/discover/english-only',
    })
  })

  it('excludes publishedEn records whose English editorial fields are incomplete', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([
      { slug: 'incomplete', published: false, publishedEn: true, titleEn: 'English title', descriptionEn: ' ', contentEn: 'English guide', updatedAt: new Date('2026-08-16T20:00:00Z') },
    ])
    const { default: sitemap } = await import('@/app/sitemap')

    const entries = await sitemap()

    expect(entries.find((entry) => entry.url.endsWith('/en/discover/incomplete'))).toBeUndefined()
  })

  it('renders at request time so post-deploy Discover publications reach the sitemap', async () => {
    const { dynamic } = await import('@/app/sitemap')

    expect(dynamic).toBe('force-dynamic')
  })

  it('skips dynamic Discover queries during a pre-migration production build', async () => {
    process.env.ASDEV_BUILD_SKIP_DYNAMIC_DB = '1'
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()

    expect(entries.length).toBeGreaterThan(0)
    expect(discoverItemMock.findMany).not.toHaveBeenCalled()
  })
})