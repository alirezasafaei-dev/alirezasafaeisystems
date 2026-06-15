import { logger } from '@/lib/logger'

export function registerServiceWorker() {
  if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker
        .register('/sw.js')
        .then((registration) => {
          logger.info('Service Worker registered', { scope: registration.scope })

          // Check for updates
          registration.addEventListener('updatefound', () => {
            const newWorker = registration.installing
            if (newWorker) {
              newWorker.addEventListener('statechange', () => {
                if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                  window.location.reload()
                }
              })
            }
          })
        })
        .catch((error) => {
          logger.error('Service Worker registration failed', {
            error: error instanceof Error ? error.message : 'unknown',
          })
        })
    })
  }
}

export function unregisterServiceWorker() {
  if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
    navigator.serviceWorker.ready
      .then((registration) => {
        registration.unregister()
      })
      .catch((error) => {
        logger.error('Service Worker unregistration failed', {
          error: error instanceof Error ? error.message : 'unknown',
        })
      })
  }
}
