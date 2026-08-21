import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { AdminDashboard } from '@/components/admin/admin-dashboard'
import { I18nProvider } from '@/lib/i18n-context'

const router = { replace: vi.fn(), refresh: vi.fn() }
const toastMock = vi.fn()

vi.mock('next/navigation', () => ({ useRouter: () => router }))
vi.mock('@/hooks/use-toast', () => ({ toast: toastMock }))

const lead = {
  id: 'lead-1',
  status: 'qualified',
  source: 'qualification',
  contactName: 'Ali',
  organizationName: 'ASDEV Test',
  organizationType: 'software_company',
  email: 'ali@example.com',
  phone: null,
  teamSize: '2-5',
  currentStack: 'Next.js',
  criticalRisk: 'Deployment risk',
  timeline: '1-month',
  budgetRange: '60-120m-irr',
  preferredContact: 'email',
  notes: null,
  attachmentPath: null,
  utmSource: null,
  utmMedium: null,
  utmCampaign: null,
  createdAt: '2026-08-21T08:00:00.000Z',
  updatedAt: '2026-08-21T08:00:00.000Z',
}

const message = {
  id: 'message-1',
  name: 'Test User',
  email: 'test@example.com',
  subject: 'Hello',
  message: 'Test',
  createdAt: '2026-08-21T08:00:00.000Z',
}

function response(body: unknown, status = 200): Response {
  return { ok: status >= 200 && status < 300, status, json: async () => body } as Response
}

function installFetchMock() {
  const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input)
    if (url === '/api/admin/leads' && init?.method === 'PATCH') {
      const payload = JSON.parse(String(init.body)) as { id: string; status: string }
      return response({ lead: { ...lead, status: payload.status } })
    }
    if (url === '/api/admin/leads') return response({ leads: [lead] })
    if (url === '/api/admin/messages') return response({ messages: [message] })
    if (url.startsWith('/api/admin/messages?id=')) return response({ success: true })
    return response({}, 404)
  })
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

function renderDashboard(language: 'fa' | 'en') {
  document.cookie = `lang=${language}; Path=/`
  return render(
    <I18nProvider initialLanguage={language}>
      <AdminDashboard />
    </I18nProvider>,
  )
}

describe('AdminDashboard localization', () => {
  beforeEach(() => {
    router.replace.mockReset()
    router.refresh.mockReset()
    toastMock.mockReset()
    document.cookie = 'lang=; Path=/; Max-Age=0'
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('renders Persian shell/status copy with RTL direction', async () => {
    installFetchMock()
    renderDashboard('fa')

    expect(screen.getByTestId('admin-dashboard')).toHaveAttribute('dir', 'rtl')
    expect(screen.getByRole('heading', { name: 'داشبورد مدیریت' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /سرنخ‌ها/ })).toBeInTheDocument()
    expect(await screen.findByText('ASDEV Test')).toBeInTheDocument()
    expect(screen.getAllByText('واجد شرایط').length).toBeGreaterThan(0)
  })

  it('renders English shell/status copy with LTR direction', async () => {
    installFetchMock()
    renderDashboard('en')

    expect(screen.getByTestId('admin-dashboard')).toHaveAttribute('dir', 'ltr')
    expect(screen.getByRole('heading', { name: 'Admin Dashboard' })).toBeInTheDocument()
    expect(await screen.findByText('ASDEV Test')).toBeInTheDocument()
    expect(screen.getAllByText('Qualified').length).toBeGreaterThan(0)
  })

  it('keeps the canonical status value in PATCH while localizing the action label', async () => {
    const fetchMock = installFetchMock()
    renderDashboard('fa')
    await screen.findByText('ASDEV Test')

    fireEvent.click(screen.getByRole('button', { name: 'بایگانی' }))

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith('/api/admin/leads', expect.objectContaining({
        method: 'PATCH',
        body: JSON.stringify({ id: 'lead-1', status: 'archived' }),
      }))
    })
  })
})
