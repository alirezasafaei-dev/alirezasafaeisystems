'use client'

import { useState } from 'react'
import { Download, Upload } from 'lucide-react'
import { discoverCreateSchema } from '@/lib/discover'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { DISCOVER_ADMIN_COPY } from './discover-admin-copy'

type ImportableForm = Record<string, unknown>

export function DiscoverImportExport({ value, onImport }: { value: ImportableForm; onImport: (value: ImportableForm) => void }) {
  const [raw, setRaw] = useState('')
  const [error, setError] = useState('')

  function importJson() {
    try {
      const parsed = JSON.parse(raw) as unknown
      const result = discoverCreateSchema.safeParse(parsed)
      if (!result.success) {
        setError(result.error.issues[0]?.message || DISCOVER_ADMIN_COPY.transfer.invalid)
        return
      }
      onImport({ ...result.data, tags: result.data.tags })
      setError('')
    } catch {
      setError(DISCOVER_ADMIN_COPY.transfer.invalidJson)
    }
  }

  function exportJson() {
    const parsed = discoverCreateSchema.safeParse(value)
    if (!parsed.success) {
      setError(DISCOVER_ADMIN_COPY.transfer.exportInvalid)
      return
    }
    const blob = new Blob([JSON.stringify(parsed.data, null, 2)], { type: 'application/json' })
    const href = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = href
    link.download = `${parsed.data.slug}.json`
    link.click()
    URL.revokeObjectURL(href)
    setError('')
  }

  return <section className="rounded-xl border bg-card p-5" aria-labelledby="discover-transfer-heading">
    <h2 id="discover-transfer-heading" className="font-semibold">{DISCOVER_ADMIN_COPY.transfer.heading}</h2>
    <label className="mt-4 block text-sm font-medium" htmlFor="discover-json-import">{DISCOVER_ADMIN_COPY.transfer.label}</label>
    <Textarea id="discover-json-import" dir="ltr" className="mt-2" value={raw} onChange={(event) => setRaw(event.target.value)} />
    {error ? <p role="alert" className="mt-2 text-sm text-destructive">{error}</p> : null}
    <div className="mt-3 flex flex-wrap gap-2">
      <Button type="button" variant="outline" onClick={importJson}><Upload />{DISCOVER_ADMIN_COPY.transfer.import}</Button>
      <Button type="button" variant="outline" onClick={exportJson}><Download />{DISCOVER_ADMIN_COPY.transfer.export}</Button>
    </div>
  </section>
}
