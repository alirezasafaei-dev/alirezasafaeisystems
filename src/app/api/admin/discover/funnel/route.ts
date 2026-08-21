import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { checkRateLimit, createRequestId, enforceAdminAccess, withCommonApiHeaders } from '@/lib/api-security'
import { db } from '@/lib/db'
import { logger } from '@/lib/logger'

const MAX_SCAN_EVENTS = 5000
const RELEVANT_EVENT_NAMES = [
  'discover_landing_view',
  'discover_item_view',
  'discover_telegram_guide_click',
  'discover_telegram_channel_click',
  'discover_telegram_group_click',
  'discover_internal_cta_click',
] as const
const TELEGRAM_EVENT_NAMES = new Set([
  'discover_telegram_guide_click',
  'discover_telegram_channel_click',
  'discover_telegram_group_click',
])
const REPORT_CTA_TARGETS = new Set(['audit_readiness', 'qualification'])
const querySchema = z.object({
  days: z.coerce.number().int().min(1).max(90).default(30),
})

type LocaleBucket = { total: number; fa: number; en: number; unknown: number }

type EventRow = {
  name: string | null
  locale: string | null
  metadata: string | null
}

function emptyBucket(): LocaleBucket {
  return { total: 0, fa: 0, en: 0, unknown: 0 }
}

function increment(bucket: LocaleBucket, locale: string | null) {
  bucket.total += 1
  if (locale === 'fa') bucket.fa += 1
  else if (locale === 'en') bucket.en += 1
  else bucket.unknown += 1
}

function readTarget(metadata: string | null): string | null {
  if (!metadata) return null
  try {
    const parsed = JSON.parse(metadata) as unknown
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return null
    const target = (parsed as Record<string, unknown>).target
    return typeof target === 'string' ? target : null
  } catch {
    return null
  }
}

function aggregate(rows: EventRow[]) {
  const steps = {
    landing: emptyBucket(),
    detail: emptyBucket(),
    telegram: emptyBucket(),
    auditOrQualification: emptyBucket(),
  }

  for (const row of rows) {
    if (row.name === 'discover_landing_view') increment(steps.landing, row.locale)
    else if (row.name === 'discover_item_view') increment(steps.detail, row.locale)
    else if (row.name && TELEGRAM_EVENT_NAMES.has(row.name)) increment(steps.telegram, row.locale)
    else if (row.name === 'discover_internal_cta_click' && REPORT_CTA_TARGETS.has(readTarget(row.metadata) || '')) {
      increment(steps.auditOrQualification, row.locale)
    }
  }

  return steps
}

export async function GET(request: NextRequest) {
  const requestId = createRequestId(request)
  const unauthorized = await enforceAdminAccess(request, requestId)
  if (unauthorized) return unauthorized

  const limit = await checkRateLimit(request, 'admin:discover:funnel:get')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Too many requests', retryAt: limit.retryAt }, { status: 429 }),
      requestId,
      limit.headers,
    )
  }

  const parsedQuery = querySchema.safeParse({ days: request.nextUrl.searchParams.get('days') ?? 30 })
  if (!parsedQuery.success) {
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Invalid reporting window. Use 1 to 90 days.' }, { status: 400 }),
      requestId,
      limit.headers,
    )
  }

  const windowDays = parsedQuery.data.days
  const since = new Date(Date.now() - windowDays * 24 * 60 * 60 * 1000)

  try {
    const rows = await db.analyticsEvent.findMany({
      where: {
        site: 'portfolio',
        name: { in: [...RELEVANT_EVENT_NAMES] },
        createdAt: { gte: since },
      },
      orderBy: { createdAt: 'desc' },
      take: MAX_SCAN_EVENTS + 1,
      select: { name: true, locale: true, metadata: true },
    })
    const truncated = rows.length > MAX_SCAN_EVENTS
    const boundedRows = truncated ? rows.slice(0, MAX_SCAN_EVENTS) : rows

    return withCommonApiHeaders(
      NextResponse.json({
        windowDays,
        scannedEvents: boundedRows.length,
        truncated,
        consentScope: 'stored_consented_telemetry_only',
        metricScope: 'event_counts_not_user_conversion_rates',
        steps: aggregate(boundedRows),
      }),
      requestId,
      limit.headers,
    )
  } catch (error) {
    logger.error('Error fetching Discover funnel report', {
      requestId,
      error: error instanceof Error ? error.message : 'unknown',
    })
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Failed to load Discover funnel report' }, { status: 500 }),
      requestId,
      limit.headers,
    )
  }
}
