import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { DiscoverManager } from '@/components/admin/discover-manager'

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
})
