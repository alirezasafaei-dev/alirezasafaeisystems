import { test, expect } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

const PAGES = [
  { name: 'Home', path: '/fa/' },
  { name: 'Services', path: '/fa/services' },
  { name: 'Case Studies', path: '/fa/case-studies' },
  { name: 'Qualification', path: '/fa/qualification' },
  { name: 'About Brand', path: '/fa/about-brand' },
  { name: 'Profile', path: '/fa/profile' },
  { name: 'Standards', path: '/fa/standards' },
  { name: 'Infrastructure Localization', path: '/fa/services/infrastructure-localization' },
  { name: 'Quick Fix Sprint', path: '/fa/services/quick-fix-sprint' },
]

for (const { name, path } of PAGES) {
  test(`${name} (${path}) has no critical accessibility violations`, async ({ page }) => {
    await page.goto(path)
    await page.waitForLoadState('networkidle')
    const results = await new AxeBuilder({ page }).analyze()
    const criticalViolations = results.violations.filter((v) => v.impact === 'critical')
    const seriousViolations = results.violations.filter((v) => v.impact === 'serious')

    if (criticalViolations.length > 0) {
      console.error(`Critical a11y violations on ${name}:`, criticalViolations.map((v) => ({
        id: v.id,
        description: v.description,
        nodes: v.nodes.length,
        help: v.help,
      })))
    }
    expect(criticalViolations).toEqual([])

    if (seriousViolations.length > 0) {
      console.warn(`Serious a11y violations on ${name}:`, seriousViolations.map((v) => ({
        id: v.id,
        description: v.description,
        nodes: v.nodes.length,
      })))
    }
  })
}

test('home page has proper heading hierarchy', async ({ page }) => {
  await page.goto('/fa/')
  await page.waitForLoadState('networkidle')

  const h1 = await page.locator('h1').count()
  expect(h1).toBe(1)

  const headings = await page.locator('h1, h2, h3').allTextContents()
  expect(headings.length).toBeGreaterThan(0)
})

test('home page has skip-to-content link', async ({ page }) => {
  await page.goto('/fa/')
  const skipLink = page.locator('a[href="#main-content"]')
  await expect(skipLink).toBeAttached()
})

test('home page has lang attribute', async ({ page }) => {
  await page.goto('/fa/')
  const lang = await page.locator('html').getAttribute('lang')
  expect(lang).toBe('fa')
})

test('home page has dir attribute for RTL', async ({ page }) => {
  await page.goto('/fa/')
  const dir = await page.locator('html').getAttribute('dir')
  expect(dir).toBe('rtl')
})

test('contact form has proper labels', async ({ page }) => {
  await page.goto('/fa/')
  await page.waitForLoadState('networkidle')

  const nameInput = page.locator('input[name="name"]')
  const nameLabel = page.locator('label[for="name"]')
  await expect(nameLabel).toBeAttached()
  await expect(nameInput).toHaveAttribute('required')

  const emailInput = page.locator('input[name="email"]')
  const emailLabel = page.locator('label[for="email"]')
  await expect(emailLabel).toBeAttached()
  await expect(emailInput).toHaveAttribute('required')

  const messageInput = page.locator('textarea[name="message"]')
  const messageLabel = page.locator('label[for="message"]')
  await expect(messageLabel).toBeAttached()
  await expect(messageInput).toHaveAttribute('required')
})

test('navigation has aria-current on active page', async ({ page }) => {
  await page.goto('/fa/services')
  await page.waitForLoadState('networkidle')

  const activeLink = page.locator('a[aria-current="page"]')
  const count = await activeLink.count()
  expect(count).toBeGreaterThanOrEqual(1)
})
