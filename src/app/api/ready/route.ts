import { NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { logger } from '@/lib/logger'

export const dynamic = 'force-dynamic'
const READINESS_CACHE_CONTROL = 'no-store'

function skipDatabaseCheck(): boolean {
  return process.env.DATABASE_URL === undefined || process.env.DATABASE_URL === ''
}

export async function GET(_request: Request) {
  const startedAt = Date.now()

  if (skipDatabaseCheck()) {
    return NextResponse.json(
      {
        status: 'ready',
        ok: true,
        service: 'alirezasafaeisystems',
        timestamp: new Date().toISOString(),
        responseMs: Date.now() - startedAt,
        checks: [
          {
            name: 'database',
            status: 'skipped',
            detail: 'DATABASE_URL is not configured on this environment',
          },
        ],
      },
      {
        headers: {
          'Cache-Control': READINESS_CACHE_CONTROL,
        },
      },
    )
  }

  try {
    await db.$queryRaw`SELECT 1`
    return NextResponse.json(
      {
        status: 'ready',
        ok: true,
        service: 'alirezasafaeisystems',
        timestamp: new Date().toISOString(),
        responseMs: Date.now() - startedAt,
      },
      {
        headers: {
          'Cache-Control': READINESS_CACHE_CONTROL,
        },
      },
    )
  } catch (error) {
    logger.error('Ready endpoint database check failed', {
      error: error instanceof Error ? error.message : 'unknown',
    })
    return NextResponse.json(
      {
        status: 'not_ready',
        ok: false,
        service: 'alirezasafaeisystems',
        timestamp: new Date().toISOString(),
        responseMs: Date.now() - startedAt,
      },
      {
        status: 503,
        headers: {
          'Cache-Control': READINESS_CACHE_CONTROL,
        },
      },
    )
  }
}

export async function HEAD(request: Request) {
  const response = await GET(request)
  return new NextResponse(null, { status: response.status, headers: response.headers })
}
