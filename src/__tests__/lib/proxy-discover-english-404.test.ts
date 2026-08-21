import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const discoverItemMock = vi.hoisted(() => ({
  findUnique: vi.fn(),
}))

vi.mock('@/lib/db', () => ({
  db: { discoverItem: discoverItemMock },
}))

describe('proxy English Discover availability guard', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
  })

  it('returns a real non-indexable 404 before streaming when English content is unavailable', async () => {
    discoverItemMock.findUnique.mockResolvedValueOnce({
      publishedEn: false,
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
    })
    const { proxy } = await import('@/proxy')

    const response = await proxy(new NextRequest('https://alirezasafaeisystems.ir/en/discover/draft-tool'))

    expect(response.status).toBe(404)
    expect(response.headers.get('x-robots-tag')).toBe('noindex, nofollow')
    expect(response.headers.get('cache-control')).toContain('no-store')
    expect(response.headers.get('content-language')).toBe('en')
    expect(await response.text()).toContain('/en/discover')
  })

  it('keeps the normal English rewrite when the item is fully publish-ready', async () => {
    discoverItemMock.findUnique.mockResolvedValueOnce({
      publishedEn: true,
      titleEn: 'Public tool',
      descriptionEn: 'Public description',
      contentEn: 'Public guide',
    })
    const { proxy } = await import('@/proxy')

    const response = await proxy(new NextRequest('https://alirezasafaeisystems.ir/en/discover/public-tool'))

    expect(response.status).toBe(200)
    expect(response.headers.get('x-site-locale')).toBe('en')
    expect(response.headers.get('x-site-pathname')).toBe('/discover/public-tool')
  })

  it('fails open on a database availability error instead of turning an outage into a false 404', async () => {
    discoverItemMock.findUnique.mockRejectedValueOnce(new Error('database unavailable'))
    const { proxy } = await import('@/proxy')

    const response = await proxy(new NextRequest('https://alirezasafaeisystems.ir/en/discover/public-tool'))

    expect(response.status).toBe(200)
    expect(response.headers.get('x-site-locale')).toBe('en')
  })
})