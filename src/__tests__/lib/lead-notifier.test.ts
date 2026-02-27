import { beforeEach, describe, expect, it, vi } from 'vitest'

const ORIGINAL_ENV = { ...process.env }

describe('lead-notifier', () => {
  beforeEach(() => {
    process.env = { ...ORIGINAL_ENV, NODE_ENV: 'test' } as NodeJS.ProcessEnv
    delete (process.env as Record<string, string | undefined>).LEAD_NOTIFICATION_WEBHOOK_URL
    vi.resetModules()
    vi.unstubAllGlobals()
  })

  it('no-ops when webhook is not configured', async () => {
    const fetchSpy = vi.fn()
    vi.stubGlobal('fetch', fetchSpy)

    const { notifyLeadSubmission } = await import('@/lib/lead-notifier')
    await notifyLeadSubmission({
      type: 'lead',
      submittedAt: new Date().toISOString(),
      requestId: 'req_1',
      email: 'lead@example.com',
      summary: 'hello',
    })

    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('sends webhook and warns on non-2xx responses', async () => {
    process.env.LEAD_NOTIFICATION_WEBHOOK_URL = 'https://hooks.example.test/lead'
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        status: 500,
      })
    )

    const { logger } = await import('@/lib/logger')
    const warnSpy = vi.spyOn(logger, 'warn').mockImplementation(() => undefined)
    const { notifyLeadSubmission } = await import('@/lib/lead-notifier')

    await notifyLeadSubmission({
      type: 'contact',
      submittedAt: new Date().toISOString(),
      requestId: 'req_2',
      email: 'a@b.com',
      name: 'Ali',
      summary: 'ping',
      subject: 'hi',
    })

    expect(warnSpy).toHaveBeenCalledTimes(1)
    expect(warnSpy.mock.calls[0]?.[0]).toContain('non-2xx')
  })

  it('warns when webhook request throws', async () => {
    process.env.LEAD_NOTIFICATION_WEBHOOK_URL = 'https://hooks.example.test/lead'
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('boom')))

    const { logger } = await import('@/lib/logger')
    const warnSpy = vi.spyOn(logger, 'warn').mockImplementation(() => undefined)
    const { notifyLeadSubmission } = await import('@/lib/lead-notifier')

    await notifyLeadSubmission({
      type: 'lead',
      submittedAt: new Date().toISOString(),
      requestId: 'req_3',
      email: 'a@b.com',
      organizationName: 'AliReza Safaei',
      summary: 'x',
    })

    expect(warnSpy).toHaveBeenCalledTimes(1)
    expect(warnSpy.mock.calls[0]?.[0]).toContain('failed')
  })
})
