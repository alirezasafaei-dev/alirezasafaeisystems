import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

const read = (path: string) => readFileSync(resolve(process.cwd(), path), 'utf8')

describe('V3.1 visual evidence contract', () => {
  it('captures the complete public review matrix under the stable evidence directory', () => {
    const visual = read('e2e/public-v31-visual.spec.ts')

    expect(visual).toContain('test-results/v31-evidence/')
    for (const file of [
      'home-fa-1440.png',
      'home-fa-390.png',
      'home-en-1440.png',
      'home-en-390.png',
      'discover-fa-1440.png',
      'discover-fa-390.png',
      'discover-detail.png',
      'blog-landing.png',
      'blog-article.png',
      'focus-state.png',
      'admin-dashboard-desktop.png',
    ]) {
      expect(visual).toContain(file)
    }
  })

  it('hydrates lazy media before full-page screenshot capture', () => {
    const visual = read('e2e/public-v31-visual.spec.ts')

    expect(visual).toContain('async function hydrateLazyMedia')
    expect(visual).toContain('await hydrateLazyMedia(page)')
    expect(visual).toContain('window.scrollTo')
  })

  it('measures rendered image tone and variance before accepting project proof', () => {
    const visual = read('e2e/public-v31-visual.spec.ts')

    expect(visual).toContain('sampleRenderedImageStats')
    expect(visual).toContain('nonNearWhiteRatio')
    expect(visual).toContain('luminanceVariance')
    expect(visual).toContain('tonalRange')
    expect(visual).toContain('edgeDensity')
    expect(visual).toContain('activeCellRatio')
    expect(visual).toContain('quantizedColorCount')
    expect(visual).toContain('real project imagery stays visibly non-empty in rendered evidence')
  })

  it('does not start heavy visual work after cancellation but still preserves upload-on-failure semantics', () => {
    const workflow = read('.github/workflows/e2e-smoke.yml')

    expect(workflow).toContain('- name: Run V3.1 visual contract\n        if: ${{ !cancelled() }}')
    expect(workflow).toContain('- name: Upload V3.1 visual evidence\n        if: always()')
  })

  it('uploads screenshot evidence for every SHA even when visual verification fails', () => {
    const workflow = read('.github/workflows/e2e-smoke.yml')

    expect(workflow).toContain('actions/upload-artifact@v4')
    expect(workflow).toContain('test-results/v31-evidence')
    expect(workflow).toContain('v31-visual-evidence-${{ github.sha }}')
    expect(workflow).toContain('if-no-files-found: error')
  })

  it('keeps production cookie security intact and adapts only the disposable browser context', () => {
    const visual = read('e2e/public-v31-visual.spec.ts')
    const auth = read('src/lib/admin-auth.ts')

    expect(auth).toContain("secure: env.NODE_ENV === 'production'")
    expect(visual).toContain("headers()['set-cookie']")
    expect(visual).toContain('page.context().addCookies')
    expect(visual).toContain('secure: false')
  })

  it('never hardcodes an admin credential in the visual evidence test', () => {
    const visual = read('e2e/public-v31-visual.spec.ts')

    expect(visual).toContain('process.env.ADMIN_USERNAME')
    expect(visual).toContain('process.env.ADMIN_PASSWORD')
    expect(visual).not.toMatch(/ADMIN_PASSWORD\s*=\s*['"][^'"]+['"]/)
  })
})
