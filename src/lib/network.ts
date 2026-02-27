export type NetworkUtmContent = 'footer' | 'profile_page' | 'standards_page'

export type NetworkLink = {
  key: 'portfolio' | 'toolbox' | 'audit'
  label: string
  baseUrl: string
}

export const SIGNATURE_TEXT = 'AliReza Safaei — علیرضا صفایی'
export const PORTFOLIO_LABEL = 'Portfolio & contact: alirezasafaeisystems.ir'
export const PORTFOLIO_URL = 'https://alirezasafaeisystems.ir/'
export const TELEGRAM_LABEL = 'Telegram: @asdevsystems'
export const TELEGRAM_URL = 'https://t.me/asdevsystems'

const NETWORK_LINKS: NetworkLink[] = [
  {
    key: 'portfolio',
    label: 'پورتفولیو و راه‌های ارتباطی',
    baseUrl: PORTFOLIO_URL,
  },
  {
    key: 'toolbox',
    label: 'PersianToolbox — ابزارهای فارسی (لوکال و امن)',
    baseUrl: 'https://persiantoolbox.ir/',
  },
  {
    key: 'audit',
    label: 'Audit IR — بررسی فنی و امنیتی',
    baseUrl: 'https://audit.alirezasafaeisystems.ir/',
  },
]

export function buildNetworkLinks(utmSource: string, utmContent: NetworkUtmContent) {
  return NETWORK_LINKS.map((item) => {
    const url = new URL(item.baseUrl)
    url.searchParams.set('utm_source', utmSource)
    url.searchParams.set('utm_medium', 'cross_site')
    url.searchParams.set('utm_campaign', 'alireza_network')
    url.searchParams.set('utm_content', utmContent)
    return {
      ...item,
      href: url.toString(),
    }
  })
}

