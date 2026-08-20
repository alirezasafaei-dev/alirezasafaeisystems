'use client'

import { FormEvent } from 'react'
import { Save } from 'lucide-react'
import { DISCOVER_CATEGORIES } from '@/lib/discover-categories'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { DiscoverEditorStatus, type DiscoverSaveStatus } from './discover-editor-status'

export type DiscoverForm = {
  id?: string; slug: string; title: string; description: string; content: string
  titleEn: string; descriptionEn: string; contentEn: string; externalUrl: string; category: string; tags: string
  imageUrl: string; instagramUrl: string; telegramGuideUrl: string; featured: boolean; published: boolean; publishedEn: boolean; order: number
}

type Props = { value: DiscoverForm; status: DiscoverSaveStatus; errors: string[]; onChange: <K extends keyof DiscoverForm>(key: K, value: DiscoverForm[K]) => void; onSubmit: (event: FormEvent<HTMLFormElement>) => void; onCancel: () => void }

const fieldClass = 'mt-1'
const englishReadyMessage = 'برای انتشار انگلیسی، عنوان، توضیح و راهنمای انگلیسی را کامل کنید.'

export function DiscoverEditor({ value, status, errors, onChange, onSubmit, onCancel }: Props) {
  const englishReady = Boolean(value.titleEn.trim() && value.descriptionEn.trim() && value.contentEn.trim())
  const issueId = 'discover-editor-errors'
  return <form data-testid="discover-editor" dir="rtl" onSubmit={onSubmit} className="space-y-5">
    <div className="rounded-xl border bg-card p-5"><div className="flex flex-wrap items-center justify-between gap-3"><h1 className="text-lg font-semibold">{value.id ? 'ویرایش آیتم Discover' : 'آیتم جدید Discover'}</h1><DiscoverEditorStatus status={status} /></div>
      {errors.length ? <div id={issueId} tabIndex={-1} role="alert" className="mt-4 rounded-md border border-destructive/40 p-3 text-sm text-destructive">{errors.map((error) => <p key={error}>{error}</p>)}</div> : null}
    </div>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="publish-heading"><h2 id="publish-heading" className="font-semibold">وضعیت انتشار</h2><div className="mt-4 flex flex-wrap gap-6">
      <label className="flex min-h-11 items-center gap-2"><input type="checkbox" checked={value.published} onChange={(event) => onChange('published', event.target.checked)} />انتشار فارسی</label>
      <div><label className="flex min-h-11 items-center gap-2"><input aria-describedby={englishReady ? undefined : 'english-publish-help'} type="checkbox" checked={value.publishedEn} disabled={!englishReady} onChange={(event) => onChange('publishedEn', event.target.checked)} />انتشار انگلیسی</label>{!englishReady ? <p id="english-publish-help" className="text-xs text-muted-foreground">{englishReadyMessage}</p> : null}</div>
      <label className="flex min-h-11 items-center gap-2"><input type="checkbox" checked={value.featured} onChange={(event) => onChange('featured', event.target.checked)} />ویژه</label>
    </div></section>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="fa-heading"><h2 id="fa-heading" className="font-semibold">محتوای فارسی</h2><div className="mt-4 grid gap-4 md:grid-cols-2">
      <label className="text-sm font-medium">عنوان فارسی<Input dir="rtl" className={fieldClass} required maxLength={140} value={value.title} onChange={(event) => onChange('title', event.target.value)} /></label>
      <label className="text-sm font-medium">نامک<Input dir="ltr" className={fieldClass} required minLength={2} maxLength={100} pattern="[a-z0-9]+(?:-[a-z0-9]+)*" value={value.slug} onChange={(event) => onChange('slug', event.target.value.toLowerCase())} /></label>
      <label className="text-sm font-medium md:col-span-2">توضیح فارسی<Textarea dir="rtl" className={fieldClass} required maxLength={400} value={value.description} onChange={(event) => onChange('description', event.target.value)} /></label>
      <label className="text-sm font-medium md:col-span-2">راهنمای فارسی<Textarea dir="rtl" className={fieldClass} required maxLength={8000} rows={8} value={value.content} onChange={(event) => onChange('content', event.target.value)} /></label>
    </div></section>
    <section dir="ltr" className="rounded-xl border bg-card p-5" aria-labelledby="en-heading"><h2 id="en-heading" className="font-semibold">English content</h2><div className="mt-4 grid gap-4">
      <label className="text-sm font-medium">English title<Input dir="ltr" className={fieldClass} maxLength={140} value={value.titleEn} onChange={(event) => onChange('titleEn', event.target.value)} /></label>
      <label className="text-sm font-medium">English description<Textarea dir="ltr" className={fieldClass} maxLength={400} value={value.descriptionEn} onChange={(event) => onChange('descriptionEn', event.target.value)} /></label>
      <label className="text-sm font-medium">English guide<Textarea dir="ltr" className={fieldClass} maxLength={8000} rows={8} value={value.contentEn} onChange={(event) => onChange('contentEn', event.target.value)} /></label>
    </div></section>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="category-heading"><h2 id="category-heading" className="font-semibold">دسته‌بندی و برچسب‌ها</h2><div className="mt-4 grid gap-4 md:grid-cols-2">
      <label className="text-sm font-medium">دسته‌بندی<select className="mt-1 flex h-9 w-full rounded-md border bg-transparent px-3 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" required value={value.category} onChange={(event) => onChange('category', event.target.value)}><option value="">انتخاب کنید</option>{Object.entries(DISCOVER_CATEGORIES).map(([key, category]) => <option key={key} value={key}>{category.fa}</option>)}</select></label>
      <label className="text-sm font-medium">برچسب‌ها<Input dir="rtl" className={fieldClass} value={value.tags} onChange={(event) => onChange('tags', event.target.value)} /></label>
      <label className="text-sm font-medium">ترتیب نمایش<Input dir="ltr" className={fieldClass} type="number" min={0} value={value.order} onChange={(event) => onChange('order', Number(event.target.value))} /></label>
    </div></section>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="links-heading"><h2 id="links-heading" className="font-semibold">لینک‌ها و منبع</h2><div className="mt-4 grid gap-4 md:grid-cols-2">
      <label className="text-sm font-medium md:col-span-2">نشانی رسمی HTTPS<Input dir="ltr" className={fieldClass} required type="url" value={value.externalUrl} onChange={(event) => onChange('externalUrl', event.target.value)} /></label>
      <label className="text-sm font-medium">نشانی اینستاگرام<Input dir="ltr" className={fieldClass} type="url" value={value.instagramUrl} onChange={(event) => onChange('instagramUrl', event.target.value)} /></label>
      <label className="text-sm font-medium">نشانی تلگرام<Input dir="ltr" className={fieldClass} type="url" value={value.telegramGuideUrl} onChange={(event) => onChange('telegramGuideUrl', event.target.value)} /></label>
      <label className="text-sm font-medium md:col-span-2">نشانی تصویر<Input dir="ltr" className={fieldClass} type="url" value={value.imageUrl} onChange={(event) => onChange('imageUrl', event.target.value)} /></label>
    </div></section>
    <div className="flex flex-wrap gap-2"><Button type="submit"><Save />ذخیره آیتم</Button>{value.id ? <Button type="button" variant="outline" onClick={onCancel}>انصراف</Button> : null}</div>
  </form>
}
