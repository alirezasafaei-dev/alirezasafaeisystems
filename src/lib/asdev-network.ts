import {
  buildNetworkLinks,
  PORTFOLIO_LABEL,
  PORTFOLIO_URL,
  SIGNATURE_TEXT,
  TELEGRAM_LABEL,
  TELEGRAM_URL,
  type NetworkLink,
  type NetworkUtmContent,
} from '@/lib/network'

// Backward-compatible aliases for existing imports.
export type AsdevUtmContent = 'footer' | 'asdev_page' | 'standards_page'
export type AsdevNetworkLink = NetworkLink

export const ASDEV_SIGNATURE_TEXT = SIGNATURE_TEXT
export const ASDEV_PORTFOLIO_LABEL = PORTFOLIO_LABEL
export const ASDEV_PORTFOLIO_URL = PORTFOLIO_URL
export const ASDEV_TELEGRAM_LABEL = TELEGRAM_LABEL
export const ASDEV_TELEGRAM_URL = TELEGRAM_URL

export function buildAsdevNetworkLinks(utmSource: string, utmContent: AsdevUtmContent) {
  const normalizedContent: NetworkUtmContent = utmContent === 'asdev_page' ? 'profile_page' : utmContent
  return buildNetworkLinks(utmSource, normalizedContent)
}

