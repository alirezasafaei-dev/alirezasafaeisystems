import { describe, expect, it } from 'vitest'
import {
  bucketToHeroVariant,
  normalizeBucket,
  pickDeterministicBucket,
  pickHeroVariant,
} from '@/lib/analytics/experiments'

describe('analytics experiments', () => {
  it('normalizes bucket values safely', () => {
    expect(normalizeBucket(-5)).toBe(0)
    expect(normalizeBucket(120)).toBe(99)
    expect(normalizeBucket(22.7)).toBe(22)
  })

  it('maps bucket to stable hero variant', () => {
    expect(bucketToHeroVariant(0)).toBe('authority')
    expect(bucketToHeroVariant(49)).toBe('authority')
    expect(bucketToHeroVariant(50)).toBe('risk')
    expect(bucketToHeroVariant(99)).toBe('risk')
  })

  it('picks deterministic bucket and variant from seed', () => {
    const seed = 'alireza-fixed-seed'
    expect(pickDeterministicBucket(seed)).toBe(pickDeterministicBucket(seed))
    expect(pickHeroVariant(seed)).toMatch(/authority|risk/)
  })
})
