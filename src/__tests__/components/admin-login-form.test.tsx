import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AdminLoginForm } from '@/components/admin/admin-login-form'
import { I18nProvider } from '@/lib/i18n-context'

const router = { push: vi.fn(), refresh: vi.fn() }
let query = new URLSearchParams()

vi.mock('next/navigation', () => ({
  useRouter: () => router,
  useSearchParams: () => query,
}))

function renderLogin(language: 'fa' | 'en') {
  document.cookie = `lang=${language}; Path=/`
  return render(
    <I18nProvider initialLanguage={language}>
      <AdminLoginForm />
    </I18nProvider>,
  )
}

describe('AdminLoginForm localization', () => {
  beforeEach(() => {
    router.push.mockReset()
    router.refresh.mockReset()
    query = new URLSearchParams()
    document.cookie = 'lang=; Path=/; Max-Age=0'
  })

  it('renders Persian login copy and RTL direction', () => {
    renderLogin('fa')

    expect(screen.getByTestId('admin-login-form')).toHaveAttribute('dir', 'rtl')
    expect(screen.getByText('ورود مدیریت', { exact: true })).toBeInTheDocument()
    expect(screen.getByLabelText('نام کاربری')).toBeInTheDocument()
    expect(screen.getByLabelText('رمز عبور')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'ورود' })).toBeInTheDocument()
  })

  it('renders English login copy and LTR direction', () => {
    renderLogin('en')

    expect(screen.getByTestId('admin-login-form')).toHaveAttribute('dir', 'ltr')
    expect(screen.getByText('Admin Login', { exact: true })).toBeInTheDocument()
    expect(screen.getByLabelText('Username')).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Sign in' })).toBeInTheDocument()
  })

  it('localizes the auth-not-configured error', () => {
    query = new URLSearchParams('error=auth_not_configured')
    renderLogin('fa')

    expect(screen.getByText('احراز هویت مدیریت در این محیط پیکربندی نشده است.')).toBeInTheDocument()
  })
})
