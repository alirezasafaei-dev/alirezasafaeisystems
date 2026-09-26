import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('Playwright Discover fixture isolation', () => {
  it('seeds only the disposable test-results database and fails closed elsewhere', () => {
    const config = readFileSync(resolve(process.cwd(), 'playwright.config.mjs'), 'utf8')
    const seed = readFileSync(resolve(process.cwd(), 'scripts/test/seed-playwright-discover.mjs'), 'utf8')

    expect(config).toContain("const playwrightDatabaseUrl = `file:${resolve(process.cwd(), 'test-results/playwright.db')}`")
    expect(config).toContain('DATABASE_URL: playwrightDatabaseUrl')
    expect(config).not.toContain("process.env.DATABASE_URL || `file:${resolve(process.cwd(), 'test-results/playwright.db')}`")
    expect(config).toContain('node scripts/test/seed-playwright-discover.mjs')

    expect(seed).toContain("const expectedPath = resolve(process.cwd(), 'test-results/playwright.db')")
    expect(seed).toContain('if (actualPath !== expectedPath)')
    expect(seed).toContain('Refusing to seed non-disposable database')
    expect(seed).toContain("where: { slug: 'playwright-discover-resource' }")
    expect(seed).toContain("telegramGuideUrl: 'https://t.me/asdev_test/123'")
  })

  it('keeps Playwright artifacts in a child directory so runner cleanup cannot delete the disposable SQLite fixture', () => {
    const config = readFileSync(resolve(process.cwd(), 'playwright.config.mjs'), 'utf8')

    expect(config).toContain("outputDir: './test-results/playwright-artifacts'")
    expect(config).toContain("const playwrightDatabaseUrl = `file:${resolve(process.cwd(), 'test-results/playwright.db')}`")
  })

  it('runs both smoke and accessibility browser contracts in the E2E workflow without persisting checkout credentials', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/e2e-smoke.yml'), 'utf8')
    const checkoutIndex = workflow.indexOf('- uses: actions/checkout@v4')
    const setupIndex = workflow.indexOf('- uses: pnpm/action-setup@v4')
    const checkoutBlock = workflow.slice(checkoutIndex, setupIndex)

    expect(workflow).toContain('pnpm run test:e2e:smoke')
    expect(workflow).toContain('pnpm exec playwright test e2e/a11y.spec.ts')
    expect(checkoutIndex).toBeGreaterThan(-1)
    expect(setupIndex).toBeGreaterThan(checkoutIndex)
    expect(checkoutBlock).toContain('persist-credentials: false')
  })

  it('creates and seeds the disposable database before the final CI build and keeps that build after enterprise verification', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/ci.yml'), 'utf8')
    const disposableDatabase = 'DATABASE_URL: "file:${{ github.workspace }}/test-results/playwright.db"'
    const enterpriseIndex = workflow.indexOf('- name: Enterprise gate')
    const setupIndex = workflow.indexOf('- name: Setup browser database and deterministic Discover fixture')
    const buildIndex = workflow.indexOf('- name: Production build')
    const smokeIndex = workflow.indexOf('- name: Browser smoke')

    expect(enterpriseIndex).toBeGreaterThan(-1)
    expect(setupIndex).toBeGreaterThan(enterpriseIndex)
    expect(buildIndex).toBeGreaterThan(setupIndex)
    expect(smokeIndex).toBeGreaterThan(buildIndex)
    expect(workflow.indexOf('- name: Enterprise gate', buildIndex)).toBe(-1)
    expect(workflow).toContain(disposableDatabase)
    expect(workflow).toContain('ASDEV_BUILD_SKIP_DYNAMIC_DB: "1"')
    expect(workflow.match(new RegExp(disposableDatabase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'))?.length).toBeGreaterThanOrEqual(3)
    expect(workflow).toContain('node scripts/test/seed-playwright-discover.mjs')
    expect(workflow).not.toContain('DATABASE_URL: "file:${{ github.workspace }}/prisma/dev.db"')
  })

  it('gives the exact Lighthouse preparation and collection steps the same job-scoped disposable Discover database', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/lighthouse.yml'), 'utf8')
    const disposableDatabase = 'DATABASE_URL: "file:${{ github.workspace }}/test-results/playwright.db"'
    const stepsIndex = workflow.indexOf('    steps:')
    const seedIndex = workflow.indexOf('- name: Prepare disposable Lighthouse data')
    const chromiumIndex = workflow.indexOf('- name: Install Chromium for Lighthouse')
    const collectIndex = workflow.indexOf('- name: Run Lighthouse CI')
    const seedBlock = workflow.slice(seedIndex, chromiumIndex)
    const collectBlock = workflow.slice(collectIndex)
    const jobPrefix = workflow.slice(0, stepsIndex)

    expect(stepsIndex).toBeGreaterThan(-1)
    expect(jobPrefix).toContain(disposableDatabase)
    expect(seedIndex).toBeGreaterThan(stepsIndex)
    expect(chromiumIndex).toBeGreaterThan(seedIndex)
    expect(collectIndex).toBeGreaterThan(chromiumIndex)
    expect(seedBlock).toContain('mkdir -p "$GITHUB_WORKSPACE/test-results"')
    expect(seedBlock).toContain('pnpm prisma db push --skip-generate --accept-data-loss')
    expect(seedBlock).toContain('node scripts/test/seed-playwright-discover.mjs')
    expect(seedBlock).not.toContain('DATABASE_URL:')
    expect(collectBlock).not.toContain('DATABASE_URL:')
    expect(workflow).not.toContain('DATABASE_URL: file:${{ runner.temp }}/lighthouse.db')
  })

  it('starts Browser Smoke with the same direct standalone launcher contract used by E2E and production', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/ci.yml'), 'utf8')

    expect(workflow).toContain('HOSTNAME=127.0.0.1 PORT=3100 node scripts/start-playwright-server.mjs &')
    expect(workflow).not.toContain('PORT=3100 pnpm run start &')
  })

  it('uses locale-neutral fixture copy independently in both create and update branches', () => {
    const seed = readFileSync(resolve(process.cwd(), 'scripts/test/seed-playwright-discover.mjs'), 'utf8')
    const createIndex = seed.indexOf('    create: {')
    const updateIndex = seed.indexOf('    update: {')
    const createBlock = seed.slice(createIndex, updateIndex)
    const updateBlock = seed.slice(updateIndex)

    expect(createIndex).toBeGreaterThan(-1)
    expect(updateIndex).toBeGreaterThan(createIndex)
    for (const block of [createBlock, updateBlock]) {
      expect(block).toContain("title: 'Playwright Fixture 01'")
      expect(block).toContain("description: 'fixture-description-01'")
      expect(block).toContain("content: 'fixture-content-01'")
      expect(block).toContain("category: 'test-fixture'")
      expect(block).not.toContain("title: 'منبع آزمایشی Playwright'")
      expect(block).not.toContain("category: 'آزمایش'")
    }
  })
})
