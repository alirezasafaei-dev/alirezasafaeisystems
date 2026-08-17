import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('self-hosted CI ripgrep bootstrap', () => {
  it('provisions a verified job-local scanner before the enterprise gate', () => {
    const root = process.cwd()
    const helperPath = resolve(root, 'scripts/ci/bootstrap-ripgrep.sh')
    const workflowPath = resolve(root, '.github/workflows/ci.yml')

    expect(existsSync(helperPath), 'CI must provide its required ripgrep scanner').toBe(true)
    if (!existsSync(helperPath)) return

    const helper = readFileSync(helperPath, 'utf8')
    const workflow = readFileSync(workflowPath, 'utf8')
    const bootstrapIndex = workflow.indexOf('bash scripts/ci/bootstrap-ripgrep.sh')
    const enterpriseGateIndex = workflow.indexOf('pnpm run enterprise:gate')

    expect(bootstrapIndex).toBeGreaterThan(-1)
    expect(enterpriseGateIndex).toBeGreaterThan(bootstrapIndex)
    expect(helper).toContain('RIPGREP_VERSION="14.1.1"')
    expect(helper).toContain('RIPGREP_TARGET="x86_64-unknown-linux-musl"')
    expect(helper).toContain('RIPGREP_ARCHIVE="ripgrep-${RIPGREP_VERSION}-${RIPGREP_TARGET}.tar.gz"')
    expect(helper).toContain('RIPGREP_CHECKSUM="ripgrep-${RIPGREP_VERSION}-${RIPGREP_TARGET}.tar.gz.sha256"')
    expect(helper).toContain('sha256sum -c')
    expect(helper).toContain('GITHUB_PATH')
    expect(helper).not.toContain('sudo ')
    expect(helper).not.toContain('apt-get')
  })
})
