import { createHmac } from 'node:crypto'
import { expect, test, type Page } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

const bilingualPath = '/discover/playwright-discover-resource'
const englishBilingualPath = '/en/discover/playwright-discover-resource'
const persianOnlyPath = '/discover/playwright-persian-only-resource'
const englishPersianOnlyPath = '/en/discover/playwright-persian-only-resource'
const adminSessionSecret = 'playwright-admin-session-secret-0000000000000000'

function createDisposableAdminToken() {
  const issuedAt = Math.floor(Date.now() / 1000)
  const payload = {
    sub: 'playwright-admin',
    role: 'admin',
    iat: issuedAt,
    exp: issuedAt + 60 * 60,
  }
  const payloadPart = Buffer.from(JSON.stringify(payload)).toString('base64url')
  const signaturePart = createHmac('sha256', adminSessionSecret).update(payloadPart).digest('base64url')
  return `${payloadPart}.${signaturePart}`
}

async function authenticateAdmin(page: Page) {
  await page.context().addCookies([
    {
      name: 'asdev_admin_session',
      value: createDisposableAdminToken(),
      url: 'http://127.0.0.1:3100',
      httpOnly: true,
      sameSite: 'Strict',
    },
  ])
}

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

test('Persian Discover navigation and canonical localized categories are visible', async ({ page }) => {
  await page.goto('/discover')

  await expect(page.getByRole('link', { name: 'ابزارها و منابع' }).first()).toBeVisible()
  await expect(page.getByRole('button', { name: 'هوش مصنوعی' })).toBeVisible()
  await expect(page.locator('article').filter({ hasText: 'منبع آزمایشی دیسکاور' })).toContainText('هوش مصنوعی')
  await expect(page.getByText('ai', { exact: true })).toHaveCount(0)
})

test('bilingual resource exposes locale-correct content, canonical and reciprocal hreflang', async ({ page }) => {
  await page.goto(bilingualPath)
  await expect(page.locator('h1')).toContainText('منبع آزمایشی دیسکاور')
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="fa-IR"]')).toHaveAttribute('href', /\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="en-US"]')).toHaveAttribute('href', /\/en\/discover\/playwright-discover-resource$/)

  await page.goto(englishBilingualPath)
  await expect(page.locator('h1')).toContainText('Playwright Discover Resource')
  await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', /\/en\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="fa-IR"]')).toHaveAttribute('href', /\/discover\/playwright-discover-resource$/)
  await expect(page.locator('link[rel="alternate"][hreflang="en-US"]')).toHaveAttribute('href', /\/en\/discover\/playwright-discover-resource$/)
})

test('Persian-only resource is excluded from the English landing and detail route', async ({ page }) => {
  await page.goto('/en/discover')
  await expect(page.getByText('Playwright Discover Resource', { exact: true })).toBeVisible()
  await expect(page.getByText('منبع فقط فارسی', { exact: true })).toHaveCount(0)

  const response = await page.goto(englishPersianOnlyPath)
  expect(response?.status()).toBe(404)

  await page.goto(persianOnlyPath)
  await expect(page.locator('h1')).toContainText('منبع فقط فارسی')
})

test('authenticated Discover Admin preserves RTL/LTR semantics and passes serious/critical axe checks', async ({ page }) => {
  await authenticateAdmin(page)
  await page.goto('/admin')
  await page.getByRole('button', { name: 'Discover' }).click()

  const editor = page.getByTestId('discover-editor')
  await expect(editor).toBeVisible()
  await expect(editor).toHaveAttribute('dir', 'rtl')
  await expect(editor.locator('input[pattern="[a-z0-9]+(?:-[a-z0-9]+)*"]')).toHaveAttribute('dir', 'ltr')
  await expect(editor.locator('input[type="url"][required]')).toHaveAttribute('dir', 'ltr')

  const englishSection = editor.locator('section[dir="ltr"]')
  await expect(englishSection).toBeVisible()
  await expect(englishSection.locator('input').first()).toHaveAttribute('dir', 'ltr')
  await expect(englishSection.locator('textarea').first()).toHaveAttribute('dir', 'ltr')

  const adminResults = await new AxeBuilder({ page }).analyze()
  expect(adminResults.violations.filter((violation) => violation.impact === 'critical' || violation.impact === 'serious')).toEqual([])
})

test('Discover landing and detail have no serious or critical axe violations and retain keyboard focus', async ({ page }) => {
  await page.goto('/discover')

  const landingResults = await new AxeBuilder({ page }).analyze()
  expect(landingResults.violations.filter((violation) => violation.impact === 'critical' || violation.impact === 'serious')).toEqual([])

  await tabUntilFocused(page, 'input[type="search"]')
  await expectFocusedInteractiveTarget(page, 'input[type="search"]')
  await tabUntilFocused(page, 'button[aria-pressed="true"]')
  await expectFocusedInteractiveTarget(page, 'button[aria-pressed="true"]')
  await tabUntilFocused(page, `a[href="${bilingualPath}"]`)
  await expectFocusedInteractiveTarget(page, `a[href="${bilingualPath}"]`)

  await page.goto(bilingualPath)
  const detailResults = await new AxeBuilder({ page }).analyze()
  expect(detailResults.violations.filter((violation) => violation.impact === 'critical' || violation.impact === 'serious')).toEqual([])
})
