import type { Metadata } from 'next'
import Link from 'next/link'
import { getRequestLanguage } from '@/lib/i18n/server'

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getRequestLanguage()
  return {
    title: lang === 'fa' ? 'ممنون' : 'Thank You',
    description:
      lang === 'fa'
        ? 'درخواست شما ثبت شد. در مرحله بعد، بررسی اولیه انجام می‌شود و سپس برای هماهنگی Discovery با شما تماس می‌گیریم.'
        : 'Your request has been received. We will follow up shortly.',
    robots: {
      index: false,
      follow: false,
    },
  }
}

export default async function ThankYouPage() {
  const lang = await getRequestLanguage()
  const withLocale = (path: string) => (lang === 'fa' ? path : `/${lang}${path}`)
  const title = lang === 'en' ? 'Thanks. Your request is in.' : 'ممنون. درخواست شما ثبت شد.'
  const desc =
    lang === 'en'
      ? 'Your request was registered. Next, we will do an initial review and then contact you to schedule discovery.'
      : 'درخواست شما ثبت شد. در مرحله بعد، بررسی اولیه انجام می‌شود و سپس برای هماهنگی Discovery با شما تماس می‌گیریم.'
  const ctaCases = lang === 'en' ? 'View Case Studies' : 'مشاهده مطالعات موردی'
  const ctaHome = lang === 'en' ? 'Back Home' : 'بازگشت به خانه'
  const nextStepsTitle = lang === 'en' ? 'What Happens Next' : 'گام‌های بعدی'
  const nextSteps =
    lang === 'en'
      ? ['Initial technical review', 'Prioritization of key risk areas', 'Discovery scheduling confirmation']
      : ['بررسی اولیه فنی', 'اولویت‌بندی ریسک‌های کلیدی', 'هماهنگی نهایی جلسه Discovery']

  return (
    <main className="container mx-auto px-4 py-28 subtle-grid">
      <section className="mx-auto max-w-2xl space-y-6 section-surface aurora-shell p-8 text-center">
        <h1 className="headline-tight text-3xl font-bold md:text-4xl">{title}</h1>
        <p className="text-muted-foreground leading-8">{desc}</p>

        <div className="rounded-xl border bg-card/70 p-4 text-start">
          <h2 className="text-base font-semibold">{nextStepsTitle}</h2>
          <ul className="mt-3 space-y-1 text-sm text-muted-foreground list-disc ps-5">
            {nextSteps.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </div>

        <div className="flex flex-wrap justify-center gap-3">
          <Link href={withLocale('/case-studies')} className="rounded-md border px-4 py-2 text-sm card-hover">
            {ctaCases}
          </Link>
          <Link href={withLocale('/')} className="rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground shine-effect">
            {ctaHome}
          </Link>
        </div>
      </section>
    </main>
  )
}
