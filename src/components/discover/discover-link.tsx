'use client'

import type { ReactNode } from 'react'
import Link from 'next/link'
import { trackEvent } from '@/lib/analytics/client'

type DiscoverLinkEventName =
  | 'discover_external_click'
  | 'discover_internal_cta_click'
  | 'discover_telegram_guide_click'
  | 'discover_telegram_channel_click'
  | 'discover_telegram_group_click'

type DiscoverLinkProps = {
  href: string
  children: ReactNode
  className?: string
  external?: boolean
  locale: 'fa' | 'en'
  eventName: DiscoverLinkEventName
  metadata?: Record<string, string | number | boolean>
  ariaLabel?: string
}

export function DiscoverLink({
  href,
  children,
  className,
  external = false,
  locale,
  eventName,
  metadata = {},
  ariaLabel,
}: DiscoverLinkProps) {
  function recordClick() {
    const category = eventName === 'discover_internal_cta_click' ? 'conversion' : 'engagement'
    void trackEvent({
      name: eventName,
      category,
      locale,
      metadata,
    })
  }

  if (external) {
    return (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        className={className}
        onClick={recordClick}
        aria-label={ariaLabel}
      >
        {children}
      </a>
    )
  }

  return (
    <Link href={href} className={className} onClick={recordClick} aria-label={ariaLabel}>
      {children}
    </Link>
  )
}
