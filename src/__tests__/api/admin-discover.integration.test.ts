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
  telegramGuideUrl: 'https://t.me/asdev/123',
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

  it('creates a draft Discover item with normalized tags and Telegram guide URL', async () => {
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
        telegramGuideUrl: 'https://t.me/asdev/123',
        published: false,
        publishedAt: null,
      }),
    })
  })

  it('persists a Persian-only draft with nullable unpublished English fields', async () => {
    discoverItemMock.create.mockResolvedValueOnce({ id: 'discover_12345', ...validItem })
    const { POST } = await import('@/app/api/admin/discover/route')
    const response = await POST(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'POST',
      body: JSON.stringify({
        ...validItem,
        titleEn: null,
        descriptionEn: null,
        contentEn: null,
        publishedEn: false,
      }),
    }))

    expect(response.status).toBe(201)
    expect(discoverItemMock.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        titleEn: null,
        descriptionEn: null,
        contentEn: null,
        publishedEn: false,
      }),
    })
  })

  it('persists a bilingual published item with English publication enabled', async () => {
    discoverItemMock.create.mockResolvedValueOnce({ id: 'discover_12345', ...validItem })
    const { POST } = await import('@/app/api/admin/discover/route')
    const response = await POST(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'POST',
      body: JSON.stringify({
        ...validItem,
        published: true,
        titleEn: 'NotebookLM',
        descriptionEn: 'Research assistant',
        contentEn: 'Upload your sources.',
        publishedEn: true,
      }),
    }))

    expect(response.status).toBe(201)
    expect(discoverItemMock.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        titleEn: 'NotebookLM',
        descriptionEn: 'Research assistant',
        contentEn: 'Upload your sources.',
        publishedEn: true,
        publishedAt: expect.any(Date),
      }),
    })
  })

  it('rejects English publication without complete English content before touching the database', async () => {
    const { POST } = await import('@/app/api/admin/discover/route')
    const response = await POST(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'POST',
      body: JSON.stringify({ ...validItem, publishedEn: true, titleEn: 'NotebookLM' }),
    }))

    expect(response.status).toBe(400)
    expect(discoverItemMock.create).not.toHaveBeenCalled()
  })

  it('normalizes a legacy category alias before persistence', async () => {
    discoverItemMock.create.mockResolvedValueOnce({ id: 'discover_12345', ...validItem, category: 'ai' })
    const { POST } = await import('@/app/api/admin/discover/route')
    const response = await POST(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'POST',
      body: JSON.stringify(validItem),
    }))

    expect(response.status).toBe(201)
    expect(discoverItemMock.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ category: 'ai' }),
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

  it('rejects a non-canonical Telegram guide host before touching the database', async () => {
    const { POST } = await import('@/app/api/admin/discover/route')
    const response = await POST(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'POST',
      body: JSON.stringify({ ...validItem, telegramGuideUrl: 'https://telegram.me/asdev/123' }),
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

  it('clears a Telegram guide URL to null on PATCH', async () => {
    discoverItemMock.update.mockResolvedValueOnce({ id: 'discover_12345', telegramGuideUrl: null })
    const { PATCH } = await import('@/app/api/admin/discover/route')
    const response = await PATCH(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'PATCH',
      body: JSON.stringify({ id: 'discover_12345', telegramGuideUrl: '' }),
    }))

    expect(response.status).toBe(200)
    expect(discoverItemMock.update).toHaveBeenCalledWith({
      where: { id: 'discover_12345' },
      data: expect.objectContaining({ telegramGuideUrl: null }),
    })
  })

  it('clears optional English fields only when English publication is disabled', async () => {
    discoverItemMock.update.mockResolvedValueOnce({ id: 'discover_12345', titleEn: null })
    const { PATCH } = await import('@/app/api/admin/discover/route')
    const response = await PATCH(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'PATCH',
      body: JSON.stringify({
        id: 'discover_12345',
        titleEn: null,
        descriptionEn: null,
        contentEn: null,
        publishedEn: false,
      }),
    }))

    expect(response.status).toBe(200)
    expect(discoverItemMock.update).toHaveBeenCalledWith({
      where: { id: 'discover_12345' },
      data: expect.objectContaining({
        titleEn: null,
        descriptionEn: null,
        contentEn: null,
        publishedEn: false,
      }),
    })
  })

  it('rejects clearing English content from an existing English-published item without unpublishing it', async () => {
    discoverItemMock.findUnique.mockResolvedValueOnce({
      publishedAt: new Date('2026-08-20T00:00:00.000Z'),
      publishedEn: true,
      titleEn: 'NotebookLM',
      descriptionEn: 'Research assistant',
      contentEn: 'Upload your sources.',
    })
    const { PATCH } = await import('@/app/api/admin/discover/route')
    const response = await PATCH(adminRequest('http://localhost:3000/api/admin/discover', {
      method: 'PATCH',
      body: JSON.stringify({ id: 'discover_12345', titleEn: null }),
    }))

    expect(response.status).toBe(400)
    expect(discoverItemMock.update).not.toHaveBeenCalled()
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

  it('returns English fields and canonical category keys from the admin list', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([{
      id: 'discover_12345',
      ...validItem,
      category: 'ai',
      titleEn: 'NotebookLM',
      descriptionEn: 'Research assistant',
      contentEn: 'Upload your sources.',
      publishedEn: true,
    }])
    const { GET } = await import('@/app/api/admin/discover/route')
    const response = await GET(adminRequest('http://localhost:3000/api/admin/discover'))

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      items: [expect.objectContaining({
        category: 'ai',
        titleEn: 'NotebookLM',
        descriptionEn: 'Research assistant',
        contentEn: 'Upload your sources.',
        publishedEn: true,
      })],
    })
  })

  it('normalizes known legacy categories in the admin list response without changing unknown categories', async () => {
    discoverItemMock.findMany.mockResolvedValueOnce([
      { id: 'discover_legacy', ...validItem, category: 'AI' },
      { id: 'discover_unknown', ...validItem, category: 'legacy-custom' },
    ])
    const { GET } = await import('@/app/api/admin/discover/route')
    const response = await GET(adminRequest('http://localhost:3000/api/admin/discover'))

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      items: [
        expect.objectContaining({ id: 'discover_legacy', category: 'ai' }),
        expect.objectContaining({ id: 'discover_unknown', category: 'legacy-custom' }),
      ],
    })
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
