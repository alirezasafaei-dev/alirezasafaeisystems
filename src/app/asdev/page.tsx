import type { Metadata } from 'next'
import Link from 'next/link'
import { headers } from 'next/headers'
import { brand } from '@/lib/brand'
import { getSiteUrl } from '@/lib/site-config'
import {
  ASDEV_PORTFOLIO_LABEL,
  ASDEV_PORTFOLIO_URL,
  ASDEV_SIGNATURE_TEXT,
  ASDEV_TELEGRAM_URL,
  buildAsdevNetworkLinks,
} from '@/lib/asdev-network'

const siteUrl = getSiteUrl()

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
  other: {
    'x-robots-tag': 'index, follow',
  },
}

export default async function AsdevPage() {
  const nonce = (await headers()).get('x-csp-nonce') || undefined
  const networkLinks = buildAsdevNetworkLinks('asdev-portfolio', 'asdev_page').map((item) => {
    if (item.key === 'portfolio') {
      return {
        ...item,
        description: 'رزومه، خدمات و راه‌های تماس مستقیم با علیرضا صفایی.',
      }
    }
    if (item.key === 'toolbox') {
      return {
        ...item,
        description: 'مجموعه ابزارهای فارسی با پردازش لوکال و حریم خصوصی کاربر.',
      }
    }
    return {
      ...item,
      description: 'پلتفرم تحلیل Performance/SEO/Security با گزارش عملیاتی.',
    }
  })

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

  const faqLd = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: [
      {
        '@type': 'Question',
        name: 'چطور بین محصولات ASDEV جابه‌جا شوم؟',
        acceptedAnswer: {
          '@type': 'Answer',
          text: 'از لینک‌های همین صفحه یا فوتر استفاده کنید؛ همه لینک‌ها دارای UTM برای رهگیری شفاف هستند.',
        },
      },
      {
        '@type': 'Question',
        name: 'تلگرام رسمی ASDEV چیست؟',
        acceptedAnswer: {
          '@type': 'Answer',
          text: 'کانال رسمی: https://t.me/asdevsystems',
        },
      },
    ],
  }

  const contactLinks = [
    { label: 'GitHub', href: 'https://github.com/alirezasafaeisystems' },
    { label: 'Telegram', href: ASDEV_TELEGRAM_URL },
    { label: 'Portfolio & contact', href: ASDEV_PORTFOLIO_URL },
  ]

  return (
    <main className="container mx-auto px-4 py-16 max-w-5xl space-y-10 subtle-grid" id="main-content">
      <script
        type="application/ld+json"
        nonce={nonce}
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <script
        type="application/ld+json"
        nonce={nonce}
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqLd) }}
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
        <p className="text-sm text-muted-foreground">{ASDEV_SIGNATURE_TEXT}</p>
        <p className="text-sm text-muted-foreground">
          <Link href={ASDEV_PORTFOLIO_URL} className="underline underline-offset-4" target="_blank" rel="noopener noreferrer">
            {ASDEV_PORTFOLIO_LABEL}
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
        <Link href="/standards" className="text-sm underline underline-offset-4">
          استانداردهای تحویل و intent map فارسی
        </Link>
      </section>
    </main>
  )
}
