import { useState } from 'react'
import { ExternalLink } from 'lucide-react'
import { Button } from '@/components/ui/button'
import type { DiscoverForm } from './discover-editor'

export function DiscoverPreview({ value }: { value: DiscoverForm }) {
  const [locale, setLocale] = useState<'fa' | 'en'>('fa')
  const isEnglish = locale === 'en'
  const title = isEnglish ? value.titleEn : value.title
  const description = isEnglish ? value.descriptionEn : value.description
  const published = isEnglish ? value.publishedEn : value.published
  const href = isEnglish ? `/en/discover/${value.slug}` : `/discover/${value.slug}`

  return <section aria-labelledby="discover-preview-heading" className="rounded-xl border bg-card p-5">
    <div className="flex flex-wrap items-center justify-between gap-3">
      <h2 id="discover-preview-heading" className="font-semibold">پیش‌نمایش و SEO</h2>
      <div className="flex gap-2">
        <Button type="button" size="sm" variant={isEnglish ? 'outline' : 'secondary'} onClick={() => setLocale('fa')}>فارسی</Button>
        <Button type="button" size="sm" variant={isEnglish ? 'secondary' : 'outline'} onClick={() => setLocale('en')}>English</Button>
      </div>
    </div>
    <article className="mt-4 rounded-lg border p-4" dir={isEnglish ? 'ltr' : 'rtl'}>
      <p className="text-xs text-muted-foreground" dir="ltr">/discover/{value.slug || '…'}</p>
      <h3 className="mt-2 font-semibold">{title || (isEnglish ? 'English title' : 'عنوان فارسی')}</h3>
      <p className="mt-2 text-sm text-muted-foreground">{description || (isEnglish ? 'English description' : 'توضیح فارسی')}</p>
    </article>
    {published && value.slug ? <Button asChild className="mt-4" variant="outline"><a href={href} target="_blank" rel="noreferrer"><ExternalLink />نمایش عمومی</a></Button> : null}
  </section>
}
