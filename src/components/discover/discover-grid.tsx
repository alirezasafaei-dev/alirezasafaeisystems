'use client'

import { useMemo, useState } from 'react'
import Link from 'next/link'
import { ArrowLeft, ArrowRight, Search, Sparkles, X } from 'lucide-react'
import { appendDiscoverAttribution, type DiscoverAttribution } from '@/lib/discover'
import type { DiscoverCategoryKey } from '@/lib/discover-categories'
import { translations } from '@/lib/i18n/translations'

export type DiscoverGridItem = {
  slug: string
  title: string
  description: string
  categoryKey: DiscoverCategoryKey
  categoryLabel: string
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
  const hasActiveFilters = category !== 'all' || query.trim().length > 0

  const categories = useMemo(
    () => [...new Map(items.map((item) => [item.categoryKey, item.categoryLabel])).entries()]
      .sort(([, leftLabel], [, rightLabel]) => leftLabel.localeCompare(rightLabel)),
    [items],
  )

  const filteredItems = useMemo(() => {
    const normalizedQuery = query.trim().toLocaleLowerCase()
    return items.filter((item) => {
      if (category !== 'all' && item.categoryKey !== category) return false
      if (!normalizedQuery) return true
      const haystack = [item.title, item.description, item.categoryLabel, ...item.tags]
        .join(' ')
        .toLocaleLowerCase()
      return haystack.includes(normalizedQuery)
    })
  }, [category, items, query])

  const copy = translations[isEn ? 'en' : 'fa'].discover.grid
  const DetailArrow = isEn ? ArrowRight : ArrowLeft
  const resetFilters = () => {
    setQuery('')
    setCategory('all')
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
            className="h-11 w-full rounded-xl border bg-background ps-10 pe-4 text-sm outline-none transition duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 motion-reduce:transition-none"
          />
        </label>

        <div className="flex flex-wrap gap-2" aria-label={copy.categories}>
          <button
            type="button"
            onClick={() => setCategory('all')}
            aria-pressed={category === 'all'}
            className={`min-h-11 cursor-pointer rounded-full border px-4 py-2 text-sm transition duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 motion-reduce:transition-none ${category === 'all' ? 'border-primary bg-primary text-primary-foreground' : 'hover:bg-muted'}`}
          >
            {copy.all}
          </button>
          {categories.map(([itemCategory, itemCategoryLabel]) => (
            <button
              key={itemCategory}
              type="button"
              onClick={() => setCategory(itemCategory)}
              aria-pressed={category === itemCategory}
              className={`min-h-11 cursor-pointer rounded-full border px-4 py-2 text-sm transition duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 motion-reduce:transition-none ${category === itemCategory ? 'border-primary bg-primary text-primary-foreground' : 'hover:bg-muted'}`}
            >
              {itemCategoryLabel}
            </button>
          ))}
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs text-muted-foreground" aria-live="polite" aria-atomic="true">
            {filteredItems.length} {copy.results}
          </p>
          {hasActiveFilters ? (
            <button
              type="button"
              onClick={resetFilters}
              className="inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-xl px-3 text-sm font-semibold text-primary transition duration-200 hover:bg-primary/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 motion-reduce:transition-none"
            >
              <X className="h-4 w-4" aria-hidden="true" />
              {copy.reset}
            </button>
          ) : null}
        </div>
      </div>

      {filteredItems.length === 0 ? (
        <div className="space-y-4 rounded-2xl border border-dashed p-10 text-center text-muted-foreground" role="status">
          <p>{copy.empty}</p>
          <button
            type="button"
            onClick={resetFilters}
            className="inline-flex min-h-11 cursor-pointer items-center rounded-xl px-4 text-sm font-semibold text-primary transition duration-200 hover:bg-primary/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 motion-reduce:transition-none"
          >
            {copy.reset}
          </button>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredItems.map((item) => {
            const basePath = isEn ? `/en/discover/${item.slug}` : `/discover/${item.slug}`
            const href = appendDiscoverAttribution(basePath, attribution)
            return (
              <article key={item.slug} className="group flex h-full flex-col overflow-hidden rounded-2xl border bg-card shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md motion-reduce:transform-none motion-reduce:transition-none">
                {item.imageUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={item.imageUrl} alt="" loading="lazy" className="aspect-[16/9] w-full border-b object-cover" />
                ) : (
                  <div className="flex aspect-[16/9] items-center justify-center border-b bg-muted/40" aria-hidden="true">
                    <Sparkles className="h-8 w-8 text-primary/70" />
                  </div>
                )}
                <div className="flex flex-1 flex-col p-5">
                  <div className="flex flex-wrap items-center gap-2 text-xs">
                    <span className="rounded-full border px-2.5 py-1 text-muted-foreground">{item.categoryLabel}</span>
                    {item.featured ? <span className="font-semibold text-primary">{copy.featured}</span> : null}
                  </div>
                  <h2 className="mt-4 text-xl font-semibold leading-8">{item.title}</h2>
                  <p className="mt-2 line-clamp-3 text-sm leading-7 text-muted-foreground">{item.description}</p>
                  <div className="mt-3 flex flex-wrap gap-1.5">
                    {item.tags.slice(0, 4).map((tag) => (
                      <span key={tag} className="text-xs text-muted-foreground">#{tag}</span>
                    ))}
                  </div>
                  <Link href={href} className="mt-auto inline-flex min-h-11 items-center gap-2 pt-5 text-sm font-semibold text-primary underline-offset-4 transition duration-200 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 motion-reduce:transition-none">
                    {copy.open}
                    <DetailArrow className="h-4 w-4" aria-hidden="true" />
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
