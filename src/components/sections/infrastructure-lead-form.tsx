'use client'

import { useEffect, useMemo, useRef, useState } from 'react'
import { usePathname, useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { trackEvent } from '@/lib/analytics/client'
import { useI18n } from '@/lib/i18n-context'

const initialState = {
  contactName: '',
  organizationName: '',
  organizationType: 'service_business',
  email: '',
  phone: '',
  teamSize: '1-5',
  currentStack: '',
  criticalRisk: '',
  timeline: 'this_week',
  budgetRange: 'starter-fixed-scope',
  preferredContact: 'telegram',
  notes: '',
  website: '',
}

const draftStorageKey = 'infra_lead_form_draft_v1'

export function InfrastructureLeadForm() {
  const router = useRouter()
  const pathname = usePathname()
  const { language } = useI18n()
  const [step, setStep] = useState<1 | 2>(1)
  const [formData, setFormData] = useState(() => {
    if (typeof window === 'undefined') return initialState
    try {
      const saved = window.localStorage.getItem(draftStorageKey)
      if (!saved) return initialState
      return { ...initialState, ...(JSON.parse(saved) as Partial<typeof initialState>) }
    } catch {
      return initialState
    }
  })
  const [attachment, setAttachment] = useState<File | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [status, setStatus] = useState<'idle' | 'error'>('idle')
  const viewTrackedRef = useRef(false)

  const locale = useMemo(() => (pathname.startsWith('/en') ? 'en' : 'fa'), [pathname])
  const isFa = language === 'fa'
  const copy = useMemo(
    () => ({
      stepOneTitle: isFa ? '1) راه ارتباط و سایت' : '1) Contact and Website',
      stepTwoTitle: isFa ? '2) مشکل و زمان‌بندی' : '2) Issue and Timing',
      stepOneHint: isFa ? 'فقط اطلاعات ضروری برای شروع بررسی سریع را وارد کنید.' : 'Share only the essentials needed to start a quick review.',
      stepTwoHint: isFa ? 'مشکل فعلی، فوریت و سطح همکاری را کوتاه مشخص کنید.' : 'Briefly define the current issue, urgency, and collaboration level.',
      contactName: isFa ? 'نام تماس' : 'Contact Name',
      orgName: isFa ? 'نام کسب‌وکار / پروژه' : 'Business / Project Name',
      orgEmail: isFa ? 'ایمیل' : 'Email',
      phone: isFa ? 'شماره تماس یا آیدی تلگرام' : 'Phone or Telegram ID',
      preferredContact: isFa ? 'کانال ترجیحی ارتباط' : 'Preferred Contact Channel',
      prefEmail: isFa ? 'ایمیل' : 'Email',
      prefPhone: isFa ? 'تماس' : 'Phone Call',
      prefTelegram: isFa ? 'تلگرام' : 'Telegram',
      nextStep: isFa ? 'مرحله بعد: مشکل فعلی' : 'Next: Current Issue',
      teamSize: isFa ? 'تعداد افراد درگیر فنی' : 'Technical People Involved',
      timeline: isFa ? 'فوریت شروع' : 'Start Urgency',
      currentStack: isFa ? 'آدرس سایت / لینک محصول زنده' : 'Live Website / Product URL',
      currentStackPh: isFa ? 'https://example.ir' : 'https://example.com',
      criticalRisk: isFa ? 'مشکل اصلی که باید سریع بهتر شود' : 'Main issue to improve quickly',
      criticalRiskPh: isFa
        ? 'مثلاً کندی سایت، خطای فرم، مشکل اعتماد، باگ خرید، افت ورودی یا مشکل deploy...'
        : 'e.g. slow pages, broken forms, trust issues, checkout bugs, weak leads, deploy problems...',
      notes: isFa ? 'توضیحات تکمیلی / دسترسی‌های قابل ارائه' : 'Extra context / available access',
      attachment: isFa ? 'فایل پیوست (اختیاری)' : 'Attachment (Optional)',
      attachmentHint: isFa
        ? 'حداکثر 5MB. فرمت‌های مجاز: PDF, DOC, DOCX, TXT, PNG, JPG'
        : 'Max 5MB. Allowed formats: PDF, DOC, DOCX, TXT, PNG, JPG',
      budget: isFa ? 'مدل شروع قابل قبول' : 'Acceptable Starting Model',
      budgetLow: isFa ? 'پکیج محدود و ثابت برای شروع سریع' : 'Fixed-scope starter package',
      budgetHigh: isFa ? 'بعد از بررسی کوتاه، قیمت دقیق بدهید' : 'Quote after a short review',
      orgType: isFa ? 'نوع کسب‌وکار' : 'Business Type',
      orgGovernment: isFa ? 'خدماتی / مشاوره‌ای' : 'Service / Consulting',
      orgPrivate: isFa ? 'فروشگاه / تجارت آنلاین' : 'Store / Online Commerce',
      orgSemiPrivate: isFa ? 'رسانه / محتوا / آموزش' : 'Media / Content / Education',
      orgStartup: isFa ? 'استارتاپ / محصول نرم‌افزاری' : 'Startup / Software Product',
      teamSolo: isFa ? 'بدون تیم فنی ثابت' : 'No fixed technical team',
      teamSmall: isFa ? '۱ تا ۵ نفر' : '1 to 5 people',
      teamExistingDev: isFa ? 'توسعه‌دهنده یا پیمانکار فعلی داریم' : 'Existing developer or contractor',
      timelineNow: isFa ? 'همین هفته' : 'This week',
      timelineSoon: isFa ? 'تا ۲ هفته آینده' : 'Within 2 weeks',
      timelineFlexible: isFa ? 'فوری نیست، اما می‌خواهیم بررسی شود' : 'Not urgent, but needs review',
      back: isFa ? 'بازگشت به مرحله قبل' : 'Back to Previous Step',
      submit: isFa ? 'درخواست بررسی + رفع سریع' : 'Request Review + Quick Fix',
      submitting: isFa ? 'در حال ارسال...' : 'Submitting...',
      submitError: isFa ? 'ارسال ناموفق بود. لطفا مجددا تلاش کنید.' : 'Submission failed. Please try again.',
      stepOneLegend: isFa ? 'مرحله اول راه ارتباط و سایت' : 'Step 1 contact and website',
      stepTwoLegend: isFa ? 'مرحله دوم مشکل و زمان‌بندی' : 'Step 2 issue and timing',
    }),
    [isFa]
  )

  useEffect(() => {
    window.localStorage.setItem(draftStorageKey, JSON.stringify(formData))
  }, [formData])

  useEffect(() => {
    if (viewTrackedRef.current) return
    viewTrackedRef.current = true
    void trackEvent({
      name: 'qualification_view',
      category: 'engagement',
      locale,
    })
  }, [locale])

  const onChange = (field: keyof typeof initialState, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }))
  }

  const isStepOneValid =
    formData.contactName.trim().length > 1 &&
    formData.organizationName.trim().length > 1 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email) &&
    formData.preferredContact.length > 0
  const progress = step === 1 ? 50 : 100
  const selectClass =
    'h-11 w-full rounded-md border border-input bg-background px-3 text-sm transition-colors focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:border-ring'

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setStatus('idle')

    try {
      const payload = new FormData()
      payload.set('contactName', formData.contactName)
      payload.set('organizationName', formData.organizationName)
      payload.set('organizationType', formData.organizationType)
      payload.set('email', formData.email)
      payload.set('phone', formData.phone)
      payload.set('teamSize', formData.teamSize)
      payload.set('currentStack', formData.currentStack)
      payload.set('criticalRisk', formData.criticalRisk)
      payload.set('timeline', formData.timeline)
      payload.set('budgetRange', formData.budgetRange)
      payload.set('preferredContact', formData.preferredContact)
      payload.set('notes', formData.notes)
      payload.set('website', formData.website)
      if (attachment) {
        payload.set('attachment', attachment)
      }

      const response = await fetch('/api/leads', {
        method: 'POST',
        body: payload,
      })

      if (!response.ok) {
        void trackEvent({
          name: 'qualification_submit_failed',
          category: 'conversion',
          locale,
        })
        setStatus('error')
        setSubmitting(false)
        return
      }

      void trackEvent({
        name: 'qualification_submit_success',
        category: 'conversion',
        locale,
      })
      setSubmitting(false)
      setFormData(initialState)
      setAttachment(null)
      setStep(1)
      window.localStorage.removeItem(draftStorageKey)
      router.push(`/${locale}/thank-you?source=lead`)
    } catch {
      void trackEvent({
        name: 'qualification_submit_failed',
        category: 'conversion',
        locale,
      })
      setStatus('error')
      setSubmitting(false)
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-5 rounded-2xl border bg-card/90 p-5 md:p-6 shadow-sm">
      <div className="hidden" aria-hidden="true">
        <Label htmlFor="website">Website</Label>
        <Input
          id="website"
          name="website"
          tabIndex={-1}
          autoComplete="off"
          value={formData.website}
          onChange={(e) => onChange('website', e.target.value)}
        />
      </div>

      <div className="space-y-2 rounded-xl border border-border/60 bg-muted/30 p-3">
        <div className="flex items-center justify-between gap-3 text-sm">
          <span className={step === 1 ? 'font-semibold text-primary' : 'text-muted-foreground'}>{copy.stepOneTitle}</span>
          <span className="text-muted-foreground">/</span>
          <span className={step === 2 ? 'font-semibold text-primary' : 'text-muted-foreground'}>{copy.stepTwoTitle}</span>
        </div>
        <div className="h-1.5 w-full rounded-full bg-background/80 overflow-hidden">
          <div
            className="h-full rounded-full bg-primary transition-all duration-300 ease-out"
            style={{ width: `${progress}%` }}
          />
        </div>
        <p className="text-xs text-muted-foreground">
          {step === 1 ? copy.stepOneHint : copy.stepTwoHint}
        </p>
      </div>

      {step === 1 ? (
        <fieldset className="space-y-4 reveal-up">
          <legend className="sr-only">{copy.stepOneLegend}</legend>
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="contactName">{copy.contactName}</Label>
              <Input id="contactName" value={formData.contactName} onChange={(e) => onChange('contactName', e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="organizationName">{copy.orgName}</Label>
              <Input id="organizationName" value={formData.organizationName} onChange={(e) => onChange('organizationName', e.target.value)} required />
            </div>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="email">{copy.orgEmail}</Label>
              <Input id="email" type="email" value={formData.email} onChange={(e) => onChange('email', e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="phone">{copy.phone}</Label>
              <Input id="phone" value={formData.phone} onChange={(e) => onChange('phone', e.target.value)} placeholder="@username یا 09..." />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="preferredContact">{copy.preferredContact}</Label>
            <select
              id="preferredContact"
              className={selectClass}
              value={formData.preferredContact}
              onChange={(e) => onChange('preferredContact', e.target.value)}
            >
              <option value="email">{copy.prefEmail}</option>
              <option value="phone">{copy.prefPhone}</option>
              <option value="telegram">{copy.prefTelegram}</option>
            </select>
          </div>

          <Button
            type="button"
            className="w-full h-11 shine-effect"
            disabled={!isStepOneValid}
            onClick={() => {
              void trackEvent({
                name: 'qualification_step1_submit',
                category: 'conversion',
                locale,
              })
              setStep(2)
            }}
          >
            {copy.nextStep}
          </Button>
        </fieldset>
      ) : (
        <fieldset className="space-y-4 reveal-up">
          <legend className="sr-only">{copy.stepTwoLegend}</legend>
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="teamSize">{copy.teamSize}</Label>
              <select
                id="teamSize"
                className={selectClass}
                value={formData.teamSize}
                onChange={(e) => onChange('teamSize', e.target.value)}
              >
                <option value="no-fixed-team">{copy.teamSolo}</option>
                <option value="1-5">{copy.teamSmall}</option>
                <option value="existing-dev">{copy.teamExistingDev}</option>
              </select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="timeline">{copy.timeline}</Label>
              <select
                id="timeline"
                className={selectClass}
                value={formData.timeline}
                onChange={(e) => onChange('timeline', e.target.value)}
              >
                <option value="this_week">{copy.timelineNow}</option>
                <option value="within_2_weeks">{copy.timelineSoon}</option>
                <option value="flexible">{copy.timelineFlexible}</option>
              </select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="currentStack">{copy.currentStack}</Label>
            <Input id="currentStack" value={formData.currentStack} onChange={(e) => onChange('currentStack', e.target.value)} placeholder={copy.currentStackPh} required />
          </div>

          <div className="space-y-2">
            <Label htmlFor="criticalRisk">{copy.criticalRisk}</Label>
            <Textarea id="criticalRisk" value={formData.criticalRisk} onChange={(e) => onChange('criticalRisk', e.target.value)} placeholder={copy.criticalRiskPh} required />
          </div>

          <div className="space-y-2">
            <Label htmlFor="notes">{copy.notes}</Label>
            <Textarea id="notes" value={formData.notes} onChange={(e) => onChange('notes', e.target.value)} />
          </div>

          <div className="space-y-2">
            <Label htmlFor="attachment">{copy.attachment}</Label>
            <Input
              id="attachment"
              type="file"
              accept=".pdf,.doc,.docx,.txt,.png,.jpg,.jpeg"
              onChange={(e) => setAttachment(e.target.files?.[0] ?? null)}
            />
            <p className="text-xs text-muted-foreground">{copy.attachmentHint}</p>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="budgetRange">{copy.budget}</Label>
              <select
                id="budgetRange"
                className={selectClass}
                value={formData.budgetRange}
                onChange={(e) => onChange('budgetRange', e.target.value)}
              >
                <option value="60-120m-irr">{copy.budgetLow}</option>
                <option value="120m-plus-irr">{copy.budgetHigh}</option>
              </select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="organizationType">{copy.orgType}</Label>
              <select
                id="organizationType"
                className={selectClass}
                value={formData.organizationType}
                onChange={(e) => onChange('organizationType', e.target.value)}
              >
                <option value="government_contractor">{copy.orgGovernment}</option>
                <option value="private_enterprise">{copy.orgPrivate}</option>
                <option value="semi_private">{copy.orgSemiPrivate}</option>
                <option value="startup">{copy.orgStartup}</option>
              </select>
            </div>
          </div>

          <div className="grid gap-2 md:grid-cols-2">
            <Button type="button" variant="outline" className="h-11 card-hover" onClick={() => setStep(1)} data-testid="qualification-back-button">
              {copy.back}
            </Button>
            <Button type="submit" disabled={submitting} className="w-full h-11 shine-effect">
              {submitting ? copy.submitting : copy.submit}
            </Button>
          </div>

          {status === 'error' ? <p className="text-sm text-red-600">{copy.submitError}</p> : null}
        </fieldset>
      )}
    </form>
  )
}
