'use client'

import { useEffect } from 'react'
import { trackEvent } from '@/lib/analytics/client'

type DiscoverTelemetryProps = {
  name: 'discover_landing_view' | 'discover_item_view'
  locale: 'fa' | 'en'
  metadata?: Record<string, string | number | boolean>
}

export function DiscoverTelemetry({ name, locale, metadata = {} }: DiscoverTelemetryProps) {
  const serializedMetadata = JSON.stringify(metadata)

  useEffect(() => {
    void trackEvent({
      name,
      category: 'engagement',
      locale,
      metadata: JSON.parse(serializedMetadata) as Record<string, string | number | boolean>,
    })
  }, [locale, name, serializedMetadata])

  return null
}
