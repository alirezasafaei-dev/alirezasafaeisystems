import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('CI database runtime contract', () => {
  it('uses the absolute disposable Playwright SQLite path for schema setup and standalone smoke', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/ci.yml'), 'utf8')

    expect(workflow).toContain('DATABASE_URL: "file:${{ github.workspace }}/test-results/playwright.db"')
    expect(workflow).not.toContain('DATABASE_URL: "file:./prisma/dev.db"')
    expect(workflow).not.toContain('DATABASE_URL: "file:${{ github.workspace }}/prisma/dev.db"')
  })
})
