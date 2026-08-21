import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ProjectManager } from '@/components/admin/project-manager'
import { I18nProvider } from '@/lib/i18n-context'

const toastMock = vi.fn()
vi.mock('@/hooks/use-toast', () => ({ toast: toastMock }))

function response(body: unknown, status = 200): Response {
  return { ok: status >= 200 && status < 300, status, json: async () => body } as Response
}

function renderManager(language: 'fa' | 'en', fetchMock: ReturnType<typeof vi.fn>) {
  document.cookie = `lang=${language}; Path=/`
  vi.stubGlobal('fetch', fetchMock)
  return render(
    <I18nProvider initialLanguage={language}>
      <ProjectManager />
    </I18nProvider>,
  )
}

describe('ProjectManager localization', () => {
  beforeEach(() => {
    toastMock.mockReset()
    document.cookie = 'lang=; Path=/; Max-Age=0'
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('renders Persian project copy with RTL direction', async () => {
    const fetchMock = vi.fn().mockResolvedValue(response({ projects: [] }))
    renderManager('fa', fetchMock)

    expect(screen.getByTestId('project-manager')).toHaveAttribute('dir', 'rtl')
    expect(screen.getByRole('heading', { name: 'پروژه نمونه‌کار جدید' })).toBeInTheDocument()
    expect(screen.getByText('پروژه‌های نمونه‌کار')).toBeInTheDocument()
    expect(await screen.findByText('هنوز پروژه نمونه‌کاری ثبت نشده است.')).toBeInTheDocument()
  })

  it('renders English project copy with LTR direction', async () => {
    const fetchMock = vi.fn().mockResolvedValue(response({ projects: [] }))
    renderManager('en', fetchMock)

    expect(screen.getByTestId('project-manager')).toHaveAttribute('dir', 'ltr')
    expect(screen.getByRole('heading', { name: 'New portfolio project' })).toBeInTheDocument()
    expect(await screen.findByText('No portfolio projects yet.')).toBeInTheDocument()
  })

  it('keeps the canonical portfolio content type in the localized save request', async () => {
    const fetchMock = vi.fn()
      .mockResolvedValueOnce(response({ projects: [] }))
      .mockResolvedValueOnce(response({
        project: {
          id: 'project-1',
          title: 'نمونه',
          description: 'توضیح',
          longDescription: null,
          githubUrl: null,
          liveUrl: null,
          tags: '',
          contentType: 'portfolio',
          featured: false,
          published: false,
          order: 0,
        },
      }, 201))
    renderManager('fa', fetchMock)
    await screen.findByText('هنوز پروژه نمونه‌کاری ثبت نشده است.')

    fireEvent.change(screen.getByLabelText('عنوان'), { target: { value: 'نمونه' } })
    fireEvent.change(screen.getByLabelText('توضیح کوتاه'), { target: { value: 'توضیح' } })
    fireEvent.click(screen.getByRole('button', { name: 'ذخیره پروژه' }))

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    const saveCall = fetchMock.mock.calls[1] as [string, RequestInit]
    expect(saveCall[0]).toBe('/api/admin/projects')
    expect(JSON.parse(String(saveCall[1].body))).toMatchObject({
      title: 'نمونه',
      description: 'توضیح',
      contentType: 'portfolio',
    })
  })
})
