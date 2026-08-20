import { describe, expect, it } from 'vitest'
import { isExpectedNextPrefetchAbort } from '../../scripts/deploy/live-verify-request-failure.mjs'

describe('live verification request failure classification', () => {
  it('ignores only aborted Next.js RSC prefetch GET requests', () => {
    expect(isExpectedNextPrefetchAbort({
      method: 'GET',
      url: 'https://alirezasafaeisystems.ir/discover?_rsc=abc123',
      errorText: 'net::ERR_ABORTED',
    })).toBe(true)

    expect(isExpectedNextPrefetchAbort({
      method: 'GET',
      url: 'https://alirezasafaeisystems.ir/discover',
      errorText: 'net::ERR_ABORTED',
    })).toBe(false)

    expect(isExpectedNextPrefetchAbort({
      method: 'POST',
      url: 'https://alirezasafaeisystems.ir/api/analytics/events?_rsc=abc123',
      errorText: 'net::ERR_ABORTED',
    })).toBe(false)

    expect(isExpectedNextPrefetchAbort({
      method: 'GET',
      url: 'https://alirezasafaeisystems.ir/discover?_rsc=abc123',
      errorText: 'net::ERR_FAILED',
    })).toBe(false)
  })
})
