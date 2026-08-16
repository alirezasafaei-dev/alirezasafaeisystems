'use client'

import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { ExternalLink, Pencil, Save, Search, Trash2, X } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { toast } from '@/hooks/use-toast'

type DiscoverItem = {
  id: string
  slug: string
  title: string
  description: string
  content: string
  externalUrl: string
  category: string
  tags: string
  imageUrl: string | null
  instagramUrl: string | null
  featured: boolean
  published: boolean
  order: number
  publishedAt: string | null
  createdAt: string
  updatedAt: string
}

type DiscoverForm = {
  id?: string
  slug: string
  title: string
  description: string
  content: string
  externalUrl: string
  category: string
  tags: string
  imageUrl: string
  instagramUrl: string
  featured: boolean
  published: boolean
  order: number
}

const emptyForm: DiscoverForm = {
  slug: '',
  title: '',
  description: '',
  content: '',
  externalUrl: '',
  category: '',
  tags: '',
  imageUrl: '',
  instagramUrl: '',
  featured: false,
  published: false,
  order: 0,
}

function toForm(item: DiscoverItem): DiscoverForm {
  return {
    id: item.id,
    slug: item.slug,
    title: item.title,
    description: item.description,
    content: item.content,
    externalUrl: item.externalUrl,
    category: item.category,
    tags: item.tags,
    imageUrl: item.imageUrl || '',
    instagramUrl: item.instagramUrl || '',
    featured: item.featured,
    published: item.published,
    order: item.order,
  }
}

export function DiscoverManager() {
  const [items, setItems] = useState<DiscoverItem[]>([])
  const [form, setForm] = useState<DiscoverForm>(emptyForm)
  const [query, setQuery] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const loadItems = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await fetch('/api/admin/discover?published=all', { cache: 'no-store' })
      if (response.status === 401) throw new Error('Authentication required')
      if (!response.ok) throw new Error('Failed to load Discover items')
      const data = await response.json() as { items?: DiscoverItem[] }
      setItems(data.items || [])
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : 'Failed to load Discover items')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      void loadItems()
    }, 0)

    return () => window.clearTimeout(timeout)
  }, [loadItems])

  const filteredItems = useMemo(() => {
    const normalized = query.trim().toLocaleLowerCase()
    if (!normalized) return items
    return items.filter((item) => [item.title, item.slug, item.category, item.tags, item.description]
      .join(' ')
      .toLocaleLowerCase()
      .includes(normalized))
  }, [items, query])

  function updateForm<K extends keyof DiscoverForm>(key: K, value: DiscoverForm[K]) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function startEdit(item: DiscoverItem) {
    setForm(toForm(item))
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  async function saveItem(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setSaving(true)
    try {
      const response = await fetch('/api/admin/discover', {
        method: form.id ? 'PATCH' : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      })
      const data = await response.json() as { item?: DiscoverItem; error?: string; details?: string[] }
      if (!response.ok || !data.item) {
        throw new Error(data.details?.join(' · ') || data.error || 'Failed to save Discover item')
      }

      const saved = data.item
      setItems((current) => form.id
        ? current.map((item) => item.id === saved.id ? saved : item)
        : [saved, ...current])
      setForm(emptyForm)
      toast({ title: 'Saved', description: `${saved.title} saved in Discover` })
    } catch (saveError) {
      toast({
        title: 'Discover save failed',
        description: saveError instanceof Error ? saveError.message : 'Failed to save Discover item',
        variant: 'destructive',
      })
    } finally {
      setSaving(false)
    }
  }

  async function deleteItem(item: DiscoverItem) {
    if (!window.confirm(`Delete “${item.title}” permanently?`)) return

    try {
      const response = await fetch(`/api/admin/discover?id=${encodeURIComponent(item.id)}`, { method: 'DELETE' })
      if (!response.ok) throw new Error('Failed to delete Discover item')
      setItems((current) => current.filter((currentItem) => currentItem.id !== item.id))
      if (form.id === item.id) setForm(emptyForm)
      toast({ title: 'Deleted', description: `${item.title} removed from Discover` })
    } catch (deleteError) {
      toast({
        title: 'Delete failed',
        description: deleteError instanceof Error ? deleteError.message : 'Failed to delete Discover item',
        variant: 'destructive',
      })
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{form.id ? 'Edit Discover item' : 'New Discover item'}</CardTitle>
          <CardDescription>
            Publish apps, services, platforms and short guides for Instagram/search acquisition.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form className="grid gap-4 md:grid-cols-2" onSubmit={saveItem}>
            <label className="space-y-1 text-sm font-medium">
              Title
              <Input required maxLength={140} value={form.title} onChange={(event) => updateForm('title', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium">
              Slug
              <Input required minLength={2} maxLength={100} pattern="[a-z0-9]+(?:-[a-z0-9]+)*" placeholder="notebooklm" value={form.slug} onChange={(event) => updateForm('slug', event.target.value.toLowerCase())} />
            </label>
            <label className="space-y-1 text-sm font-medium">
              Category
              <Input required maxLength={60} placeholder="AI" value={form.category} onChange={(event) => updateForm('category', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium">
              Tags
              <Input placeholder="AI, research, productivity" value={form.tags} onChange={(event) => updateForm('tags', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium md:col-span-2">
              Short description
              <Textarea required maxLength={400} value={form.description} onChange={(event) => updateForm('description', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium md:col-span-2">
              Short practical guide
              <Textarea required maxLength={8000} rows={8} placeholder="Use blank lines to separate paragraphs." value={form.content} onChange={(event) => updateForm('content', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium md:col-span-2">
              Official HTTPS URL
              <Input required type="url" placeholder="https://example.com/" value={form.externalUrl} onChange={(event) => updateForm('externalUrl', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium">
              Instagram post/reel URL
              <Input type="url" placeholder="https://www.instagram.com/reel/..." value={form.instagramUrl} onChange={(event) => updateForm('instagramUrl', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium">
              Image HTTPS URL
              <Input type="url" placeholder="https://..." value={form.imageUrl} onChange={(event) => updateForm('imageUrl', event.target.value)} />
            </label>
            <label className="space-y-1 text-sm font-medium">
              Sort order
              <Input type="number" min={0} value={form.order} onChange={(event) => updateForm('order', Number(event.target.value))} />
            </label>
            <div className="flex flex-wrap items-center gap-5 self-end pb-2">
              <label className="inline-flex items-center gap-2 text-sm">
                <input type="checkbox" checked={form.published} onChange={(event) => updateForm('published', event.target.checked)} />
                Published
              </label>
              <label className="inline-flex items-center gap-2 text-sm">
                <input type="checkbox" checked={form.featured} onChange={(event) => updateForm('featured', event.target.checked)} />
                Featured
              </label>
            </div>
            <div className="flex flex-wrap gap-2 md:col-span-2">
              <Button type="submit" disabled={saving}>
                <Save className="me-2 h-4 w-4" />
                {saving ? 'Saving…' : 'Save Discover item'}
              </Button>
              {form.id ? (
                <Button type="button" variant="outline" onClick={() => setForm(emptyForm)}>
                  <X className="me-2 h-4 w-4" /> Cancel
                </Button>
              ) : null}
            </div>
          </form>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <CardTitle>Discover library</CardTitle>
              <CardDescription>{loading ? 'Loading…' : `${items.length} item(s)`}</CardDescription>
            </div>
            <label className="relative block">
              <span className="sr-only">Search Discover items</span>
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input className="w-full pl-9 md:w-72" placeholder="Search title, slug, category…" value={query} onChange={(event) => setQuery(event.target.value)} />
            </label>
          </div>
        </CardHeader>
        <CardContent>
          {error ? <div role="alert" className="rounded-md border border-destructive/40 p-4 text-destructive">{error}</div> : null}
          {!loading && !error && filteredItems.length === 0 ? (
            <div className="rounded-md border border-dashed p-8 text-center text-muted-foreground">No Discover items found.</div>
          ) : null}
          <div className="space-y-3">
            {filteredItems.map((item) => (
              <div key={item.id} className="flex flex-col gap-4 rounded-xl border p-4 lg:flex-row lg:items-center lg:justify-between">
                <div className="min-w-0 space-y-2">
                  <div className="flex flex-wrap items-center gap-2">
                    <strong>{item.title}</strong>
                    <Badge variant="outline">{item.category}</Badge>
                    <Badge variant={item.published ? 'default' : 'secondary'}>{item.published ? 'Published' : 'Draft'}</Badge>
                    {item.featured ? <Badge>Featured</Badge> : null}
                  </div>
                  <p className="text-xs text-muted-foreground">/{item.slug} · order {item.order}</p>
                  <p className="line-clamp-2 text-sm text-muted-foreground">{item.description}</p>
                </div>
                <div className="flex shrink-0 flex-wrap gap-2">
                  {item.published ? (
                    <Button asChild type="button" variant="outline" size="sm">
                      <a href={`/discover/${item.slug}`} target="_blank" rel="noopener noreferrer">
                        <ExternalLink className="me-2 h-4 w-4" /> Preview
                      </a>
                    </Button>
                  ) : null}
                  <Button type="button" variant="outline" size="sm" onClick={() => startEdit(item)}>
                    <Pencil className="me-2 h-4 w-4" /> Edit
                  </Button>
                  <Button type="button" variant="ghost" size="sm" onClick={() => void deleteItem(item)} aria-label={`Delete ${item.title}`}>
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
