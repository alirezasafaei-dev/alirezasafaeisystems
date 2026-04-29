import { NextRequest, NextResponse } from 'next/server'
import {
  ADMIN_SESSION_COOKIE_NAME,
  isAdminAuthConfigured,
  verifyAdminSessionToken,
} from '@/lib/admin-auth'
import { env } from '@/lib/env'

const ADMIN_LOGIN_PATH = '/admin/login'
const PUBLIC_FILE = /\.(.*)$/
const SUPPORTED_LOCALES = new Set(['fa', 'en'])

const BASE_SECURITY_HEADERS = {
  'X-Frame-Options': 'DENY',
  'X-DNS-Prefetch-Control': 'off',
  'X-Permitted-Cross-Domain-Policies': 'none',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Resource-Policy': 'same-origin',
}

export function getCacheControl(pathname: string): string {
  if (
    pathname.startsWith('/api/') ||
    pathname === '/admin' ||
    pathname.startsWith('/admin/') ||
    pathname === '/account' ||
    pathname.startsWith('/account/') ||
    pathname === '/auth' ||
    pathname.startsWith('/auth/')
  ) {
    return 'no-store, no-cache, must-revalidate, max-age=0'
  }
  return 'public, max-age=0, s-maxage=300, stale-while-revalidate=600'
}

function buildCsp(_nonce: string): string {
  const scriptSources = [`'self'`, "'unsafe-inline'"]
  const styleSources = [`'self'`, "'unsafe-inline'"]
  const fontSources = [`'self'`, 'data:']
  const connectSources = [`'self'`, 'https:']
  const fontCdnOrigin = getFontCdnOrigin()

  if (fontCdnOrigin) {
    styleSources.push(fontCdnOrigin)
    fontSources.push(fontCdnOrigin)
    connectSources.push(fontCdnOrigin)
  }

  if (env.NODE_ENV !== 'production') {
    scriptSources.push("'unsafe-eval'")
  }

  return [
    "default-src 'self'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "object-src 'none'",
    "img-src 'self' data: blob:",
    `font-src ${fontSources.join(' ')}`,
    `style-src ${styleSources.join(' ')}`,
    "style-src-attr 'unsafe-inline'",
    `script-src ${scriptSources.join(' ')}`,
    `connect-src ${connectSources.join(' ')}`,
  ].join('; ')
}

function getFontCdnOrigin(): string | null {
  if (env.NEXT_PUBLIC_FONT_CDN_ENABLED !== 'true' || !env.NEXT_PUBLIC_FONT_CDN_URL) {
    return null
  }

  try {
    const parsed = new URL(env.NEXT_PUBLIC_FONT_CDN_URL)
    return parsed.origin
  } catch {
    return null
  }
}

function withSecurityHeaders(response: NextResponse, pathname: string, nonce: string): NextResponse {
  for (const [header, value] of Object.entries(BASE_SECURITY_HEADERS)) {
    response.headers.set(header, value)
  }
  response.headers.set('Content-Security-Policy', buildCsp(nonce))
  response.headers.set('Cache-Control', getCacheControl(pathname))
  if (env.NODE_ENV === 'production') {
    response.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload')
  }
  return response
}

function resolveLocale(request: NextRequest, pathnameLocale?: string): 'fa' | 'en' {
  if (pathnameLocale === 'fa' || pathnameLocale === 'en') {
    return pathnameLocale
  }

  const cookieLocale = request.cookies.get('lang')?.value
  if (cookieLocale === 'en' || cookieLocale === 'fa') {
    return cookieLocale
  }

  return 'fa'
}

function withRequestContextHeaders(
  response: NextResponse,
  {
    correlationId,
    nonce,
    locale,
    pathname,
  }: {
    correlationId: string
    nonce: string
    locale: 'fa' | 'en'
    pathname: string
  },
): NextResponse {
  response.headers.set('X-Request-ID', correlationId)
  response.headers.set('X-Correlation-ID', correlationId)
  response.headers.set('x-csp-nonce', nonce)
  response.headers.set('x-site-locale', locale)
  response.headers.set('x-site-pathname', pathname)
  // Backward-compatibility with old internal header names.
  response.headers.set('x-asdev-locale', locale)
  response.headers.set('x-asdev-pathname', pathname)
  return response
}

export async function proxy(request: NextRequest) {
  const pathname = request.nextUrl.pathname
  const [, maybeLocale] = pathname.split('/')
  const locale = resolveLocale(request, maybeLocale)
  const correlationId =
    request.headers.get('x-request-id') ||
    request.headers.get('x-correlation-id') ||
    crypto.randomUUID()
  const nonce = crypto.randomUUID().replace(/-/g, '')
  const requestHeaders = new Headers(request.headers)
  requestHeaders.set('x-request-id', correlationId)
  requestHeaders.set('x-correlation-id', correlationId)
  requestHeaders.set('x-csp-nonce', nonce)
  requestHeaders.set('x-site-locale', locale)
  requestHeaders.set('x-site-pathname', pathname)
  requestHeaders.set('x-asdev-locale', locale)
  requestHeaders.set('x-asdev-pathname', pathname)

  const isLocalizedCandidate =
    !pathname.startsWith('/api') &&
    !pathname.startsWith('/admin') &&
    pathname !== '/robots.txt' &&
    pathname !== '/sitemap.xml' &&
    pathname !== '/manifest.json' &&
    pathname !== '/favicon.ico' &&
    pathname !== '/favicon.svg' &&
    !PUBLIC_FILE.test(pathname)

  const hasLocalePrefix = SUPPORTED_LOCALES.has(maybeLocale ?? '')

  if (isLocalizedCandidate && hasLocalePrefix) {
    const internalPath = pathname.replace(/^\/(fa|en)(?=\/|$)/, '') || '/'
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = internalPath
    const response = NextResponse.redirect(redirectUrl)
    response.cookies.set('lang', locale, {
      path: '/',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 365,
    })
    withRequestContextHeaders(response, { correlationId, nonce, locale, pathname })
    return withSecurityHeaders(response, pathname, nonce)
  }

  if (pathname.startsWith('/admin') && pathname !== ADMIN_LOGIN_PATH) {
    if (!isAdminAuthConfigured()) {
      const loginUrl = request.nextUrl.clone()
      loginUrl.pathname = ADMIN_LOGIN_PATH
      loginUrl.searchParams.set('error', 'auth_not_configured')
      const response = NextResponse.redirect(loginUrl)
      withRequestContextHeaders(response, { correlationId, nonce, locale, pathname })
      return withSecurityHeaders(response, pathname, nonce)
    }

    const token = request.cookies.get(ADMIN_SESSION_COOKIE_NAME)?.value
    const session = token ? await verifyAdminSessionToken(token) : null
    if (!session) {
      const loginUrl = request.nextUrl.clone()
      loginUrl.pathname = ADMIN_LOGIN_PATH
      loginUrl.searchParams.set('redirect', pathname)
      const response = NextResponse.redirect(loginUrl)
      withRequestContextHeaders(response, { correlationId, nonce, locale, pathname })
      return withSecurityHeaders(response, pathname, nonce)
    }
  }

  const response = NextResponse.next({ request: { headers: requestHeaders } })
  withRequestContextHeaders(response, { correlationId, nonce, locale, pathname })
  return withSecurityHeaders(response, pathname, nonce)
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|robots.txt|sitemap.xml|manifest.json).*)',
  ],
}
