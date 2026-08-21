export const DISCOVER_DRAFT_PREFIX = 'asdev:discover:draft:'

export type DiscoverDraft<T> = { savedAt: number; form: T }

export function draftKey(id?: string): string {
  return `${DISCOVER_DRAFT_PREFIX}${id || 'new'}`
}

export function readDraft<T>(id?: string): DiscoverDraft<T> | null {
  const raw = window.localStorage.getItem(draftKey(id))
  if (!raw) return null
  try {
    const value = JSON.parse(raw) as DiscoverDraft<T>
    return typeof value.savedAt === 'number' && value.form ? value : null
  } catch {
    return null
  }
}

export function writeDraft<T>(form: T): void {
  const id = typeof form === 'object' && form && 'id' in form && typeof form.id === 'string' ? form.id : undefined
  window.localStorage.setItem(draftKey(id), JSON.stringify({ savedAt: Date.now(), form }))
}

export function discardDraft(id?: string): void {
  window.localStorage.removeItem(draftKey(id))
}
