export const DISCOVER_CATEGORIES = {
  ai: { fa: 'هوش مصنوعی', en: 'AI', order: 10 },
  productivity: { fa: 'بهره‌وری', en: 'Productivity', order: 20 },
  'developer-tools': { fa: 'ابزار توسعه', en: 'Developer Tools', order: 30 },
  automation: { fa: 'اتوماسیون', en: 'Automation', order: 40 },
  research: { fa: 'تحقیق و پژوهش', en: 'Research', order: 50 },
  'image-video': { fa: 'تصویر و ویدیو', en: 'Image & Video', order: 60 },
  telegram: { fa: 'تلگرام', en: 'Telegram', order: 70 },
  general: { fa: 'عمومی', en: 'General', order: 80 },
} as const

export type DiscoverCategoryKey = keyof typeof DISCOVER_CATEGORIES
export type DiscoverCategoryLocale = 'fa' | 'en'

const DISCOVER_CATEGORY_ALIASES: Record<string, DiscoverCategoryKey> = {
  ai: 'ai',
  AI: 'ai',
  productivity: 'productivity',
  'developer-tools': 'developer-tools',
  automation: 'automation',
  research: 'research',
  'image-video': 'image-video',
  telegram: 'telegram',
  general: 'general',
}

export function getDiscoverCategoryLabel(key: DiscoverCategoryKey, locale: DiscoverCategoryLocale): string {
  return DISCOVER_CATEGORIES[key][locale]
}

export function normalizeDiscoverCategory(value: string): DiscoverCategoryKey {
  const category = DISCOVER_CATEGORY_ALIASES[value]
  if (!category) throw new Error(`Unknown Discover category: ${value}`)
  return category
}
