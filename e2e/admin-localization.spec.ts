import { createHmac } from 'node:crypto'
import { expect, test, type BrowserContext, type Page } from '@playwright/test'

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

async function authenticateAdmin(context: BrowserContext, language: 'fa' | 'en') {
  await context.addCookies([
    {
      name: 'asdev_admin_session',
      value: createDisposableAdminToken(),
      url: 'http://127.0.0.1:3100',
      httpOnly: true,
      sameSite: 'Strict',
    },
    {
      name: 'lang',
      value: language,
      url: 'http://127.0.0.1:3100',
      sameSite: 'Lax',
    },
  ])
}

async function expectNoDocumentOverflow(page: Page) {
  await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true)
}

test('Persian Admin shell stays RTL and usable at mobile width', async ({ page, context }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await authenticateAdmin(context, 'fa')
  await page.goto('/admin')

  await expect(page.getByTestId('admin-dashboard')).toHaveAttribute('dir', 'rtl')
  await expect(page.getByRole('heading', { name: 'داشبورد مدیریت' })).toBeVisible()
  await expect(page.getByRole('button', { name: /سرنخ‌ها/ })).toBeVisible()
  await expectNoDocumentOverflow(page)

  await page.getByRole('button', { name: 'پروژه‌ها' }).click()
  await expect(page.getByTestId('project-manager')).toHaveAttribute('dir', 'rtl')
  await expect(page.getByRole('heading', { name: 'پروژه نمونه‌کار جدید' })).toBeVisible()
  await expectNoDocumentOverflow(page)
})

test('English Admin shell stays LTR and usable at mobile width', async ({ page, context }) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await authenticateAdmin(context, 'en')
  await page.goto('/admin')

  await expect(page.getByTestId('admin-dashboard')).toHaveAttribute('dir', 'ltr')
  await expect(page.getByRole('heading', { name: 'Admin Dashboard' })).toBeVisible()
  await expect(page.getByRole('button', { name: /Leads/ })).toBeVisible()
  await expectNoDocumentOverflow(page)

  await page.getByRole('button', { name: 'Projects' }).click()
  await expect(page.getByTestId('project-manager')).toHaveAttribute('dir', 'ltr')
  await expect(page.getByRole('heading', { name: 'New portfolio project' })).toBeVisible()
  await expectNoDocumentOverflow(page)
})
