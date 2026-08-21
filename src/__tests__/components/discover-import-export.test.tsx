import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { DiscoverImportExport } from '@/components/admin/discover/discover-import-export'

const validPayload = {
  slug: 'notebooklm', title: 'نوت‌بوک ال‌ام', description: 'دستیار پژوهش', content: 'راهنمای کاربردی',
  titleEn: 'NotebookLM', descriptionEn: 'Research assistant', contentEn: 'Upload sources.',
  externalUrl: 'https://notebooklm.google.com/', category: 'ai', tags: 'ai, research', imageUrl: '',
  instagramUrl: '', telegramGuideUrl: '', featured: false, published: true, publishedEn: true, order: 1,
}

describe('Discover import and export', () => {
  it('imports only a production-schema-valid normalized payload', () => {
    const onImport = vi.fn()
    render(<DiscoverImportExport value={validPayload} onImport={onImport} />)
    fireEvent.change(screen.getByLabelText('JSON برای ورود'), { target: { value: JSON.stringify(validPayload) } })
    fireEvent.click(screen.getByRole('button', { name: 'ورود JSON' }))
    expect(onImport).toHaveBeenCalledWith(expect.objectContaining({ category: 'ai', tags: ['ai', 'research'] }))
  })

  it('shows an inline error instead of importing invalid JSON payloads', () => {
    const onImport = vi.fn()
    render(<DiscoverImportExport value={validPayload} onImport={onImport} />)
    fireEvent.change(screen.getByLabelText('JSON برای ورود'), { target: { value: '{' } })
    fireEvent.click(screen.getByRole('button', { name: 'ورود JSON' }))
    expect(onImport).not.toHaveBeenCalled()
    expect(screen.getByRole('alert')).toHaveTextContent('JSON معتبر نیست')
  })
})
