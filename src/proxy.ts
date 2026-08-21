import { NextRequest, NextResponse } from 'next/server'
import {
  ADMIN_SESSION_COOKIE_NAME,
  isAdminAuthConfigured,
  verifyAdminSessionToken,
} from '@/lib/admin-auth'
import { db } from '@/lib/db'
import { isDiscoverEnglishPublic } from '@/lib/discover'
import { env } from '@/lib/env'

const ADMIN_LOGIN_PATH = '/admin/login'
const PUBLIC_FILE = /\.(.*)$/
const SUPPORTED_LOCALES = new Set(['fa', 'en'])
const ENGLISH_DISCOVER_DETAIL_PATH = /^\/discover\/([a-z0-9]+(?:-[a-z0-9]+)*)$/
const EXCLUDED_PREFIXES = [
  '/_next',
  '/api',
  '/admin',
  '/account',
  '/auth',
  '/assets',
  '/fonts',
  '/images',
  '/manifest.json',
  '/robots.txt',
  '/sitemap.xml',
  '/sitemap-manifest.json',
  '/favicon.ico',
  '/favicon.svg',
]

const BASE_SECURITY_HEADERS = {
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
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

function buildCsp(nonce: string): string {
  const scriptSources = [`'self'`, `'nonce-${nonce}'`]
  const styleSources = [`'self'`, `'nonce-${nonce}'`]
  const fontSources = [`'self'`, 'data:']
  const connectSources = [`'self'`]
  const fontCdnOrigin = getFontCdnOrigin()

  if (fontCdnOrigin) {
    styleSources.push(fontCdnOrigin)
    fontSources.push(fontCdnOrigin)
    connectSources.push(fontCdnOrigin)
  }

  if (env.NODE_ENV !== 'production') {
    scriptSources.push("'unsafe-eval'")
    styleSources.push("'unsafe-inline'")
  }

  return [
    "default-src 'self'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "object-src 'none'",
    "img-src 'self' data: blob: https:",
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
  response.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload')
  return response
}

function resolveLocale(request: NextRequest, pathnameLocale?: string, isInternalContext = false): 'fa' | 'en' {
  if (pathnameLocale === 'fa' || pathnameLocale === 'en') {
    return pathnameLocale
  }

  if (isInternalContext) {
    const propagatedLocale = request.headers.get('x-site-locale') || request.headers.get('x-asdev-locale')
    if (propagatedLocale === 'en' || propagatedLocale === 'fa') {
      return propagatedLocale
    }
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

async function isEnglishDiscoverUnavailable(pathname: string): Promise<boolean | null> {
  const match = ENGLISH_DISCOVER_DETAIL_PATH.exec(pathname)
  if (!match) return false

  try {
    const item = await db.discoverItem.findUnique({
      where: { slug: match[1] },
      select: { publishedEn: true, titleEn: true, descriptionEn: true, contentEn: true },
    })
    return !item || !isDiscoverEnglishPublic(item)
  } catch {
    // Fail open on infrastructure errors. The page-level guard remains authoritative,
    // and a database outage must not be misreported or cached as a content 404.
    return null
  }
}

function englishDiscoverNotFoundResponse({
  pathname,
  correlationId,
  nonce,
}: {
  pathname: string
  correlationId: string
  nonce: string
}): NextResponse {
  const response = new NextResponse(
    '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="robots" content="noindex,nofollow"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Resource not found | Discover</title></head><body><main><h1>Resource not found</h1><p>This Discover resource is not available in English.</p><p><a href="/en/discover">Back to Discover</a></p></main></body></html>',
    {
      status: 404,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Content-Language': 'en',
        'X-Robots-Tag': 'noindex, nofollow',
      },
    },
  )
  withRequestContextHeaders(response, { correlationId, nonce, locale: 'en', pathname })
  withSecurityHeaders(response, pathname, nonce)
  response.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
  return response
}

export async function proxy(request: NextRequest) {
  const pathname = request.nextUrl.pathname
  const hasLocaleRedirectContext = request.headers.get('x-asdev-locale-context') === '1'
  const [, maybeLocale] = pathname.split('/')
  const locale = resolveLocale(request, maybeLocale, hasLocaleRedirectContext)
  const correlationId =
    request.headers.get('x-request-id') ||
    request.headers.get('x-correlation-id') ||
    crypto.randomUUID()
  const nonce = crypto.randomUUID().replace(/-/g, '')
  const isExcludedPath = EXCLUDED_PREFIXES.some((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`))
  const isLocalizedCandidate = !isExcludedPath && !PUBLIC_FILE.test(pathname)
  const hasLocalePrefix = SUPPORTED_LOCALES.has(maybeLocale ?? '')
  const internalPath = hasLocalePrefix ? pathname.replace(/^\/(fa|en)(?=\/|$)/, '') || '/' : pathname
  const normalizedLocalePath = internalPath.startsWith('/') ? internalPath : `/${internalPath}`
  const isExcludedInternalPath = EXCLUDED_PREFIXES.some(
    (prefix) => normalizedLocalePath === prefix || normalizedLocalePath.startsWith(`${prefix}/`),
  )

  const requestHeadersWithContext = new Headers(request.headers)
  requestHeadersWithContext.set('x-request-id', correlationId)
  requestHeadersWithContext.set('x-correlation-id', correlationId)
  requestHeadersWithContext.set('x-csp-nonce', nonce)
  requestHeadersWithContext.set('x-site-locale', locale)
  requestHeadersWithContext.set('x-site-pathname', normalizedLocalePath)
  requestHeadersWithContext.set('x-asdev-locale', locale)
  requestHeadersWithContext.set('x-asdev-pathname', normalizedLocalePath)
  requestHeadersWithContext.set('x-asdev-locale-context', '1')

  const isLocaleInternalCandidate = isLocalizedCandidate && hasLocalePrefix && !isExcludedInternalPath
  const isLegacyAsdevAlias = normalizedLocalePath === '/asdev'

  if (
    (request.method === 'GET' || request.method === 'HEAD') &&
    maybeLocale === 'en' &&
    isLocaleInternalCandidate
  ) {
    const unavailable = await isEnglishDiscoverUnavailable(normalizedLocalePath)
    if (unavailable === true) {
      return englishDiscoverNotFoundResponse({ pathname: normalizedLocalePath, correlationId, nonce })
    }
  }

  if (isLegacyAsdevAlias) {
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = `/${locale}/profile`
    const response = NextResponse.redirect(redirectUrl, 308)
    response.cookies.set('lang', locale, {
      path: '/',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 365,
    })
    withRequestContextHeaders(response, { correlationId, nonce, locale, pathname: normalizedLocalePath })
    return withSecurityHeaders(response, pathname, nonce)
  }

  if (pathname === '/') {
    const response = NextResponse.next({ request: { headers: requestHeadersWithContext } })
    response.cookies.set('lang', 'fa', {
      path: '/',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 365,
    })
    withRequestContextHeaders(response, { correlationId, nonce, locale: 'fa', pathname })
    return withSecurityHeaders(response, pathname, nonce)
  }

  if (isLocaleInternalCandidate) {
    if (locale === 'fa') {
      const redirectUrl = request.nextUrl.clone()
      redirectUrl.pathname = normalizedLocalePath
      const response = NextResponse.redirect(redirectUrl, 308)
      response.cookies.set('lang', locale, {
        path: '/',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 365,
      })
      withRequestContextHeaders(response, { correlationId, nonce, locale, pathname: normalizedLocalePath })
      return withSecurityHeaders(response, pathname, nonce)
    }

    const rewriteUrl = request.nextUrl.clone()
    rewriteUrl.pathname = normalizedLocalePath
    rewriteUrl.protocol = 'http:'
    const response = NextResponse.rewrite(rewriteUrl, { request: { headers: requestHeadersWithContext } })
    response.cookies.set('lang', locale, {
      path: '/',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 365,
    })
    withRequestContextHeaders(response, { correlationId, nonce, locale, pathname: normalizedLocalePath })
    return withSecurityHeaders(response, pathname, nonce)
  }

  if (isLocalizedCandidate && !hasLocalePrefix && pathname !== '/' && !hasLocaleRedirectContext && locale === 'en') {
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = `/en${pathname === '/' ? '' : pathname}`
    const response = NextResponse.redirect(redirectUrl, 308)
    withRequestContextHeaders(response, { correlationId, nonce, locale: 'en', pathname })
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

  const response = NextResponse.next({ request: { headers: requestHeadersWithContext } })
  withRequestContextHeaders(response, { correlationId, nonce, locale, pathname })
  return withSecurityHeaders(response, pathname, nonce)
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|robots.txt|sitemap.xml|manifest.json).*)',
  ],
}