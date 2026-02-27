import { test, expect } from '@playwright/test'

const scenarios = [
  {
    id: 'sections-hero--default',
    slug: 'hero',
  },
  {
    id: 'sections-contact--default',
    slug: 'contact',
  },
  {
    id: 'layout-footer--default',
    slug: 'footer',
  },
] as const

const locales = ['fa', 'en'] as const

for (const scenario of scenarios) {
  for (const locale of locales) {
    test(`${scenario.slug} visual regression (${locale})`, async ({ page }) => {
      await page.goto(
        `/iframe.html?id=${scenario.id}&viewMode=story&globals=locale:${locale};theme:light`,
        { waitUntil: 'networkidle' },
      )

      await page.addStyleTag({
        content: `
          *, *::before, *::after {
            animation-duration: 0s !important;
            animation-delay: 0s !important;
            transition: none !important;
          }
        `,
      })

      await expect(page).toHaveScreenshot(`${scenario.slug}-${locale}-light.png`, {
        fullPage: true,
      })
    })
  }
}
