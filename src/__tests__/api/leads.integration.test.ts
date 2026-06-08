import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const dbMock = vi.hoisted(() => ({
  lead: {
    create: vi.fn(),
  },
}))

const fsMock = vi.hoisted(() => ({
  mkdir: vi.fn(),
  writeFile: vi.fn(),
}))

vi.mock('@/lib/db', () => ({
  db: dbMock,
}))

vi.mock('node:fs/promises', () => ({ ...fsMock, default: fsMock }))

const validLeadPayload = {
  contactName: 'Ali Safaei',
  organizationName: 'Industrial Co',
  organizationType: 'government_contractor',
  email: 'lead@example.com',
  phone: '09120000000',
  teamSize: '12',
  currentStack: 'Next.js + PostgreSQL',
  criticalRisk: 'No disaster recovery test and no release governance.',
  timeline: '30 days',
  budgetRange: '60-120m-irr',
  preferredContact: 'email',
  notes: 'Need risk assessment this month.',
}

function createJsonLeadRequest(payload: Record<string, unknown>) {
  return new NextRequest('http://localhost:3000/api/leads', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  })
}

function createMultipartLeadRequest(payload: Record<string, string>, attachment?: File) {
  const form = new FormData()
  Object.entries(payload).forEach(([key, value]) => form.set(key, value))
  if (attachment) {
    form.set('attachment', attachment)
  }

  return new NextRequest('http://localhost:3000/api/leads', {
    method: 'POST',
    body: form,
  })
}

describe('lead API integration', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    vi.stubEnv('NODE_ENV', 'test')
    process.env.API_RATE_LIMIT_MAX_REQUESTS = '20'
    process.env.API_RATE_LIMIT_WINDOW_MS = '60000'
  })

  it('stores a valid lead request', async () => {
    const { POST } = await import('@/app/api/leads/route')
    const request = createJsonLeadRequest(validLeadPayload)

    const response = await POST(request)
    expect(response.status).toBe(201)
    expect(dbMock.lead.create).toHaveBeenCalledTimes(1)
  })

  it('rejects invalid payload', async () => {
    const { POST } = await import('@/app/api/leads/route')
    const request = createJsonLeadRequest({
      contactName: 'A',
    })

    const response = await POST(request)
    expect(response.status).toBe(400)
    expect(dbMock.lead.create).not.toHaveBeenCalled()
  })

  it('ignores honeypot submissions without storing data', async () => {
    const { POST } = await import('@/app/api/leads/route')
    const request = createJsonLeadRequest({
      ...validLeadPayload,
      website: 'https://spam.example.com',
    })

    const response = await POST(request)
    expect(response.status).toBe(201)
    expect(dbMock.lead.create).not.toHaveBeenCalled()
  })

  it('stores a valid multipart attachment after payload validation', async () => {
    const { POST } = await import('@/app/api/leads/route')
    const request = createMultipartLeadRequest(
      validLeadPayload,
      new File(['audit context'], 'audit-context.txt', { type: 'text/plain' })
    )

    const response = await POST(request)

    expect(response.status).toBe(201)
    expect(fsMock.mkdir).toHaveBeenCalledTimes(1)
    expect(fsMock.writeFile).toHaveBeenCalledTimes(1)
    expect(dbMock.lead.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        attachmentPath: expect.stringContaining('storage/leads/'),
      }),
    }))
  })

  it('rejects invalid multipart attachments without storing data', async () => {
    const { POST } = await import('@/app/api/leads/route')
    const request = createMultipartLeadRequest(
      validLeadPayload,
      new File(['malicious'], 'payload.exe', { type: 'application/pdf' })
    )

    const response = await POST(request)

    expect(response.status).toBe(400)
    expect(fsMock.writeFile).not.toHaveBeenCalled()
    expect(dbMock.lead.create).not.toHaveBeenCalled()
  })

  it('does not save attachments for invalid multipart payloads', async () => {
    const { POST } = await import('@/app/api/leads/route')
    const request = createMultipartLeadRequest(
      { contactName: 'A' },
      new File(['audit context'], 'audit-context.txt', { type: 'text/plain' })
    )

    const response = await POST(request)

    expect(response.status).toBe(400)
    expect(fsMock.writeFile).not.toHaveBeenCalled()
    expect(dbMock.lead.create).not.toHaveBeenCalled()
  })
})
