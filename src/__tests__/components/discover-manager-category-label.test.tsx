import { render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { DiscoverManager } from '@/components/admin/discover-manager'
import { I18nProvider } from '@/lib/i18n-context'

vi.mock('@/hooks/use-toast', () => ({ toast: vi.fn() }))

const item = {
  id: 'discover-item-category-0001',
  slug: 'ai-tool',
  title: 'ابزار هوش مصنوعی',
  description: 'توضیح',
  content: 'راهنما',
  titleEn: null,
  descriptionEn: null,
  contentEn: null,
  externalUrl: 'https://example.com/tool',
  category: 'ai',
  tags: 'ai',
  imageUrl: null,
  instagramUrl: null,
  telegramGuideUrl: null,
  featured: false,
  published: true,
  publishedEn: false,
  order: 1,
  publishedAt: '2026-08-20T00:00:00.000Z',
  createdAt: '2026-08-20T00:00:00.000Z',
  updatedAt: '2026-08-20T00:00:00.000Z',
}

describe('DiscoverManager category labels', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('shows the Persian category label instead of the canonical database key', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ items: [item] }),
    } as Response))

    render(
      <I18nProvider initialLanguage="fa">
        <DiscoverManager />
      </I18nProvider>,
    )

    expect(await screen.findByText('هوش مصنوعی')).toBeInTheDocument()
    expect(screen.queryByText('ai', { exact: true })).not.toBeInTheDocument()
  })
})
