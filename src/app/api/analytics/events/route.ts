import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { checkRateLimit, createRequestId, withCommonApiHeaders } from '@/lib/api-security'
import { db } from '@/lib/db'

const analyticsSchema = z.object({
  name: z.string().min(2).max(120),
  category: z.enum(['conversion', 'engagement', 'web_vital']),
  path: z.string().max(200).optional().default(''),
  locale: z.enum(['fa', 'en']).optional(),
  variant: z.string().max(40).optional().default(''),
  value: z.number().finite().optional(),
  metadata: z.record(z.string(), z.union([z.string(), z.number(), z.boolean()])).optional(),
})

export async function POST(request: NextRequest) {
  const requestId = createRequestId(request)
  const limit = await checkRateLimit(request, 'analytics')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ success: false, message: 'Too many requests' }, { status: 429 }),
      requestId,
      limit.headers
    )
  }

  try {
    const body: unknown = await request.json()
    const parsed = analyticsSchema.safeParse(body)

    if (!parsed.success) {
      return withCommonApiHeaders(
        NextResponse.json({ success: false, message: 'Validation failed' }, { status: 400 }),
        requestId,
        limit.headers
      )
    }

    const payload = parsed.data

    if (!process.env.DATABASE_URL) {
      return withCommonApiHeaders(
        NextResponse.json({ success: true, skipped: 'database_unconfigured' }, { status: 202 }),
        requestId,
        limit.headers
      )
    }

    await db.analyticsEvent.create({
      data: {
        site: 'portfolio',
        event: payload.category,
        name: payload.name,
        category: payload.category,
        path: payload.path || undefined,
        locale: payload.locale,
        variant: payload.variant || undefined,
        value: payload.value,
        metadata: payload.metadata ? JSON.stringify(payload.metadata) : undefined,
      },
    })

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
