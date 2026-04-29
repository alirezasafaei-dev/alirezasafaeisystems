import type { Metadata } from 'next'
import Link from 'next/link'
import { headers } from 'next/headers'
import { getRequestLanguage } from '@/lib/i18n/server'
import { getSiteUrl } from '@/lib/site-config'
import { buildNetworkLinks } from '@/lib/network'

const siteUrl = getSiteUrl()

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: 'استانداردهای تحویل AliReza Safaei',
    description:
      'راهنمای کوتاه استانداردهای تحویل علیرضا صفایی: این سایت چیست، برای چه تیمی مناسب است، و خروجی اجرایی چه خواهد بود.',
    alternates: {
      canonical: `${siteUrl}/${lang}/standards`,
    },
    openGraph: {
      title: 'AliReza Safaei Standards — استانداردهای تحویل',
      description: 'استانداردهای تحویل، intent map فارسی، و برنامه لینک داخلی بین Portfolio، PersianToolbox و Audit IR.',
      url: `${siteUrl}/${lang}/standards`,
      type: 'article',
    },
    twitter: {
      card: 'summary_large_image',
      title: 'استانداردهای تحویل AliReza Safaei',
      description: 'تعریف خروجی، مخاطب و نقشه لینک داخلی شبکه کاری.',
    },
  }
}

export default async function StandardsPage() {
  const nonce = (await headers()).get('x-csp-nonce') || undefined
  const links = buildNetworkLinks('alireza-portfolio', 'standards_page')

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    name: 'AliReza Safaei Network Internal Links',
    itemListElement: links.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.label,
      url: item.href,
    })),
  }

  return (
    <main className="container mx-auto px-4 py-14 max-w-5xl space-y-8" id="main-content">
      <script type="application/ld+json" nonce={nonce} dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <section className="rounded-2xl border bg-card p-6 md:p-8 space-y-3">
        <p className="text-sm font-semibold text-primary">AliReza Safaei Standards</p>
        <h1 className="text-3xl font-bold">استانداردهای تحویل و رشد پایدار</h1>
        <p className="text-muted-foreground leading-8">
          این صفحه تعریف می‌کند این سایت چیست، برای چه تیمی طراحی شده، و چه خروجی قابل‌اندازه‌گیری باید تولید شود.
        </p>
      </section>

      <section className="grid gap-4 md:grid-cols-3">
        <article className="rounded-xl border bg-card p-5 space-y-2">
          <h2 className="font-semibold">این سایت چیست؟</h2>
          <p className="text-sm text-muted-foreground leading-7">
            یک لایه Portfolio/Trust برای معرفی توانمندی معماری، تاب‌آوری عملیاتی، و مدل تحویل مبتنی بر شواهد.
          </p>
        </article>
        <article className="rounded-xl border bg-card p-5 space-y-2">
          <h2 className="font-semibold">برای چه کسی است؟</h2>
          <p className="text-sm text-muted-foreground leading-7">
            مدیر فنی، تیم پلتفرم، و تیم محصول که می‌خواهند ریسک زیرساخت، شکست انتشار، و اثر تحریم‌های خارجی علیه ایران را قابل‌کنترل کنند.
          </p>
        </article>
        <article className="rounded-xl border bg-card p-5 space-y-2">
          <h2 className="font-semibold">خروجی چیست؟</h2>
          <p className="text-sm text-muted-foreground leading-7">
            نقشه ریسک وابستگی، backlog اولویت‌دار، قرارداد Release/Rollback، و گزارش مدیریتی قابل ارائه.
          </p>
        </article>
      </section>

      <section className="rounded-xl border bg-muted/30 p-5 md:p-6 space-y-4">
        <h2 className="text-lg font-semibold">Intent Map فارسی + لینک داخلی بین سه محصول</h2>
        <ul className="space-y-2 text-sm text-muted-foreground">
          <li>کلاستر ۱: «پایداری زیرساخت» → Portfolio (راهبرد و خدمات)</li>
          <li>کلاستر ۲: «ابزار عملیاتی روزانه» → PersianToolbox (اجرای سریع و لوکال)</li>
          <li>کلاستر ۳: «Audit فنی و امنیتی» → Audit IR (تشخیص و اولویت‌بندی ریسک)</li>
        </ul>
        <div className="flex flex-wrap gap-3">
          {links.map((item) => (
            <Link
              key={item.key}
              href={item.href}
              target="_blank"
              rel="noopener noreferrer"
              className="underline underline-offset-4 text-sm"
            >
              {item.label}
            </Link>
          ))}
          <Link href="/profile" className="underline underline-offset-4 text-sm">
            صفحه معرفی شبکه
          </Link>
        </div>
      </section>
    </main>
  )
}
