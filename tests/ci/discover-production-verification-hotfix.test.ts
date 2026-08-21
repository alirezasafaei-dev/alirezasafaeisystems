import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('Discover production verification hotfix contracts', () => {
  it('treats an empty published Discover catalog as a warning instead of a deployment failure', () => {
    const verifier = readFileSync(resolve(process.cwd(), 'scripts/deploy/live-verify.mjs'), 'utf8')

    expect(verifier).toContain("warnings.push(`${discoverPath}: no published Discover detail link; detail verification skipped`)")
    expect(verifier).toContain('if (detailCount < 1) {')
    expect(verifier).not.toContain('if (detailCount < 1) throw new Error(`${discoverPath} has no published Discover detail link`)')
  })

  it('verifies the Admin auth boundary using a locale-independent structural marker', () => {
    const verifier = readFileSync(resolve(process.cwd(), 'scripts/deploy/live-verify.mjs'), 'utf8')

    expect(verifier).toContain("page.getByTestId('admin-login-form')")
    expect(verifier).not.toContain("page.getByText('Admin Login'")
  })

  it('passes the request CSP nonce on the ThemeProvider opening tag so its inline bootstrap script is permitted', () => {
    const layout = readFileSync(resolve(process.cwd(), 'src/app/layout.tsx'), 'utf8')

    expect(layout).toMatch(/<ThemeProvider[\s\S]*?nonce=\{nonce\}[\s\S]*?>/)
  })

  it('clips the Discover aurora decoration so it cannot expand the mobile document width', () => {
    const page = readFileSync(resolve(process.cwd(), 'src/app/discover/page.tsx'), 'utf8')

    expect(page).toContain('section-surface aurora-shell overflow-hidden')
  })

  it('waits for the current route network to settle before intentional navigation can abort its own chunks', () => {
    const verifier = readFileSync(resolve(process.cwd(), 'scripts/deploy/live-verify.mjs'), 'utf8')

    expect(verifier).toContain("waitUntil: 'networkidle'")
  })
})
