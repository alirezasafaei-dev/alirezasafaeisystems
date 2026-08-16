import { existsSync, readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'

function source(path: string): string {
  return readFileSync(path, 'utf8')
}

describe('Discover acquisition surface contract', () => {
  it('has a dedicated DiscoverItem data model instead of storing new Discover content as projects', () => {
    const schema = source('prisma/schema.prisma')

    expect(schema).toContain('model DiscoverItem {')
    expect(schema).toContain('slug         String')
    expect(schema).toContain('externalUrl')
    expect(schema).toContain('instagramUrl')
  })

  it('has an internal detail route and a dedicated authenticated admin API', () => {
    expect(existsSync('src/app/discover/[slug]/page.tsx')).toBe(true)
    expect(existsSync('src/app/api/admin/discover/route.ts')).toBe(true)
  })

  it('positions the landing page as a social acquisition surface rather than a project directory', () => {
    const landing = source('src/app/discover/page.tsx')

    expect(landing).toContain('DiscoverGrid')
    expect(landing).toContain('discover_landing_view')
    expect(landing).not.toContain('مشاهده پروژه')
  })

  it('exposes Discover as its own Admin tab instead of nesting it inside Portfolio projects', () => {
    const dashboard = source('src/components/admin/admin-dashboard.tsx')
    const projectManager = source('src/components/admin/project-manager.tsx')

    expect(dashboard).toContain("'discover'")
    expect(dashboard).toContain('DiscoverManager')
    expect(dashboard).toContain("activeTab === 'discover'")
    expect(projectManager).not.toContain('DiscoverManager')
  })

  it('allows curated HTTPS Discover images through the site CSP', () => {
    const proxy = source('src/proxy.ts')

    expect(proxy).toContain('"img-src \'self\' data: blob: https:"')
  })

  it('documents Discover as an ASDEV acquisition surface in the focus policy', () => {
    const focusPolicy = source('docs/strategy/FOCUS_POLICY.md')

    expect(focusPolicy).toContain('Discover')
    expect(focusPolicy.toLowerCase()).toContain('acquisition')
  })
})
