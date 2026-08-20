import { expect, test } from '@playwright/test'

test.describe('smoke', () => {
  test('homepage loads with primary sections', async ({ page }) => {
    await page.goto('/')
    await expect(page.locator('main')).toBeVisible()
    await expect(page.locator('h1')).toBeVisible()
  })

  test('services page loads', async ({ page }) => {
    await page.goto('/services')
    await expect(page.locator('main')).toBeVisible()
  })

  test('case studies page loads', async ({ page }) => {
    await page.goto('/case-studies')
    await expect(page.locator('main')).toBeVisible()
  })

  test('Discover loads as the Persian Resource Hub', async ({ page }) => {
    await page.goto('/discover')
    await expect.poll(async () => page.evaluate(() => document.documentElement.lang)).toBe('fa')
    await expect.poll(async () => page.evaluate(() => document.documentElement.dir)).toBe('rtl')
    await expect(page.locator('h1')).toContainText('ابزارها و منابعی که در اینستاگرام معرفی می‌کنم، اینجا پیدا کن')
    await expect(page.getByText('اسم ابزار را جستجو کن، به مقصد رسمی برو، راهنمای کوتاه را بخوان و اگر منبع کامل تلگرام موجود بود مستقیم همان را باز کن.')).toBeVisible()
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

    await expect(page.locator('h1')).toContainText('منبع آزمایشی دیسکاور')
    await expect(page.getByText('این راهنمای کوتاه فقط داخل پایگاه داده موقت Playwright ساخته می‌شود.')).toBeVisible()

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
    await expect(page.locator('a[href="https://persiantoolbox.ir"]')).toBeVisible()
  })

  test('admin routes redirect to login when unauthenticated', async ({ page }) => {
    await page.goto('/admin')
    await expect(page).toHaveURL(/\/admin\/login(?:\?|$)/)
  })
})
