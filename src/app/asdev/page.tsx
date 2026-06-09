import { getRequestLanguage } from '@/lib/i18n/server'
import { redirect } from 'next/navigation'

export default async function LegacyAsdevPage() {
  const lang = await getRequestLanguage()
  redirect(lang === 'fa' ? '/profile' : `/${lang}/profile`)
}
