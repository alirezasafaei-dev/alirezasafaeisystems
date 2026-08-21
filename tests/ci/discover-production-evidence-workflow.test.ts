import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'

const workflow = readFileSync('.github/workflows/discover-production-evidence.yml', 'utf8')
const deployWorkflow = readFileSync('.github/workflows/deploy-vps.yml', 'utf8')
const apiEvidence = readFileSync('scripts/evidence/discover-production-api-evidence.mjs', 'utf8')
const browserEvidence = readFileSync('scripts/evidence/discover-admin-browser-evidence.mjs', 'utf8')
const sessionHelper = readFileSync('scripts/evidence/admin-session-token.mjs', 'utf8')

describe('Discover production evidence workflow safety contract', () => {
  it('is request-driven from a docs-only path outside the Deploy VPS trigger', () => {
    expect(workflow).toContain('docs/evidence-requests/discover-production-evidence.json')
    expect(workflow).toContain('inventory|admin-crud')
    expect(deployWorkflow).not.toContain('docs/evidence-requests/**')
    expect(deployWorkflow).not.toContain('scripts/evidence/**')
    expect(workflow).not.toContain('workflow_dispatch:')
  })

  it('masks the ephemeral Admin session and never uploads runner state', () => {
    expect(workflow).toContain('echo "::add-mask::$SESSION_CREDENTIAL"')
    expect(workflow).toContain('EVIDENCE_SESSION_CREDENTIAL=%s')
    expect(workflow).toContain('path: evidence-output/')
    expect(workflow).not.toContain('path: $RUNNER_TEMP/discover-crud-state.json')
    expect(sessionHelper).not.toContain('ADMIN_PASSWORD)')
    expect(sessionHelper).not.toContain('console.log')
  })

  it('forces CRUD cleanup even when browser verification fails', () => {
    expect(workflow).toContain("if: ${{ always() && steps.request.outputs.mode == 'admin-crud' }}")
    expect(workflow).toContain('EVIDENCE_MODE=crud-cleanup')
    expect(workflow).toContain("test \"$(jq -r '.baselineRestored' evidence-output/crud-cleanup.json)\" = \"true\"")
    expect(apiEvidence).toContain("if (created?.id)")
    expect(apiEvidence).toContain('await deleteItem(cookie, created.id)')
  })

  it('starts disposable evidence unpublished and verifies a restored draft plus baseline integrity', () => {
    expect(apiEvidence).toContain('published: false')
    expect(apiEvidence).toContain('publishedEn: false')
    expect(apiEvidence).toContain('{ published: true, publishedEn: true }')
    expect(apiEvidence).toContain('{ published: false, publishedEn: false }')
    expect(apiEvidence).toContain("inventoryDigest(after.items) === state.baselineDigest")
    expect(apiEvidence).toContain("enDetail.response.status === 404")
  })

  it('keeps browser evidence schema-valid and covers import, preview, export and mobile directions', () => {
    expect(browserEvidence).toContain("imageUrl: ''")
    expect(browserEvidence).toContain("instagramUrl: ''")
    expect(browserEvidence).toContain("telegramGuideUrl: ''")
    expect(browserEvidence).toContain('EVIDENCE_SESSION_CREDENTIAL')
    expect(browserEvidence).toContain("page.locator('#discover-json-import')")
    expect(browserEvidence).toContain("page.waitForEvent('download')")
    expect(browserEvidence).toContain("for (const language of ['fa', 'en'])")
    expect(browserEvidence).toContain("width: 390, height: 844")
  })

  it.each([
    'scripts/evidence/discover-production-api-evidence.mjs',
    'scripts/evidence/discover-admin-browser-evidence.mjs',
    'scripts/evidence/admin-session-token.mjs',
  ])('has valid Node syntax: %s', (path) => {
    expect(() => execFileSync(process.execPath, ['--check', path], { stdio: 'pipe' })).not.toThrow()
  })
})
