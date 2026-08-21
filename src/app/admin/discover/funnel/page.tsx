import type { Metadata } from 'next'
import Link from 'next/link'
import { DiscoverFunnelReport } from '@/components/admin/discover-funnel-report'
import { ADMIN_FUNNEL_COPY } from '@/lib/i18n/admin-funnel-copy'
import { getRequestLanguage } from '@/lib/i18n/server'

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: ADMIN_FUNNEL_COPY[lang].metadataTitle,
    robots: {
      index: false,
      follow: false,
    },
  }
}

export default async function DiscoverFunnelReportPage() {
  const lang = await getRequestLanguage()
  const copy = ADMIN_FUNNEL_COPY[lang]

  return (
    <main className="min-h-screen bg-background px-4 py-8 md:px-6" dir={lang === 'fa' ? 'rtl' : 'ltr'}>
      <div className="mx-auto mb-6 w-full max-w-6xl">
        <Link href="/admin" className="text-sm font-medium underline underline-offset-4">
          {copy.backToAdmin}
        </Link>
      </div>
      <DiscoverFunnelReport />
    </main>
  )
}
