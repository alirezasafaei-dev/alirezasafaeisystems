import type { Metadata } from 'next'
import Link from 'next/link'
import { DiscoverFunnelReport } from '@/components/admin/discover-funnel-report'

export const metadata: Metadata = {
  title: 'Discover Funnel Report | Admin',
  robots: {
    index: false,
    follow: false,
  },
}

export default function DiscoverFunnelReportPage() {
  return (
    <main className="min-h-screen bg-background px-4 py-8 md:px-6">
      <div className="mx-auto mb-6 w-full max-w-6xl">
        <Link href="/admin" className="text-sm font-medium underline underline-offset-4">
          ← Admin
        </Link>
      </div>
      <DiscoverFunnelReport />
    </main>
  )
}
