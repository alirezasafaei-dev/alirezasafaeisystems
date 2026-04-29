/* eslint-disable no-console */
import fs from 'node:fs/promises'
import path from 'node:path'

const SITES = [
  {
    key: 'portfolio',
    role: 'conversion_engine',
    baseUrl: 'https://alirezasafaeisystems.ir',
    readyPath: '/api/ready',
    expectedLocale: { lang: 'fa', dir: 'rtl' },
  },
  {
    key: 'audit',
    role: 'qualification_engine',
    baseUrl: 'https://audit.alirezasafaeisystems.ir',
    readyPath: '/api/ready',
    expectedLocale: { lang: 'fa', dir: 'rtl' },
  },
  {
    key: 'toolbox',
    role: 'acquisition_engine',
    baseUrl: 'https://persiantoolbox.ir',
    readyPath: '/api/ready',
    expectedLocale: { lang: 'fa', dir: 'rtl' },
  },
]

function nowIso() {
  return new Date().toISOString()
}

function stamp() {
  return nowIso().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z')
}

function extractHtmlTagAttr(html, attrName) {
  const openTag = html.match(/<html[^>]*>/i)?.[0] ?? ''
  const attr = openTag.match(new RegExp(`${attrName}=["']([^"']+)["']`, 'i'))?.[1] ?? null
  return attr
}

function extractTitle(html) {
  return html.match(/<title[^>]*>([^<]+)<\/title>/i)?.[1]?.trim() ?? null
}

function extractMetaDescription(html) {
  return html.match(/<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i)?.[1] ?? null
}

function extractCanonical(html) {
  return html.match(/<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)["']/i)?.[1] ?? null
}

function hasHostLink(html, host) {
  return html.includes(host)
}

async function fetchText(url) {
  const startedAt = Date.now()
  const res = await fetch(url, { redirect: 'follow', cache: 'no-store' })
  const text = await res.text()
  return {
    ok: res.ok,
    status: res.status,
    latencyMs: Date.now() - startedAt,
    text,
  }
}

async function fetchReady(url) {
  const startedAt = Date.now()
  const res = await fetch(url, { redirect: 'follow', cache: 'no-store' })
  const body = await res.text()
  return {
    ok: res.ok,
    status: res.status,
    latencyMs: Date.now() - startedAt,
    body,
  }
}

function checkCommonSeoAndUx(site, html) {
  const title = extractTitle(html)
  const description = extractMetaDescription(html)
  const canonical = extractCanonical(html)
  const lang = extractHtmlTagAttr(html, 'lang')
  const dir = extractHtmlTagAttr(html, 'dir')

  const checks = []
  checks.push({
    id: 'html_locale',
    status: lang === site.expectedLocale.lang && dir === site.expectedLocale.dir ? 'pass' : 'fail',
    detail: `lang=${lang ?? 'null'} dir=${dir ?? 'null'}`,
  })
  checks.push({
    id: 'title',
    status: title && title.length >= 10 ? 'pass' : 'fail',
    detail: title ? `length=${title.length}` : 'missing',
  })
  checks.push({
    id: 'meta_description',
    status: description && description.length >= 60 ? 'pass' : 'fail',
    detail: description ? `length=${description.length}` : 'missing',
  })
  checks.push({
    id: 'canonical',
    status: canonical ? 'pass' : 'fail',
    detail: canonical ?? 'missing',
  })

  return { checks, title, description, canonical, lang, dir }
}

function checkCrossLinks(siteKey, html) {
  const checks = []
  if (siteKey === 'portfolio') {
    checks.push({
      id: 'cross_link_audit',
      status: hasHostLink(html, 'audit.alirezasafaeisystems.ir') ? 'pass' : 'fail',
      detail: 'expects audit cross-link',
    })
    checks.push({
      id: 'cross_link_toolbox',
      status: hasHostLink(html, 'persiantoolbox.ir') ? 'pass' : 'fail',
      detail: 'expects toolbox cross-link',
    })
    checks.push({
      id: 'intent_router',
      status: html.includes('id="intent-router"') ? 'pass' : 'fail',
      detail: 'expects intent-router section on homepage',
    })
  } else if (siteKey === 'audit') {
    checks.push({
      id: 'cross_link_portfolio',
      status: hasHostLink(html, 'alirezasafaeisystems.ir') ? 'pass' : 'fail',
      detail: 'expects portfolio cross-link',
    })
    checks.push({
      id: 'cross_link_toolbox',
      status: hasHostLink(html, 'persiantoolbox.ir') ? 'pass' : 'fail',
      detail: 'expects toolbox cross-link',
    })
    checks.push({
      id: 'intent_router',
      status: html.includes('id="intent-router"') ? 'pass' : 'fail',
      detail: 'expects intent-router section on homepage',
    })
    checks.push({
      id: 'footer_clean_old_network',
      status: html.includes('<h3>شبکه علیرضا صفایی</h3>') ? 'fail' : 'pass',
      detail: 'legacy network footer section must be removed',
    })
    checks.push({
      id: 'footer_clean_badges',
      status: html.includes('footer-badges') ? 'fail' : 'pass',
      detail: 'legacy footer badges must be removed',
    })
    checks.push({
      id: 'footer_clean_old_bottom',
      status: html.includes('class="footer-bottom"') ? 'fail' : 'pass',
      detail: 'legacy footer-bottom block must be removed',
    })
  } else if (siteKey === 'toolbox') {
    checks.push({
      id: 'cross_link_portfolio',
      status: hasHostLink(html, 'alirezasafaeisystems.ir') ? 'pass' : 'fail',
      detail: 'expects portfolio link',
    })
    checks.push({
      id: 'intent_router',
      status: html.includes('id="intent-router"') ? 'pass' : 'fail',
      detail: 'expects intent-router section on homepage',
    })
  }

  return checks
}

function aggregateStatus(checks) {
  const pass = checks.filter((c) => c.status === 'pass').length
  const fail = checks.filter((c) => c.status === 'fail').length
  return {
    pass,
    fail,
    score: checks.length ? Math.round((pass / checks.length) * 100) : 0,
  }
}

function buildPhaseActions(resultSet) {
  const actions = []
  const hasAnyFail = (id) =>
    resultSet.some((r) => r.checks.some((c) => c.id === id && c.status === 'fail'))

  if (hasAnyFail('html_locale')) {
    actions.push({
      phase: 'Phase 2: Deep Audit Baseline',
      priority: 'high',
      action: 'Fix default locale and direction contract (fa/rtl) on failing domains.',
    })
  }
  if (hasAnyFail('meta_description') || hasAnyFail('title') || hasAnyFail('canonical')) {
    actions.push({
      phase: 'Phase 6: SEO Architecture and Content Clusters',
      priority: 'high',
      action: 'Normalize metadata contracts (title, description, canonical) on key templates.',
    })
  }
  if (hasAnyFail('cross_link_audit') || hasAnyFail('cross_link_toolbox') || hasAnyFail('cross_link_portfolio')) {
    actions.push({
      phase: 'Phase 3: Information Architecture Refactor',
      priority: 'high',
      action: 'Repair missing cross-site intent links to keep acquisition -> qualification -> conversion path intact.',
    })
  }
  if (hasAnyFail('intent_router')) {
    actions.push({
      phase: 'Phase 3: Information Architecture Refactor',
      priority: 'high',
      action: 'Add missing intent-router blocks to reduce CTA ambiguity and speed up user path selection.',
    })
  }
  if (hasAnyFail('footer_clean_old_network') || hasAnyFail('footer_clean_badges') || hasAnyFail('footer_clean_old_bottom')) {
    actions.push({
      phase: 'Phase 5: Design System Consolidation',
      priority: 'medium',
      action: 'Remove legacy footer blocks from audit domain and enforce clean enterprise footer contract.',
    })
  }

  if (actions.length === 0) {
    actions.push({
      phase: 'Phase 7: Conversion and Funnel Optimization',
      priority: 'medium',
      action: 'Baseline is clean; proceed with CTA experiments and funnel drop-off optimization.',
    })
  }

  return actions
}

function renderMarkdownReport(resultSet, actions) {
  const lines = []
  lines.push('# Enterprise Network Audit Report')
  lines.push('')
  lines.push(`- Generated at: ${nowIso()}`)
  lines.push(`- Scope: ${SITES.map((s) => s.baseUrl).join(' | ')}`)
  lines.push('')
  lines.push('## Site Results')
  lines.push('')

  for (const result of resultSet) {
    lines.push(`### ${result.site.key} (${result.site.baseUrl})`)
    lines.push(`- Role: ${result.site.role}`)
    lines.push(`- Root status: ${result.root.status}`)
    lines.push(`- Ready status: ${result.ready.status}`)
    lines.push(`- Score: ${result.summary.score} (${result.summary.pass} pass / ${result.summary.fail} fail)`)
    lines.push('')
    lines.push('| Check | Status | Detail |')
    lines.push('|---|---|---|')
    for (const check of result.checks) {
      lines.push(`| ${check.id} | ${check.status.toUpperCase()} | ${check.detail} |`)
    }
    lines.push('')
  }

  lines.push('## Phase Actions')
  lines.push('')
  lines.push('| Priority | Phase | Action |')
  lines.push('|---|---|---|')
  for (const action of actions) {
    lines.push(`| ${action.priority.toUpperCase()} | ${action.phase} | ${action.action} |`)
  }
  lines.push('')

  return lines.join('\n')
}

async function main() {
  const outDir = path.resolve('reports/enterprise-network')
  await fs.mkdir(outDir, { recursive: true })

  const resultSet = []

  for (const site of SITES) {
    const root = await fetchText(`${site.baseUrl}/`)
    const ready = await fetchReady(`${site.baseUrl}${site.readyPath}`)

    const common = checkCommonSeoAndUx(site, root.text)
    const cross = checkCrossLinks(site.key, root.text)
    const checks = [...common.checks, ...cross]
    const summary = aggregateStatus(checks)

    resultSet.push({
      site,
      root: { status: root.status, latencyMs: root.latencyMs },
      ready: { status: ready.status, latencyMs: ready.latencyMs },
      checks,
      summary,
      extracted: {
        title: common.title,
        description: common.description,
        canonical: common.canonical,
        lang: common.lang,
        dir: common.dir,
      },
    })
  }

  const actions = buildPhaseActions(resultSet)
  const reportMd = renderMarkdownReport(resultSet, actions)
  const reportJson = {
    generatedAt: nowIso(),
    resultSet,
    actions,
  }

  const fileTag = stamp()
  const mdPath = path.join(outDir, `${fileTag}-enterprise-network-audit.md`)
  const jsonPath = path.join(outDir, `${fileTag}-enterprise-network-audit.json`)
  const latestPath = path.join(outDir, 'latest-enterprise-network-audit.json')

  await fs.writeFile(mdPath, reportMd)
  await fs.writeFile(jsonPath, JSON.stringify(reportJson, null, 2))
  await fs.writeFile(latestPath, JSON.stringify(reportJson, null, 2))

  console.log(`[enterprise-audit] markdown report: ${mdPath}`)
  console.log(`[enterprise-audit] json report: ${jsonPath}`)
  console.log(`[enterprise-audit] latest snapshot: ${latestPath}`)

  const hasFail = resultSet.some((r) => r.summary.fail > 0)
  if (hasFail) {
    process.exitCode = 1
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
