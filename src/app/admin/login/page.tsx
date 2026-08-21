import type { Metadata } from 'next'
import { Suspense } from 'react'
import { AdminLoginForm } from '@/components/admin/admin-login-form'
import { ADMIN_SHELL_COPY } from '@/lib/i18n/admin-shell-copy'
import { getRequestLanguage } from '@/lib/i18n/server'

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: ADMIN_SHELL_COPY[lang].login.metadataTitle,
    robots: {
      index: false,
      follow: false,
    },
  }
}

export default async function AdminLoginPage() {
  const lang = await getRequestLanguage()
  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-muted/30">
      <Suspense fallback={<div className="text-sm text-muted-foreground">{ADMIN_SHELL_COPY[lang].login.loading}</div>}>
        <AdminLoginForm />
      </Suspense>
    </div>
  )
}
