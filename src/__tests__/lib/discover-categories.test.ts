import { describe, expect, it } from 'vitest'
import {
  getDiscoverCategoryLabel,
  getSafeDiscoverCategoryLabel,
  normalizeDiscoverCategory,
} from '@/lib/discover-categories'

describe('Discover category registry', () => {
  it('normalizes explicit category aliases to canonical keys', () => {
    expect(normalizeDiscoverCategory('AI')).toBe('ai')
  })

  it('returns the localized label for a canonical category', () => {
    expect(getDiscoverCategoryLabel('ai', 'fa')).toBe('هوش مصنوعی')
    expect(getDiscoverCategoryLabel('ai', 'en')).toBe('AI')
  })

  it('rejects unknown category values', () => {
    expect(() => normalizeDiscoverCategory('made-up')).toThrow()
  })

  it('uses the localized general label for unknown persisted category values', () => {
    expect(getSafeDiscoverCategoryLabel('legacy-unknown', 'fa')).toBe('عمومی')
    expect(getSafeDiscoverCategoryLabel('legacy-unknown', 'en')).toBe('General')
    expect(getSafeDiscoverCategoryLabel('ai', 'fa')).toBe('هوش مصنوعی')
  })
})
