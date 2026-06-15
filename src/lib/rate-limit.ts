import { env } from '@/lib/env'
import { logger } from '@/lib/logger'

// Rate limiting utility with distributed Redis support (Upstash REST compatible)

interface RateLimitRecord {
  count: number
  resetTime: number
}

const rateLimitStore = new Map<string, RateLimitRecord>()

interface RateLimitOptions {
  windowMs?: number // Time window in milliseconds
  maxRequests?: number // Max requests per window
}

interface RateLimitResult {
  success: boolean
  remaining: number
  resetTime: Date
  limit: number
  windowMs: number
  source: 'memory' | 'redis'
}

interface RedisPipelineItem {
  result?: number | string
  error?: string
}

function hasRedisConfig(): boolean {
  return Boolean(env.REDIS_REST_URL && env.REDIS_REST_TOKEN)
}

async function rateLimitRedis(
  identifier: string,
  options: Required<RateLimitOptions>
): Promise<RateLimitResult | null> {
  if (!env.REDIS_REST_URL || !env.REDIS_REST_TOKEN) {
    return null
  }

  const now = Date.now()
  const ttlSeconds = Math.max(1, Math.ceil(options.windowMs / 1000))
  const bucket = Math.floor(now / options.windowMs)
  const key = `rl:${identifier}:${bucket}`

  try {
    const response = await fetch(`${env.REDIS_REST_URL}/pipeline`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.REDIS_REST_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify([
        ['INCR', key],
        ['EXPIRE', key, ttlSeconds],
        ['TTL', key],
      ]),
    })

    if (!response.ok) {
      logger.warn('Redis rate limit request failed', {
        status: response.status,
        identifier,
      })
      return null
    }

    const data = (await response.json()) as RedisPipelineItem[]
    const count = Number(data?.[0]?.result ?? 0)
    const ttl = Number(data?.[2]?.result ?? ttlSeconds)
    const boundedTtl = Number.isFinite(ttl) && ttl > 0 ? ttl : ttlSeconds
    const remaining = Math.max(0, options.maxRequests - count)

    return {
      success: count <= options.maxRequests,
      remaining,
      resetTime: new Date(now + boundedTtl * 1000),
      limit: options.maxRequests,
      windowMs: options.windowMs,
      source: 'redis',
    }
  } catch (error) {
    logger.warn('Redis rate limit fallback to memory', {
      identifier,
      error: error instanceof Error ? error.message : 'unknown',
    })
    return null
  }
}

function rateLimitMemory(
  identifier: string,
  options: Required<RateLimitOptions>
): RateLimitResult {
  const now = Date.now()
  const record = rateLimitStore.get(identifier)

  if (record && now > record.resetTime) {
    rateLimitStore.delete(identifier)
  }

  const current = rateLimitStore.get(identifier) || { count: 0, resetTime: now + options.windowMs }
  if (current.count >= options.maxRequests) {
    return {
      success: false,
      remaining: 0,
      resetTime: new Date(current.resetTime),
      limit: options.maxRequests,
      windowMs: options.windowMs,
      source: 'memory',
    }
  }

  current.count += 1
  rateLimitStore.set(identifier, current)

  return {
    success: true,
    remaining: Math.max(0, options.maxRequests - current.count),
    resetTime: new Date(current.resetTime),
    limit: options.maxRequests,
    windowMs: options.windowMs,
    source: 'memory',
  }
}

/**
 * Checks if a request should be rate limited
 */
export async function rateLimit(
  identifier: string,
  options: RateLimitOptions = {}
): Promise<RateLimitResult> {
  const normalized: Required<RateLimitOptions> = {
    windowMs: options.windowMs ?? 15 * 60 * 1000,
    maxRequests: options.maxRequests ?? 5,
  }

  if (hasRedisConfig()) {
    const redisResult = await rateLimitRedis(identifier, normalized)
    if (redisResult) {
      return redisResult
    }
  }

  return rateLimitMemory(identifier, normalized)
}

/**
 * Gets rate limit headers for HTTP responses
 */
export function getRateLimitHeaders(
  result: Pick<RateLimitResult, 'limit' | 'remaining' | 'resetTime' | 'windowMs' | 'source'>
): Record<string, string> {
  return {
    'X-RateLimit-Limit': result.limit.toString(),
    'X-RateLimit-Remaining': result.remaining.toString(),
    'X-RateLimit-Reset': result.resetTime.toISOString(),
    'X-RateLimit-Policy': `fixed_window;w=${Math.ceil(result.windowMs / 1000)};r=${result.limit}`,
    'X-RateLimit-Store': result.source,
  }
}

/**
 * Resets the rate limit for a specific identifier (for admin use)
 */
export function resetRateLimit(identifier: string): void {
  rateLimitStore.delete(identifier)
}

/**
 * Gets current rate limit status for an identifier
 */
export function getRateLimitStatus(identifier: string): {
  remaining: number
  resetTime: Date
} | null {
  const record = rateLimitStore.get(identifier)
  if (!record) {
    return null
  }

  return {
    remaining: Math.max(0, 5 - record.count),
    resetTime: new Date(record.resetTime),
  }
}

let cleanupTimer: ReturnType<typeof setInterval> | null = null

function ensureCleanupRunning() {
  if (cleanupTimer !== null) return
  cleanupTimer = setInterval(() => {
    const now = Date.now()
    for (const [key, value] of rateLimitStore.entries()) {
      if (now > value.resetTime) {
        rateLimitStore.delete(key)
      }
    }
    if (rateLimitStore.size === 0 && cleanupTimer !== null) {
      clearInterval(cleanupTimer)
      cleanupTimer = null
    }
  }, 60 * 1000)
}

ensureCleanupRunning()
