import { cookies, headers } from 'next/headers'

export type RequestLanguage = 'fa' | 'en'

export async function getRequestLanguage(): Promise<RequestLanguage> {
  const reqHeaders = await headers()
  const headerLocale = reqHeaders.get('x-site-locale') || reqHeaders.get('x-asdev-locale')
  if (headerLocale === 'en' || headerLocale === 'fa') return headerLocale
  const value = (await cookies()).get('lang')?.value
  return value === 'en' ? 'en' : 'fa'
}

export function isRtl(lang: RequestLanguage): boolean {
  return lang === 'fa'
}
