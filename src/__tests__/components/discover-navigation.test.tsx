import { fireEvent, render, screen, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { Header } from '@/components/layout/header'
import { Footer } from '@/components/layout/footer'
import { I18nProvider } from '@/lib/i18n-context'

vi.mock('next/navigation', () => ({
  usePathname: () => '/',
  useRouter: () => ({ push: vi.fn(), refresh: vi.fn() }),
}))

function PersianProvider({ children }: { children: React.ReactNode }) {
  return <I18nProvider initialLanguage="fa">{children}</I18nProvider>
}

function EnglishProvider({ children }: { children: React.ReactNode }) {
  return <I18nProvider initialLanguage="en">{children}</I18nProvider>
}

describe('Discover navigation localization', () => {
  beforeEach(() => {
    document.cookie = 'lang=; Path=/; Max-Age=0'
  })

  it('renders the Persian Discover label in desktop header and footer links', () => {
    const { container } = render(<><Header /><Footer /></>, { wrapper: PersianProvider })
    const header = container.querySelector('header')
    const footer = container.querySelector('footer')

    expect(header).not.toBeNull()
    expect(footer).not.toBeNull()
    expect(within(header as HTMLElement).getByRole('link', { name: 'ابزارها و منابع' })).toBeInTheDocument()
    expect(within(footer as HTMLElement).getByRole('link', { name: /ابزارها و منابع/ })).toBeInTheDocument()
  })

  it('renders the Persian Discover label in the mobile navigation', () => {
    render(<Header />, { wrapper: PersianProvider })

    fireEvent.click(screen.getByRole('button', { name: 'باز کردن منو' }))
    expect(screen.getByRole('link', { name: 'ابزارها و منابع' })).toBeInTheDocument()
  })

  it('renders English Discover links in desktop, mobile, and footer navigation', () => {
    document.cookie = 'lang=en; Path=/'
    const { container } = render(<><Header /><Footer /></>, { wrapper: EnglishProvider })

    expect(within(container.querySelector('header') as HTMLElement).getByRole('link', { name: 'Discover' })).toBeInTheDocument()
    expect(within(container.querySelector('footer') as HTMLElement).getByRole('link', { name: /Discover/ })).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Open menu' }))
    expect(screen.getByRole('link', { name: 'Discover' })).toBeInTheDocument()
  })
})
