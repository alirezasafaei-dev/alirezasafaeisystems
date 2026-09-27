import { createHash, randomUUID } from 'node:crypto'
import { writeFile } from 'node:fs/promises'

const mode = process.env.EVIDENCE_MODE || 'inventory'
const internalBaseUrl = (process.env.EVIDENCE_INTERNAL_BASE_URL || 'http://127.0.0.1:3002').replace(/\/$/, '')
const publicBaseUrl = (process.env.EVIDENCE_PUBLIC_BASE_URL || 'https://alirezasafaeisystems.ir').replace(/\/$/, '')
const reportPath = process.env.EVIDENCE_REPORT_PATH
const statePath = process.env.EVIDENCE_STATE_PATH

if (!['inventory', 'crud-prepare', 'crud-cleanup'].includes(mode)) throw new Error(`Unsupported EVIDENCE_MODE: ${mode}`)
if (!reportPath) throw new Error('EVIDENCE_REPORT_PATH is required')
if (mode !== 'inventory' && !statePath) throw new Error('EVIDENCE_STATE_PATH is required for CRUD evidence')

const startedAt = new Date().toISOString()

function assert(condition, message) {
  if (!condition) throw new Error(message)
}

function normalizeCookie(setCookie) {
  if (!setCookie) return null
  const match = setCookie.match(/(?:^|,\s*)asdev_admin_session=([^;]+)/)
  return match ? `asdev_admin_session=${match[1]}` : null
}

async function loginSession() {
  assert(process.env.ADMIN_USERNAME, 'ADMIN_USERNAME is not configured')
  assert(process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD is not configured')
  const response = await fetch(`${internalBaseUrl}/api/admin/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: process.env.ADMIN_USERNAME, password: process.env.ADMIN_PASSWORD }),
    redirect: 'manual',
  })
  assert(response.ok, `Normal Admin login failed with HTTP ${response.status}`)
  const cookie = normalizeCookie(response.headers.get('set-cookie'))
  assert(cookie, 'Admin login succeeded but no session cookie was returned')
  return { cookie, status: response.status, requestId: response.headers.get('x-request-id') }
}

async function adminFetch(path, cookie, init = {}) {
  const headers = new Headers(init.headers || {})
  headers.set('cookie', cookie)
  const response = await fetch(`${internalBaseUrl}${path}`, { ...init, headers })
  return response
}

async function jsonResponse(response) {
  const text = await response.text()
  try {
    return text ? JSON.parse(text) : null
  } catch {
    throw new Error(`Expected JSON from ${response.url}; received HTTP ${response.status}`)
  }
}

function stableInventory(items, excludedId = null) {
  return items
    .filter((item) => item.id !== excludedId)
    .map((item) => ({
      id: item.id,
      slug: item.slug,
      published: Boolean(item.published),
      publishedEn: Boolean(item.publishedEn),
      updatedAt: item.updatedAt,
    }))
    .sort((a, b) => a.id.localeCompare(b.id))
}

function inventoryDigest(items, excludedId = null) {
  return createHash('sha256').update(JSON.stringify(stableInventory(items, excludedId))).digest('hex')
}

function englishComplete(item) {
  return Boolean(item.titleEn?.trim() && item.descriptionEn?.trim() && item.contentEn?.trim())
}

function parseCanonical(html) {
  for (const match of html.matchAll(/<link\b[^>]*>/gi)) {
    const tag = match[0]
    if (!/\brel=["'][^"']*canonical[^"']*["']/i.test(tag)) continue
    const href = tag.match(/\bhref=["']([^"']+)["']/i)?.[1]
    if (href) return href
  }
  return null
}

async function fetchText(url) {
  const response = await fetch(url, { redirect: 'manual', headers: { 'cache-control': 'no-cache' } })
  return { response, text: await response.text() }
}

async function loadItems(cookie) {
  const response = await adminFetch('/api/admin/discover?published=all', cookie, { cache: 'no-store' })
  assert(response.ok, `Admin Discover inventory failed with HTTP ${response.status}`)
  const payload = await jsonResponse(response)
  assert(Array.isArray(payload?.items), 'Admin Discover inventory response has no items array')
  return { items: payload.items, requestId: response.headers.get('x-request-id') }
}

async function collectInventory(cookie) {
  const { items, requestId } = await loadItems(cookie)
  const [faLanding, enLanding, sitemap] = await Promise.all([
    fetchText(`${publicBaseUrl}/discover?evidence=${Date.now()}`),
    fetchText(`${publicBaseUrl}/en/discover?evidence=${Date.now()}`),
    fetchText(`${publicBaseUrl}/sitemap.xml?evidence=${Date.now()}`),
  ])
  assert(faLanding.response.status === 200, `FA Discover landing returned HTTP ${faLanding.response.status}`)
  assert(enLanding.response.status === 200, `EN Discover landing returned HTTP ${enLanding.response.status}`)
  assert(sitemap.response.status === 200, `Sitemap returned HTTP ${sitemap.response.status}`)

  const rows = []
  const mismatches = []
  for (const item of items) {
    const enComplete = englishComplete(item)
    const expectedFaPublic = Boolean(item.published)
    const expectedEnPublic = Boolean(item.publishedEn && enComplete)
    const faPath = `/discover/${item.slug}`
    const enPath = `/en/discover/${item.slug}`
    const [faDetail, enDetail] = await Promise.all([
      fetchText(`${publicBaseUrl}${faPath}?evidence=${Date.now()}`),
      fetchText(`${publicBaseUrl}${enPath}?evidence=${Date.now()}`),
    ])
    const faLandingPresent = faLanding.text.includes(`href="${faPath}"`) || faLanding.text.includes(`href='${faPath}'`)
    const enLandingPresent = enLanding.text.includes(`href="${enPath}"`) || enLanding.text.includes(`href='${enPath}'`)
    const faSitemapPresent = sitemap.text.includes(`${publicBaseUrl}${faPath}`)
    const enSitemapPresent = sitemap.text.includes(`${publicBaseUrl}${enPath}`)
    const faCanonical = parseCanonical(faDetail.text)
    const enCanonical = parseCanonical(enDetail.text)

    if (faLandingPresent !== expectedFaPublic) mismatches.push(`${item.slug}: FA landing presence mismatch`)
    if (faSitemapPresent !== expectedFaPublic) mismatches.push(`${item.slug}: FA sitemap presence mismatch`)
    if (expectedFaPublic && faDetail.response.status !== 200) mismatches.push(`${item.slug}: FA detail expected 200, got ${faDetail.response.status}`)
    if (expectedFaPublic && faCanonical && faCanonical !== `${publicBaseUrl}${faPath}`) mismatches.push(`${item.slug}: FA canonical mismatch (${faCanonical})`)
    if (enLandingPresent !== expectedEnPublic) mismatches.push(`${item.slug}: EN landing presence mismatch`)
    if (enSitemapPresent !== expectedEnPublic) mismatches.push(`${item.slug}: EN sitemap presence mismatch`)
    if (expectedEnPublic && enDetail.response.status !== 200) mismatches.push(`${item.slug}: EN detail expected 200, got ${enDetail.response.status}`)
    if (!expectedEnPublic && enDetail.response.status !== 404) mismatches.push(`${item.slug}: unavailable EN detail expected true 404, got ${enDetail.response.status}`)
    if (expectedEnPublic && enCanonical && enCanonical !== `${publicBaseUrl}${enPath}`) mismatches.push(`${item.slug}: EN canonical mismatch (${enCanonical})`)

    rows.push({
      slug: item.slug,
      publishedFa: Boolean(item.published),
      englishComplete: enComplete,
      publishedEn: Boolean(item.publishedEn),
      expectedFaPublic,
      expectedEnPublic,
      fa: { status: faDetail.response.status, landing: faLandingPresent, sitemap: faSitemapPresent, canonical: faCanonical },
      en: { status: enDetail.response.status, landing: enLandingPresent, sitemap: enSitemapPresent, canonical: enCanonical },
    })
  }

  return {
    adminRequestId: requestId,
    itemCount: items.length,
    inventoryDigest: inventoryDigest(items),
    landing: { fa: faLanding.response.status, en: enLanding.response.status, sitemap: sitemap.response.status },
    items: rows,
    mismatches,
  }
}

async function createDisposableDraft(cookie) {
  const suffix = `${Date.now()}-${randomUUID().slice(0, 8)}`
  const slug = `dgr04-evidence-${suffix}`
  const payload = {
    slug,
    title: `DGR-04 evidence FA ${suffix}`,
    description: 'Disposable production Admin CRUD evidence record. Safe to delete.',
    content: 'Disposable production Admin CRUD evidence content. This record is created only for verification and must be removed.',
    externalUrl: 'https://example.com/dgr04-evidence',
    category: 'general',
    tags: ['dgr04', 'evidence'],
    featured: false,
    published: false,
    publishedEn: false,
    order: 9999,
  }
  const response = await adminFetch('/api/admin/discover', cookie, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  })
  const body = await jsonResponse(response)
  assert(response.status === 201 && body?.item?.id, `Draft creation failed with HTTP ${response.status}`)
  return { item: body.item, requestId: response.headers.get('x-request-id') }
}

async function patchItem(cookie, item, changes) {
  const response = await adminFetch('/api/admin/discover', cookie, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ id: item.id, expectedUpdatedAt: item.updatedAt, ...changes }),
  })
  const body = await jsonResponse(response)
  assert(response.ok && body?.item?.id === item.id, `PATCH failed with HTTP ${response.status}`)
  return { item: body.item, requestId: response.headers.get('x-request-id') }
}

async function deleteItem(cookie, id) {
  const response = await adminFetch(`/api/admin/discover?id=${encodeURIComponent(id)}`, cookie, { method: 'DELETE' })
  const body = await jsonResponse(response)
  assert(response.ok && body?.success === true, `DELETE failed with HTTP ${response.status}`)
  return { requestId: response.headers.get('x-request-id') }
}

async function runCrudPrepare(cookie, loginEvidence) {
  const baseline = await loadItems(cookie)
  const baselineDigest = inventoryDigest(baseline.items)
  const baselineCount = baseline.items.length
  let created = null
  const requestIds = { login: loginEvidence.requestId, baseline: baseline.requestId }

  try {
    const invalidResponse = await adminFetch('/api/admin/discover', cookie, {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ slug: 'x' }),
    })
    const invalidBody = await jsonResponse(invalidResponse)
    assert(invalidResponse.status === 400 && invalidBody?.error === 'Validation failed', `Expected validation HTTP 400, got ${invalidResponse.status}`)
    requestIds.validation = invalidResponse.headers.get('x-request-id')

    const creation = await createDisposableDraft(cookie)
    created = creation.item
    requestIds.create = creation.requestId

    let inventory = await loadItems(cookie)
    let reopened = inventory.items.find((item) => item.id === created.id)
    assert(reopened?.slug === created.slug && reopened.published === false && reopened.publishedEn === false, 'Created draft did not reopen with expected persisted values')
    requestIds.reopen = inventory.requestId

    const faTitle = `${created.title} — edited`
    const faPatch = await patchItem(cookie, reopened, { title: faTitle })
    reopened = faPatch.item
    requestIds.faPatch = faPatch.requestId
    assert(reopened.title === faTitle, 'FA edit did not persist')

    const enPatch = await patchItem(cookie, reopened, {
      titleEn: `DGR-04 evidence EN ${created.slug}`,
      descriptionEn: 'Disposable English evidence description.',
      contentEn: 'Disposable English evidence content used only for production CRUD verification.',
    })
    reopened = enPatch.item
    requestIds.enPatch = enPatch.requestId
    assert(reopened.title === faTitle && reopened.titleEn?.startsWith('DGR-04 evidence EN'), 'EN edit overwrote or failed to preserve FA fields')

    const publishPatch = await patchItem(cookie, reopened, { published: true, publishedEn: true })
    reopened = publishPatch.item
    requestIds.publish = publishPatch.requestId
    assert(reopened.published === true && reopened.publishedEn === true, 'Publish state did not persist')

    const [faPublic, enPublic] = await Promise.all([
      fetchText(`${publicBaseUrl}/discover/${created.slug}?evidence=${Date.now()}`),
      fetchText(`${publicBaseUrl}/en/discover/${created.slug}?evidence=${Date.now()}`),
    ])
    assert(faPublic.response.status === 200 && faPublic.text.includes(faTitle), `Published FA evidence record was not publicly visible (HTTP ${faPublic.response.status})`)
    assert(enPublic.response.status === 200 && enPublic.text.includes(`DGR-04 evidence EN ${created.slug}`), `Published EN evidence record was not publicly visible (HTTP ${enPublic.response.status})`)
    const faCanonical = parseCanonical(faPublic.text)
    const enCanonical = parseCanonical(enPublic.text)
    assert(!faCanonical || faCanonical === `${publicBaseUrl}/discover/${created.slug}`, `Published FA canonical mismatch: ${faCanonical}`)
    assert(!enCanonical || enCanonical === `${publicBaseUrl}/en/discover/${created.slug}`, `Published EN canonical mismatch: ${enCanonical}`)

    const unpublishPatch = await patchItem(cookie, reopened, { published: false, publishedEn: false })
    reopened = unpublishPatch.item
    requestIds.unpublish = unpublishPatch.requestId
    assert(reopened.published === false && reopened.publishedEn === false, 'Unpublish state did not persist')

    const state = { id: created.id, slug: created.slug, baselineDigest, baselineCount }
    await writeFile(statePath, `${JSON.stringify(state)}\n`, { mode: 0o600 })
    return {
      login: { status: loginEvidence.status, requestId: loginEvidence.requestId },
      baseline: { count: baselineCount, digest: baselineDigest },
      validation: { status: invalidResponse.status, requestId: requestIds.validation },
      created: { id: created.id, slug: created.slug, published: false, publishedEn: false },
      persisted: { faTitlePreserved: true, englishFieldsComplete: true },
      publishCycle: {
        faStatus: faPublic.response.status,
        enStatus: enPublic.response.status,
        faCanonical,
        enCanonical,
        restoredToDraft: true,
      },
      requestIds,
      cleanupPending: true,
    }
  } catch (error) {
    if (created?.id) {
      try { await deleteItem(cookie, created.id) } catch {}
    }
    throw error
  }
}

async function runCrudCleanup(cookie) {
  const state = JSON.parse(await (await import('node:fs/promises')).readFile(statePath, 'utf8'))
  assert(state?.id && state?.slug && state?.baselineDigest, 'CRUD evidence state is incomplete')
  const before = await loadItems(cookie)
  const existedBeforeCleanup = before.items.some((item) => item.id === state.id)
  if (existedBeforeCleanup) await deleteItem(cookie, state.id)
  const after = await loadItems(cookie)
  assert(!after.items.some((item) => item.id === state.id || item.slug === state.slug), 'Evidence record still exists after cleanup')
  assert(after.items.length === state.baselineCount, `Discover item count changed after cleanup: expected ${state.baselineCount}, got ${after.items.length}`)
  assert(inventoryDigest(after.items) === state.baselineDigest, 'Pre-existing Discover item inventory changed during disposable CRUD evidence')

  const [faLanding, enLanding, faDetail, enDetail] = await Promise.all([
    fetchText(`${publicBaseUrl}/discover?evidence=${Date.now()}`),
    fetchText(`${publicBaseUrl}/en/discover?evidence=${Date.now()}`),
    fetchText(`${publicBaseUrl}/discover/${state.slug}?evidence=${Date.now()}`),
    fetchText(`${publicBaseUrl}/en/discover/${state.slug}?evidence=${Date.now()}`),
  ])
  assert(!faLanding.text.includes(`/discover/${state.slug}`), 'Evidence slug remains on FA landing after cleanup')
  assert(!enLanding.text.includes(`/en/discover/${state.slug}`), 'Evidence slug remains on EN landing after cleanup')
  assert(!faDetail.text.includes(state.slug), 'Evidence record content remains publicly visible on FA detail after cleanup')
  assert(enDetail.response.status === 404, `Cleaned-up EN evidence detail expected 404, got ${enDetail.response.status}`)

  return {
    evidenceRecordExistedBeforeCleanup: existedBeforeCleanup,
    deleted: true,
    adminAbsent: true,
    baselineRestored: true,
    baselineCount: state.baselineCount,
    baselineDigest: state.baselineDigest,
    public: {
      faLandingAbsent: true,
      enLandingAbsent: true,
      faDetailStatus: faDetail.response.status,
      enDetailStatus: enDetail.response.status,
    },
  }
}

let report
try {
  const login = await loginSession()
  if (mode === 'inventory') report = { kind: 'DGR-01', ...(await collectInventory(login.cookie)) }
  if (mode === 'crud-prepare') report = { kind: 'DGR-04-prepare', ...(await runCrudPrepare(login.cookie, login)) }
  if (mode === 'crud-cleanup') report = { kind: 'DGR-04-cleanup', ...(await runCrudCleanup(login.cookie)) }

  const completed = {
    verdict: 'PASS',
    mode,
    startedAt,
    finishedAt: new Date().toISOString(),
    internalTarget: '127.0.0.1:3002',
    publicTarget: publicBaseUrl,
    ...report,
  }
  await writeFile(reportPath, `${JSON.stringify(completed, null, 2)}\n`, 'utf8')
  process.stdout.write(`${mode}: PASS\n`)
} catch (error) {
  const failed = {
    verdict: 'FAIL',
    mode,
    startedAt,
    finishedAt: new Date().toISOString(),
    internalTarget: '127.0.0.1:3002',
    publicTarget: publicBaseUrl,
    error: error instanceof Error ? error.message : String(error),
  }
  await writeFile(reportPath, `${JSON.stringify(failed, null, 2)}\n`, 'utf8')
  process.stderr.write(`${mode}: FAIL — ${failed.error}\n`)
  process.exitCode = 1
}
