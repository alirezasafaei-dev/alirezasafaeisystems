import type { Metadata } from 'next'
import Link from 'next/link'
import { brand } from '@/lib/brand'
import { getSiteUrl } from '@/lib/site-config'

const siteUrl = getSiteUrl()
const utmSource = 'asdev-portfolio'

function withUtm(baseUrl: string, content: 'footer' | 'asdev_page') {
  const url = new URL(baseUrl)
  url.searchParams.set('utm_source', utmSource)
  url.searchParams.set('utm_medium', 'cross_site')
  url.searchParams.set('utm_campaign', 'asdev_network')
  url.searchParams.set('utm_content', content)
  return url.toString()
}

export const metadata: Metadata = {
  title: 'ASDEV — صفحه برند و شبکه',
  description: 'صفحه برند ASDEV و لینک‌های رسمی شبکه (Portfolio، PersianToolbox، Audit IR) برای همکاری و تماس.',
  alternates: {
    canonical: `${siteUrl}/asdev`,
  },
  openGraph: {
    title: 'ASDEV | Alireza Safaei',
    description: 'معرفی برند ASDEV و لینک‌دهی متقابل بین پورتفولیو، PersianToolbox و Audit IR.',
    url: `${siteUrl}/asdev`,
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'ASDEV — صفحه برند',
    description: 'لینک‌های رسمی شبکه ASDEV و راه‌های ارتباطی علیرضا صفایی.',
  },
}

export default function AsdevPage() {
  const networkLinks = [
    {
      label: 'پورتفولیو و راه‌های ارتباطی',
      href: withUtm('https://alirezasafaeisystems.ir/', 'asdev_page'),
      description: 'رزومه، خدمات و راه‌های تماس مستقیم با علیرضا صفایی.',
    },
    {
      label: 'PersianToolbox — ابزارهای فارسی (لوکال و امن)',
      href: withUtm('https://persiantoolbox.ir/', 'asdev_page'),
      description: 'مجموعه ابزارهای فارسی با پردازش لوکال و حریم خصوصی کاربر.',
    },
    {
      label: 'Audit IR — بررسی فنی و امنیتی',
      href: withUtm('https://audit.alirezasafaeisystems.ir/', 'asdev_page'),
      description: 'پلتفرم تحلیل Performance/SEO/Security با گزارش عملیاتی.',
    },
  ]

  const jsonLd = {
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'Organization',
        name: 'ASDEV',
        url: siteUrl,
        sameAs: [brand.githubUrl, brand.linkedinUrl, brand.telegramUrl].filter(Boolean),
      },
      {
        '@type': 'Person',
        name: brand.ownerName,
        url: siteUrl,
        jobTitle: 'Architecture & Systems Engineer',
      },
    ],
  }

  const contactLinks = [
    { label: 'GitHub', href: 'https://github.com/alirezasafaeisystems' },
    { label: 'Telegram', href: 'https://t.me/asdevsystems' },
    { label: 'Portfolio & contact', href: 'https://alirezasafaeisystems.ir/' },
  ]

  return (
    <main className="container mx-auto px-4 py-16 max-w-5xl space-y-10 subtle-grid" id="main-content">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      <header className="space-y-3 rounded-2xl border bg-card p-6 md:p-8 card-hover aurora-shell">
        <p className="text-sm font-semibold text-primary">ASDEV | Architecture & Systems DEV</p>
        <h1 className="text-3xl md:text-4xl font-bold">ASDEV — علیرضا صفایی</h1>
        <p className="text-muted-foreground leading-7 md:leading-8">
          تمرکز بر بومی‌سازی زیرساخت، تاب‌آوری عملیاتی، امنیت و SEO فارسی. لینک‌های رسمی شبکه ASDEV در ادامه آمده است.
        </p>
      </header>

      <section className="grid gap-4 md:gap-6 md:grid-cols-3">
        {networkLinks.map((item) => (
          <article key={item.label} className="rounded-xl border bg-card p-5 h-full card-hover space-y-2">
            <h2 className="text-lg font-semibold leading-tight">{item.label}</h2>
            <p className="text-sm text-muted-foreground leading-6">{item.description}</p>
            <Link
              href={item.href}
              className="text-primary text-sm font-semibold inline-flex items-center gap-1"
              target="_blank"
              rel="noopener noreferrer"
            >
              مشاهده
              <span aria-hidden>→</span>
            </Link>
          </article>
        ))}
      </section>

      <section className="rounded-xl border bg-muted/30 p-5 md:p-6 space-y-3">
        <h2 className="text-base font-semibold">امضای برند</h2>
        <p className="text-sm text-muted-foreground">ASDEV | Alireza Safaei — علیرضا صفایی</p>
        <p className="text-sm text-muted-foreground">
          Portfolio &amp; contact:{' '}
          <Link href="https://alirezasafaeisystems.ir/" className="underline underline-offset-4" target="_blank" rel="noopener noreferrer">
            alirezasafaeisystems.ir
          </Link>
        </p>
        <div className="flex flex-wrap gap-3 text-sm">
          {contactLinks.map((item) => (
            <Link
              key={item.label}
              href={item.href}
              target="_blank"
              rel="noopener noreferrer"
              className="underline underline-offset-4"
            >
              {item.label}
            </Link>
          ))}
        </div>
      </section>
    </main>
  )
}
