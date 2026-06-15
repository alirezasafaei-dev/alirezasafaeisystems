'use client'

import { useEffect } from 'react'
import Link from 'next/link'

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      console.error('Unhandled app error', {
        message: error.message,
        digest: error.digest,
      })
    }
  }, [error])

  return (
    <html lang="fa" dir="rtl">
      <body className="min-h-screen flex items-center justify-center p-6 bg-background text-foreground">
        <div className="max-w-xl text-center space-y-4">
          <h1 className="text-4xl font-bold text-primary">خطا</h1>
          <h2 className="text-xl font-semibold">خطای غیرمنتظره رخ داد</h2>
          <p className="text-sm text-muted-foreground">
            درخواست شما با خطا مواجه شد. لطفاً دوباره تلاش کنید یا با مدیر سامانه تماس بگیرید.
          </p>
          {error.digest && (
            <p className="text-xs text-muted-foreground font-mono">Error ID: {error.digest}</p>
          )}
          <div className="flex flex-wrap justify-center gap-3">
            <button
              type="button"
              onClick={reset}
              className="inline-flex items-center justify-center rounded-md bg-primary text-primary-foreground px-4 py-2 text-sm hover:opacity-90 transition-opacity"
            >
              تلاش مجدد
            </button>
            <Link
              href="/"
              className="inline-flex items-center justify-center rounded-md border border-border px-4 py-2 text-sm hover:bg-muted transition-colors"
            >
              بازگشت به خانه
            </Link>
          </div>
        </div>
      </body>
    </html>
  )
}
