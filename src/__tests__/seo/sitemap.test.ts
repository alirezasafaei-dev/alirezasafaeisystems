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

  it('adds only published locale detail routes and does not advertise an unavailable English alternate', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([
      { slug: 'notebooklm', published: true, publishedEn: false, updatedAt: new Date('2026-08-15T20:00:00Z') },
    ])
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()

    const detail = entries.find((entry) => entry.url.endsWith('/fa/discover/notebooklm'))
    expect(detail).toBeDefined()
    expect(detail?.alternates?.languages).toEqual({
      'fa-IR': 'https://alirezasafaeisystems.ir/fa/discover/notebooklm',
      'x-default': 'https://alirezasafaeisystems.ir/fa/discover/notebooklm',
    })
    expect(discoverItemMock.findMany).toHaveBeenCalledWith({
      where: { OR: [{ published: true }, { publishedEn: true }] },
      select: { slug: true, published: true, publishedEn: true, updatedAt: true },
      orderBy: { updatedAt: 'desc' },
    })
  })

  it('emits reciprocal alternates only when both detail locales are published', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([
      { slug: 'notebooklm', published: true, publishedEn: true, updatedAt: new Date('2026-08-15T20:00:00Z') },
      { slug: 'english-only', published: false, publishedEn: true, updatedAt: new Date('2026-08-16T20:00:00Z') },
    ])
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()

    const persian = entries.find((entry) => entry.url.endsWith('/fa/discover/notebooklm'))
    const english = entries.find((entry) => entry.url.endsWith('/en/discover/notebooklm'))
    const englishOnly = entries.find((entry) => entry.url.endsWith('/en/discover/english-only'))
    expect(persian?.alternates?.languages).toEqual(expect.objectContaining({
      'fa-IR': 'https://alirezasafaeisystems.ir/fa/discover/notebooklm',
      'en-US': 'https://alirezasafaeisystems.ir/en/discover/notebooklm',
    }))
    expect(english?.alternates?.languages).toEqual(expect.objectContaining({
      'fa-IR': 'https://alirezasafaeisystems.ir/fa/discover/notebooklm',
      'en-US': 'https://alirezasafaeisystems.ir/en/discover/notebooklm',
    }))
    expect(englishOnly?.alternates?.languages).toEqual({
      'en-US': 'https://alirezasafaeisystems.ir/en/discover/english-only',
    })
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
