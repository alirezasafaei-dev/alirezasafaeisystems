'use client'

import { FormEvent } from 'react'
import { Save } from 'lucide-react'
import { DISCOVER_CATEGORIES } from '@/lib/discover-categories'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { DiscoverEditorStatus, type DiscoverSaveStatus } from './discover-editor-status'
import { useDiscoverAdminCopy } from './discover-admin-copy'

export type DiscoverForm = {
  id?: string; slug: string; title: string; description: string; content: string
  titleEn: string; descriptionEn: string; contentEn: string; externalUrl: string; category: string; tags: string
  imageUrl: string; instagramUrl: string; telegramGuideUrl: string; featured: boolean; published: boolean; publishedEn: boolean; order: number
}

type Props = { value: DiscoverForm; status: DiscoverSaveStatus; errors: string[]; fieldErrors: Partial<Record<keyof DiscoverForm, string>>; onChange: <K extends keyof DiscoverForm>(key: K, value: DiscoverForm[K]) => void; onSubmit: (event: FormEvent<HTMLFormElement>) => void; onCancel: () => void }

const fieldClass = 'mt-1'
const errorId = (field: keyof DiscoverForm) => `discover-${field}-error`

function FieldError({ field, error }: { field: keyof DiscoverForm; error?: string }) {
  return error ? <p id={errorId(field)} className="mt-1 text-xs text-destructive">{error}</p> : null
}

export function DiscoverEditor({ value, status, errors, fieldErrors, onChange, onSubmit, onCancel }: Props) {
  const DISCOVER_ADMIN_COPY = useDiscoverAdminCopy()
  const englishReady = Boolean(value.titleEn.trim() && value.descriptionEn.trim() && value.contentEn.trim())
  const issueId = DISCOVER_ADMIN_COPY.editor.errorsId
  return <form data-testid="discover-editor" dir="rtl" onSubmit={onSubmit} className="space-y-5">
    <div className="rounded-xl border bg-card p-5"><div className="flex flex-wrap items-center justify-between gap-3"><h1 className="text-lg font-semibold">{value.id ? DISCOVER_ADMIN_COPY.editor.editing : DISCOVER_ADMIN_COPY.editor.creating}</h1><DiscoverEditorStatus status={status} /></div>
      {errors.length ? <div id={issueId} tabIndex={-1} role="alert" className="mt-4 rounded-md border border-destructive/40 p-3 text-sm text-destructive">{errors.map((error, index) => <p key={`${error}-${index}`}>{error}</p>)}</div> : null}
    </div>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="publish-heading"><h2 id="publish-heading" className="font-semibold">{DISCOVER_ADMIN_COPY.editor.publishHeading}</h2><div className="mt-4 flex flex-wrap gap-6">
      <label className="flex min-h-11 items-center gap-2"><input aria-invalid={Boolean(fieldErrors.published)} aria-describedby={fieldErrors.published ? errorId('published') : undefined} type="checkbox" checked={value.published} onChange={(event) => onChange('published', event.target.checked)} />{DISCOVER_ADMIN_COPY.editor.published}<FieldError field="published" error={fieldErrors.published} /></label>
      <div><label className="flex min-h-11 items-center gap-2"><input aria-invalid={Boolean(fieldErrors.publishedEn)} aria-describedby={fieldErrors.publishedEn ? errorId('publishedEn') : englishReady ? undefined : 'english-publish-help'} type="checkbox" checked={value.publishedEn} disabled={!englishReady} onChange={(event) => onChange('publishedEn', event.target.checked)} />{DISCOVER_ADMIN_COPY.editor.publishedEn}</label>{!englishReady ? <p id="english-publish-help" className="text-xs text-muted-foreground">{DISCOVER_ADMIN_COPY.editor.englishPublishHelp}</p> : null}<FieldError field="publishedEn" error={fieldErrors.publishedEn} /></div>
      <label className="flex min-h-11 items-center gap-2"><input aria-invalid={Boolean(fieldErrors.featured)} aria-describedby={fieldErrors.featured ? errorId('featured') : undefined} type="checkbox" checked={value.featured} onChange={(event) => onChange('featured', event.target.checked)} />{DISCOVER_ADMIN_COPY.editor.featured}<FieldError field="featured" error={fieldErrors.featured} /></label>
    </div></section>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="fa-heading"><h2 id="fa-heading" className="font-semibold">{DISCOVER_ADMIN_COPY.editor.persianHeading}</h2><div className="mt-4 grid gap-4 md:grid-cols-2">
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.title}<Input dir="rtl" aria-invalid={Boolean(fieldErrors.title)} aria-describedby={fieldErrors.title ? errorId('title') : undefined} className={fieldClass} required maxLength={140} value={value.title} onChange={(event) => onChange('title', event.target.value)} /><FieldError field="title" error={fieldErrors.title} /></label>
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.slug}<Input dir="ltr" aria-invalid={Boolean(fieldErrors.slug)} aria-describedby={fieldErrors.slug ? errorId('slug') : undefined} className={fieldClass} required minLength={2} maxLength={100} pattern="[a-z0-9]+(?:-[a-z0-9]+)*" value={value.slug} onChange={(event) => onChange('slug', event.target.value.toLowerCase())} /><FieldError field="slug" error={fieldErrors.slug} /></label>
      <label className="text-sm font-medium md:col-span-2">{DISCOVER_ADMIN_COPY.editor.description}<Textarea dir="rtl" aria-invalid={Boolean(fieldErrors.description)} aria-describedby={fieldErrors.description ? errorId('description') : undefined} className={fieldClass} required maxLength={400} value={value.description} onChange={(event) => onChange('description', event.target.value)} /><FieldError field="description" error={fieldErrors.description} /></label>
      <label className="text-sm font-medium md:col-span-2">{DISCOVER_ADMIN_COPY.editor.content}<Textarea dir="rtl" aria-invalid={Boolean(fieldErrors.content)} aria-describedby={fieldErrors.content ? errorId('content') : undefined} className={fieldClass} required maxLength={8000} rows={8} value={value.content} onChange={(event) => onChange('content', event.target.value)} /><FieldError field="content" error={fieldErrors.content} /></label>
    </div></section>
    <section dir="ltr" className="rounded-xl border bg-card p-5" aria-labelledby="en-heading"><h2 id="en-heading" className="font-semibold">{DISCOVER_ADMIN_COPY.editor.englishHeading}</h2><div className="mt-4 grid gap-4">
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.titleEn}<Input dir="ltr" aria-invalid={Boolean(fieldErrors.titleEn)} aria-describedby={fieldErrors.titleEn ? errorId('titleEn') : undefined} className={fieldClass} maxLength={140} value={value.titleEn} onChange={(event) => onChange('titleEn', event.target.value)} /><FieldError field="titleEn" error={fieldErrors.titleEn} /></label>
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.descriptionEn}<Textarea dir="ltr" aria-invalid={Boolean(fieldErrors.descriptionEn)} aria-describedby={fieldErrors.descriptionEn ? errorId('descriptionEn') : undefined} className={fieldClass} maxLength={400} value={value.descriptionEn} onChange={(event) => onChange('descriptionEn', event.target.value)} /><FieldError field="descriptionEn" error={fieldErrors.descriptionEn} /></label>
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.contentEn}<Textarea dir="ltr" aria-invalid={Boolean(fieldErrors.contentEn)} aria-describedby={fieldErrors.contentEn ? errorId('contentEn') : undefined} className={fieldClass} maxLength={8000} rows={8} value={value.contentEn} onChange={(event) => onChange('contentEn', event.target.value)} /><FieldError field="contentEn" error={fieldErrors.contentEn} /></label>
    </div></section>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="category-heading"><h2 id="category-heading" className="font-semibold">{DISCOVER_ADMIN_COPY.editor.categoryHeading}</h2><div className="mt-4 grid gap-4 md:grid-cols-2">
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.category}<select aria-invalid={Boolean(fieldErrors.category)} aria-describedby={fieldErrors.category ? errorId('category') : undefined} className="mt-1 flex h-9 w-full rounded-md border bg-transparent px-3 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" required value={value.category} onChange={(event) => onChange('category', event.target.value)}><option value="">{DISCOVER_ADMIN_COPY.editor.selectCategory}</option>{Object.entries(DISCOVER_CATEGORIES).map(([key, category]) => <option key={key} value={key}>{category.fa}</option>)}</select><FieldError field="category" error={fieldErrors.category} /></label>
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.tags}<Input dir="rtl" aria-invalid={Boolean(fieldErrors.tags)} aria-describedby={fieldErrors.tags ? errorId('tags') : undefined} className={fieldClass} value={value.tags} onChange={(event) => onChange('tags', event.target.value)} /><FieldError field="tags" error={fieldErrors.tags} /></label>
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.order}<Input dir="ltr" aria-invalid={Boolean(fieldErrors.order)} aria-describedby={fieldErrors.order ? errorId('order') : undefined} className={fieldClass} type="number" min={0} value={value.order} onChange={(event) => onChange('order', Number(event.target.value))} /><FieldError field="order" error={fieldErrors.order} /></label>
    </div></section>
    <section className="rounded-xl border bg-card p-5" aria-labelledby="links-heading"><h2 id="links-heading" className="font-semibold">{DISCOVER_ADMIN_COPY.editor.linksHeading}</h2><div className="mt-4 grid gap-4 md:grid-cols-2">
      <label className="text-sm font-medium md:col-span-2">{DISCOVER_ADMIN_COPY.editor.externalUrl}<Input dir="ltr" aria-invalid={Boolean(fieldErrors.externalUrl)} aria-describedby={fieldErrors.externalUrl ? errorId('externalUrl') : undefined} className={fieldClass} required type="url" value={value.externalUrl} onChange={(event) => onChange('externalUrl', event.target.value)} /><FieldError field="externalUrl" error={fieldErrors.externalUrl} /></label>
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.instagramUrl}<Input dir="ltr" aria-invalid={Boolean(fieldErrors.instagramUrl)} aria-describedby={fieldErrors.instagramUrl ? errorId('instagramUrl') : undefined} className={fieldClass} type="url" value={value.instagramUrl} onChange={(event) => onChange('instagramUrl', event.target.value)} /><FieldError field="instagramUrl" error={fieldErrors.instagramUrl} /></label>
      <label className="text-sm font-medium">{DISCOVER_ADMIN_COPY.editor.telegramGuideUrl}<Input dir="ltr" aria-invalid={Boolean(fieldErrors.telegramGuideUrl)} aria-describedby={fieldErrors.telegramGuideUrl ? errorId('telegramGuideUrl') : undefined} className={fieldClass} type="url" value={value.telegramGuideUrl} onChange={(event) => onChange('telegramGuideUrl', event.target.value)} /><FieldError field="telegramGuideUrl" error={fieldErrors.telegramGuideUrl} /></label>
      <label className="text-sm font-medium md:col-span-2">{DISCOVER_ADMIN_COPY.editor.imageUrl}<Input dir="ltr" aria-invalid={Boolean(fieldErrors.imageUrl)} aria-describedby={fieldErrors.imageUrl ? errorId('imageUrl') : undefined} className={fieldClass} type="url" value={value.imageUrl} onChange={(event) => onChange('imageUrl', event.target.value)} /><FieldError field="imageUrl" error={fieldErrors.imageUrl} /></label>
    </div></section>
    <div className="flex flex-wrap gap-2"><Button type="submit"><Save />{DISCOVER_ADMIN_COPY.editor.save}</Button>{value.id ? <Button type="button" variant="outline" onClick={onCancel}>{DISCOVER_ADMIN_COPY.editor.cancel}</Button> : null}</div>
  </form>
}
