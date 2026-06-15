import { getRequestLanguage } from '@/lib/i18n/server'
import { redirect } from 'next/navigation'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  robots: {
    index: false,
    follow: true,
  },
}

export default async function LegacyAsdevPage() {
  const lang = await getRequestLanguage()
  redirect(lang === 'fa' ? '/profile' : `/${lang}/profile`)
}
