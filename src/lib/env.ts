import { z } from 'zod'
import { telegramUrlSchema } from '@/lib/telegram'

const optionalTelegramEnvUrlSchema = z.preprocess(
  (value) => typeof value === 'string' && value.trim() === '' ? undefined : value,
  telegramUrlSchema.optional(),
)

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  NEXT_PUBLIC_SITE_URL: z.string().url().optional(),
  NEXT_PUBLIC_BRAND_NAME: z.string().min(2).optional(),
  NEXT_PUBLIC_OWNER_NAME: z.string().min(2).optional(),
  NEXT_PUBLIC_TWITTER_HANDLE: z.string().regex(/^@[\w_]{1,15}$/).optional(),
  NEXT_PUBLIC_GITHUB_URL: z.string().url().optional(),
  NEXT_PUBLIC_LINKEDIN_URL: z.string().url().optional(),
  NEXT_PUBLIC_TELEGRAM_URL: z.string().url().optional(),
  NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: optionalTelegramEnvUrlSchema,
  NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL: optionalTelegramEnvUrlSchema,
  NEXT_PUBLIC_INSTAGRAM_URL: z.string().url().optional(),
  NEXT_PUBLIC_WHATSAPP_URL: z.string().url().optional(),
  NEXT_PUBLIC_TWITTER_URL: z.string().url().optional(),
  NEXT_PUBLIC_CONTACT_EMAIL: z.string().email().optional(),
  NEXT_PUBLIC_CONTACT_PHONE: z.string().min(7).optional(),
  NEXT_PUBLIC_GOOGLE_VERIFICATION_CODE: z.string().min(6).optional(),
  NEXT_PUBLIC_ENABLE_ANALYTICS: z.enum(['true', 'false']).default('false'),
  NEXT_PUBLIC_ENABLE_WEB_VITALS: z.enum(['true', 'false']).default('false'),
  NEXT_PUBLIC_FONT_CDN_ENABLED: z.enum(['true', 'false']).default('false'),
  NEXT_PUBLIC_FONT_CDN_URL: z.string().url().optional(),
  NEXT_PUBLIC_POSITIONING_EN: z.string().min(10).optional(),
  NEXT_PUBLIC_POSITIONING_FA: z.string().min(10).optional(),
  ADMIN_API_TOKEN: z.string().min(16).optional(),
  ADMIN_USERNAME: z.string().min(3).optional(),
  ADMIN_PASSWORD: z.string().min(8).optional(),
  ADMIN_SESSION_SECRET: z.string().min(32).optional(),
  ADMIN_SESSION_MAX_AGE_SECONDS: z.coerce.number().int().positive().default(60 * 60 * 8),
  REDIS_REST_URL: z.string().url().optional(),
  REDIS_REST_TOKEN: z.string().min(8).optional(),
  LEAD_NOTIFICATION_WEBHOOK_URL: z.string().url().optional(),
  API_RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(15 * 60 * 1000),
  API_RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(5),
})

export type AppEnv = z.infer<typeof envSchema>

export function parseEnv(input: Record<string, string | undefined>): AppEnv {
  return envSchema.parse(input)
}

const parsed = parseEnv({
  NODE_ENV: process.env.NODE_ENV,
  NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
  NEXT_PUBLIC_BRAND_NAME: process.env.NEXT_PUBLIC_BRAND_NAME,
  NEXT_PUBLIC_OWNER_NAME: process.env.NEXT_PUBLIC_OWNER_NAME,
  NEXT_PUBLIC_TWITTER_HANDLE: process.env.NEXT_PUBLIC_TWITTER_HANDLE,
  NEXT_PUBLIC_GITHUB_URL: process.env.NEXT_PUBLIC_GITHUB_URL,
  NEXT_PUBLIC_LINKEDIN_URL: process.env.NEXT_PUBLIC_LINKEDIN_URL,
  NEXT_PUBLIC_TELEGRAM_URL: process.env.NEXT_PUBLIC_TELEGRAM_URL,
  NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: process.env.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL,
  NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL: process.env.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL,
  NEXT_PUBLIC_INSTAGRAM_URL: process.env.NEXT_PUBLIC_INSTAGRAM_URL,
  NEXT_PUBLIC_WHATSAPP_URL: process.env.NEXT_PUBLIC_WHATSAPP_URL,
  NEXT_PUBLIC_TWITTER_URL: process.env.NEXT_PUBLIC_TWITTER_URL,
  NEXT_PUBLIC_CONTACT_EMAIL: process.env.NEXT_PUBLIC_CONTACT_EMAIL,
  NEXT_PUBLIC_CONTACT_PHONE: process.env.NEXT_PUBLIC_CONTACT_PHONE,
  NEXT_PUBLIC_GOOGLE_VERIFICATION_CODE: process.env.NEXT_PUBLIC_GOOGLE_VERIFICATION_CODE,
  NEXT_PUBLIC_ENABLE_ANALYTICS: process.env.NEXT_PUBLIC_ENABLE_ANALYTICS,
  NEXT_PUBLIC_ENABLE_WEB_VITALS: process.env.NEXT_PUBLIC_ENABLE_WEB_VITALS,
  NEXT_PUBLIC_FONT_CDN_ENABLED: process.env.NEXT_PUBLIC_FONT_CDN_ENABLED,
  NEXT_PUBLIC_FONT_CDN_URL: process.env.NEXT_PUBLIC_FONT_CDN_URL,
  NEXT_PUBLIC_POSITIONING_EN: process.env.NEXT_PUBLIC_POSITIONING_EN,
  NEXT_PUBLIC_POSITIONING_FA: process.env.NEXT_PUBLIC_POSITIONING_FA,
  ADMIN_API_TOKEN: process.env.ADMIN_API_TOKEN,
  ADMIN_USERNAME: process.env.ADMIN_USERNAME,
  ADMIN_PASSWORD: process.env.ADMIN_PASSWORD,
  ADMIN_SESSION_SECRET: process.env.ADMIN_SESSION_SECRET,
  ADMIN_SESSION_MAX_AGE_SECONDS: process.env.ADMIN_SESSION_MAX_AGE_SECONDS,
  REDIS_REST_URL: process.env.REDIS_REST_URL,
  REDIS_REST_TOKEN: process.env.REDIS_REST_TOKEN,
  LEAD_NOTIFICATION_WEBHOOK_URL: process.env.LEAD_NOTIFICATION_WEBHOOK_URL,
  API_RATE_LIMIT_WINDOW_MS: process.env.API_RATE_LIMIT_WINDOW_MS,
  API_RATE_LIMIT_MAX_REQUESTS: process.env.API_RATE_LIMIT_MAX_REQUESTS,
})

export const env = parsed
