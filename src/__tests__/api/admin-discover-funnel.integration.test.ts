import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NextRequest } from 'next/server'

const analyticsEventMock = vi.hoisted(() => ({ findMany: vi.fn() }))
vi.mock('@/lib/db', () => ({ db: { analyticsEvent: analyticsEventMock } }))

function adminRequest(query = '') {
  return new NextRequest(`http://localhost:3000/api/admin/discover/funnel${query}`, {
    headers: { authorization: 'Bearer abcdefghijklmnopqrstuvwxyz' },
  })
}

const events = [
  { name: 'discover_landing_view', locale: 'fa', metadata: '{"surface":"discover"}' },
  { name: 'discover_landing_view', locale: 'en', metadata: '{"surface":"discover"}' },
  { name: 'discover_item_view', locale: 'fa', metadata: '{"slug":"one"}' },
  { name: 'discover_telegram_guide_click', locale: 'fa', metadata: '{"target":"telegram_guide"}' },
  { name: 'discover_telegram_channel_click', locale: 'en', metadata: '{"target":"telegram_channel"}' },
  { name: 'discover_internal_cta_click', locale: 'fa', metadata: '{"target":"audit_readiness"}' },
  { name: 'discover_internal_cta_click', locale: 'en', metadata: '{"target":"qualification"}' },
  { name: 'discover_internal_cta_click', locale: 'en', metadata: '{"target":"case_studies"}' },
]

describe('Admin Discover funnel report API', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    process.env.ADMIN_API_TOKEN = 'abcdefghijklmnopqrstuvwxyz'
    process.env.API_RATE_LIMIT_MAX_REQUESTS = '50'
    process.env.API_RATE_LIMIT_WINDOW_MS = '60000'
  })

  it('requires Admin access', async () => {
    delete process.env.ADMIN_API_TOKEN
    const { GET } = await import('@/app/api/admin/discover/funnel/route')
    const response = await GET(new NextRequest('http://localhost:3000/api/admin/discover/funnel'))
    expect(response.status).toBe(503)
    expect(analyticsEventMock.findMany).not.toHaveBeenCalled()
  })

  it.each(['?days=0', '?days=91', '?days=abc'])('rejects an out-of-bounds window: %s', async (query) => {
    const { GET } = await import('@/app/api/admin/discover/funnel/route')
    const response = await GET(adminRequest(query))
    expect(response.status).toBe(400)
    expect(analyticsEventMock.findMany).not.toHaveBeenCalled()
  })

  it('returns bounded aggregate event counts without raw identifiers', async () => {
    analyticsEventMock.findMany.mockResolvedValueOnce(events)
    const { GET } = await import('@/app/api/admin/discover/funnel/route')
    const response = await GET(adminRequest('?days=30'))
    const payload = await response.json()

    expect(response.status).toBe(200)
    expect(analyticsEventMock.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({
        site: 'portfolio',
        name: { in: expect.arrayContaining(['discover_landing_view', 'discover_item_view', 'discover_internal_cta_click']) },
        createdAt: { gte: expect.any(Date) },
      }),
      orderBy: { createdAt: 'desc' },
      take: 5001,
      select: { name: true, locale: true, metadata: true },
    }))
    expect(payload).toMatchObject({
      windowDays: 30,
      scannedEvents: 8,
      truncated: false,
      consentScope: 'stored_consented_telemetry_only',
      steps: {
        landing: { total: 2, fa: 1, en: 1, unknown: 0 },
        detail: { total: 1, fa: 1, en: 0, unknown: 0 },
        telegram: { total: 2, fa: 1, en: 1, unknown: 0 },
        auditOrQualification: { total: 2, fa: 1, en: 1, unknown: 0 },
      },
    })
    const serialized = JSON.stringify(payload)
    expect(serialized).not.toContain('sessionId')
    expect(serialized).not.toContain('userAgent')
    expect(serialized).not.toContain('ip')
  })

  it('returns zeroed steps for an empty stored-event window', async () => {
    analyticsEventMock.findMany.mockResolvedValueOnce([])
    const { GET } = await import('@/app/api/admin/discover/funnel/route')
    const response = await GET(adminRequest('?days=7'))
    const payload = await response.json()

    expect(response.status).toBe(200)
    expect(payload.scannedEvents).toBe(0)
    expect(payload.steps.landing.total).toBe(0)
    expect(payload.steps.auditOrQualification.total).toBe(0)
  })

  it('marks a capped scan partial and ignores rows beyond the 5000-event bound', async () => {
    analyticsEventMock.findMany.mockResolvedValueOnce(Array.from({ length: 5001 }, () => ({
      name: 'discover_landing_view', locale: 'fa', metadata: null,
    })))
    const { GET } = await import('@/app/api/admin/discover/funnel/route')
    const response = await GET(adminRequest('?days=90'))
    const payload = await response.json()

    expect(payload.truncated).toBe(true)
    expect(payload.scannedEvents).toBe(5000)
    expect(payload.steps.landing.total).toBe(5000)
  })
})
