export type DiscoverSaveStatus = 'idle' | 'saving' | 'saved'

export function DiscoverEditorStatus({ status }: { status: DiscoverSaveStatus }) {
  const label = status === 'saving' ? 'در حال ذخیره…' : status === 'saved' ? 'ذخیره شد' : 'ذخیره‌نشده'
  return <p aria-live="polite" className="text-sm text-muted-foreground">{label}</p>
}
