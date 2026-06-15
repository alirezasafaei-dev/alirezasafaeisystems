import { describe, it, expect, beforeEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { ReactNode } from 'react'
import { I18nProvider, useI18n } from '@/lib/i18n-context'

function createWrapper(initialLanguage: 'fa' | 'en' = 'fa') {
  return function Wrapper({ children }: { children: ReactNode }) {
    return <I18nProvider initialLanguage={initialLanguage}>{children}</I18nProvider>
  }
}

describe('I18nProvider', () => {
  beforeEach(() => {
    document.cookie = 'lang=; Path=/; Max-Age=0'
  })

  it('provides fa language when cookie is empty', () => {
    const wrapper = createWrapper('fa')
    const { result } = renderHook(() => useI18n(), { wrapper })
    expect(result.current.language).toBe('fa')
  })

  it('provides English initial language when cookie is set to en', () => {
    document.cookie = 'lang=en; Path=/'
    const wrapper = createWrapper('en')
    const { result } = renderHook(() => useI18n(), { wrapper })
    expect(result.current.language).toBe('en')
  })

  it('changes language via setLanguage', () => {
    const wrapper = createWrapper()
    const { result } = renderHook(() => useI18n(), { wrapper })

    act(() => {
      result.current.setLanguage('en')
    })

    expect(result.current.language).toBe('en')
  })

  it('translates keys with t() function', () => {
    const wrapper = createWrapper('fa')
    const { result } = renderHook(() => useI18n(), { wrapper })

    expect(result.current.t('nav.home')).toBeDefined()
    expect(result.current.t('nav.services')).toBeDefined()
  })

  it('translates English keys', () => {
    const wrapper = createWrapper('en')
    const { result } = renderHook(() => useI18n(), { wrapper })

    expect(result.current.t('nav.home')).toBe('Home')
    expect(result.current.t('nav.services')).toBe('Services')
  })

  it('returns key for non-existent translation', () => {
    const wrapper = createWrapper()
    const { result } = renderHook(() => useI18n(), { wrapper })

    expect(result.current.t('nonexistent.key')).toBe('nonexistent.key')
  })

  it('returns key for empty string', () => {
    const wrapper = createWrapper()
    const { result } = renderHook(() => useI18n(), { wrapper })

    expect(result.current.t('')).toBe('')
  })

  it('returns key for non-string input', () => {
    const wrapper = createWrapper()
    const { result } = renderHook(() => useI18n(), { wrapper })

    expect(result.current.t(undefined as unknown as string)).toBe(undefined)
  })

  it('handles nested translation keys', () => {
    const wrapper = createWrapper('en')
    const { result } = renderHook(() => useI18n(), { wrapper })

    expect(result.current.t('hero.title')).toContain('stable')
  })
})

describe('useI18n without provider', () => {
  it('throws error when used outside provider', () => {
    expect(() => {
      renderHook(() => useI18n())
    }).toThrow('useI18n must be used within an I18nProvider')
  })
})
