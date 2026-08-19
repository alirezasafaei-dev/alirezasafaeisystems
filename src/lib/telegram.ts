import { z } from 'zod'

export const telegramUrlSchema = z
  .string()
  .trim()
  .min(1)
  .max(2000)
  .refine((value) => {
    try {
      const url = new URL(value)
      return url.protocol === 'https:' && !url.username && !url.password && url.hostname.toLowerCase() === 't.me'
    } catch {
      return false
    }
  }, 'Telegram URL must use a credential-free https://t.me/ URL')

export const optionalTelegramUrlSchema = z
  .union([z.literal(''), telegramUrlSchema])
  .optional()
  .transform((value) => (value === '' ? null : value))
