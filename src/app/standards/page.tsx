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
    title: lang === 'fa' ? 'استانداردهای تحویل AliReza Safaei' : 'AliReza Safaei Delivery Standards',
    description:
      lang === 'fa'
        ? 'راهنمای کوتاه استانداردهای تحویل علیرضا صفایی: این سایت چیست، برای چه تیمی مناسب است، و خروجی اجرایی چه خواهد بود.'
        : 'Quick guide to Alireza Safaei delivery standards: what this site is, who it is designed for, and what measurable output will be produced.',
    alternates: {
      canonical: `${siteUrl}/${lang}/standards`,
    },
    openGraph: {
      title: lang === 'fa' ? 'AliReza Safaei Standards — استانداردهای تحویل' : 'AliReza Safaei Standards — Delivery Standards',
      description:
        lang === 'fa'
          ? 'استانداردهای تحویل، intent map فارسی، و برنامه لینک داخلی بین Portfolio، PersianToolbox و Audit IR.'
          : 'Delivery standards, Persian intent map, and internal linking plan across Portfolio, PersianToolbox, and Audit IR.',
      url: `${siteUrl}/${lang}/standards`,
      type: 'article',
    },
    twitter: {
      card: 'summary_large_image',
      title: lang === 'fa' ? 'استانداردهای تحویل AliReza Safaei' : 'AliReza Safaei Delivery Standards',
      description:
        lang === 'fa'
          ? 'تعریف خروجی، مخاطب و نقشه لینک داخلی شبکه کاری.'
          : 'Output definition, audience, and internal link map for the work network.',
    },
  }
}

export default async function StandardsPage() {
  const nonce = (await headers()).get('x-csp-nonce') || undefined
  const links = buildNetworkLinks('alireza-portfolio', 'standards_page')
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    name: lang === 'fa' ? 'لینک‌های داخلی شبکه AliReza Safaei' : 'AliReza Safaei Network Internal Links',
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
        <h1 className="text-3xl font-bold">
          {lang === 'fa' ? 'استانداردهای تحویل و رشد پایدار' : 'Delivery Standards & Sustainable Growth'}
        </h1>
        <p className="text-muted-foreground leading-8">
          {lang === 'fa'
            ? 'این صفحه تعریف می‌کند این سایت چیست، برای چه تیمی طراحی شده، و چه خروجی قابل‌اندازه‌گیری باید تولید شود.'
            : 'This page defines what this site is, who it is designed for, and what measurable output should be produced.'}
        </p>
      </section>

      <section className="grid gap-4 md:grid-cols-3">
        <article className="rounded-xl border bg-card p-5 space-y-2">
          <h2 className="font-semibold">{lang === 'fa' ? 'این سایت چیست؟' : 'What is this site?'}</h2>
          <p className="text-sm text-muted-foreground leading-7">
            {lang === 'fa'
              ? 'یک لایه Portfolio/Trust برای معرفی توانمندی معماری، تاب‌آوری عملیاتی، و مدل تحویل مبتنی بر شواهد.'
              : 'A Portfolio/Trust layer for demonstrating architecture capability, operational resilience, and evidence-based delivery model.'}
          </p>
        </article>
        <article className="rounded-xl border bg-card p-5 space-y-2">
          <h2 className="font-semibold">{lang === 'fa' ? 'برای چه کسی است؟' : 'Who is it for?'}</h2>
          <p className="text-sm text-muted-foreground leading-7">
            {lang === 'fa'
              ? 'مدیر فنی، تیم پلتفرم، و تیم محصول که می‌خواهند ریسک زیرساخت، شکست انتشار، و اثر تحریم‌های خارجی علیه ایران را قابل‌کنترل کنند.'
              : 'Technical managers, platform teams, and product teams who want to make infrastructure risk, release failures, and the impact of external sanctions on Iran manageable.'}
          </p>
        </article>
        <article className="rounded-xl border bg-card p-5 space-y-2">
          <h2 className="font-semibold">{lang === 'fa' ? 'خروجی چیست؟' : 'What is the output?'}</h2>
          <p className="text-sm text-muted-foreground leading-7">
            {lang === 'fa'
              ? 'نقشه ریسک وابستگی، backlog اولویت‌دار، قرارداد Release/Rollback، و گزارش مدیریتی قابل ارائه.'
              : 'Dependency risk map, prioritized backlog, Release/Rollback contract, and presentation-ready management report.'}
          </p>
        </article>
      </section>

      <section className="rounded-xl border bg-muted/30 p-5 md:p-6 space-y-4">
        <h2 className="text-lg font-semibold">
          {lang === 'fa' ? 'Intent Map فارسی + لینک داخلی بین سه محصول' : 'Persian Intent Map + Internal Links Between Three Products'}
        </h2>
        <ul className="space-y-2 text-sm text-muted-foreground">
          {lang === 'fa' ? (
            <>
              <li>کلاستر ۱: «پایداری زیرساخت» → Portfolio (راهبرد و خدمات)</li>
              <li>کلاستر ۲: «ابزار عملیاتی روزانه» → PersianToolbox (اجرای سریع و لوکال)</li>
              <li>کلاستر ۳: «Audit فنی و امنیتی» → Audit IR (تشخیص و اولویت‌بندی ریسک)</li>
            </>
          ) : (
            <>
              <li>Cluster 1: &quot;Infrastructure Stability&quot; → Portfolio (strategy & services)</li>
              <li>Cluster 2: &quot;Daily Operational Tools&quot; → PersianToolbox (fast, local execution)</li>
              <li>Cluster 3: &quot;Technical &amp; Security Audit&quot; → Audit IR (risk detection &amp; prioritization)</li>
            </>
          )}
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
          <Link href={withLocale('/profile')} className="underline underline-offset-4 text-sm">
            {lang === 'fa' ? 'صفحه معرفی شبکه' : 'Network Profile Page'}
          </Link>
        </div>
      </section>
    </main>
  )
}
