import { expect, test, type Page } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

const resourcePath = '/discover/playwright-discover-resource'

async function tabUntilFocused(page: Page, selector: string) {
  for (let attempt = 0; attempt < 30; attempt += 1) {
    await page.keyboard.press('Tab')
    const target = page.locator(selector)
    if (await target.evaluate((element) => document.activeElement === element)) {
      await expect(target).toBeFocused()
      return
    }
  }

  await expect(page.locator(selector)).toBeFocused()
}

async function expectFocusedInteractiveTarget(page: Page, selector: string) {
  const target = page.locator(selector)
  await expect(target).toBeFocused()
  await expect(target).toBeVisible()
  await expect.poll(() => page.evaluate(() => document.activeElement?.tagName)).toMatch(/^(A|BUTTON|INPUT)$/)
}

test('Persian Discover navigation and the known disposable fixture category are visible', async ({ page }) => {
  await page.goto('/discover')

  await expect(page.getByRole('link', { name: 'ابزارها و منابع' }).first()).toBeVisible()
  await expect(page.getByRole('button', { name: 'Testing' })).toBeVisible()
  await expect(page.locator('article').filter({ hasText: 'Playwright Discover Resource' })).toContainText('Testing')
  await expect(page.getByText('general', { exact: true })).toHaveCount(0)
})

test('Persian fixture detail exposes the current locale alternate metadata', async ({ page }) => {
  await page.goto(resourcePath)

  await expect(page.locator('h1')).toContainText('Playwright Discover Resource')
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="fa-IR"]')).toHaveAttribute('href', /\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="en-US"]')).toHaveAttribute('href', /\/en\/discover\/playwright-discover-resource$/)
})

test('Discover landing and detail have no serious or critical axe violations and retain keyboard focus', async ({ page }) => {
  await page.goto('/discover')

  const landingResults = await new AxeBuilder({ page }).analyze()
  expect(landingResults.violations.filter((violation) => violation.impact === 'critical' || violation.impact === 'serious')).toEqual([])

  await tabUntilFocused(page, 'input[type="search"]')
  await expectFocusedInteractiveTarget(page, 'input[type="search"]')
  await tabUntilFocused(page, 'button[aria-pressed="true"]')
  await expectFocusedInteractiveTarget(page, 'button[aria-pressed="true"]')
  await tabUntilFocused(page, `a[href="${resourcePath}"]`)
  await expectFocusedInteractiveTarget(page, `a[href="${resourcePath}"]`)

  await page.goto(resourcePath)
  const detailResults = await new AxeBuilder({ page }).analyze()
  expect(detailResults.violations.filter((violation) => violation.impact === 'critical' || violation.impact === 'serious')).toEqual([])
})
