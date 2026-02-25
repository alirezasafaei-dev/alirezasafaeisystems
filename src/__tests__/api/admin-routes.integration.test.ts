import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const dbMock = vi.hoisted(() => ({
  contactMessage: {
    findMany: vi.fn(),
    delete: vi.fn(),
  },
  project: {
    findMany: vi.fn(),
    create: vi.fn(),
  },
}))

vi.mock('@/lib/db', () => ({
  db: dbMock,
}))

function setBaseEnv() {
  process.env.NEXT_PUBLIC_ENABLE_WEB_VITALS = 'false'
  process.env.API_RATE_LIMIT_MAX_REQUESTS = '20'
  process.env.API_RATE_LIMIT_WINDOW_MS = '60000'
}

describe('admin API integration', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    delete process.env.ADMIN_API_TOKEN
    delete process.env.ADMIN_USERNAME
    delete process.env.ADMIN_PASSWORD
    delete process.env.ADMIN_SESSION_SECRET
    setBaseEnv()
  })

  it('returns 503 when admin auth is not configured', async () => {
    const { GET } = await import('@/app/api/admin/messages/route')
    const request = new NextRequest('http://localhost:3000/api/admin/messages')

    const response = await GET(request)
    const payload = await response.json()

    expect(response.status).toBe(503)
    expect(payload.error).toContain('not configured')
  })

  it('allows bearer-authenticated admin messages read', async () => {
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    dbMock.contactMessage.findMany.mockResolvedValueOnce([
      { id: 'msg_1', name: 'John', email: 'john@example.com', subject: '', message: 'Hello', createdAt: new Date() },
    ])

    const { GET } = await import('@/app/api/admin/messages/route')
    const request = new NextRequest('http://localhost:3000/api/admin/messages', {
      headers: {
        authorization: 'Bearer abcdefghijklmnopqrstuvwxyz',
        'x-request-id': 'req-admin-1',
      },
    })

    const response = await GET(request)
    const payload = await response.json()

    expect(response.status).toBe(200)
    expect(response.headers.get('X-Request-ID')).toBe('req-admin-1')
    expect(Array.isArray(payload.messages)).toBe(true)
    expect(dbMock.contactMessage.findMany).toHaveBeenCalledTimes(1)
  })

  it('enforces project payload contract validation', async () => {
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    const { POST } = await import('@/app/api/admin/projects/route')
    const request = new NextRequest('http://localhost:3000/api/admin/projects', {
      method: 'POST',
      headers: {
        authorization: 'Bearer abcdefghijklmnopqrstuvwxyz',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        title: '',
        description: '',
        tags: [],
      }),
    })

    const response = await POST(request)
    const payload = await response.json()

    expect(response.status).toBe(400)
    expect(payload.error).toBe('Validation failed')
    expect(Array.isArray(payload.details)).toBe(true)
    expect(dbMock.project.create).not.toHaveBeenCalled()
  })

  it('deletes admin message with id', async () => {
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    dbMock.contactMessage.delete.mockResolvedValueOnce({ id: 'msg_1' })

    const { DELETE } = await import('@/app/api/admin/messages/route')
    const request = new NextRequest('http://localhost:3000/api/admin/messages?id=msg_1', {
      method: 'DELETE',
      headers: { authorization: 'Bearer abcdefghijklmnopqrstuvwxyz' },
    })

    const response = await DELETE(request)
    const payload = await response.json()

    expect(response.status).toBe(200)
    expect(payload.success).toBe(true)
    expect(dbMock.contactMessage.delete).toHaveBeenCalledTimes(1)
  })

  it('returns 400 when deleting admin message without id', async () => {
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    const { DELETE } = await import('@/app/api/admin/messages/route')
    const request = new NextRequest('http://localhost:3000/api/admin/messages', {
      method: 'DELETE',
      headers: { authorization: 'Bearer abcdefghijklmnopqrstuvwxyz' },
    })

    const response = await DELETE(request)
    expect(response.status).toBe(400)
  })

  it('returns 400 when creating project with invalid url', async () => {
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    const { POST } = await import('@/app/api/admin/projects/route')
    const request = new NextRequest('http://localhost:3000/api/admin/projects', {
      method: 'POST',
      headers: {
        authorization: 'Bearer abcdefghijklmnopqrstuvwxyz',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        title: 't',
        description: 'd',
        tags: ['x'],
        githubUrl: 'not-a-url',
      }),
    })

    const response = await POST(request)
    const payload = await response.json()
    expect(response.status).toBe(400)
    expect(payload.error).toContain('Invalid URL')
  })

  it('creates admin project for valid payload', async () => {
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    dbMock.project.create.mockResolvedValueOnce({ id: 'p1', title: 't' })

    const { POST } = await import('@/app/api/admin/projects/route')
    const request = new NextRequest('http://localhost:3000/api/admin/projects', {
      method: 'POST',
      headers: {
        authorization: 'Bearer abcdefghijklmnopqrstuvwxyz',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        title: 'Title',
        description: 'Description',
        tags: ['Next.js'],
        featured: true,
        order: 1,
        githubUrl: 'https://github.com/parsairaniiidev/asdev-portfolio',
      }),
    })

    const response = await POST(request)
    expect(response.status).toBe(201)
    expect(dbMock.project.create).toHaveBeenCalledTimes(1)
  })
})
