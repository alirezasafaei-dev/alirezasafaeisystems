import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const dbMock = vi.hoisted(() => ({
  $queryRaw: vi.fn(),
}))

vi.mock('@/lib/db', () => ({
  db: dbMock,
}))

describe('ready endpoint', () => {
  beforeEach(() => {
    process.env.DATABASE_URL = 'file:./tmp/ready-test.db'
    vi.resetModules()
    vi.clearAllMocks()
  })

  it('returns 200 when database check succeeds', async () => {
    dbMock.$queryRaw.mockResolvedValueOnce([1])
    const { GET } = await import('@/app/api/ready/route')
    const response = await GET(new NextRequest('http://localhost:3000/api/ready'))
    const payload = await response.json()
    expect(response.status).toBe(200)
    expect(payload.status).toBe('ready')
  })

  it('returns 503 when database check fails', async () => {
    dbMock.$queryRaw.mockRejectedValueOnce(new Error('db down'))
    const { GET } = await import('@/app/api/ready/route')
    const response = await GET(new NextRequest('http://localhost:3000/api/ready'))
    const payload = await response.json()
    expect(response.status).toBe(503)
    expect(payload.status).toBe('not_ready')
  })
})
