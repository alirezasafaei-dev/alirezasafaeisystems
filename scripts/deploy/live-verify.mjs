import { mkdir, writeFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { chromium } from '@playwright/test'
import { isExpectedNextPrefetchAbort } from './live-verify-request-failure.mjs'

const baseUrl = process.env.LIVE_VERIFY_BASE_URL
const releaseSha = process.env.LIVE_VERIFY_RELEASE_SHA
const reportPath = process.env.LIVE_VERIFY_REPORT_PATH

if (!baseUrl || !releaseSha || !reportPath) {
  throw new Error('LIVE_VERIFY_BASE_URL, LIVE_VERIFY_RELEASE_SHA and LIVE_VERIFY_REPORT_PATH are required')
}

const normalizedBaseUrl = baseUrl.replace(/\/$/, '')
const baseOrigin = new URL(normalizedBaseUrl).origin
const artifactDir = resolve(process.cwd(), 'live-verification-artifacts')
const failures = []
const warnings = []
const checkedUrls = new Set()
const startedAt = new Date().toISOString()

await mkdir(artifactDir, { recursive: true })
await mkdir(dirname(reportPath), { recursive: true })

function sameOrigin(url) {
  try {
    return new URL(url).origin === baseOrigin
  } catch {
    return false
  }
}

function recordFailure(scope, message) {
  failures.push({ scope, message })
}

function attachDiagnostics(page, scope) {
  page.on('console', (message) => {
    if (message.type() === 'error') {
      recordFailure(scope, `console error: ${message.text()}`)
    }
  })
  page.on('pageerror', (error) => recordFailure(scope, `page error: ${error.message}`))
  page.on('requestfailed', (request) => {
    const errorText = request.failure()?.errorText ?? 'unknown'
    if (sameOrigin(request.url()) && !isExpectedNextPrefetchAbort({
      method: request.method(),
      url: request.url(),
      errorText,
    })) {
      recordFailure(scope, `request failed: ${request.method()} ${request.url()} (${errorText})`)
    }
  })
  page.on('response', (response) => {
    if (sameOrigin(response.url()) && response.status() >= 500) {
      recordFailure(scope, `server response ${response.status()}: ${response.url()}`)
    }
  })
}

async function goto(page, pathname, { requireMain = true } = {}) {
  const url = new URL(pathname, `${normalizedBaseUrl}/`).toString()
  checkedUrls.add(url)
  const response = await page.goto(url, { waitUntil: 'networkidle', timeout: 30_000 })
  if (!response || response.status() >= 400) {
    throw new Error(`navigation failed for ${url}: HTTP ${response?.status() ?? 'no response'}`)
  }
  if (requireMain) {
    await page.locator('main').first().waitFor({ state: 'visible', timeout: 15_000 })
  }
  await page.waitForTimeout(400)
  return url
}

async function runCheck(browser, name, viewport, check) {
  const context = await browser.newContext({ viewport, javaScriptEnabled: true })
  const page = await context.newPage()
  attachDiagnostics(page, name)
  const failureCountBefore = failures.length

  try {
    await check(page)
  } catch (error) {
    recordFailure(name, error instanceof Error ? error.message : String(error))
  }

  if (failures.length > failureCountBefore) {
    try {
      await page.screenshot({ path: resolve(artifactDir, `${name}.png`), fullPage: true })
    } catch (error) {
      warnings.push(`${name}: screenshot failed: ${error instanceof Error ? error.message : String(error)}`)
    }
  }

  await context.close()
}

async function verifyDiscover(page, prefix = '') {
  const discoverPath = `${prefix}/discover` || '/discover'
  await goto(page, discoverPath)

  const expectedLang = prefix === '/en' ? 'en' : 'fa'
  const expectedDir = prefix === '/en' ? 'ltr' : 'rtl'
  const lang = await page.locator('html').getAttribute('lang')
  const dir = await page.locator('html').getAttribute('dir')
  if (lang !== expectedLang) throw new Error(`${discoverPath} lang=${lang}; expected ${expectedLang}`)
  if (dir !== expectedDir) throw new Error(`${discoverPath} dir=${dir}; expected ${expectedDir}`)

  const detailPrefix = prefix === '/en' ? '/en/discover/' : '/discover/'
  const detailLinks = page.locator(`a[href^="${detailPrefix}"]`)
  const detailCount = await detailLinks.count()
  if (detailCount < 1) {
    warnings.push(`${discoverPath}: no published Discover detail link; detail verification skipped`)
    return
  }

  const href = await detailLinks.first().getAttribute('href')
  if (!href) throw new Error(`${discoverPath} first detail link has no href`)

  await goto(page, href)
  await page.locator('h1').first().waitFor({ state: 'visible', timeout: 10_000 })
  const detailUrl = page.url()
  checkedUrls.add(detailUrl)

  const reload = await page.reload({ waitUntil: 'networkidle', timeout: 30_000 })
  if (!reload || reload.status() >= 400) {
    throw new Error(`hard refresh failed for ${detailUrl}: HTTP ${reload?.status() ?? 'no response'}`)
  }
}

let browser
try {
  browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  })

  await runCheck(browser, 'desktop-core', { width: 1440, height: 900 }, async (page) => {
    await goto(page, '/')
    await page.locator('h1').first().waitFor({ state: 'visible', timeout: 10_000 })
    await verifyDiscover(page)
  })

  await runCheck(browser, 'desktop-english', { width: 1440, height: 900 }, async (page) => {
    await verifyDiscover(page, '/en')
  })

  await runCheck(browser, 'mobile-discover', { width: 390, height: 844 }, async (page) => {
    await goto(page, '/discover')
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)
    if (overflow > 1) throw new Error(`/discover has ${overflow}px horizontal overflow on mobile`)
    await page.locator('h1').first().waitFor({ state: 'visible', timeout: 10_000 })
  })

  await runCheck(browser, 'admin-auth', { width: 1280, height: 800 }, async (page) => {
    await goto(page, '/admin', { requireMain: false })
    if (!page.url().includes('/admin/login')) {
      throw new Error(`/admin did not redirect to /admin/login; got ${page.url()}`)
    }
    await page.getByTestId('admin-login-form').waitFor({ state: 'visible', timeout: 10_000 })
  })
} catch (error) {
  recordFailure('runner', error instanceof Error ? error.message : String(error))
} finally {
  if (browser) await browser.close()

  const verdict = failures.length === 0
    ? 'LIVE_VERIFICATION_PASS'
    : 'LIVE_VERIFICATION_FAIL_HOTFIX_REQUIRED'
  const finishedAt = new Date().toISOString()
  const lines = [
    '# Live Verification Report — ASDEV Systems Discover',
    '',
    `- Verdict: \`${verdict}\``,
    `- Base URL: \`${normalizedBaseUrl}\``,
    `- Exact deployed commit/ref: \`${releaseSha}\``,
    `- Started: \`${startedAt}\``,
    `- Finished: \`${finishedAt}\``,
    '- Browser: Chromium (headless, JavaScript enabled)',
    '- Viewports: desktop 1440×900; mobile 390×844',
    `- Tested URLs: ${checkedUrls.size}`,
    '',
    '## URLs',
    ...[...checkedUrls].sort().map((url) => `- ${url}`),
    '',
    '## Failures',
    ...(failures.length === 0 ? ['- none'] : failures.map((failure) => `- **${failure.scope}** — ${failure.message}`)),
    '',
    '## Warnings',
    ...(warnings.length === 0 ? ['- none'] : warnings.map((warning) => `- ${warning}`)),
    '',
    '## Evidence',
    '- Browser screenshots are written to `live-verification-artifacts/` for failing checks.',
    '- The GitHub Actions run records the exact target ref, VPS smoke checks, browser result, and deployment summary.',
    '',
  ]
  await writeFile(reportPath, `${lines.join('\n')}\n`, 'utf8')
  process.stdout.write(`${verdict}\n`)

  if (failures.length > 0) {
    process.stderr.write(`${failures.map((failure) => `[${failure.scope}] ${failure.message}`).join('\n')}\n`)
    process.exitCode = 1
  }
}
