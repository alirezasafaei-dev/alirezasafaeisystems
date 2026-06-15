import type { Metadata } from 'next'
import { Hero } from '@/components/sections/hero'
import { Services } from '@/components/sections/services'
import { FeaturedCaseStudies } from '@/components/sections/featured-case-studies'
import { AboutSummary } from '@/components/sections/about-summary'
import { Contact } from '@/components/sections/contact'
import { getRequestLanguage } from '@/lib/i18n/server'
import { brand } from '@/lib/brand'

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: lang === 'fa'
      ? `${brand.ownerName} | مهندس سیستم‌های وب - بومی‌سازی زیرساخت و تاب‌آوری عملیاتی`
      : `${brand.ownerName} | Web Systems Engineer - Infrastructure Localization & Operational Resilience`,
    description:
      lang === 'fa'
        ? `${brand.ownerName}، مهندس سیستم‌های وب. بومی‌سازی زیرساخت، پایداری عملیاتی، سخت‌سازی CI/CD و حکمرانی انتشار. از معماری تا تحویل آماده تولید.`
        : `${brand.ownerName}, Web Systems Engineer. Infrastructure localization, operational resilience, CI/CD hardening, and release governance. From architecture to production-ready delivery.`,
    keywords: lang === 'fa'
      ? ['مهندس سیستم وب', 'بومی‌سازی زیرساخت', 'پایداری عملیاتی', 'CI/CD', 'معماری نرم‌افزار', 'تاب‌آوری']
      : ['web systems engineer', 'infrastructure localization', 'operational resilience', 'CI/CD', 'software architecture', 'production readiness'],
  }
}

export default function Home() {
  return (
    <div className="w-full min-h-screen">
      <Hero />
      <Services />
      <FeaturedCaseStudies />
      <AboutSummary />
      <Contact />
    </div>
  )
}
