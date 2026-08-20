import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { DiscoverManager } from '@/components/admin/discover-manager'

const { toastMock } = vi.hoisted(() => ({ toastMock: vi.fn() }))
vi.mock('@/hooks/use-toast', () => ({ toast: toastMock }))

const draftItem = { id: 'discover-item-0001', slug: 'draft-tool', title: 'ابزار پیش‌نویس', description: 'توضیح پیش‌نویس', content: 'راهنمای پیش‌نویس', titleEn: null, descriptionEn: null, contentEn: null, externalUrl: 'https://example.com/draft', category: 'ai', tags: 'ai,draft', imageUrl: null, instagramUrl: null, telegramGuideUrl: 'https://t.me/asdev/123', featured: false, published: false, publishedEn: false, order: 2, publishedAt: null, createdAt: '2026-08-17T00:00:00.000Z', updatedAt: '2026-08-17T00:00:00.000Z' }
const publishedItem = { ...draftItem, id: 'discover-item-0002', slug: 'published-tool', title: 'ابزار منتشرشده', published: true, featured: true, order: 1, publishedAt: '2026-08-17T00:00:00.000Z' }

function jsonResponse(body: unknown, status = 200): Response { return { ok: status >= 200 && status < 300, status, json: async () => body } as Response }

describe('DiscoverManager', () => {
  let confirmMock: ReturnType<typeof vi.fn>
  beforeEach(() => { toastMock.mockReset(); confirmMock = vi.fn().mockReturnValue(true); vi.stubGlobal('scrollTo', vi.fn()); vi.stubGlobal('confirm', confirmMock) })
  afterEach(() => { vi.unstubAllGlobals(); vi.restoreAllMocks() })

  it('loads draft/published rows and exposes the required Persian-first editor fields', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({ items: [draftItem, publishedItem] })); vi.stubGlobal('fetch', fetchMock)
    render(<DiscoverManager />)
    expect(await screen.findByText('ابزار پیش‌نویس')).toBeInTheDocument(); expect(screen.getByText('ابزار منتشرشده')).toBeInTheDocument(); expect(screen.getByText('پیش‌نویس')).toBeInTheDocument(); expect(screen.getByText('منتشرشده')).toBeInTheDocument()
    expect(screen.getByLabelText('عنوان فارسی')).toBeRequired(); expect(screen.getByLabelText('نامک')).toBeRequired(); expect(screen.getByLabelText('دسته‌بندی')).toBeRequired(); expect(screen.getByLabelText('توضیح فارسی')).toBeRequired(); expect(screen.getByLabelText('راهنمای فارسی')).toBeRequired(); expect(screen.getByLabelText('نشانی رسمی HTTPS')).toBeRequired(); expect(screen.getByLabelText('نشانی تلگرام')).toBeInTheDocument(); expect(screen.getByLabelText('انتشار فارسی')).toBeInTheDocument(); expect(screen.getByLabelText('ویژه')).toBeInTheDocument()
    expect(screen.getByLabelText('نامک')).toHaveAttribute('dir', 'ltr'); expect(screen.getByLabelText('نشانی تلگرام')).toHaveAttribute('dir', 'ltr'); expect(fetchMock).toHaveBeenCalledWith('/api/admin/discover?published=all', { cache: 'no-store' })
  })

  it('creates a Discover item as JSON through the dedicated admin endpoint', async () => {
    const saved = { ...draftItem, id: 'discover-item-0003', slug: 'new-tool', title: 'ابزار جدید', description: 'ابزار کاربردی', content: 'برای کار متمرکز استفاده کنید.', externalUrl: 'https://example.com/new-tool', telegramGuideUrl: 'https://t.me/asdev/456', category: 'productivity', tags: 'focus,work', order: 3 }
    const fetchMock = vi.fn().mockResolvedValueOnce(jsonResponse({ items: [] })).mockResolvedValueOnce(jsonResponse({ item: saved }, 201)); vi.stubGlobal('fetch', fetchMock)
    render(<DiscoverManager />); await screen.findByText('0 آیتم')
    fireEvent.change(screen.getByLabelText('عنوان فارسی'), { target: { value: 'ابزار جدید' } }); fireEvent.change(screen.getByLabelText('نامک'), { target: { value: 'new-tool' } }); fireEvent.change(screen.getByLabelText('دسته‌بندی'), { target: { value: 'productivity' } }); fireEvent.change(screen.getByLabelText('برچسب‌ها'), { target: { value: 'focus,work' } }); fireEvent.change(screen.getByLabelText('توضیح فارسی'), { target: { value: 'ابزار کاربردی' } }); fireEvent.change(screen.getByLabelText('راهنمای فارسی'), { target: { value: 'برای کار متمرکز استفاده کنید.' } }); fireEvent.change(screen.getByLabelText('نشانی رسمی HTTPS'), { target: { value: 'https://example.com/new-tool' } }); fireEvent.change(screen.getByLabelText('نشانی تلگرام'), { target: { value: 'https://t.me/asdev/456' } }); fireEvent.change(screen.getByLabelText('ترتیب نمایش'), { target: { value: '3' } }); fireEvent.click(screen.getByRole('button', { name: 'ذخیره آیتم' }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2)); const [, request] = fetchMock.mock.calls[1] as [string, RequestInit]; expect(request.method).toBe('POST'); expect(request.headers).toEqual({ 'Content-Type': 'application/json' }); expect(JSON.parse(String(request.body))).toMatchObject({ slug: 'new-tool', title: 'ابزار جدید', category: 'productivity', tags: 'focus,work', description: 'ابزار کاربردی', content: 'برای کار متمرکز استفاده کنید.', externalUrl: 'https://example.com/new-tool', telegramGuideUrl: 'https://t.me/asdev/456', published: false, featured: false, order: 3 }); expect((await screen.findAllByText('ابزار جدید')).length).toBeGreaterThan(1); expect(toastMock).toHaveBeenCalledWith(expect.objectContaining({ title: 'ذخیره شد' }))
  })

  it('loads and clears an existing Telegram guide in edit mode before deletion', async () => {
    const updated = { ...draftItem, title: 'ابزار به‌روز', telegramGuideUrl: null }; const fetchMock = vi.fn().mockResolvedValueOnce(jsonResponse({ items: [draftItem] })).mockResolvedValueOnce(jsonResponse({ item: updated })).mockResolvedValueOnce(jsonResponse({ success: true })); vi.stubGlobal('fetch', fetchMock)
    render(<DiscoverManager />); expect(await screen.findByText('ابزار پیش‌نویس')).toBeInTheDocument(); fireEvent.click(screen.getByRole('button', { name: 'ویرایش' })); expect(screen.getByText('ویرایش آیتم Discover')).toBeInTheDocument(); expect(screen.getByLabelText('عنوان فارسی')).toHaveValue('ابزار پیش‌نویس'); expect(screen.getByLabelText('نامک')).toHaveValue('draft-tool'); expect(screen.getByLabelText('نشانی تلگرام')).toHaveValue('https://t.me/asdev/123')
    fireEvent.change(screen.getByLabelText('عنوان فارسی'), { target: { value: 'ابزار به‌روز' } }); fireEvent.change(screen.getByLabelText('نشانی تلگرام'), { target: { value: '' } }); fireEvent.click(screen.getByRole('button', { name: 'ذخیره آیتم' })); await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2)); expect(fetchMock.mock.calls[1]?.[0]).toBe('/api/admin/discover'); expect((fetchMock.mock.calls[1]?.[1] as RequestInit).method).toBe('PATCH'); expect(JSON.parse(String((fetchMock.mock.calls[1]?.[1] as RequestInit).body))).toMatchObject({ id: 'discover-item-0001', telegramGuideUrl: '' })
    const deleteButton = await screen.findByRole('button', { name: 'Delete ابزار به‌روز' }); fireEvent.click(deleteButton); await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3)); expect(confirmMock).toHaveBeenCalledWith('Delete “ابزار به‌روز” permanently?'); expect(fetchMock.mock.calls[2]?.[0]).toBe('/api/admin/discover?id=discover-item-0001'); expect((fetchMock.mock.calls[2]?.[1] as RequestInit).method).toBe('DELETE')
  })
})
