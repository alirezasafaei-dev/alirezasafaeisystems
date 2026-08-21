import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { DiscoverManager } from '@/components/admin/discover-manager'
import { DiscoverPreview } from '@/components/admin/discover/discover-preview'

const { toastMock } = vi.hoisted(() => ({ toastMock: vi.fn() }))
vi.mock('@/hooks/use-toast', () => ({ toast: toastMock }))

function response(body: unknown): Response {
  return { ok: true, status: 200, json: async () => body } as Response
}

describe('Discover editor', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('uses Persian-first directionality and stores category keys', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(response({ items: [] })))
    render(<DiscoverManager />)

    const editor = await screen.findByTestId('discover-editor')
    expect(editor).toHaveAttribute('dir', 'rtl')
    expect(screen.getByLabelText('عنوان فارسی')).toHaveAttribute('dir', 'rtl')
    expect(screen.getByLabelText('نامک')).toHaveAttribute('dir', 'ltr')
    expect(screen.getByLabelText('English title')).toHaveAttribute('dir', 'ltr')

    const category = screen.getByLabelText('دسته‌بندی') as HTMLSelectElement
    expect(screen.getByRole('option', { name: 'هوش مصنوعی' })).toHaveValue('ai')
    fireEvent.change(category, { target: { value: 'ai' } })
    expect(category.value).toBe('ai')
  })

  it('keeps English publishing disabled until every English field is complete', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(response({ items: [] })))
    render(<DiscoverManager />)
    await screen.findByTestId('discover-editor')

    const control = screen.getByLabelText('انتشار انگلیسی')
    expect(control).toBeDisabled()
    expect(control).toHaveAccessibleDescription('برای انتشار انگلیسی، عنوان، توضیح و راهنمای انگلیسی را کامل کنید.')

    fireEvent.change(screen.getByLabelText('English title'), { target: { value: 'NotebookLM' } })
    fireEvent.change(screen.getByLabelText('English description'), { target: { value: 'Research assistant' } })
    fireEvent.change(screen.getByLabelText('English guide'), { target: { value: 'Upload your sources.' } })
    await waitFor(() => expect(screen.getByLabelText('انتشار انگلیسی')).toBeEnabled())
  })

  it('shows a public preview link only for the selected published locale', () => {
    const value = { id: 'discover-item-0001', slug: 'tool', title: 'ابزار', description: 'توضیح', content: 'راهنما', titleEn: 'Tool', descriptionEn: 'Description', contentEn: 'Guide', externalUrl: 'https://example.com', category: 'ai', tags: '', imageUrl: '', instagramUrl: '', telegramGuideUrl: '', featured: false, published: true, publishedEn: false, order: 0 }
    render(<DiscoverPreview value={value} />)
    expect(screen.getByRole('link', { name: 'نمایش عمومی' })).toHaveAttribute('href', '/discover/tool')
    fireEvent.click(screen.getByRole('button', { name: 'انگلیسی' }))
    expect(screen.queryByRole('link', { name: 'نمایش عمومی' })).not.toBeInTheDocument()
  })
})
