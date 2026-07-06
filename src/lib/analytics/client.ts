'use client'

const CONSENT_KEY = 'asdev_analytics_consent_v1'
const SESSION_KEY = 'asdev_session_v1'

const ENDPOINT = process.env['NEXT_PUBLIC_ANALYTICS_ENDPOINT']
  ?? (typeof process !== 'undefined' && process.env?.['NEXT_PUBLIC_SITE_URL']
    ? `${process.env['NEXT_PUBLIC_SITE_URL']}/api/analytics/events`
    : '/api/analytics/events')

function hasConsent(): boolean {
  if (typeof window === 'undefined') return false
  try {
    const raw = localStorage.getItem(CONSENT_KEY)
    if (!raw) return false
    const parsed = JSON.parse(raw) as { analytics?: boolean; updatedAt?: number | null }
    return parsed.analytics === true && parsed.updatedAt !== null
  } catch {
    return false
  }
}

function getSessionId(): string {
  if (typeof window === 'undefined') return 'server'
  let session = localStorage.getItem(SESSION_KEY)
  if (!session) {
    session = `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
    localStorage.setItem(SESSION_KEY, session)
  }
  return session
}

type AnalyticsPayload = {
  name: string
  category: 'conversion' | 'engagement' | 'web_vital'
  locale?: 'fa' | 'en'
  variant?: string
  value?: number
  metadata?: Record<string, string | number | boolean>
}

export async function trackEvent(payload: AnalyticsPayload): Promise<void> {
  if (typeof window === 'undefined') return
  if (!hasConsent()) return

  const body = {
    name: payload.name,
    category: payload.category,
    sessionId: getSessionId(),
    path: typeof window !== 'undefined' ? window.location.pathname : '',
    locale: payload.locale,
    variant: payload.variant,
    value: payload.value,
    metadata: payload.metadata
      ? Object.fromEntries(Object.entries(payload.metadata).slice(0, 20))
      : undefined,
  }

  try {
    const serialized = JSON.stringify(body)
    if (navigator.sendBeacon) {
      const blob = new Blob([serialized], { type: 'application/json' })
      navigator.sendBeacon(ENDPOINT, blob)
      return
    }

    await fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: serialized,
      keepalive: true,
    })
  } catch {
    // Avoid breaking UI for telemetry failures.
  }
}
