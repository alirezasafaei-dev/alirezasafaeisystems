import { useDiscoverAdminCopy } from './discover-admin-copy'

export type DiscoverSaveStatus = 'idle' | 'saving' | 'saved'

export function DiscoverEditorStatus({ status }: { status: DiscoverSaveStatus }) {
  const DISCOVER_ADMIN_COPY = useDiscoverAdminCopy()
  const label = status === 'saving' ? DISCOVER_ADMIN_COPY.status.saving : status === 'saved' ? DISCOVER_ADMIN_COPY.status.saved : DISCOVER_ADMIN_COPY.status.unsaved
  return <p aria-live="polite" className="text-sm text-muted-foreground">{label}</p>
}
