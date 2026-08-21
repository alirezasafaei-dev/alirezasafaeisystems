import type { Language } from '@/lib/i18n/translations'

export const DISCOVER_CONCURRENCY_COPY: Record<Language, {
  conflict: string
  reloadLatest: string
  reloadFailed: string
}> = {
  fa: {
    conflict: 'نسخه جدیدتری از این آیتم روی سرور ذخیره شده است. ویرایش محلی شما حفظ شده؛ قبل از ذخیره دوباره نسخه جدید سرور را بارگذاری و تغییرات را تطبیق دهید.',
    reloadLatest: 'بارگذاری نسخه جدید سرور',
    reloadFailed: 'بارگذاری نسخه جدید سرور ناموفق بود.',
  },
  en: {
    conflict: 'A newer version of this item was saved on the server. Your local edit is preserved; reload the latest server version and reconcile changes before saving again.',
    reloadLatest: 'Reload latest server version',
    reloadFailed: 'Could not load the latest server version.',
  },
}
