import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { trackEvent } from '@/lib/analytics/client'

describe('trackEvent', () => {
  let sendBeaconSpy: ReturnType<typeof vi.fn>
  let fetchSpy: ReturnType<typeof vi.fn>
  let localStore: Map<string, string>
  let sessionStore: Map<string, string>
  const CONSENT_KEY = 'asdev_analytics_consent_v1'
  const SESSION_KEY = 'asdev_session_v1'

  beforeEach(() => {
    localStore = new Map<string, string>()
    sessionStore = new Map<string, string>()
    sendBeaconSpy = vi.fn().mockReturnValue(true)
    fetchSpy = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal('localStorage', {
      getItem: (key: string) => localStore.get(key) ?? null,
      setItem: (key: string, value: string) => { localStore.set(key, value) },
      removeItem: (key: string) => { localStore.delete(key) },
    })
    vi.stubGlobal('sessionStorage', {
      getItem: (key: string) => sessionStore.get(key) ?? null,
      setItem: (key: string, value: string) => { sessionStore.set(key, value) },
      removeItem: (key: string) => { sessionStore.delete(key) },
    })
    vi.stubGlobal('navigator', { sendBeacon: sendBeaconSpy })
    vi.stubGlobal('fetch', fetchSpy)
    vi.stubGlobal('window', { location: { pathname: '/fa/' } })

    localStorage.setItem(CONSENT_KEY, JSON.stringify({ analytics: true, updatedAt: Date.now(), version: 1 }))
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
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

  it('keeps analytics correlation in sessionStorage rather than persistent localStorage', async () => {
    await trackEvent({ name: 'first_event', category: 'engagement' })
    await trackEvent({ name: 'second_event', category: 'conversion' })

    const firstBody = JSON.parse(await sendBeaconSpy.mock.calls[0][1].text())
    const secondBody = JSON.parse(await sendBeaconSpy.mock.calls[1][1].text())

    expect(firstBody.sessionId).toBeTruthy()
    expect(secondBody.sessionId).toBe(firstBody.sessionId)
    expect(sessionStore.get(SESSION_KEY)).toBe(firstBody.sessionId)
    expect(localStore.has(SESSION_KEY)).toBe(false)
  })

  it('uses Web Crypto for newly created analytics session IDs', async () => {
    const sessionId = '4b083d8b-b83f-48c2-9f1d-4fe3a2fbb220'
    const randomUUID = vi.fn().mockReturnValue(sessionId)
    vi.stubGlobal('crypto', { randomUUID })

    await trackEvent({ name: 'secure_session_event', category: 'engagement' })

    const body = JSON.parse(await sendBeaconSpy.mock.calls[0][1].text())
    expect(randomUUID).toHaveBeenCalledOnce()
    expect(body.sessionId).toBe(sessionId)
    expect(sessionStore.get(SESSION_KEY)).toBe(sessionId)
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
