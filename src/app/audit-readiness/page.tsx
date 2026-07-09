import type { Metadata } from 'next'
import { getSiteUrl } from '@/lib/site-config'
import { getRequestLanguage } from '@/lib/i18n/server'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: lang === 'fa' ? 'آیا سایت شما برای Audit آماده است؟' : 'Is Your Site Ready for an Audit?',
    description:
      lang === 'fa'
        ? 'چک‌لیست رایگان برای بررسی آمادگی سایت شما قبل از دریافت گزارش فنی.'
        : 'Free checklist to check your site readiness before getting a technical audit report.',
    alternates: {
      canonical: `${siteUrl}/${lang}/audit-readiness`,
    },
  }
}

export default async function AuditReadinessPage() {
  const lang = await getRequestLanguage()

  const copy = {
    eyebrow: lang === 'en' ? 'Free Checklist' : 'چک‌لیست رایگان',
    title: lang === 'en' ? 'Is Your Site Ready for an Audit?' : 'آیا سایت شما برای Audit آماده است؟',
    intro: lang === 'en'
      ? 'Before running a technical audit, check if your site meets these basic requirements.'
      : 'قبل از اجرای Audit فنی، بررسی کنید که آیا سایت شما این الزامات اساسی را دارد.',
    checks: lang === 'en' ? [
      { label: 'Site is publicly accessible', description: 'Your site must be reachable from the internet, not behind a firewall or VPN.' },
      { label: 'HTTPS is configured', description: 'Most modern audits require HTTPS. If you only have HTTP, some checks may fail.' },
      { label: 'DNS is resolving', description: 'Your domain must point to a valid IP address.' },
      { label: 'No maintenance mode', description: 'If your site is in maintenance mode, the audit will not see real content.' },
      { label: 'Sitemap or robots.txt exists', description: 'Helps the auditor understand your site structure.' },
    ] : [
      { label: 'سایت از اینترنت قابل دسترسی است', description: 'سایت شما باید از اینترنت قابل دسترسی باشد، نه پشت فایروال یا VPN.' },
      { label: 'HTTPS پیکربندی شده است', description: 'بیشتر Audit های مدرن به HTTPS نیاز دارند.' },
      { label: 'DNS در حال رفع است', description: 'دامنه شما باید به یک IP معتبر اشاره کند.' },
      { label: 'حالت تعمیر و نگهداری فعال نیست', description: 'اگر سایت در حالت تعمیر باشد، Audit محتوای واقعی را نمی‌بیند.' },
      { label: 'Sitemap یا robots.txt وجود دارد', description: 'به auditor کمک می‌کند ساختار سایت شما را درک کند.' },
    ],
    cta: lang === 'en' ? 'Start Free Audit' : 'دریافت Audit رایگان',
    sampleReport: lang === 'en' ? 'View Sample Report' : 'مشاهده نمونه گزارش',
  }

  return (
    <main className="container mx-auto max-w-3xl px-4 py-12">
      <p className="text-sm font-semibold uppercase tracking-wider text-primary mb-2">
        {copy.eyebrow}
      </p>
      <h1 className="text-3xl font-bold mb-4">{copy.title}</h1>
      <p className="text-muted-foreground mb-8">{copy.intro}</p>

      <div className="space-y-4 mb-8">
        {copy.checks.map((check, i) => (
          <div key={i} className="rounded-lg border p-4">
            <div className="flex items-start gap-3">
              <span className="text-green-600 mt-0.5">✓</span>
              <div>
                <h3 className="font-semibold">{check.label}</h3>
                <p className="text-sm text-muted-foreground mt-1">{check.description}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <a
          href="https://audit.alirezasafaeisystems.ir/audit?utm_source=portfolio&utm_medium=audit_readiness&utm_campaign=asdev_audit"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center justify-center rounded-md bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground hover:bg-primary/90 transition-colors"
        >
          {copy.cta}
        </a>
        <a
          href="https://audit.alirezasafaeisystems.ir/sample-report?utm_source=portfolio&utm_medium=audit_readiness&utm_campaign=asdev_audit"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center justify-center rounded-md border border-border px-6 py-3 text-sm font-semibold hover:bg-muted transition-colors"
        >
          {copy.sampleReport}
        </a>
      </div>
    </main>
  )
}
