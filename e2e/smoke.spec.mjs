import { test, expect } from '@playwright/test'

test.describe('smoke', () => {
  test.beforeEach(async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 })
  })

  test('skip link is keyboard reachable and targets main content', async ({ page }) => {
    await page.goto('/')
    await page.keyboard.press('Tab')

    const focusedHref = await page.evaluate(() => {
      const active = document.activeElement
      return active instanceof HTMLAnchorElement ? active.getAttribute('href') : null
    })
    expect(focusedHref).toBe('#main-content')

    await page.keyboard.press('Enter')
    await expect(page).toHaveURL(/#main-content$/)
  })

  test('home page renders key sections', async ({ page }) => {
    await page.goto('/')
    await expect(page.locator('main')).toBeVisible()
    await expect(page.locator('section#services')).toBeVisible()
    await expect(page.locator('a[href="/services/infrastructure-localization"]')).toBeVisible()
    await expect(page.locator('section#contact')).toBeVisible()
  })

  test('language switch sets english direction', async ({ page }) => {
    await page.goto('/en/services')
    await expect.poll(async () => page.evaluate(() => document.documentElement.dir)).toBe('ltr')
    await expect(page.locator('h1')).toContainText('Services')
  })

  test('Discover keeps English locale and presents the Resource Hub contract', async ({ page }) => {
    await page.goto('/en/discover')
    await expect.poll(async () => page.evaluate(() => document.documentElement.lang)).toBe('en')
    await expect.poll(async () => page.evaluate(() => document.documentElement.dir)).toBe('ltr')
    await expect(page.locator('h1')).toContainText('Find the tools and resources I mention on Instagram')
    await expect(page.getByText('Search a name, open its real official destination, read the quick guide, and use the full Telegram resource when one is available.')).toBeVisible()
    await expect(page.getByText('Use this page as the single link in my Instagram bio; no DM automation is required.')).toBeVisible()
  })

  test('Discover resource detail preserves the exact Telegram guide link without campaign leakage', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 })
    await page.goto('/discover/playwright-discover-resource?utm_source=instagram&utm_medium=social&utm_campaign=playwright&utm_content=reel-test')

    await expect(page.locator('h1')).toContainText('Playwright Discover Resource')
    await expect(page.getByText('This quick guide is seeded only for disposable browser testing.')).toBeVisible()

    const official = page.locator('a[href="https://example.com/tool"]')
    const telegramGuide = page.locator('a[href="https://t.me/asdev_test/123"]')
    await expect(official).toBeVisible()
    await expect(telegramGuide).toBeVisible()
    await expect(telegramGuide).toHaveAttribute('href', 'https://t.me/asdev_test/123')
    await expect(telegramGuide).toHaveAttribute('target', '_blank')
    await expect(telegramGuide).toHaveAttribute('rel', 'noopener noreferrer')

    expect(new URL(await telegramGuide.getAttribute('href')).search).toBe('')
  })

  test('theme toggle button is removed from header', async ({ page }) => {
    await page.goto('/')
    await expect(page.locator('header button[aria-label="Toggle theme"]')).toHaveCount(0)
  })

  test('profile page loads in mobile viewport with brand links', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 })
    await page.goto('/profile')
    await expect(page.locator('h1')).toContainText('علیرضا صفایی')
    await expect(page.getByRole('heading', { name: /پورتفولیو و راه‌های ارتباطی/ })).toBeVisible()
    await expect(page.getByRole('heading', { name: /PersianToolbox — ابزارهای فارسی/ })).toBeVisible()
    await expect(page.getByRole('heading', { name: /Audit IR — بررسی فنی و امنیتی/ })).toBeVisible()
    expect(await page.locator('a[href*="utm_campaign=alireza_safaei_network"]').count()).toBeGreaterThanOrEqual(3)
  })

  test('standards page is available and keeps network links', async ({ page }) => {
    await page.goto('/standards')
    await expect(page.locator('h1')).toContainText('استانداردهای تحویل')
    expect(await page.locator('a[href*="utm_campaign=alireza_safaei_network"]').count()).toBeGreaterThanOrEqual(3)
  })

  test('admin route redirects unauthenticated users to login', async ({ page }) => {
    await page.goto('/admin')
    await expect(page).toHaveURL(/\/admin\/login/)
    await expect(page.locator('text=Admin Login')).toBeVisible()
  })

  test('qualification form submits and redirects to thank-you', async ({ page }) => {
    await page.route('**/api/leads', async (route) => {
      await route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, message: 'Lead registered successfully' }),
      })
    })

    await page.goto('/qualification')

    await page.locator('#contactName').fill('Ali Safaei')
    await page.locator('#organizationName').fill('Industrial Co')
    await page.locator('#email').fill('lead-e2e@example.com')
    await page.locator('#phone').fill('09120000000')
    await page.getByRole('button', { name: 'مرحله بعد: مشکل فعلی' }).click()

    await page.locator('#teamSize').selectOption('1-5')
    await page.locator('#timeline').selectOption('this_week')
    await page.locator('#currentStack').fill('https://example.com')
    await page.locator('#criticalRisk').fill('Deployment governance is missing and rollback drills are not practiced.')
    await page.locator('#notes').fill('Please contact by email.')

    await page.getByRole('button', { name: /درخواست بررسی \+ رفع سریع/ }).click()
    await expect(page).toHaveURL(/\/(?:fa\/)?thank-you\?source=lead/)
    await expect(page.locator('h1')).toContainText(/Thanks\. Your request is in\.|ممنون\. درخواست شما ثبت شد\./)
  })
})
