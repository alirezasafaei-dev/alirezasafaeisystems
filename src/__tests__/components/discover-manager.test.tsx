import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { DiscoverManager } from '@/components/admin/discover-manager'

const { toastMock } = vi.hoisted(() => ({ toastMock: vi.fn() }))
vi.mock('@/hooks/use-toast', () => ({ toast: toastMock }))

const draftItem = {
  id: 'discover-item-0001',
  slug: 'draft-tool',
  title: 'Draft Tool',
  description: 'Draft description',
  content: 'Draft guide',
  externalUrl: 'https://example.com/draft',
  category: 'AI',
  tags: 'ai,draft',
  imageUrl: null,
  instagramUrl: null,
  featured: false,
  published: false,
  order: 2,
  publishedAt: null,
  createdAt: '2026-08-17T00:00:00.000Z',
  updatedAt: '2026-08-17T00:00:00.000Z',
}

const publishedItem = {
  ...draftItem,
  id: 'discover-item-0002',
  slug: 'published-tool',
  title: 'Published Tool',
  published: true,
  featured: true,
  order: 1,
  publishedAt: '2026-08-17T00:00:00.000Z',
}

function jsonResponse(body: unknown, status = 200): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => body,
  } as Response
}

describe('DiscoverManager', () => {
  let confirmMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    toastMock.mockReset()
    confirmMock = vi.fn().mockReturnValue(true)
    vi.stubGlobal('scrollTo', vi.fn())
    vi.stubGlobal('confirm', confirmMock)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('loads draft/published items and exposes the required editor fields', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse({ items: [draftItem, publishedItem] }))
    vi.stubGlobal('fetch', fetchMock)

    render(<DiscoverManager />)

    expect(await screen.findByText('Draft Tool')).toBeInTheDocument()
    expect(screen.getByText('Published Tool')).toBeInTheDocument()
    expect(screen.getByText('Draft')).toBeInTheDocument()
    expect(screen.getAllByText('Published').length).toBeGreaterThan(0)

    expect(screen.getByLabelText('Title')).toBeRequired()
    expect(screen.getByLabelText('Slug')).toBeRequired()
    expect(screen.getByLabelText('Category')).toBeRequired()
    expect(screen.getByLabelText('Short description')).toBeRequired()
    expect(screen.getByLabelText('Short practical guide')).toBeRequired()
    expect(screen.getByLabelText('Official HTTPS URL')).toBeRequired()
    expect(screen.getByLabelText('Published')).toBeInTheDocument()
    expect(screen.getByLabelText('Featured')).toBeInTheDocument()

    expect(fetchMock).toHaveBeenCalledWith('/api/admin/discover?published=all', { cache: 'no-store' })
  })

  it('creates a Discover item as JSON through the dedicated admin endpoint', async () => {
    const saved = {
      ...draftItem,
      id: 'discover-item-0003',
      slug: 'new-tool',
      title: 'New Tool',
      description: 'Useful tool',
      content: 'Use it for focused work.',
      externalUrl: 'https://example.com/new-tool',
      category: 'Productivity',
      tags: 'focus,work',
      order: 3,
    }
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(jsonResponse({ items: [] }))
      .mockResolvedValueOnce(jsonResponse({ item: saved }, 201))
    vi.stubGlobal('fetch', fetchMock)

    render(<DiscoverManager />)
    await screen.findByText('0 item(s)')

    fireEvent.change(screen.getByLabelText('Title'), { target: { value: 'New Tool' } })
    fireEvent.change(screen.getByLabelText('Slug'), { target: { value: 'new-tool' } })
    fireEvent.change(screen.getByLabelText('Category'), { target: { value: 'Productivity' } })
    fireEvent.change(screen.getByLabelText('Tags'), { target: { value: 'focus,work' } })
    fireEvent.change(screen.getByLabelText('Short description'), { target: { value: 'Useful tool' } })
    fireEvent.change(screen.getByLabelText('Short practical guide'), { target: { value: 'Use it for focused work.' } })
    fireEvent.change(screen.getByLabelText('Official HTTPS URL'), { target: { value: 'https://example.com/new-tool' } })
    fireEvent.change(screen.getByLabelText('Sort order'), { target: { value: '3' } })
    fireEvent.click(screen.getByRole('button', { name: /Save Discover item/i }))

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    const [, request] = fetchMock.mock.calls[1] as [string, RequestInit]
    expect(request.method).toBe('POST')
    expect(request.headers).toEqual({ 'Content-Type': 'application/json' })
    expect(JSON.parse(String(request.body))).toMatchObject({
      slug: 'new-tool',
      title: 'New Tool',
      category: 'Productivity',
      tags: 'focus,work',
      description: 'Useful tool',
      content: 'Use it for focused work.',
      externalUrl: 'https://example.com/new-tool',
      published: false,
      featured: false,
      order: 3,
    })
    expect(await screen.findByText('New Tool')).toBeInTheDocument()
    expect(toastMock).toHaveBeenCalledWith(expect.objectContaining({ title: 'Saved' }))
  })

  it('loads an existing item into edit mode and confirms deletion before issuing DELETE', async () => {
    const updated = { ...draftItem, title: 'Draft Tool Updated' }
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(jsonResponse({ items: [draftItem] }))
      .mockResolvedValueOnce(jsonResponse({ item: updated }))
      .mockResolvedValueOnce(jsonResponse({ success: true }))
    vi.stubGlobal('fetch', fetchMock)

    render(<DiscoverManager />)
    expect(await screen.findByText('Draft Tool')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /Edit/i }))
    expect(screen.getByText('Edit Discover item')).toBeInTheDocument()
    expect(screen.getByLabelText('Title')).toHaveValue('Draft Tool')
    expect(screen.getByLabelText('Slug')).toHaveValue('draft-tool')

    fireEvent.change(screen.getByLabelText('Title'), { target: { value: 'Draft Tool Updated' } })
    fireEvent.click(screen.getByRole('button', { name: /Save Discover item/i }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(fetchMock.mock.calls[1]?.[0]).toBe('/api/admin/discover')
    expect((fetchMock.mock.calls[1]?.[1] as RequestInit).method).toBe('PATCH')

    fireEvent.click(screen.getByRole('button', { name: 'Delete Draft Tool Updated' }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3))
    expect(confirmMock).toHaveBeenCalledWith('Delete “Draft Tool Updated” permanently?')
    expect(fetchMock.mock.calls[2]?.[0]).toBe('/api/admin/discover?id=discover-item-0001')
    expect((fetchMock.mock.calls[2]?.[1] as RequestInit).method).toBe('DELETE')
  })
})
