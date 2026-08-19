import { describe, expect, it } from 'vitest'
import { parseEnv } from '@/lib/env'

describe('env', () => {
  it('uses defaults when optional vars are not provided', () => {
    const parsed = parseEnv({
      NODE_ENV: undefined,
      NEXT_PUBLIC_SITE_URL: undefined,
      NEXT_PUBLIC_ENABLE_ANALYTICS: undefined,
      NEXT_PUBLIC_ENABLE_WEB_VITALS: undefined,
      NEXT_PUBLIC_FONT_CDN_ENABLED: undefined,
      NEXT_PUBLIC_FONT_CDN_URL: undefined,
      ADMIN_API_TOKEN: undefined,
      ADMIN_USERNAME: undefined,
      ADMIN_PASSWORD: undefined,
      ADMIN_SESSION_SECRET: undefined,
      ADMIN_SESSION_MAX_AGE_SECONDS: undefined,
      REDIS_REST_URL: undefined,
      REDIS_REST_TOKEN: undefined,
      API_RATE_LIMIT_WINDOW_MS: undefined,
      API_RATE_LIMIT_MAX_REQUESTS: undefined,
    })

    expect(parsed.NODE_ENV).toBe('development')
    expect(parsed.NEXT_PUBLIC_ENABLE_ANALYTICS).toBe('false')
    expect(parsed.NEXT_PUBLIC_ENABLE_WEB_VITALS).toBe('false')
    expect(parsed.NEXT_PUBLIC_FONT_CDN_ENABLED).toBe('false')
    expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL).toBeUndefined()
    expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL).toBeUndefined()
    expect(parsed.ADMIN_SESSION_MAX_AGE_SECONDS).toBe(60 * 60 * 8)
    expect(parsed.API_RATE_LIMIT_WINDOW_MS).toBe(15 * 60 * 1000)
    expect(parsed.API_RATE_LIMIT_MAX_REQUESTS).toBe(5)
  })

  it('parses custom numeric limits', () => {
    const parsed = parseEnv({
      NODE_ENV: 'production',
      NEXT_PUBLIC_SITE_URL: 'https://example.com',
      NEXT_PUBLIC_ENABLE_ANALYTICS: 'true',
      NEXT_PUBLIC_ENABLE_WEB_VITALS: 'true',
      NEXT_PUBLIC_FONT_CDN_ENABLED: 'true',
      NEXT_PUBLIC_FONT_CDN_URL: 'https://assets.example.com/fonts/persian.css',
      ADMIN_API_TOKEN: 'abcdefghijklmnopqrstuvwxyz',
      ADMIN_USERNAME: 'admin',
      ADMIN_PASSWORD: 'supersecurepassword',
      ADMIN_SESSION_SECRET: 'very-secure-session-secret-with-32-plus',
      ADMIN_SESSION_MAX_AGE_SECONDS: '1800',
      REDIS_REST_URL: 'https://redis.example.com',
      REDIS_REST_TOKEN: 'redis-secret-token',
      API_RATE_LIMIT_WINDOW_MS: '60000',
      API_RATE_LIMIT_MAX_REQUESTS: '12',
    })

    expect(parsed.NODE_ENV).toBe('production')
    expect(parsed.NEXT_PUBLIC_SITE_URL).toBe('https://example.com')
    expect(parsed.NEXT_PUBLIC_ENABLE_ANALYTICS).toBe('true')
    expect(parsed.NEXT_PUBLIC_ENABLE_WEB_VITALS).toBe('true')
    expect(parsed.NEXT_PUBLIC_FONT_CDN_ENABLED).toBe('true')
    expect(parsed.NEXT_PUBLIC_FONT_CDN_URL).toBe('https://assets.example.com/fonts/persian.css')
    expect(parsed.ADMIN_SESSION_MAX_AGE_SECONDS).toBe(1800)
    expect(parsed.REDIS_REST_URL).toBe('https://redis.example.com')
    expect(parsed.API_RATE_LIMIT_WINDOW_MS).toBe(60000)
    expect(parsed.API_RATE_LIMIT_MAX_REQUESTS).toBe(12)
  })

  it('accepts canonical Discover Telegram channel and group URLs', () => {
    const parsed = parseEnv({
      NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: 'https://t.me/asdev',
      NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL: 'https://t.me/asdev_chat',
    })

    expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL).toBe('https://t.me/asdev')
    expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL).toBe('https://t.me/asdev_chat')
  })

  it('treats blank Discover Telegram configuration as absent', () => {
    const parsed = parseEnv({
      NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: '',
      NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL: '   ',
    })

    expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL).toBeUndefined()
    expect(parsed.NEXT_PUBLIC_DISCOVER_TELEGRAM_GROUP_URL).toBeUndefined()
  })

  it('rejects non-t.me Discover Telegram destinations', () => {
    expect(() => parseEnv({
      NEXT_PUBLIC_DISCOVER_TELEGRAM_CHANNEL_URL: 'https://telegram.me/asdev',
    })).toThrow()
  })
})
