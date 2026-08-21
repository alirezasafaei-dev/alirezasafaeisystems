import type { Metadata } from 'next'
import Link from 'next/link'
import { AdminDashboard } from '@/components/admin/admin-dashboard'
import { ADMIN_FUNNEL_COPY } from '@/lib/i18n/admin-funnel-copy'
import { ADMIN_SHELL_COPY } from '@/lib/i18n/admin-shell-copy'
import { getRequestLanguage } from '@/lib/i18n/server'

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: ADMIN_SHELL_COPY[lang].dashboard.metadataTitle,
    robots: {
      index: false,
      follow: false,
    },
  }
}

export default async function AdminPage() {
  const lang = await getRequestLanguage()
  const copy = ADMIN_FUNNEL_COPY[lang]

  return (
    <>
      <div className="container mx-auto px-4 pt-24" dir={lang === 'fa' ? 'rtl' : 'ltr'}>
        <Link
          href="/admin/discover/funnel"
          className="inline-flex items-center rounded-md border px-3 py-2 text-sm font-medium hover:bg-accent"
        >
          {copy.navigationLabel}
        </Link>
      </div>
      <AdminDashboard />
    </>
  )
}
