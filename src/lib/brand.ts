import { env } from '@/lib/env'

const DEFAULT_HANDLE = 'alirezasafaeisystems'
const DEFAULT_GITHUB_URL = 'https://github.com/parsairaniiidev/asdev-portfolio'
const DEFAULT_LINKEDIN_URL = `https://linkedin.com/in/${DEFAULT_HANDLE}`
const DEFAULT_TELEGRAM_URL = `https://t.me/asdevsystems`
const DEFAULT_INSTAGRAM_URL = `https://www.instagram.com/${DEFAULT_HANDLE}`
const DEFAULT_WHATSAPP_URL = 'https://wa.me/message/ANXJHRC3RKRSL1'
const DEFAULT_CONTACT_EMAIL = 'alirezasafaeisystems@gmail.com'
const DEFAULT_CONTACT_PHONE = '+9890001602030'
const DEFAULT_POSITIONING_EN =
  'ASDEV | Alireza Safaei — Production-Grade Web Systems Engineer | Architecture • Scalability • Reliability'
const DEFAULT_POSITIONING_FA =
  'ASDEV | علیرضا صفایی — مهندس سیستم‌های وب Production-Grade | معماری • مقیاس‌پذیری • پایداری'

export const brand = {
  ownerName: env.NEXT_PUBLIC_OWNER_NAME || 'Alireza Safaei',
  brandName: env.NEXT_PUBLIC_BRAND_NAME || 'ASDEV',
  twitterHandle: env.NEXT_PUBLIC_TWITTER_HANDLE || undefined,
  githubUrl: env.NEXT_PUBLIC_GITHUB_URL || DEFAULT_GITHUB_URL,
  linkedinUrl: env.NEXT_PUBLIC_LINKEDIN_URL || DEFAULT_LINKEDIN_URL,
  telegramUrl: env.NEXT_PUBLIC_TELEGRAM_URL || DEFAULT_TELEGRAM_URL,
  instagramUrl: env.NEXT_PUBLIC_INSTAGRAM_URL || DEFAULT_INSTAGRAM_URL,
  whatsappUrl: env.NEXT_PUBLIC_WHATSAPP_URL || DEFAULT_WHATSAPP_URL,
  twitterUrl: env.NEXT_PUBLIC_TWITTER_URL || '',
  contactEmail: env.NEXT_PUBLIC_CONTACT_EMAIL || DEFAULT_CONTACT_EMAIL,
  contactPhone: env.NEXT_PUBLIC_CONTACT_PHONE || DEFAULT_CONTACT_PHONE,
  googleVerificationCode: env.NEXT_PUBLIC_GOOGLE_VERIFICATION_CODE || undefined,
  positioningEn: env.NEXT_PUBLIC_POSITIONING_EN || DEFAULT_POSITIONING_EN,
  positioningFa: env.NEXT_PUBLIC_POSITIONING_FA || DEFAULT_POSITIONING_FA,
} as const
