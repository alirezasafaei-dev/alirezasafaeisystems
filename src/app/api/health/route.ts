import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET(_request: Request) {
  return NextResponse.json({ status: 'ok', timestamp: new Date().toISOString() })
}
