import type { Metadata } from "next";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
import { Header } from "@/components/layout/header";
import { Footer } from "@/components/layout/footer";
import { BottomNav } from "@/components/layout/bottom-nav";
import { ScrollProgress } from "@/components/layout/scroll-progress";
import { JsonLd } from "@/components/seo/json-ld";
import { I18nProvider } from "@/lib/i18n-context";
import { ThemeProvider } from "@/components/theme/theme-provider";
import { FontCdnLoader } from "@/components/layout/font-cdn-loader";
import { WebVitals } from "@/components/analytics/web-vitals";
import { generatePersonSchema, generateWebSiteSchema, generateBreadcrumbSchema, generateOrganizationSchema } from "@/lib/seo";
import { getSiteUrl } from "@/lib/site-config";
import { brand } from "@/lib/brand";
import { env } from "@/lib/env";
import { cookies, headers } from "next/headers";

const siteUrl = getSiteUrl();
const ownerName = brand.ownerName;
const fontCdnEnabled =
  env.NODE_ENV !== 'production' &&
  env.NEXT_PUBLIC_FONT_CDN_ENABLED === 'true' &&
  Boolean(env.NEXT_PUBLIC_FONT_CDN_URL);
const fontCdnUrl = env.NEXT_PUBLIC_FONT_CDN_URL;

function normalizePathname(pathname: string): string {
  if (!pathname || pathname === '/') return '/'
  const cleaned = pathname.endsWith('/') ? pathname : `${pathname}/`
  return cleaned
}

function swapLocalePath(pathname: string, targetLocale: 'fa' | 'en'): string {
  const normalized = normalizePathname(pathname)
  if (normalized.startsWith('/fa/')) {
    return normalized.replace('/fa/', `/${targetLocale}/`)
  }
  if (normalized.startsWith('/en/')) {
    return normalized.replace('/en/', `/${targetLocale}/`)
  }
  if (targetLocale === 'fa') {
    return normalized
  }
  return `/${targetLocale}${normalized}`
}

export async function generateMetadata(): Promise<Metadata> {
  const reqHeaders = await headers()
  const reqCookies = await cookies()
  const headerLocale = reqHeaders.get('x-site-locale') || reqHeaders.get('x-asdev-locale')
  const cookieLocale = reqCookies.get('lang')?.value
  const locale = headerLocale === 'en' || cookieLocale === 'en' ? 'en' : 'fa'
  const pathname = normalizePathname(reqHeaders.get('x-site-pathname') || reqHeaders.get('x-asdev-pathname') || '/')
  const canonicalPath = pathname.startsWith('/en/') || locale === 'fa' ? pathname : `/${locale}${pathname}`
  const canonicalUrl = new URL(canonicalPath, siteUrl).toString()

  const description = locale === 'fa' ? brand.positioningFa : brand.positioningEn
  const titleDefault =
    locale === 'fa'
      ? 'علیرضا صفایی | بومی‌سازی زیرساخت و تاب‌آوری عملیاتی'
      : 'Alireza Safaei | Infrastructure Localization & Operational Resilience'

  return {
    title: {
      default: titleDefault,
      template: `%s | ${ownerName}`,
    },
    description,
    keywords: [
      "infrastructure localization",
      "operational resilience",
      "production stability",
      "ci/cd hardening",
      "release governance",
      "disaster recovery planning",
      "ارزیابی ریسک زیرساخت",
      "معماری مقاوم در برابر تحریم",
      "سخت سازی CI/CD",
      "پایداری عملیاتی تولید",
    ],
    authors: [{ name: ownerName, url: siteUrl }],
    creator: ownerName,
    publisher: brand.brandName,
    formatDetection: {
      email: false,
      address: false,
      telephone: false,
    },
    metadataBase: new URL(siteUrl),
    alternates: {
      canonical: canonicalPath,
      languages: {
        'fa-IR': swapLocalePath(canonicalPath, 'fa'),
        'en-US': swapLocalePath(canonicalPath, 'en'),
      },
    },
    openGraph: {
      type: 'website',
      locale: locale === 'fa' ? 'fa_IR' : 'en_US',
      alternateLocale: locale === 'fa' ? ['en_US'] : ['fa_IR'],
      url: canonicalUrl,
      siteName: `${brand.brandName} | ${ownerName}`,
      title: titleDefault,
      description,
      images: [
        {
          url: '/api/og-image',
          height: 630,
          alt: `${ownerName} - Web Systems Engineer`,
        },
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: titleDefault,
      description,
      images: ['/api/og-image'],
      creator: brand.twitterHandle,
    },
    robots: {
      index: true,
      follow: true,
      googleBot: {
        index: true,
        follow: true,
        'max-video-preview': -1,
        'max-image-preview': 'large',
        'max-snippet': -1,
      },
    },
    verification: {
      google: brand.googleVerificationCode,
    },
  }
}

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const nonce = (await headers()).get('x-csp-nonce') || undefined;
  const requestHeaders = await headers()
  const langHeader = requestHeaders.get('x-site-locale') || requestHeaders.get('x-asdev-locale')
  const langCookie = (await cookies()).get('lang')?.value;
  const lang = langHeader === 'en' || langCookie === 'en' ? 'en' : 'fa';
  const dir = lang === 'fa' ? 'rtl' : 'ltr';

  return (
    <html lang={lang} dir={dir} suppressHydrationWarning>
      <head>
        <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
        <link rel="manifest" href="/manifest.json" />
        <link rel="preload" href="/fonts/Vazirmatn-Variable.woff2" as="font" type="font/woff2" crossOrigin="anonymous" />
        <link rel="alternate" type="application/rss+xml" title="RSS Feed (English)" href="/api/rss?lang=en" />
        <link rel="alternate" type="application/rss+xml" title="خوراک RSS (فارسی)" href="/api/rss?lang=fa" />
      </head>
      <body
        className="antialiased bg-background text-foreground min-h-screen flex flex-col font-sans"
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <I18nProvider initialLanguage={lang as 'fa' | 'en'}>
          {/* Skip to main content link for accessibility */}
          <a
            href="#main-content"
            className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50 bg-primary text-primary-foreground px-4 py-2 rounded-md"
          >
            {lang === 'fa' ? 'پرش به محتوای اصلی' : 'Skip to main content'}
          </a>

          {/* Schema.org Structured Data */}
          <JsonLd data={generatePersonSchema()} nonce={nonce} />
          <JsonLd data={generateWebSiteSchema()} nonce={nonce} />
          <JsonLd data={generateOrganizationSchema()} nonce={nonce} />
          <JsonLd
            data={{
              '@context': 'https://schema.org',
              '@graph': [
                {
                  '@type': 'Organization',
                  name: ownerName,
                  url: siteUrl,
                  sameAs: [
                    'https://audit.alirezasafaeisystems.ir/',
                    'https://persiantoolbox.ir/',
                  ],
                },
                {
                  '@type': 'WebSite',
                  name: 'Alireza Safaei Systems',
                  url: siteUrl,
                },
                {
                  '@type': 'WebSite',
                  name: 'Audit Systems',
                  url: 'https://audit.alirezasafaeisystems.ir/',
                },
                {
                  '@type': 'WebSite',
                  name: 'PersianToolbox',
                  url: 'https://persiantoolbox.ir/',
                },
              ],
            }}
            nonce={nonce}
          />
          <JsonLd
            data={{
              '@context': 'https://schema.org',
              '@type': 'Service',
              name: 'برنامه بومی‌سازی زیرساخت و تاب‌آوری عملیاتی',
              provider: {
                '@type': 'Person',
                name: ownerName,
                url: siteUrl,
              },
              areaServed: 'IR',
              serviceType: 'Infrastructure risk audit, architecture hardening, governance and DR planning',
              offers: {
                '@type': 'Offer',
                priceCurrency: 'IRR',
                priceSpecification: {
                  '@type': 'PriceSpecification',
                  minPrice: '60000000',
                  maxPrice: '120000000',
                  priceCurrency: 'IRR',
                },
              },
            }}
            nonce={nonce}
          />
          <JsonLd data={generateBreadcrumbSchema([
            { name: 'Home', url: siteUrl },
          ])} nonce={nonce} />

          <ScrollProgress />
          <Header />
          <FontCdnLoader enabled={fontCdnEnabled} href={fontCdnUrl} />
          <WebVitals />
          <main id="main-content" className="flex-1 pb-20 md:pb-0">
            {children}
          </main>
          <BottomNav />
          <Footer />
          <Toaster />
        </I18nProvider>
      </ThemeProvider>
      </body>
    </html>
  );
}
