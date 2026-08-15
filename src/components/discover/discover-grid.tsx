'use client'

import { useMemo, useState } from 'react'
import Link from 'next/link'
import { Search, Sparkles } from 'lucide-react'
import { appendDiscoverAttribution, type DiscoverAttribution } from '@/lib/discover'

export type DiscoverGridItem = {
  slug: string
  title: string
  description: string
  category: string
  tags: string[]
  featured: boolean
  imageUrl: string | null
}

type DiscoverGridProps = {
  items: DiscoverGridItem[]
  attribution: DiscoverAttribution
  isEn: boolean
}

export function DiscoverGrid({ items, attribution, isEn }: DiscoverGridProps) {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('all')

  const categories = useMemo(
    () => [...new Set(items.map((item) => item.category).filter(Boolean))].sort((a, b) => a.localeCompare(b)),
    [items],
  )

  const filteredItems = useMemo(() => {
    const normalizedQuery = query.trim().toLocaleLowerCase()
    return items.filter((item) => {
      if (category !== 'all' && item.category !== category) return false
      if (!normalizedQuery) return true
      const haystack = [item.title, item.description, item.category, ...item.tags]
        .join(' ')
        .toLocaleLowerCase()
      return haystack.includes(normalizedQuery)
    })
  }, [category, items, query])

  const copy = isEn
    ? {
        search: 'Search tools and services',
        all: 'All',
        featured: 'Featured',
        open: 'View guide and official link',
        empty: 'No Discover items match this filter.',
        results: 'items',
      }
    : {
        search: 'جستجو بین ابزارها و سرویس‌ها',
        all: 'همه',
        featured: 'منتخب',
        open: 'توضیح کوتاه و لینک رسمی',
        empty: 'موردی با این فیلتر پیدا نشد.',
        results: 'مورد',
      }

  return (
    <div className="space-y-6">
      <div className="space-y-4 rounded-2xl border bg-card/70 p-4 md:p-5">
        <label className="relative block">
          <span className="sr-only">{copy.search}</span>
          <Search className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="search"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder={copy.search}
            className="h-11 w-full rounded-xl border bg-background ps-10 pe-4 text-sm outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </label>

        <div className="flex flex-wrap gap-2" aria-label={isEn ? 'Discover categories' : 'دسته‌بندی‌های Discover'}>
          <button
            type="button"
            onClick={() => setCategory('all')}
            aria-pressed={category === 'all'}
            className={`rounded-full border px-3 py-1.5 text-sm transition ${category === 'all' ? 'border-primary bg-primary text-primary-foreground' : 'hover:bg-muted'}`}
          >
            {copy.all}
          </button>
          {categories.map((itemCategory) => (
            <button
              key={itemCategory}
              type="button"
              onClick={() => setCategory(itemCategory)}
              aria-pressed={category === itemCategory}
              className={`rounded-full border px-3 py-1.5 text-sm transition ${category === itemCategory ? 'border-primary bg-primary text-primary-foreground' : 'hover:bg-muted'}`}
            >
              {itemCategory}
            </button>
          ))}
        </div>

        <p className="text-xs text-muted-foreground" aria-live="polite">
          {filteredItems.length} {copy.results}
        </p>
      </div>

      {filteredItems.length === 0 ? (
        <div className="rounded-2xl border border-dashed p-10 text-center text-muted-foreground" role="status">
          {copy.empty}
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredItems.map((item) => {
            const basePath = isEn ? `/en/discover/${item.slug}` : `/discover/${item.slug}`
            const href = appendDiscoverAttribution(basePath, attribution)
            return (
              <article key={item.slug} className="group flex h-full flex-col overflow-hidden rounded-2xl border bg-card card-hover">
                {item.imageUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={item.imageUrl} alt="" loading="lazy" className="aspect-[16/9] w-full border-b object-cover" />
                ) : (
                  <div className="flex aspect-[16/7] items-center justify-center border-b bg-muted/40" aria-hidden="true">
                    <Sparkles className="h-8 w-8 text-primary/70" />
                  </div>
                )}
                <div className="flex flex-1 flex-col p-5">
                  <div className="flex flex-wrap items-center gap-2 text-xs">
                    <span className="rounded-full border px-2.5 py-1 text-muted-foreground">{item.category}</span>
                    {item.featured ? <span className="font-semibold text-primary">{copy.featured}</span> : null}
                  </div>
                  <h2 className="mt-4 text-xl font-semibold leading-8">{item.title}</h2>
                  <p className="mt-2 line-clamp-3 text-sm leading-7 text-muted-foreground">{item.description}</p>
                  <div className="mt-3 flex flex-wrap gap-1.5">
                    {item.tags.slice(0, 4).map((tag) => (
                      <span key={tag} className="text-xs text-muted-foreground">#{tag}</span>
                    ))}
                  </div>
                  <Link href={href} className="mt-auto pt-5 text-sm font-semibold text-primary underline-offset-4 hover:underline">
                    {copy.open} →
                  </Link>
                </div>
              </article>
            )
          })}
        </div>
      )}
    </div>
  )
}
