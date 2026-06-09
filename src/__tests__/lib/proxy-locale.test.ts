import { describe, expect, it } from 'vitest'
import { NextRequest } from 'next/server'
import { proxy } from '@/proxy'

describe('proxy locale routing', () => {
  it('redirects localized /fa path to root and sets lang cookie', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/fa')
    const response = await proxy(request)

    expect(response.status).toBe(308)
    expect(response.headers.get('location')).toBe('https://alirezasafaeisystems.ir/')
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

  it('serves root as the default Persian page without /fa redirect', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/')
    const response = await proxy(request)

    expect(response.status).toBe(200)
    expect(response.headers.get('location')).toBeNull()
    expect(response.headers.get('x-site-locale')).toBe('fa')
    expect(response.headers.get('x-site-pathname')).toBe('/')
  })

  it('redirects locale-prefixed Persian paths to unprefixed paths', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/fa/profile')
    const response = await proxy(request)

    expect(response.status).toBe(308)
    expect(response.headers.get('location')).toBe('https://alirezasafaeisystems.ir/profile')
    expect(response.headers.get('x-site-pathname')).toBe('/profile')
    expect(response.headers.get('x-site-locale')).toBe('fa')
  })

  it('detects english from Accept-Language when locale cookie is not set', async () => {
    const request = new NextRequest('https://alirezasafaeisystems.ir/services', {
      headers: {
        'accept-language': 'en-US,en;q=0.9',
      },
    })
    const response = await proxy(request)

    expect(response.status).toBe(200)
    expect(response.headers.get('x-site-locale')).toBe('fa')
    expect(response.headers.get('x-site-pathname')).toBe('/services')
  })
})
