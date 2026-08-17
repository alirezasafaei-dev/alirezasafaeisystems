import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

const portableWorkflows = [
  '.github/workflows/ci.yml',
  '.github/workflows/ci-router.yml',
  '.github/workflows/e2e-smoke.yml',
  '.github/workflows/lighthouse.yml',
  '.github/workflows/security-audit.yml',
  '.github/workflows/codeql.yml',
]

describe('verification runner contract', () => {
  it.each(portableWorkflows)('%s uses GitHub-hosted capacity', (workflowPath) => {
    const workflow = readFileSync(resolve(process.cwd(), workflowPath), 'utf8')

    expect(workflow).toContain('runs-on: ubuntu-latest')
    expect(workflow).not.toContain('runs-on: [self-hosted, linux, x64, asdev-ci]')
  })

  it('keeps host diagnostics on the dedicated self-hosted runner', () => {
    const diagnostic = readFileSync(
      resolve(process.cwd(), '.github/workflows/self-hosted-diagnostic.yml'),
      'utf8'
    )

    expect(diagnostic).toContain('runs-on: [self-hosted, linux, x64, asdev-ci]')
  })
})
