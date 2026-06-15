import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <div className="max-w-xl text-center space-y-4">
        <h1 className="text-6xl font-bold text-primary">۴۰۴</h1>
        <h2 className="text-2xl font-bold">صفحه مورد نظر یافت نشد</h2>
        <p className="text-sm text-muted-foreground">
          صفحه‌ای که دنبال آن هستید وجود ندارد یا منتقل شده است.
        </p>
        <Link
          href="/"
          className="inline-flex items-center justify-center rounded-md bg-primary text-primary-foreground px-4 py-2 text-sm hover:opacity-90 transition-opacity"
        >
          بازگشت به خانه
        </Link>
      </div>
    </div>
  )
}
