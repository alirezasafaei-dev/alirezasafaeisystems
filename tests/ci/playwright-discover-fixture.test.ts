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

  it('runs both smoke and accessibility browser contracts in the E2E workflow', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/e2e-smoke.yml'), 'utf8')

    expect(workflow).toContain('pnpm run test:e2e:smoke')
    expect(workflow).toContain('pnpm exec playwright test e2e/a11y.spec.ts')
  })

  it('creates and seeds the same disposable database before the CI standalone build and Browser Smoke', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/ci.yml'), 'utf8')
    const disposableDatabase = 'DATABASE_URL: "file:${{ github.workspace }}/test-results/playwright.db"'
    const setupIndex = workflow.indexOf('- name: Setup browser database and deterministic Discover fixture')
    const buildIndex = workflow.indexOf('- name: Production build')
    const smokeIndex = workflow.indexOf('- name: Browser smoke')

    expect(setupIndex).toBeGreaterThan(-1)
    expect(buildIndex).toBeGreaterThan(setupIndex)
    expect(smokeIndex).toBeGreaterThan(buildIndex)
    expect(workflow).toContain(disposableDatabase)
    expect(workflow).toContain('ASDEV_BUILD_SKIP_DYNAMIC_DB: "1"')
    expect(workflow.match(new RegExp(disposableDatabase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'))?.length).toBeGreaterThanOrEqual(3)
    expect(workflow).toContain('node scripts/test/seed-playwright-discover.mjs')
    expect(workflow).not.toContain('DATABASE_URL: "file:${{ github.workspace }}/prisma/dev.db"')
  })
})
