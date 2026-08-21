import { describe, expect, it } from 'vitest'
import { ADMIN_SHELL_COPY } from '@/lib/i18n/admin-shell-copy'

function flattenKeys(value: unknown, prefix = ''): string[] {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return []
  return Object.entries(value as Record<string, unknown>).flatMap(([key, nested]) => {
    const nextPrefix = prefix ? `${prefix}.${key}` : key
    if (nested && typeof nested === 'object' && !Array.isArray(nested)) return flattenKeys(nested, nextPrefix)
    return [nextPrefix]
  })
}

describe('Admin shell bilingual copy', () => {
  it('keeps Persian and English Admin shell keys in exact parity', () => {
    expect(flattenKeys(ADMIN_SHELL_COPY.fa).sort()).toEqual(flattenKeys(ADMIN_SHELL_COPY.en).sort())
  })

  it('defines representative login, dashboard status, and project labels in both locales', () => {
    expect(ADMIN_SHELL_COPY.en.login.title).toBe('Admin Login')
    expect(ADMIN_SHELL_COPY.fa.login.title).toBe('ورود مدیریت')
    expect(ADMIN_SHELL_COPY.en.dashboard.status.qualified).toBe('Qualified')
    expect(ADMIN_SHELL_COPY.fa.dashboard.status.qualified).toBe('واجد شرایط')
    expect(ADMIN_SHELL_COPY.en.projects.save).toBe('Save project')
    expect(ADMIN_SHELL_COPY.fa.projects.save).toBe('ذخیره پروژه')
  })
})
