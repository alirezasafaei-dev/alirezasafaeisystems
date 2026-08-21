import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { DiscoverManager } from '@/components/admin/discover-manager'

const { toastMock } = vi.hoisted(() => ({ toastMock: vi.fn() }))
vi.mock('@/hooks/use-toast', () => ({ toast: toastMock }))

const originalItem = {
  id: 'discover-item-0001',
  slug: 'draft-tool',
  title: 'نسخه اولیه',
  description: 'توضیح',
  content: 'راهنما',
  titleEn: null,
  descriptionEn: null,
  contentEn: null,
  externalUrl: 'https://example.com/draft',
  category: 'ai',
  tags: 'ai,draft',
  imageUrl: null,
  instagramUrl: null,
  telegramGuideUrl: null,
  featured: false,
  published: false,
  publishedEn: false,
  order: 1,
  publishedAt: null,
  createdAt: '2026-08-21T07:00:00.000Z',
  updatedAt: '2026-08-21T08:00:00.000Z',
}

const latestItem = {
  ...originalItem,
  title: 'نسخه جدید سرور',
  updatedAt: '2026-08-21T08:05:00.000Z',
}

function jsonResponse(body: unknown, status = 200): Response {
  return { ok: status >= 200 && status < 300, status, json: async () => body } as Response
}

describe('DiscoverManager stale-editor protection', () => {
  beforeEach(() => {
    toastMock.mockReset()
    vi.stubGlobal('scrollTo', vi.fn())
  })

  afterEach(() => {
    localStorage.clear()
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('sends updatedAt, preserves the local edit on 409, and offers an explicit reload of the latest server version', async () => {
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(jsonResponse({ items: [originalItem] }))
      .mockResolvedValueOnce(jsonResponse({ code: 'STALE_WRITE', error: 'This item changed on the server.' }, 409))
      .mockResolvedValueOnce(jsonResponse({ items: [latestItem] }))
    vi.stubGlobal('fetch', fetchMock)

    render(<DiscoverManager />)
    await screen.findByText('نسخه اولیه')
    fireEvent.click(screen.getByRole('button', { name: 'ویرایش' }))
    fireEvent.change(screen.getByLabelText('عنوان فارسی'), { target: { value: 'ویرایش محلی من' } })
    fireEvent.click(screen.getByRole('button', { name: 'ذخیره آیتم' }))

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    const patch = fetchMock.mock.calls[1] as [string, RequestInit]
    expect(patch[0]).toBe('/api/admin/discover')
    expect(JSON.parse(String(patch[1].body))).toMatchObject({
      id: originalItem.id,
      title: 'ویرایش محلی من',
      expectedUpdatedAt: originalItem.updatedAt,
    })
    expect(screen.getByLabelText('عنوان فارسی')).toHaveValue('ویرایش محلی من')
    expect(await screen.findByText(/نسخه جدیدتری از این آیتم روی سرور ذخیره شده/)).toBeInTheDocument()
    expect(document.querySelector('[aria-describedby="discover-slug-error"]')).toBeNull()

    fireEvent.click(screen.getByRole('button', { name: 'بارگذاری نسخه جدید سرور' }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3))
    expect(screen.getByLabelText('عنوان فارسی')).toHaveValue('نسخه جدید سرور')
  })
})