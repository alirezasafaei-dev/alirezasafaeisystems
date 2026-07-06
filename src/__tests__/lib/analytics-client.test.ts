import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { trackEvent } from '@/lib/analytics/client'

describe('trackEvent', () => {
  let sendBeaconSpy: ReturnType<typeof vi.fn>
  let fetchSpy: ReturnType<typeof vi.fn>
  const CONSENT_KEY = 'asdev_analytics_consent_v1'

  beforeEach(() => {
    sendBeaconSpy = vi.fn().mockReturnValue(true)
    fetchSpy = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal('navigator', { sendBeacon: sendBeaconSpy })
    vi.stubGlobal('fetch', fetchSpy)
    vi.stubGlobal('window', { location: { pathname: '/fa/' } })

    localStorage.setItem(CONSENT_KEY, JSON.stringify({ analytics: true, updatedAt: Date.now(), version: 1 }))
  })

  afterEach(() => {
    vi.restoreAllMocks()
    localStorage.removeItem(CONSENT_KEY)
  })

  it('sends event via sendBeacon when available', async () => {
    await trackEvent({
      name: 'test_event',
      category: 'engagement',
      locale: 'fa',
    })

    expect(sendBeaconSpy).toHaveBeenCalledOnce()
    const [url, blob] = sendBeaconSpy.mock.calls[0]
    expect(url).toBe('/api/analytics/events')
    expect(blob).toBeInstanceOf(Blob)
  })

  it('sends event via fetch when sendBeacon is not available', async () => {
    vi.stubGlobal('navigator', { sendBeacon: undefined })

    await trackEvent({
      name: 'test_event',
      category: 'conversion',
      locale: 'en',
    })

    expect(fetchSpy).toHaveBeenCalledOnce()
    expect(fetchSpy).toHaveBeenCalledWith(
      '/api/analytics/events',
      expect.objectContaining({
        method: 'POST',
        keepalive: true,
      })
    )
  })

  it('does nothing on server side', async () => {
    vi.stubGlobal('window', undefined)
    vi.stubGlobal('navigator', {})

    await trackEvent({
      name: 'test_event',
      category: 'engagement',
    })

    expect(sendBeaconSpy).not.toHaveBeenCalled()
    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('does nothing without consent', async () => {
    localStorage.removeItem(CONSENT_KEY)

    await trackEvent({
      name: 'test_event',
      category: 'engagement',
    })

    expect(sendBeaconSpy).not.toHaveBeenCalled()
    expect(fetchSpy).not.toHaveBeenCalled()
  })

  it('sends correct payload structure', async () => {
    await trackEvent({
      name: 'test_event',
      category: 'engagement',
      metadata: { key1: 'value1', key2: 42 },
    })

    const [, blob] = sendBeaconSpy.mock.calls[0]
    const text = await blob.text()
    const body = JSON.parse(text)
    expect(body.name).toBe('test_event')
    expect(body.category).toBe('engagement')
    expect(body.path).toBe('/fa/')
    expect(body.metadata).toEqual({ key1: 'value1', key2: 42 })
  })

  it('limits metadata to 20 entries', async () => {
    const metadata: Record<string, string> = {}
    for (let i = 0; i < 30; i++) {
      metadata[`key${i}`] = `value${i}`
    }

    await trackEvent({
      name: 'test_event',
      category: 'engagement',
      metadata,
    })

    const [, blob] = sendBeaconSpy.mock.calls[0]
    const text = await blob.text()
    const body = JSON.parse(text)
    expect(Object.keys(body.metadata)).toHaveLength(20)
  })

  it('includes current path in payload', async () => {
    await trackEvent({
      name: 'test_event',
      category: 'engagement',
    })

    const [, blob] = sendBeaconSpy.mock.calls[0]
    const text = await blob.text()
    const body = JSON.parse(text)
    expect(body.path).toBe('/fa/')
  })

  it('handles fetch errors gracefully', async () => {
    vi.stubGlobal('navigator', { sendBeacon: undefined })
    fetchSpy.mockRejectedValue(new Error('Network error'))

    await expect(
      trackEvent({
        name: 'test_event',
        category: 'engagement',
      })
    ).resolves.not.toThrow()
  })
})
