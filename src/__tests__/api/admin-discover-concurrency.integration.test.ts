import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const discoverItemMock = vi.hoisted(() => ({
  findUnique: vi.fn(),
  update: vi.fn(),
}))

vi.mock('@/lib/db', () => ({
  db: { discoverItem: discoverItemMock },
}))

function adminPatch(body: Record<string, unknown>) {
  return new NextRequest('http://localhost:3000/api/admin/discover', {
    method: 'PATCH',
    headers: {
      authorization: 'Bearer abcdefghijklmnopqrstuvwxyz',
      'content-type': 'application/json',
    },
    body: JSON.stringify(body),
  })
}

describe('Discover admin optimistic concurrency', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    process.env.API_RATE_LIMIT_MAX_REQUESTS = '50'
    process.env.API_RATE_LIMIT_WINDOW_MS = '60000'
  })

  it('uses the editor snapshot timestamp as an atomic PATCH precondition', async () => {
    const expectedUpdatedAt = '2026-08-21T08:00:00.000Z'
    discoverItemMock.update.mockResolvedValueOnce({
      id: 'discover_12345',
      title: 'Updated title',
      updatedAt: new Date('2026-08-21T08:05:00.000Z'),
    })

    const { PATCH } = await import('@/app/api/admin/discover/route')
    const response = await PATCH(adminPatch({
      id: 'discover_12345',
      title: 'Updated title',
      expectedUpdatedAt,
    }))

    expect(response.status).toBe(200)
    expect(discoverItemMock.update).toHaveBeenCalledWith({
      where: {
        id: 'discover_12345',
        updatedAt: new Date(expectedUpdatedAt),
      },
      data: expect.objectContaining({ title: 'Updated title' }),
    })
  })

  it('returns a typed 409 when another editor already changed the item', async () => {
    discoverItemMock.update.mockRejectedValueOnce({ code: 'P2025' })

    const { PATCH } = await import('@/app/api/admin/discover/route')
    const response = await PATCH(adminPatch({
      id: 'discover_12345',
      title: 'Stale edit',
      expectedUpdatedAt: '2026-08-21T08:00:00.000Z',
    }))

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      code: 'STALE_WRITE',
      error: expect.any(String),
    })
  })
})