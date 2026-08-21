import type { Metadata } from 'next'
import { AdminDashboard } from '@/components/admin/admin-dashboard'
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

export default function AdminPage() {
  return <AdminDashboard />
}
