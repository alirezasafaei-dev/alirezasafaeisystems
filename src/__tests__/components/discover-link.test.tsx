import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { DiscoverLink } from '@/components/discover/discover-link'

const { trackEventMock } = vi.hoisted(() => ({
  trackEventMock: vi.fn(),
}))

vi.mock('@/lib/analytics/client', () => ({
  trackEvent: trackEventMock,
}))

describe('DiscoverLink Telegram telemetry', () => {
  beforeEach(() => {
    trackEventMock.mockReset()
    trackEventMock.mockResolvedValue(undefined)
  })

  it('tracks an exact Telegram guide click as engagement and preserves external link semantics', () => {
    render(
      <DiscoverLink
        href="https://t.me/asdev/123"
        external
        locale="fa"
        eventName="discover_telegram_guide_click"
        metadata={{ slug: 'qwen', category: 'AI', target: 'telegram_guide' }}
      >
        آموزش کامل
      </DiscoverLink>,
    )

    const link = screen.getByRole('link', { name: 'آموزش کامل' })
    expect(link).toHaveAttribute('href', 'https://t.me/asdev/123')
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')

    fireEvent.click(link)

    expect(trackEventMock).toHaveBeenCalledWith({
      name: 'discover_telegram_guide_click',
      category: 'engagement',
      locale: 'fa',
      metadata: { slug: 'qwen', category: 'AI', target: 'telegram_guide' },
    })
  })

  it.each([
    'discover_telegram_channel_click',
    'discover_telegram_group_click',
  ] as const)('treats %s as engagement telemetry', (eventName) => {
    render(
      <DiscoverLink
        href="https://t.me/asdev"
        external
        locale="en"
        eventName={eventName}
        metadata={{ slug: 'qwen', category: 'AI', target: eventName }}
      >
        Telegram
      </DiscoverLink>,
    )

    fireEvent.click(screen.getByRole('link', { name: 'Telegram' }))
    expect(trackEventMock).toHaveBeenLastCalledWith(expect.objectContaining({
      name: eventName,
      category: 'engagement',
      locale: 'en',
    }))
  })

  it('does not couple external navigation markup to telemetry success', () => {
    trackEventMock.mockRejectedValueOnce(new Error('telemetry unavailable'))

    render(
      <DiscoverLink
        href="https://t.me/asdev/123"
        external
        locale="fa"
        eventName="discover_telegram_guide_click"
      >
        باز کردن تلگرام
      </DiscoverLink>,
    )

    const link = screen.getByRole('link', { name: 'باز کردن تلگرام' })
    fireEvent.click(link)
    expect(link).toHaveAttribute('href', 'https://t.me/asdev/123')
  })
})
