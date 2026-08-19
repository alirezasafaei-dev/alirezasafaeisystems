import { describe, expect, it } from 'vitest'
import { optionalTelegramUrlSchema, telegramUrlSchema } from '@/lib/telegram'

describe('Telegram public URL contract', () => {
  it('accepts only credential-free HTTPS t.me URLs', () => {
    expect(telegramUrlSchema.parse('https://t.me/asdev/123')).toBe('https://t.me/asdev/123')
    expect(telegramUrlSchema.safeParse('http://t.me/asdev/123').success).toBe(false)
    expect(telegramUrlSchema.safeParse('https://telegram.me/asdev/123').success).toBe(false)
    expect(telegramUrlSchema.safeParse('https://user:pass@t.me/asdev/123').success).toBe(false)
    expect(telegramUrlSchema.safeParse('https://example.com/asdev/123').success).toBe(false)
  })

  it('normalizes blank optional values to null', () => {
    expect(optionalTelegramUrlSchema.parse('')).toBeNull()
    expect(optionalTelegramUrlSchema.parse(undefined)).toBeUndefined()
  })
})
