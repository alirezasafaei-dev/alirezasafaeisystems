'use client'

import React, { useState, useEffect, ReactNode } from 'react'
import { Language, translations } from './i18n/translations'

interface I18nContextType {
  language: Language
  setLanguage: (lang: Language) => void
  t: (key: string) => string
}

const I18nContext = React.createContext<I18nContextType | undefined>(undefined)

function setLangCookie(lang: Language) {
  // One-year, Lax; keeps SSR and CSR in sync. No external deps.
  document.cookie = `lang=${lang}; Path=/; Max-Age=31536000; SameSite=Lax`
}

function hasLangCookie(): boolean {
  return typeof document !== 'undefined' && document.cookie.split(';').some((c) => c.trim().startsWith('lang='))
}

export function I18nProvider({ children, initialLanguage = 'fa' }: { children: ReactNode; initialLanguage?: Language }) {
  const [language, setLanguage] = useState<Language>(() => {
    if (typeof document === 'undefined') return initialLanguage

    const cookieLang = document.cookie
      .split(';')
      .map((c) => c.trim())
      .find((c) => c.startsWith('lang='))
      ?.split('=')[1]

    if (cookieLang === 'en' || cookieLang === 'fa') {
      return cookieLang
    }

    return initialLanguage
  })

  // Set initial language and direction
  useEffect(() => {
    document.documentElement.lang = language
    document.documentElement.dir = language === 'fa' ? 'rtl' : 'ltr'
  }, [language])

  // Ensure persistence without triggering re-renders.
  useEffect(() => {
    if (typeof window === 'undefined') return
    try {
      if (!hasLangCookie()) setLangCookie(language)
      localStorage.setItem('language', language)
    } catch {
      // ignore
    }
  }, [language])

  const changeLanguage = (lang: Language) => {
    setLanguage(lang)
    if (typeof window !== 'undefined') {
      localStorage.setItem('language', lang)
      setLangCookie(lang)
    }
  }

  const t = (key: string): string => {
    if (!key || typeof key !== 'string') {
      return key
    }

    if (!translations[language]) {
      return key
    }

    const keys = key.split('.')
    let value: unknown = translations[language]

    // Navigate through nested keys
    for (const k of keys) {
      if (typeof value === 'object' && value !== null && k in value) {
        value = (value as Record<string, unknown>)[k]
      } else {
        // If any key in the path doesn't exist, stop and return key
        // This ensures we don't return partial translations
        return key
      }
    }

    return typeof value === 'string' ? value : key
  }

  return (
    <I18nContext.Provider value={{ language, setLanguage: changeLanguage, t }}>
      {children}
    </I18nContext.Provider>
  )
}

export function useI18n() {
  const context = React.useContext(I18nContext)
  if (context === undefined) {
    throw new Error('useI18n must be used within an I18nProvider')
  }
  return context
}

export { translations }
