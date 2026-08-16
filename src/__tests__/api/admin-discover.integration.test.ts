import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const discoverItemMock = vi.hoisted(() => ({
  findMany: vi.fn(),
  findUnique: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
}))

vi.mock('@/lib/db', () => ({
  db: { discoverItem: discoverItemMock },
}))

const validItem = {
  slug: 'notebooklm',
  title: 'NotebookLM',
  description: 'Research assistant for your own sources',
  content: 'Upload your sources and use the grounded workspace to study them.',
  externalUrl: 'https://notebooklm.google.com/',
  category: 'AI',
  tags: ['AI', 'research'],
  imageUrl: '',
  instagramUrl: 'https://www.instagram.com/reel/example/',
  featured: true,
  published: false,
  order: 1,
}

type NextRequestInit = NonNullable<ConstructorParameters<typeof NextRequest>[1]>

function adminRequest(url: string, init: NextRequestInit = {}) {
  const headers = new Headers(init.headers)
  headers.set('authorization', 'Bearer abcdefghijklmnopqrstuvwxyz')
  if (init.body) headers.set('content-type', 'application/json')

  return new NextRequest(url, {
    ...init,
    headers,
  })
}

describe('Discover admin API', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    process.env.API_RATE_LIMIT_MAX_REQUESTS = '50'
    process.env.API_RATE_LIMIT_WINDOW_MS = '60000'
  })

  it('creates a draft Discover item with normalized tags', async () => {
    discoverItemMock.create.mockResolvedValueOnce({ id: 'discover_12345', ...validItem, tags: 'AI,research' })
    const { POST } = await import('@/app/api/admin/discover/route')
    const response = await POST(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'POST',
      body: JSON.stringify(validItem),
    }))

    expect(response.status).toBe(201)
    expect(discoverItemMock.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        slug: 'notebooklm',
        tags: 'AI,research',
        published: false,
        publishedAt: null,
      }),
    })
  })

  it('rejects a non-Instagram source URL before touching the database', async () => {
    const { POST } = await import('@/app/api/admin/discover/route')
    const response = await POST(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'POST',
      body: JSON.stringify({ ...validItem, instagramUrl: 'https://example.com/post/1' }),
    }))

    expect(response.status).toBe(400)
    expect(discoverItemMock.create).not.toHaveBeenCalled()
  })

  it('sets publishedAt on first publish without erasing it on later edits', async () => {
    discoverItemMock.findUnique.mockResolvedValueOnce({ publishedAt: null })
    discoverItemMock.update.mockImplementationOnce(async ({ data }: { data: Record<string, unknown> }) => ({
      id: 'discover_12345',
      ...data,
    }))
    const { PATCH } = await import('@/app/api/admin/discover/route')
    const response = await PATCH(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'PATCH',
      body: JSON.stringify({ id: 'discover_12345', published: true }),
    }))

    expect(response.status).toBe(200)
    expect(discoverItemMock.update).toHaveBeenCalledWith({
      where: { id: 'discover_12345' },
      data: expect.objectContaining({ published: true, publishedAt: expect.any(Date) }),
    })
  })

  it('builds safe list filters for publication, category, and search', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([])
    const { GET } = await import('@/app/api/admin/discover/route')
    const response = await GET(adminRequest('http://localhost:3000/api/admin/discover?published=true&category=AI&q=note'))

    expect(response.status).toBe(200)
    expect(discoverItemMock.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ published: true, category: 'AI' }),
      orderBy: [{ featured: 'desc' }, { order: 'asc' }, { updatedAt: 'desc' }],
    }))
  })

  it('deletes an authenticated Discover item by id', async () => {
    discoverItemMock.delete.mockResolvedValueOnce({ id: 'discover_12345' })
    const { DELETE } = await import('@/app/api/admin/discover/route')
    const response = await DELETE(adminRequest('http://localhost:3000/api/admin/discover?id=discover_12345', {
      method: 'DELETE',
    }))

    expect(response.status).toBe(200)
    expect(discoverItemMock.delete).toHaveBeenCalledWith({ where: { id: 'discover_12345' } })
  })
})
