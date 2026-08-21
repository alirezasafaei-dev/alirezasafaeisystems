import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { DiscoverFunnelReport } from '@/components/admin/discover-funnel-report'
import { I18nProvider } from '@/lib/i18n-context'

const baseReport = {
  windowDays: 30,
  scannedEvents: 7,
  truncated: false,
  consentScope: 'stored_consented_telemetry_only',
  metricScope: 'event_counts_not_user_conversion_rates',
  steps: {
    landing: { total: 3, fa: 2, en: 1, unknown: 0 },
    detail: { total: 2, fa: 1, en: 1, unknown: 0 },
    telegram: { total: 1, fa: 1, en: 0, unknown: 0 },
    auditOrQualification: { total: 1, fa: 1, en: 0, unknown: 0 },
  },
}

function response(body: unknown, status = 200): Response {
  return { ok: status >= 200 && status < 300, status, json: async () => body } as Response
}

function renderReport(language: 'fa' | 'en', report = baseReport) {
  const fetchMock = vi.fn().mockResolvedValue(response(report))
  vi.stubGlobal('fetch', fetchMock)
  document.cookie = `lang=${language}; Path=/`
  render(
    <I18nProvider initialLanguage={language}>
      <DiscoverFunnelReport />
    </I18nProvider>,
  )
  return fetchMock
}

describe('DiscoverFunnelReport', () => {
  beforeEach(() => {
    document.cookie = 'lang=; Path=/; Max-Age=0'
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('renders Persian aggregate event counts with explicit consent and metric scope', async () => {
    renderReport('fa')

    expect(screen.getByTestId('discover-funnel-report')).toHaveAttribute('dir', 'rtl')
    expect(screen.getByRole('heading', { name: 'گزارش قیف Discover' })).toBeInTheDocument()
    expect(await screen.findByText('۳')).toBeInTheDocument()
    expect(screen.getByText(/فقط رویدادهای ذخیره‌شده از کاربرانی که رضایت تحلیل داده‌اند/)).toBeInTheDocument()
    expect(screen.getByText(/این اعداد شمارش رویداد هستند، نه نرخ تبدیل یکتای کاربران/)).toBeInTheDocument()
  })

  it('renders English copy and LTR direction', async () => {
    renderReport('en')

    expect(screen.getByTestId('discover-funnel-report')).toHaveAttribute('dir', 'ltr')
    expect(screen.getByRole('heading', { name: 'Discover funnel report' })).toBeInTheDocument()
    expect(await screen.findByText('Landing views')).toBeInTheDocument()
    expect(screen.getByText(/stored events from visitors who granted analytics consent/i)).toBeInTheDocument()
  })

  it('shows an honest empty state when no stored events exist', async () => {
    renderReport('fa', {
      ...baseReport,
      scannedEvents: 0,
      steps: {
        landing: { total: 0, fa: 0, en: 0, unknown: 0 },
        detail: { total: 0, fa: 0, en: 0, unknown: 0 },
        telegram: { total: 0, fa: 0, en: 0, unknown: 0 },
        auditOrQualification: { total: 0, fa: 0, en: 0, unknown: 0 },
      },
    })

    expect(await screen.findByText('در این بازه هیچ رویداد ذخیره‌شده‌ای برای Discover وجود ندارد.')).toBeInTheDocument()
  })

  it('refetches a bounded seven-day window without changing the reporting contract', async () => {
    const fetchMock = renderReport('fa')
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith('/api/admin/discover/funnel?days=30', expect.any(Object)))

    fireEvent.click(screen.getByRole('button', { name: '۷ روز' }))

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith('/api/admin/discover/funnel?days=7', expect.any(Object)))
  })

  it('warns when the bounded server scan was truncated', async () => {
    renderReport('en', { ...baseReport, truncated: true, scannedEvents: 5000 })

    expect(await screen.findByText(/partial because the 5,000-event safety cap was reached/i)).toBeInTheDocument()
  })
})
