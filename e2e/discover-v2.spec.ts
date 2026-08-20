import { expect, test, type Page } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

const resourcePath = '/discover/playwright-discover-resource'

async function tabUntilFocused(page: Page, selector: string) {
  for (let attempt = 0; attempt < 30; attempt += 1) {
    await page.keyboard.press('Tab')
    if (await page.locator(selector).evaluate((element) => document.activeElement === element)) return
  }

  await expect(page.locator(selector)).toBeFocused()
}

test('Persian Discover navigation and category labels are localized without raw category values', async ({ page }) => {
  await page.goto('/discover')

  await expect(page.getByRole('link', { name: 'ابزارها و منابع' }).first()).toBeVisible()
  await expect(page.getByRole('button', { name: 'عمومی' })).toBeVisible()
  await expect(page.locator('article').filter({ hasText: 'Playwright Discover Resource' })).toContainText('عمومی')
  await expect(page.getByText('Testing', { exact: true })).toHaveCount(0)
  await expect(page.getByText('general', { exact: true })).toHaveCount(0)
})

test('English-unpublished fixture is unavailable while Persian detail retains locale SEO', async ({ page }) => {
  await page.goto(resourcePath)

  await expect(page.locator('h1')).toContainText('Playwright Discover Resource')
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="fa-IR"]')).toHaveAttribute('href', /\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="en-US"]')).toHaveCount(0)

  const englishResponse = await page.goto(`/en${resourcePath}`)
  expect(englishResponse?.status()).toBe(404)
})

test('Discover landing and detail have no serious or critical axe violations and retain keyboard focus', async ({ page }) => {
  await page.goto('/discover')

  const landingResults = await new AxeBuilder({ page }).analyze()
  expect(landingResults.violations.filter((violation) => violation.impact === 'critical' || violation.impact === 'serious')).toEqual([])

  await tabUntilFocused(page, 'input[type="search"]')
  await tabUntilFocused(page, 'button[aria-pressed="true"]')
  await tabUntilFocused(page, `a[href="${resourcePath}"]`)

  await page.goto(resourcePath)
  const detailResults = await new AxeBuilder({ page }).analyze()
  expect(detailResults.violations.filter((violation) => violation.impact === 'critical' || violation.impact === 'serious')).toEqual([])
})
