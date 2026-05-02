import { describe, expect, it } from 'vitest'
import { NextRequest } from 'next/server'
import { proxy } from '@/proxy'

function requireLocation(value: string | null): string {
  if (!value) {
    throw new Error('Expected location header to be set')
  }
  return value
}

describe('proxy locale routing', () => {
  it('rewrites localized /fa path to internal root and sets lang cookie', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/fa')
    const response = await proxy(request)

    expect(response.status).toBe(200)
    const location = response.headers.get('location')
    expect(location).toBeNull()
    expect(response.headers.get('x-site-pathname')).toBe('/')
    expect(response.cookies.get('lang')?.value).toBe('fa')
    expect(response.headers.get('x-site-locale')).toBe('fa')
  })

  it('rewrites localized /en path to internal route and sets english cookie', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/en/services')
    const response = await proxy(request)

    expect(response.status).toBe(200)
    const location = response.headers.get('location')
    expect(location).toBeNull()
    expect(response.headers.get('x-site-pathname')).toBe('/services')
    expect(response.cookies.get('lang')?.value).toBe('en')
    expect(response.headers.get('x-site-locale')).toBe('en')
  })

  it('redirects root to /fa once and avoids locale redirect loop', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/')
    const response = await proxy(request)

    expect(response.status).toBe(308)
    expect(response.headers.get('location')).toContain('/fa')
    expect(response.headers.get('x-site-locale')).toBe('fa')
    expect(response.headers.get('x-site-pathname')).toBe('/')
  })

  it('detects english from Accept-Language when locale cookie is not set', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/services', {
      headers: {
        'accept-language': 'en-US,en;q=0.9',
      },
    })
    const response = await proxy(request)

    expect(response.status).toBe(308)
    expect(response.headers.get('x-site-locale')).toBe('fa')
    expect(response.headers.get('x-site-pathname')).toBe('/services')
  })
})
