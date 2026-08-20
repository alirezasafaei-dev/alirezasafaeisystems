'use client'

import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { ExternalLink, Pencil, Search, Trash2 } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { toast } from '@/hooks/use-toast'
import { DiscoverEditor, type DiscoverForm } from './discover/discover-editor'
import { type DiscoverSaveStatus } from './discover/discover-editor-status'
import { discardDraft, readDraft, writeDraft } from './discover/discover-draft-recovery'
import { DiscoverImportExport } from './discover/discover-import-export'
import { DiscoverPreview } from './discover/discover-preview'

type DiscoverItem = DiscoverForm & { id: string; imageUrl: string | null; instagramUrl: string | null; telegramGuideUrl: string | null; titleEn: string | null; descriptionEn: string | null; contentEn: string | null; publishedAt: string | null; createdAt: string; updatedAt: string }

const emptyForm: DiscoverForm = { slug: '', title: '', description: '', content: '', titleEn: '', descriptionEn: '', contentEn: '', externalUrl: '', category: '', tags: '', imageUrl: '', instagramUrl: '', telegramGuideUrl: '', featured: false, published: false, publishedEn: false, order: 0 }

function toForm(item: DiscoverItem): DiscoverForm {
  return { ...item, titleEn: item.titleEn || '', descriptionEn: item.descriptionEn || '', contentEn: item.contentEn || '', imageUrl: item.imageUrl || '', instagramUrl: item.instagramUrl || '', telegramGuideUrl: item.telegramGuideUrl || '' }
}

function payload(form: DiscoverForm): Record<string, unknown> {
  return { ...form, titleEn: form.titleEn || null, descriptionEn: form.descriptionEn || null, contentEn: form.contentEn || null }
}

export function DiscoverManager() {
  const [items, setItems] = useState<DiscoverItem[]>([])
  const [form, setForm] = useState<DiscoverForm>(emptyForm)
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(true)
  const [saveStatus, setSaveStatus] = useState<DiscoverSaveStatus>('idle')
  const [error, setError] = useState('')
  const [formErrors, setFormErrors] = useState<string[]>([])
  const [recovery, setRecovery] = useState<DiscoverForm | null>(null)

  const loadItems = useCallback(async () => {
    setLoading(true); setError('')
    try {
      const response = await fetch('/api/admin/discover?published=all', { cache: 'no-store' })
      if (response.status === 401) throw new Error('Authentication required')
      if (!response.ok) throw new Error('Failed to load Discover items')
      const data = await response.json() as { items?: DiscoverItem[] }
      setItems(data.items || [])
    } catch (loadError) { setError(loadError instanceof Error ? loadError.message : 'Failed to load Discover items') } finally { setLoading(false) }
  }, [])

  useEffect(() => {
    const timeout = window.setTimeout(() => { void loadItems() }, 0)
    return () => window.clearTimeout(timeout)
  }, [loadItems])
  useEffect(() => {
    const timeout = window.setTimeout(() => {
      const draft = readDraft<DiscoverForm>(form.id)
      if (draft && draft.savedAt > 0) setRecovery(draft.form)
    }, 0)
    return () => window.clearTimeout(timeout)
  }, [form.id])

  const filteredItems = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase()
    return normalized ? items.filter((item) => [item.title, item.titleEn || '', item.slug, item.category, item.tags, item.description].join(' ').toLocaleLowerCase().includes(normalized)) : items
  }, [items, query])

  function updateForm<K extends keyof DiscoverForm>(key: K, value: DiscoverForm[K]) {
    setForm((current) => { const next = { ...current, [key]: value }; writeDraft(next); return next })
    setSaveStatus('idle')
  }

  function startEdit(item: DiscoverItem) { setRecovery(null); setForm(toForm(item)); setFormErrors([]); window.scrollTo({ top: 0, behavior: 'smooth' }) }
  function resetForm() { discardDraft(form.id); setRecovery(null); setForm(emptyForm); setFormErrors([]); setSaveStatus('idle') }

  async function saveItem(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setSaveStatus('saving'); setFormErrors([])
    try {
      const response = await fetch('/api/admin/discover', { method: form.id ? 'PATCH' : 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload(form)) })
      const data = await response.json() as { item?: DiscoverItem; error?: string; details?: string[] }
      if (!response.ok || !data.item) {
        const details = data.details || [data.error || 'ذخیره آیتم ناموفق بود.']
        setFormErrors(details); throw new Error(details.join(' · '))
      }
      const saved = data.item
      setItems((current) => form.id ? current.map((item) => item.id === saved.id ? saved : item) : [saved, ...current])
      discardDraft(form.id); setSaveStatus('saved'); setForm(toForm(saved)); toast({ title: 'ذخیره شد', description: `${saved.title} در Discover ذخیره شد.` })
    } catch (saveError) { setSaveStatus('idle'); toast({ title: 'ذخیره ناموفق بود', description: saveError instanceof Error ? saveError.message : 'ذخیره آیتم ناموفق بود.', variant: 'destructive' }) }
  }

  async function deleteItem(item: DiscoverItem) {
    if (!window.confirm(`Delete “${item.title}” permanently?`)) return
    try {
      const response = await fetch(`/api/admin/discover?id=${encodeURIComponent(item.id)}`, { method: 'DELETE' })
      if (!response.ok) throw new Error('Failed to delete Discover item')
      setItems((current) => current.filter((currentItem) => currentItem.id !== item.id)); if (form.id === item.id) resetForm(); toast({ title: 'Deleted', description: `${item.title} removed from Discover` })
    } catch (deleteError) { toast({ title: 'Delete failed', description: deleteError instanceof Error ? deleteError.message : 'Failed to delete Discover item', variant: 'destructive' }) }
  }

  return <div dir="rtl" className="space-y-6">
    {recovery ? <div role="status" className="rounded-xl border border-primary/40 bg-card p-4"><p>یک پیش‌نویس محلی پیدا شد. تا انتخاب شما، دادهٔ سرور تغییری نمی‌کند.</p><div className="mt-3 flex gap-2"><Button type="button" onClick={() => { setForm(recovery); setRecovery(null) }}>بازیابی پیش‌نویس</Button><Button type="button" variant="outline" onClick={() => { discardDraft(form.id); setRecovery(null) }}>حذف پیش‌نویس</Button></div></div> : null}
    <DiscoverEditor value={form} status={saveStatus} errors={formErrors} onChange={updateForm} onSubmit={saveItem} onCancel={resetForm} />
    <div className="grid gap-6 xl:grid-cols-2"><DiscoverImportExport value={payload(form)} onImport={(value) => { const imported = value as unknown as DiscoverForm; setForm({ ...emptyForm, ...imported, id: form.id, tags: Array.isArray(imported.tags) ? imported.tags.join(', ') : imported.tags }); setSaveStatus('idle'); setFormErrors([]) }} /><DiscoverPreview value={form} /></div>
    <Card><CardHeader><div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between"><div><CardTitle>کتابخانهٔ Discover</CardTitle><CardDescription>{loading ? 'در حال بارگذاری…' : `${items.length} آیتم`}</CardDescription></div><label className="relative block"><span className="sr-only">Search Discover items</span><Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" /><Input dir="rtl" className="w-full ps-9 md:w-72" placeholder="جست‌وجوی عنوان، نامک یا دسته‌بندی" value={query} onChange={(event) => setQuery(event.target.value)} /></label></div></CardHeader><CardContent>
      {error ? <div role="alert" className="rounded-md border border-destructive/40 p-4 text-destructive">{error}</div> : null}
      {!loading && !error && filteredItems.length === 0 ? <div className="rounded-md border border-dashed p-8 text-center text-muted-foreground">آیتمی پیدا نشد.</div> : null}
      <div className="space-y-3">{filteredItems.map((item) => <div key={item.id} className="flex flex-col gap-4 rounded-xl border p-4 lg:flex-row lg:items-center lg:justify-between"><div className="min-w-0 space-y-2"><div className="flex flex-wrap items-center gap-2"><strong>{item.title}</strong><Badge variant="outline">{item.category}</Badge><Badge variant={item.published ? 'default' : 'secondary'}>{item.published ? 'منتشرشده' : 'پیش‌نویس'}</Badge></div><p dir="ltr" className="text-xs text-muted-foreground">/{item.slug} · order {item.order}</p><p className="line-clamp-2 text-sm text-muted-foreground">{item.description}</p></div><div className="flex shrink-0 flex-wrap gap-2">{item.published ? <Button asChild type="button" variant="outline" size="sm"><a href={`/discover/${item.slug}`} target="_blank" rel="noopener noreferrer"><ExternalLink />پیش‌نمایش فارسی</a></Button> : null}{item.publishedEn ? <Button asChild type="button" variant="outline" size="sm"><a href={`/en/discover/${item.slug}`} target="_blank" rel="noopener noreferrer"><ExternalLink />English preview</a></Button> : null}<Button type="button" variant="outline" size="sm" onClick={() => startEdit(item)}><Pencil />ویرایش</Button><Button type="button" variant="ghost" size="sm" onClick={() => void deleteItem(item)} aria-label={`Delete ${item.title}`}><Trash2 className="text-destructive" /></Button></div></div>)}</div>
    </CardContent></Card>
  </div>
}
