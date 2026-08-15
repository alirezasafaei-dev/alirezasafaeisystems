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

  it('adds published Discover detail routes with language alternates', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([
      { slug: 'notebooklm', updatedAt: new Date('2026-08-15T20:00:00Z') },
    ])
    const { default: sitemap } = await import('@/app/sitemap')
    const entries = await sitemap()

    const detail = entries.find((entry) => entry.url.endsWith('/fa/discover/notebooklm'))
    expect(detail).toBeDefined()
    expect(detail?.alternates?.languages).toEqual(expect.objectContaining({
      'fa-IR': 'https://alirezasafaeisystems.ir/fa/discover/notebooklm',
      'en-US': 'https://alirezasafaeisystems.ir/en/discover/notebooklm',
      'x-default': 'https://alirezasafaeisystems.ir/fa/discover/notebooklm',
    }))
    expect(discoverItemMock.findMany).toHaveBeenCalledWith({
      where: { published: true },
      select: { slug: true, updatedAt: true },
      orderBy: { updatedAt: 'desc' },
    })
  })
})
