'use client'

import { useEffect, useState } from 'react'
import { useI18n } from '@/lib/i18n-context'

type FunnelBucket = {
  total: number
  fa: number
  en: number
  unknown: number
}

type FunnelReport = {
  windowDays: number
  scannedEvents: number
  truncated: boolean
  consentScope: 'stored_consented_telemetry_only'
  metricScope: 'event_counts_not_user_conversion_rates'
  steps: {
    landing: FunnelBucket
    detail: FunnelBucket
    telegram: FunnelBucket
    auditOrQualification: FunnelBucket
  }
}

type Copy = {
  title: string
  description: string
  consentNotice: string
  metricNotice: string
  loading: string
  loadError: string
  retry: string
  empty: string
  truncated: string
  scanned: string
  windows: Record<7 | 30 | 90, string>
  steps: Record<keyof FunnelReport['steps'], string>
  localeSplit: (fa: string, en: string, unknown: string) => string
}

const COPY: Record<'fa' | 'en', Copy> = {
  fa: {
    title: 'گزارش قیف Discover',
    description: 'نمایش فقط بر اساس رویدادهای واقعی ذخیره‌شده در بازه انتخابی.',
    consentNotice: 'فقط رویدادهای ذخیره‌شده از کاربرانی که رضایت تحلیل داده‌اند در این گزارش دیده می‌شود.',
    metricNotice: 'این اعداد شمارش رویداد هستند، نه نرخ تبدیل یکتای کاربران.',
    loading: 'در حال بارگذاری گزارش…',
    loadError: 'بارگذاری گزارش Discover ناموفق بود.',
    retry: 'تلاش دوباره',
    empty: 'در این بازه هیچ رویداد ذخیره‌شده‌ای برای Discover وجود ندارد.',
    truncated: 'این گزارش جزئی است چون سقف ایمنی ۵٬۰۰۰ رویداد پر شده است.',
    scanned: 'رویداد بررسی‌شده',
    windows: { 7: '۷ روز', 30: '۳۰ روز', 90: '۹۰ روز' },
    steps: {
      landing: 'بازدید صفحه Discover',
      detail: 'بازدید جزئیات',
      telegram: 'کلیک تلگرام',
      auditOrQualification: 'کلیک Audit / ارزیابی',
    },
    localeSplit: (fa, en, unknown) => `فارسی ${fa} · انگلیسی ${en} · نامشخص ${unknown}`,
  },
  en: {
    title: 'Discover funnel report',
    description: 'Read-only counts from events actually stored inside the selected window.',
    consentNotice: 'This report includes only stored events from visitors who granted analytics consent.',
    metricNotice: 'These are event counts, not unique-user conversion rates.',
    loading: 'Loading report…',
    loadError: 'Failed to load the Discover funnel report.',
    retry: 'Retry',
    empty: 'No stored Discover events exist in this window.',
    truncated: 'This report is partial because the 5,000-event safety cap was reached.',
    scanned: 'events scanned',
    windows: { 7: '7 days', 30: '30 days', 90: '90 days' },
    steps: {
      landing: 'Landing views',
      detail: 'Detail views',
      telegram: 'Telegram clicks',
      auditOrQualification: 'Audit / qualification CTA clicks',
    },
    localeSplit: (fa, en, unknown) => `FA ${fa} · EN ${en} · unknown ${unknown}`,
  },
}

const WINDOWS = [7, 30, 90] as const

function isFunnelReport(value: unknown): value is FunnelReport {
  if (!value || typeof value !== 'object') return false
  const report = value as Partial<FunnelReport>
  return typeof report.windowDays === 'number'
    && typeof report.scannedEvents === 'number'
    && typeof report.truncated === 'boolean'
    && report.consentScope === 'stored_consented_telemetry_only'
    && report.metricScope === 'event_counts_not_user_conversion_rates'
    && Boolean(report.steps)
}

export function DiscoverFunnelReport() {
  const { language } = useI18n()
  const copy = COPY[language]
  const [days, setDays] = useState<(typeof WINDOWS)[number]>(30)
  const [report, setReport] = useState<FunnelReport | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [reloadKey, setReloadKey] = useState(0)
  const numberLocale = language === 'fa' ? 'fa-IR' : 'en-US'
  const formatNumber = (value: number) => value.toLocaleString(numberLocale)

  useEffect(() => {
    const controller = new AbortController()

    async function loadReport() {
      setLoading(true)
      setError(false)
      try {
        const response = await fetch(`/api/admin/discover/funnel?days=${days}`, {
          cache: 'no-store',
          credentials: 'same-origin',
          signal: controller.signal,
        })
        if (!response.ok) throw new Error('report_request_failed')
        const payload: unknown = await response.json()
        if (!isFunnelReport(payload)) throw new Error('invalid_report_payload')
        setReport(payload)
      } catch (loadError) {
        if (loadError instanceof DOMException && loadError.name === 'AbortError') return
        setReport(null)
        setError(true)
      } finally {
        if (!controller.signal.aborted) setLoading(false)
      }
    }

    void loadReport()
    return () => controller.abort()
  }, [days, reloadKey])

  return (
    <section
      data-testid="discover-funnel-report"
      dir={language === 'fa' ? 'rtl' : 'ltr'}
      className="mx-auto w-full max-w-6xl space-y-6"
    >
      <header className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight">{copy.title}</h1>
        <p className="text-sm text-muted-foreground">{copy.description}</p>
      </header>

      <div className="flex flex-wrap gap-2" aria-label={language === 'fa' ? 'بازه گزارش' : 'Report window'}>
        {WINDOWS.map((windowDays) => (
          <button
            key={windowDays}
            type="button"
            aria-pressed={days === windowDays}
            onClick={() => setDays(windowDays)}
            className="rounded-md border px-3 py-2 text-sm font-medium disabled:opacity-60"
          >
            {copy.windows[windowDays]}
          </button>
        ))}
      </div>

      <div className="space-y-2 rounded-lg border bg-muted/30 p-4 text-sm leading-6">
        <p>{copy.consentNotice}</p>
        <p>{copy.metricNotice}</p>
      </div>

      {loading ? <p role="status">{copy.loading}</p> : null}

      {!loading && error ? (
        <div role="alert" className="space-y-3 rounded-lg border p-4">
          <p>{copy.loadError}</p>
          <button
            type="button"
            className="rounded-md border px-3 py-2 text-sm font-medium"
            onClick={() => setReloadKey((value) => value + 1)}
          >
            {copy.retry}
          </button>
        </div>
      ) : null}

      {!loading && report ? (
        <>
          <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
            <span>{formatNumber(report.scannedEvents)} {copy.scanned}</span>
            {report.truncated ? <span role="status">{copy.truncated}</span> : null}
          </div>

          {report.scannedEvents === 0 ? (
            <p className="rounded-lg border p-5 text-sm text-muted-foreground">{copy.empty}</p>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
              {(Object.keys(report.steps) as Array<keyof FunnelReport['steps']>).map((stepKey) => {
                const bucket = report.steps[stepKey]
                return (
                  <article key={stepKey} className="rounded-lg border bg-card p-5 shadow-sm">
                    <h2 className="text-sm font-semibold text-muted-foreground">{copy.steps[stepKey]}</h2>
                    <p className="mt-3 text-3xl font-bold tabular-nums">{formatNumber(bucket.total)}</p>
                    <p className="mt-2 text-xs leading-5 text-muted-foreground">
                      {copy.localeSplit(formatNumber(bucket.fa), formatNumber(bucket.en), formatNumber(bucket.unknown))}
                    </p>
                  </article>
                )
              })}
            </div>
          )}
        </>
      ) : null}
    </section>
  )
}
