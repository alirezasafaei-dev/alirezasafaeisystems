import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { checkRateLimit, createRequestId, withCommonApiHeaders } from '@/lib/api-security'
import { db } from '@/lib/db'

const webVitalsSchema = z.object({
  LCP: z.number().nonnegative(),
  FID: z.number().nonnegative(),
  CLS: z.number().nonnegative(),
  FCP: z.number().nonnegative(),
  TTFB: z.number().nonnegative(),
  locale: z.enum(['fa', 'en']).optional(),
  path: z.string().max(200).optional(),
})

export async function POST(request: NextRequest) {
  const requestId = createRequestId(request)
  const limit = await checkRateLimit(request, 'web-vitals')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ success: false, message: 'Too many requests' }, { status: 429 }),
      requestId,
      limit.headers
    )
  }

  try {
    const body: unknown = await request.json()
    const parsed = webVitalsSchema.safeParse(body)

    if (!parsed.success) {
      return withCommonApiHeaders(
        NextResponse.json({ success: false, message: 'Validation failed' }, { status: 400 }),
        requestId,
        limit.headers
      )
    }

    const payload = parsed.data
    const path = payload.path || request.nextUrl.searchParams.get('path') || undefined

    if (!process.env.DATABASE_URL) {
      return withCommonApiHeaders(
        NextResponse.json({ success: true, skipped: 'database_unconfigured' }, { status: 202 }),
        requestId,
        limit.headers
      )
    }

    const vitals = [
      ['LCP', payload.LCP],
      ['FID', payload.FID],
      ['CLS', payload.CLS],
      ['FCP', payload.FCP],
      ['TTFB', payload.TTFB],
    ] as const

    await Promise.all(
      vitals.map(([name, value]) =>
        db.analyticsEvent.create({
          data: {
            site: 'portfolio',
            event: 'web_vital',
            name,
            category: 'web_vital',
            path,
            locale: payload.locale,
            value,
          },
        })
      )
    )

    return withCommonApiHeaders(
      NextResponse.json({ success: true }, { status: 201 }),
      requestId,
      limit.headers
    )
  } catch {
    return withCommonApiHeaders(
      NextResponse.json({ success: false, message: 'Internal error' }, { status: 500 }),
      requestId,
      limit.headers
    )
  }
}
