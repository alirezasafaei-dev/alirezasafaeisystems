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
})
