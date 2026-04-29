import type { Metadata } from 'next'
import Link from 'next/link'
import { headers } from 'next/headers'
import { brand } from '@/lib/brand'
import { getSiteUrl } from '@/lib/site-config'
import {
  PORTFOLIO_LABEL,
  PORTFOLIO_URL,
  RESUME_PDF_URL,
  SIGNATURE_TEXT,
  TELEGRAM_URL,
  buildNetworkLinks,
} from '@/lib/network'

const siteUrl = getSiteUrl()

export const metadata: Metadata = {
  title: 'AliReza Safaei — صفحه معرفی و شبکه',
  description: 'معرفی علیرضا صفایی، مهندس سیستم‌های وب، به‌همراه لینک‌های رسمی Portfolio، PersianToolbox و Audit IR.',
  alternates: {
    canonical: `${siteUrl}/profile`,
  },
  openGraph: {
    title: 'AliReza Safaei | Web Systems Engineer',
    description: 'معرفی علیرضا صفایی و لینک‌دهی متقابل بین پورتفولیو، PersianToolbox و Audit IR.',
    url: `${siteUrl}/profile`,
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'AliReza Safaei — صفحه معرفی',
    description: 'لینک‌های رسمی شبکه کاری و راه‌های ارتباطی علیرضا صفایی.',
  },
  other: {
    'x-robots-tag': 'index, follow',
  },
}

export default async function ProfilePage() {
  const nonce = (await headers()).get('x-csp-nonce') || undefined
  const networkLinks = buildNetworkLinks('alireza-portfolio', 'profile_page').map((item) => {
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
        name: 'AliReza Safaei',
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
        name: 'چطور بین محصولات این شبکه جابه‌جا شوم؟',
        acceptedAnswer: {
          '@type': 'Answer',
          text: 'از لینک‌های همین صفحه یا فوتر استفاده کنید؛ همه لینک‌ها دارای UTM برای رهگیری شفاف هستند.',
        },
      },
      {
        '@type': 'Question',
        name: 'تلگرام رسمی چیست؟',
        acceptedAnswer: {
          '@type': 'Answer',
          text: 'کانال رسمی: https://t.me/asdevsystems',
        },
      },
    ],
  }

  const contactLinks = [
    { label: 'GitHub', href: 'https://github.com/parsairaniiidev/alirezasafaeisystems' },
    { label: 'Telegram', href: TELEGRAM_URL },
    { label: 'Resume PDF', href: RESUME_PDF_URL },
    { label: 'Portfolio & contact', href: PORTFOLIO_URL },
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
        <p className="text-sm font-semibold text-primary">AliReza Safaei | Web Systems Engineer</p>
        <h1 className="text-3xl md:text-4xl font-bold">علیرضا صفایی — مهندس سیستم‌های وب</h1>
        <p className="text-muted-foreground leading-7 md:leading-8">
          طراحی و توسعه صفر تا صد، معماری نرم‌افزار، تکمیل پروژه‌های نیمه‌کاره، آماده‌سازی محیط تولید، و مقابله عملی با تحریم‌های خارجی علیه ایران از مسیر بومی‌سازی زیرساخت.
        </p>
        <div className="flex flex-wrap gap-3 pt-2 text-sm">
          <Link
            href={RESUME_PDF_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center rounded-md border px-4 py-2 font-semibold hover:bg-muted"
          >
            دانلود رزومه PDF
          </Link>
          <Link
            href={PORTFOLIO_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center rounded-md border px-4 py-2 hover:bg-muted"
          >
            مشاهده پورتفولیو
          </Link>
        </div>
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
        <h2 className="text-base font-semibold">امضا و مسیر همکاری</h2>
        <p className="text-sm text-muted-foreground">{SIGNATURE_TEXT}</p>
        <p className="text-sm text-muted-foreground">
          <Link href={PORTFOLIO_URL} className="underline underline-offset-4" target="_blank" rel="noopener noreferrer">
            {PORTFOLIO_LABEL}
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
          استانداردهای تحویل، کیفیت UX فارسی و نقشه اجرا
        </Link>
      </section>
    </main>
  )
}
