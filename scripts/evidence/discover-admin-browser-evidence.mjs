import { readFile, writeFile, mkdir } from 'node:fs/promises'
import { resolve } from 'node:path'
import { chromium } from '@playwright/test'

const baseUrl = (process.env.EVIDENCE_PUBLIC_BASE_URL || 'https://alirezasafaeisystems.ir').replace(/\/$/, '')
const sessionToken = process.env.EVIDENCE_SESSION_TOKEN
const statePath = process.env.EVIDENCE_STATE_PATH
const outputDir = process.env.EVIDENCE_OUTPUT_DIR

if (!sessionToken) throw new Error('EVIDENCE_SESSION_TOKEN is required')
if (!statePath) throw new Error('EVIDENCE_STATE_PATH is required')
if (!outputDir) throw new Error('EVIDENCE_OUTPUT_DIR is required')

await mkdir(outputDir, { recursive: true })
const state = JSON.parse(await readFile(statePath, 'utf8'))
if (!state?.slug) throw new Error('Evidence state has no slug')

const imported = {
  slug: state.slug,
  title: `DGR-04 browser preview FA ${state.slug}`,
  description: 'پیش‌نمایش موقت برای مدرک مرورگر مدیریت.',
  content: 'محتوای موقت پیش‌نمایش؛ این import فقط در فرم مرورگر انجام می‌شود و ذخیره نمی‌شود.',
  titleEn: `DGR-04 browser preview EN ${state.slug}`,
  descriptionEn: 'Disposable browser-preview evidence.',
  contentEn: 'Disposable browser-preview content. This import is not saved.',
  externalUrl: 'https://example.com/dgr04-evidence',
  category: 'general',
  tags: ['dgr04', 'browser-evidence'],
  imageUrl: null,
  instagramUrl: null,
  telegramGuideUrl: null,
  featured: false,
  published: false,
  publishedEn: false,
  order: 9999,
}

function assert(condition, message) {
  if (!condition) throw new Error(message)
}

async function addAuth(context, language) {
  await context.addCookies([
    {
      name: 'asdev_admin_session', value: sessionToken, url: baseUrl,
      httpOnly: true, secure: true, sameSite: 'Strict',
    },
    {
      name: 'lang', value: language, url: baseUrl,
      secure: true, sameSite: 'Lax',
    },
  ])
}

async function noDocumentOverflow(page) {
  const dimensions = await page.evaluate(() => ({
    viewport: document.documentElement.clientWidth,
    document: document.documentElement.scrollWidth,
    body: document.body.scrollWidth,
  }))
  assert(dimensions.document <= dimensions.viewport + 1, `document overflow: ${JSON.stringify(dimensions)}`)
  assert(dimensions.body <= dimensions.viewport + 1, `body overflow: ${JSON.stringify(dimensions)}`)
  return dimensions
}

async function openDiscover(page, language) {
  await page.goto(`${baseUrl}/admin`, { waitUntil: 'networkidle', timeout: 30_000 })
  assert(!page.url().includes('/admin/login'), 'Authenticated Admin unexpectedly redirected to login')
  const dashboard = page.getByTestId('admin-dashboard')
  await dashboard.waitFor({ state: 'visible', timeout: 15_000 })
  const expectedDir = language === 'fa' ? 'rtl' : 'ltr'
  assert(await dashboard.getAttribute('dir') === expectedDir, `Admin dashboard direction is not ${expectedDir}`)
  const tabName = language === 'fa' ? 'ابزارها و منابع' : 'Discover'
  await page.getByRole('button', { name: tabName, exact: true }).click()
  await page.getByTestId('discover-editor').waitFor({ state: 'visible', timeout: 15_000 })
}

const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--disable-dev-shm-usage'] })
const evidence = {
  verdict: 'PASS',
  startedAt: new Date().toISOString(),
  slug: state.slug,
  desktop: {},
  mobile: {},
}

try {
  const desktop = await browser.newContext({ viewport: { width: 1440, height: 900 }, acceptDownloads: true })
  await addAuth(desktop, 'en')
  const page = await desktop.newPage()
  await openDiscover(page, 'en')

  const transfer = page.locator('section[aria-labelledby="discover-transfer-heading"]')
  await transfer.waitFor({ state: 'visible' })
  await page.locator('#discover-json-import').fill(JSON.stringify(imported))
  await transfer.getByRole('button').nth(0).click()

  const preview = page.locator('section[aria-labelledby="discover-preview-heading"]')
  await preview.waitFor({ state: 'visible' })
  await preview.getByText(imported.title, { exact: true }).waitFor({ state: 'visible' })
  assert((await preview.textContent())?.includes(state.slug), 'FA preview did not contain the evidence slug')
  await preview.getByRole('button').nth(1).click()
  await preview.getByText(imported.titleEn, { exact: true }).waitFor({ state: 'visible' })

  const downloadPromise = page.waitForEvent('download')
  await transfer.getByRole('button').nth(1).click()
  const download = await downloadPromise
  const downloadedPath = await download.path()
  assert(downloadedPath, 'Admin export did not produce a downloadable file')
  const exported = JSON.parse(await readFile(downloadedPath, 'utf8'))
  assert(exported.slug === state.slug, 'Exported JSON slug does not match imported evidence')
  assert(exported.title === imported.title && exported.titleEn === imported.titleEn, 'Exported JSON lost locale fields')
  const desktopDimensions = await noDocumentOverflow(page)
  await page.screenshot({ path: resolve(outputDir, 'admin-discover-desktop.png'), fullPage: true })
  evidence.desktop = {
    language: 'en', direction: 'ltr', editorVisible: true,
    importValidated: true, previewFa: true, previewEn: true, exportValidated: true,
    dimensions: desktopDimensions,
  }
  await desktop.close()

  for (const language of ['fa', 'en']) {
    const mobile = await browser.newContext({ viewport: { width: 390, height: 844 } })
    await addAuth(mobile, language)
    const mobilePage = await mobile.newPage()
    await openDiscover(mobilePage, language)
    const dimensions = await noDocumentOverflow(mobilePage)
    await mobilePage.screenshot({ path: resolve(outputDir, `admin-discover-mobile-${language}.png`), fullPage: true })
    evidence.mobile[language] = {
      direction: language === 'fa' ? 'rtl' : 'ltr',
      editorVisible: true,
      transferVisible: await mobilePage.locator('section[aria-labelledby="discover-transfer-heading"]').isVisible(),
      previewVisible: await mobilePage.locator('section[aria-labelledby="discover-preview-heading"]').isVisible(),
      dimensions,
    }
    await mobile.close()
  }

  evidence.finishedAt = new Date().toISOString()
  await writeFile(resolve(outputDir, 'browser-evidence.json'), `${JSON.stringify(evidence, null, 2)}\n`, 'utf8')
  process.stdout.write('admin-browser: PASS\n')
} catch (error) {
  evidence.verdict = 'FAIL'
  evidence.finishedAt = new Date().toISOString()
  evidence.error = error instanceof Error ? error.message : String(error)
  await writeFile(resolve(outputDir, 'browser-evidence.json'), `${JSON.stringify(evidence, null, 2)}\n`, 'utf8')
  process.stderr.write(`admin-browser: FAIL — ${evidence.error}\n`)
  process.exitCode = 1
} finally {
  await browser.close()
}
