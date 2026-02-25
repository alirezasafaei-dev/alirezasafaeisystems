import { NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { logger } from '@/lib/logger'

export const dynamic = 'force-dynamic'

export async function GET(_request: Request) {
  try {
    await db.$queryRaw`SELECT 1`
    return NextResponse.json({ status: 'ready' })
  } catch (error) {
    logger.error('Ready endpoint database check failed', {
      error: error instanceof Error ? error.message : 'unknown',
    })
    return NextResponse.json({ status: 'not_ready' }, { status: 503 })
  }
}

export async function HEAD(request: Request) {
  const response = await GET(request)
  return new NextResponse(null, { status: response.status, headers: response.headers })
}
