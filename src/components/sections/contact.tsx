'use client'

import { useMemo, useRef, useState } from 'react'
import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Mail, MapPin, MessageCircle, Send, CheckCircle, ClipboardList, Handshake, PhoneCall } from 'lucide-react'
import { brand } from '@/lib/brand'
import { useI18n } from '@/lib/i18n-context'
import { trackEvent } from '@/lib/analytics/client'

function withLocale(path: string, language: 'fa' | 'en'): string {
  const normalized = path.startsWith('/') ? path : `/${path}`
  return `/${language}${normalized === '/' ? '/' : normalized}`
}

function getIntentTemplates(language: 'fa' | 'en') {
  if (language === 'en') {
    return [
      {
        key: 'consulting',
        title: 'Technical Consultation',
        detail: 'Architecture, delivery risk, and production decisions',
        subject: 'Technical consultation request',
        message:
          'I need consultation on architecture and production readiness. Current challenge:\n\nTeam size:\nDeadline:\n',
        icon: ClipboardList,
      },
      {
        key: 'project',
        title: 'Project Order',
        detail: 'From design and build to production launch',
        subject: 'Project execution request',
        message:
          'I want to start a project with end-to-end execution. Product scope:\n\nCurrent status:\nExpected timeline:\n',
        icon: Send,
      },
      {
        key: 'review',
        title: 'Audit / Stabilization',
        detail: 'Localization, dependency reduction, test and reporting setup',
        subject: 'Infrastructure review and stabilization',
        message:
          'I need a technical review and stabilization plan. Main risks are:\n\nCurrent stack:\nProduction issues:\n',
        icon: CheckCircle,
      },
      {
        key: 'partnership',
        title: 'Organization Partnership',
        detail: 'Long-term engineering collaboration',
        subject: 'Organization partnership request',
        message:
          'We are looking for long-term collaboration on web systems engineering. Collaboration model:\n\nMain goals:\n',
        icon: Handshake,
      },
    ]
  }

  return [
    {
      key: 'consulting',
      title: 'درخواست مشاوره فنی',
      detail: 'برای معماری، ریسک تحویل و آمادگی تولید',
      subject: 'درخواست مشاوره فنی',
      message:
        'برای معماری و آمادگی تولید نیاز به مشاوره دارم.\n\nمسئله اصلی:\nاندازه تیم:\nددلاین:\n',
      icon: ClipboardList,
    },
    {
      key: 'project',
      title: 'ثبت سفارش پروژه',
      detail: 'از طراحی تا پیاده‌سازی و آماده‌سازی تولید',
      subject: 'درخواست اجرای پروژه',
      message:
        'می‌خواهم پروژه را به‌صورت صفر تا صد اجرا کنیم.\n\nحوزه محصول:\nوضعیت فعلی:\nزمان‌بندی مورد انتظار:\n',
      icon: Send,
    },
    {
      key: 'review',
      title: 'بررسی فنی و پایدارسازی',
      detail: 'لوکال‌سازی، رفع وابستگی، تست و گزارش‌گیری',
      subject: 'درخواست بررسی فنی و پایدارسازی',
      message:
        'برای بررسی فنی و برنامه پایدارسازی نیاز دارم.\n\nریسک‌های فعلی:\nاستک فعلی:\nمشکلات تولید:\n',
      icon: CheckCircle,
    },
    {
      key: 'partnership',
      title: 'همکاری سازمانی',
      detail: 'همکاری بلندمدت برای توسعه سیستم‌های وب',
      subject: 'درخواست همکاری سازمانی',
      message:
        'برای همکاری بلندمدت مهندسی سیستم‌های وب تماس می‌گیرم.\n\nمدل همکاری:\nاهداف اصلی:\n',
      icon: Handshake,
    },
  ]
}

export function Contact() {
  const { language } = useI18n()
  const intentTemplates = getIntentTemplates(language)
  const intentAlignClass = language === 'fa' ? 'text-right' : 'text-left'
  const formTopRef = useRef<HTMLDivElement>(null)
  const [activeIntent, setActiveIntent] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: '',
    website: '',
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const completionPercent = useMemo(() => {
    let completed = 0
    if (activeIntent) completed += 1
    if (formData.name.trim() !== '') completed += 1
    if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) completed += 1
    if (formData.message.trim() !== '') completed += 1
    return Math.round((completed / 4) * 100)
  }, [activeIntent, formData.name, formData.email, formData.message])

  const contactInfo = [
    {
      key: 'email',
      icon: Mail,
      label: language === 'en' ? 'Email' : 'ایمیل',
      value: brand.contactEmail,
      href: `mailto:${brand.contactEmail}`,
    },
    {
      key: 'phone',
      icon: PhoneCall,
      label: language === 'en' ? 'Phone' : 'تلفن',
      value: brand.contactPhone,
      href: `tel:${brand.contactPhone}`,
    },
    {
      key: 'telegram',
      icon: MessageCircle,
      label: 'Telegram',
      value: '@asdevsystems',
      href: brand.telegramUrl,
    },
    {
      key: 'location',
      icon: MapPin,
      label: language === 'en' ? 'Location' : 'موقعیت',
      value: language === 'en' ? 'Tehran / Remote (Iran)' : 'تهران / ریموت (سراسر ایران)',
      href: undefined,
    },
  ]

  const copy = {
    title: language === 'en' ? 'Step 5: Start Your Request' : 'مرحله ۵: ثبت درخواست همکاری',
    subtitle:
      language === 'en'
        ? 'Choose your request type, then submit a short brief. You will receive a structured follow-up.'
        : 'نوع درخواست را انتخاب کنید، سپس یک خلاصه کوتاه ثبت کنید تا مسیر پیگیری ساختاریافته دریافت کنید.',
    requestPathTitle: language === 'en' ? 'Choose Request Path' : 'نوع درخواست را انتخاب کنید',
    progressLabel: language === 'en' ? 'Request Progress' : 'وضعیت تکمیل درخواست',
    stepOne: language === 'en' ? 'Step 1: Pick type' : 'مرحله ۱: انتخاب نوع درخواست',
    stepTwo: language === 'en' ? 'Step 2: Fill brief' : 'مرحله ۲: تکمیل خلاصه',
    stepThree: language === 'en' ? 'Step 3: Submit' : 'مرحله ۳: ثبت نهایی',
    directContact: language === 'en' ? 'Direct Channels' : 'راه‌های ارتباط مستقیم',
    qualifyCta: language === 'en' ? 'Open Qualification Form' : 'باز کردن فرم Qualification',
    formTitle: language === 'en' ? 'Submit Your Brief' : 'ارسال خلاصه درخواست',
    sentTitle: language === 'en' ? 'Request Sent' : 'درخواست ثبت شد',
    sentDesc:
      language === 'en'
        ? 'Your message is received. Initial response is usually within one business day.'
        : 'پیام شما ثبت شد. پاسخ اولیه معمولاً تا یک روز کاری ارسال می‌شود.',
    sendAnother: language === 'en' ? 'Send Another Request' : 'ثبت درخواست جدید',
    name: language === 'en' ? 'Name' : 'نام',
    email: language === 'en' ? 'Email' : 'ایمیل',
    subject: language === 'en' ? 'Subject' : 'موضوع',
    message: language === 'en' ? 'Message' : 'توضیحات',
    namePh: language === 'en' ? 'Your name' : 'نام شما',
    emailPh: language === 'en' ? 'name@company.com' : 'name@company.com',
    subjectPh: language === 'en' ? 'Request subject' : 'موضوع درخواست',
    messagePh:
      language === 'en'
        ? 'Describe your current challenge and expected outcome...'
        : 'چالش فعلی و خروجی مورد انتظار را کوتاه توضیح دهید...',
    submit: language === 'en' ? 'Submit Request' : 'ثبت درخواست',
    sending: language === 'en' ? 'Submitting...' : 'در حال ارسال...',
    trustItemOne: language === 'en' ? 'NDA available for sensitive projects' : 'امکان NDA برای پروژه‌های حساس',
    trustItemTwo: language === 'en' ? 'Initial response within one business day' : 'پاسخ اولیه حداکثر تا یک روز کاری',
    trustItemThree:
      language === 'en' ? 'Structured qualification before commitment' : 'ارزیابی ساختاریافته قبل از شروع همکاری',
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const applyIntent = (intentKey: string) => {
    const selected = intentTemplates.find((item) => item.key === intentKey)
    if (!selected) return

    setActiveIntent(intentKey)
    setFormData((prev) => ({
      ...prev,
      subject: selected.subject,
      message: prev.message.trim() === '' ? selected.message : prev.message,
    }))
    void trackEvent({
      name: 'contact_intent_selected',
      category: 'engagement',
      locale: language,
      metadata: { intentKey },
    })
    formTopRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }

  const validateForm = () => {
    return (
      formData.name.trim() !== '' &&
      formData.email.trim() !== '' &&
      formData.message.trim() !== '' &&
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    void trackEvent({
      name: 'contact_submit_attempt',
      category: 'conversion',
      locale: language,
    })

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (response.ok) {
        void trackEvent({
          name: 'contact_submit_success',
          category: 'conversion',
          locale: language,
        })
        setIsSubmitted(true)
        setActiveIntent(null)
        setFormData({ name: '', email: '', subject: '', message: '', website: '' })
      } else {
        void trackEvent({
          name: 'contact_submit_failed',
          category: 'conversion',
          locale: language,
        })
      }
    } catch {
      void trackEvent({
        name: 'contact_submit_failed',
        category: 'conversion',
        locale: language,
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <section id="contact" className="section-block-soft bg-muted/30 relative overflow-hidden subtle-grid">
      <div className="absolute inset-0 bg-gradient-to-bl from-background via-background/50 to-muted/30 pointer-events-none" />

      <div className="container mx-auto px-4 relative z-10 space-y-8">
        <div className="text-center space-y-4">
          <h2 className="headline-tight text-3xl md:text-4xl lg:text-5xl font-bold">{copy.title}</h2>
          <p className="text-lg text-muted-foreground max-w-3xl mx-auto text-copy">{copy.subtitle}</p>
        </div>

        <div className="section-surface p-5 md:p-6">
          <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <p className="text-sm font-semibold text-primary">{copy.requestPathTitle}</p>
            <p className="text-xs text-muted-foreground">
              {copy.progressLabel}: {completionPercent}%
            </p>
          </div>

          <div className="mb-4 h-2 w-full rounded-full bg-muted">
            <div
              className="h-2 rounded-full bg-primary transition-all duration-300"
              style={{ width: `${completionPercent}%` }}
              aria-hidden="true"
            />
          </div>

          <div className="mb-4 grid gap-2 md:grid-cols-3">
            <p className="rounded-md border border-border/60 bg-card/70 px-3 py-2 text-xs text-muted-foreground">{copy.stepOne}</p>
            <p className="rounded-md border border-border/60 bg-card/70 px-3 py-2 text-xs text-muted-foreground">{copy.stepTwo}</p>
            <p className="rounded-md border border-border/60 bg-card/70 px-3 py-2 text-xs text-muted-foreground">{copy.stepThree}</p>
          </div>

          <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
            {intentTemplates.map((item) => (
              <button
                key={item.key}
                type="button"
                onClick={() => applyIntent(item.key)}
                className={`rounded-lg border p-4 transition-colors card-hover ${intentAlignClass} ${
                  activeIntent === item.key
                    ? 'border-primary/60 bg-primary/10'
                    : 'border-border/70 bg-card/70 hover:border-primary/40'
                }`}
              >
                <p className="mb-2 inline-flex items-center gap-2 text-sm font-semibold">
                  <item.icon className="h-4 w-4 text-primary" />
                  <span>{item.title}</span>
                </p>
                <p className="text-sm text-muted-foreground text-ui">{item.detail}</p>
              </button>
            ))}
          </div>
        </div>

        <div className="mx-auto max-w-5xl space-y-5">
          <Card className="glass card-hover">
            <CardHeader>
              <CardTitle>{copy.directContact}</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-3 md:grid-cols-2">
              {contactInfo.map((info) => (
                <div key={info.key} className="rounded-lg border border-border/60 bg-card/70 p-3">
                  <p className="inline-flex items-center gap-2 text-sm font-semibold">
                    <info.icon className="h-4 w-4 text-primary" />
                    <span>{info.label}</span>
                  </p>
                  <div className="mt-1 text-sm text-muted-foreground">
                    {info.href ? (
                      <a
                        href={info.href}
                        target={info.href.startsWith('mailto') || info.href.startsWith('tel') ? undefined : '_blank'}
                        rel={info.href.startsWith('mailto') || info.href.startsWith('tel') ? undefined : 'noopener noreferrer'}
                        className="hover:text-primary transition-colors"
                      >
                        {info.value}
                      </a>
                    ) : (
                      <span>{info.value}</span>
                    )}
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          <Card className="bg-primary/5 border-primary/20 card-hover">
            <CardContent className="p-6 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div className="space-y-2">
                <h3 className="font-semibold">
                  {language === 'en'
                    ? 'Need structured qualification first?'
                    : 'اگر قبل از فرم تماس، ارزیابی ساختاریافته می‌خواهید'}
                </h3>
                <p className="text-sm text-muted-foreground text-ui">
                  {language === 'en'
                    ? 'Use the qualification form for clearer scoping, risk mapping, and faster execution planning.'
                    : 'از فرم Qualification استفاده کنید تا دامنه، ریسک‌ها و مسیر اجرا شفاف‌تر و سریع‌تر مشخص شود.'}
                </p>
              </div>
              <Button asChild variant="outline" className="card-hover md:min-w-56">
                <Link href={withLocale('/qualification', language)}>{copy.qualifyCta}</Link>
              </Button>
            </CardContent>
          </Card>

          <div ref={formTopRef}>
            <Card className="glass card-hover">
              <CardHeader>
                <CardTitle>{copy.formTitle}</CardTitle>
              </CardHeader>
              <CardContent>
              {isSubmitted ? (
                <div className="text-center py-12 space-y-4">
                  <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-primary/10 text-primary">
                    <CheckCircle className="h-8 w-8" />
                  </div>
                  <h3 className="text-2xl font-bold mb-2 gradient-text">{copy.sentTitle}</h3>
                  <p className="text-muted-foreground">{copy.sentDesc}</p>
                  <Button onClick={() => setIsSubmitted(false)} variant="outline">
                    {copy.sendAnother}
                  </Button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="hidden" aria-hidden="true">
                    <Label htmlFor="website">Website</Label>
                    <Input
                      id="website"
                      name="website"
                      tabIndex={-1}
                      autoComplete="off"
                      value={formData.website}
                      onChange={handleChange}
                    />
                  </div>

                  <div className="grid gap-4 md:grid-cols-2">
                    <div className="space-y-2">
                      <Label htmlFor="name">{copy.name} *</Label>
                      <Input
                        id="name"
                        name="name"
                        value={formData.name}
                        onChange={handleChange}
                        placeholder={copy.namePh}
                        className="h-11"
                        required
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="email">{copy.email} *</Label>
                      <Input
                        id="email"
                        name="email"
                        type="email"
                        value={formData.email}
                        onChange={handleChange}
                        placeholder={copy.emailPh}
                        className="h-11"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="subject">{copy.subject}</Label>
                    <Input
                      id="subject"
                      name="subject"
                      value={formData.subject}
                      onChange={handleChange}
                      placeholder={copy.subjectPh}
                      className="h-11"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="message">{copy.message} *</Label>
                    <Textarea
                      id="message"
                      name="message"
                      value={formData.message}
                      onChange={handleChange}
                      placeholder={copy.messagePh}
                      rows={6}
                      required
                    />
                  </div>

                  <Button type="submit" className="w-full gap-2 shine-effect" disabled={isSubmitting || !validateForm()}>
                    {isSubmitting ? (
                      copy.sending
                    ) : (
                      <>
                        <Send className="h-4 w-4" />
                        {copy.submit}
                      </>
                    )}
                  </Button>
                  <div className="rounded-md border border-border/70 bg-card/50 p-3 text-xs text-muted-foreground space-y-1">
                    <p>{copy.trustItemOne}</p>
                    <p>{copy.trustItemTwo}</p>
                    <p>{copy.trustItemThree}</p>
                  </div>
                </form>
              )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </section>
  )
}
