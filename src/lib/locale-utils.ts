export type Locale = 'fa' | 'en'

export function withLocale(path: string, lang: Locale): string {
  const normalized = path.startsWith('/') ? path : `/${path}`
  return lang === 'fa' ? normalized : `/${lang}${normalized === '/' ? '/' : normalized}`
}

export function getLocalizedPathname(pathname: string, lang: Locale): string {
  const withoutLocale = pathname.replace(/^\/(fa|en)(?=\/|$)/, '') || '/'
  return withLocale(withoutLocale, lang)
}

export function extractLocale(pathname: string): Locale {
  if (pathname.startsWith('/en')) return 'en'
  return 'fa'
}

export function swapLocale(pathname: string, targetLocale: Locale): string {
  const normalized = pathname.endsWith('/') ? pathname : `${pathname}/`
  if (normalized.startsWith('/fa/')) {
    return normalized.replace('/fa/', `/${targetLocale}/`)
  }
  if (normalized.startsWith('/en/')) {
    return normalized.replace('/en/', `/${targetLocale}/`)
  }
  if (targetLocale === 'fa') {
    return normalized
  }
  return `/${targetLocale}${normalized}`
}
