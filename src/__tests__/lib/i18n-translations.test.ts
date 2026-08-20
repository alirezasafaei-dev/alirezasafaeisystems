import { describe, expect, it } from 'vitest'
import { translations } from '@/lib/i18n/translations'

function flattenKeys(value: unknown, prefix = ''): string[] {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return []
  }

  return Object.entries(value as Record<string, unknown>).flatMap(([key, nested]) => {
    const nextPrefix = prefix ? `${prefix}.${key}` : key
    if (nested && typeof nested === 'object' && !Array.isArray(nested)) {
      return flattenKeys(nested, nextPrefix)
    }
    return [nextPrefix]
  })
}

describe('i18n translations parity', () => {
  it('should include all english keys in persian translations', () => {
    const enKeys = flattenKeys(translations.en)
    const faKeys = new Set(flattenKeys(translations.fa))
    const missingInFa = enKeys.filter((key) => !faKeys.has(key))

    expect(missingInFa).toEqual([])
  })

  it('should include all persian keys in english translations', () => {
    const faKeys = flattenKeys(translations.fa)
    const enKeys = new Set(flattenKeys(translations.en))
    const missingInEn = faKeys.filter((key) => !enKeys.has(key))

    expect(missingInEn).toEqual([])
  })

  it('localizes the Discover navigation label in Persian', () => {
    expect(translations.fa.nav.discover).toBe('ابزارها و منابع')
    expect(translations.fa.footer.quickDiscover).toBe('ابزارها و منابع')
  })
})
