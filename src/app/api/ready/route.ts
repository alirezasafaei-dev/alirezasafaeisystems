import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET(_request: Request) {
  // در آینده می‌توان وابستگی DB/Redis را هم چک کرد
  return NextResponse.json({ status: 'ready' })
}

export async function HEAD(request: Request) {
  const response = await GET(request)
  return new NextResponse(null, { status: response.status, headers: response.headers })
}
