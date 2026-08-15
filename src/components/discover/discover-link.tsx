'use client'

import type { ReactNode } from 'react'
import Link from 'next/link'
import { trackEvent } from '@/lib/analytics/client'

type DiscoverLinkProps = {
  href: string
  children: ReactNode
  className?: string
  external?: boolean
  locale: 'fa' | 'en'
  eventName: 'discover_external_click' | 'discover_internal_cta_click'
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
    void trackEvent({
      name: eventName,
      category: eventName === 'discover_internal_cta_click' ? 'conversion' : 'engagement',
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
