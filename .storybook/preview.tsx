import type { Preview } from '@storybook/nextjs-vite'
import { useEffect, type ReactNode } from 'react'
import '../src/app/globals.css'
import { I18nProvider } from '../src/lib/i18n-context'
import { ThemeProvider } from '../src/components/theme/theme-provider'

function StoryShell({
  children,
  locale,
  theme,
}: {
  children: ReactNode
  locale: 'fa' | 'en'
  theme: 'light' | 'dark'
}) {
  useEffect(() => {
    window.localStorage.setItem('language', locale)
    document.cookie = `lang=${locale}; Path=/; Max-Age=31536000; SameSite=Lax`
    document.documentElement.lang = locale
    document.documentElement.dir = locale === 'fa' ? 'rtl' : 'ltr'
  }, [locale])

  return (
    <ThemeProvider attribute="class" forcedTheme={theme} enableSystem={false}>
      <I18nProvider initialLanguage={locale}>
        <div className="min-h-screen bg-background text-foreground">{children}</div>
      </I18nProvider>
    </ThemeProvider>
  )
}

const preview: Preview = {
  parameters: {
    layout: 'fullscreen',
    nextjs: {
      appDirectory: true,
    },
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
  },
  globalTypes: {
    locale: {
      name: 'Locale',
      description: 'Interface language',
      defaultValue: 'fa',
      toolbar: {
        icon: 'globe',
        items: [
          { value: 'fa', title: 'فارسی' },
          { value: 'en', title: 'English' },
        ],
      },
    },
    theme: {
      name: 'Theme',
      description: 'Story theme',
      defaultValue: 'light',
      toolbar: {
        icon: 'mirror',
        items: [
          { value: 'light', title: 'Light' },
          { value: 'dark', title: 'Dark' },
        ],
      },
    },
  },
  decorators: [
    (Story, context) => {
      const locale = (context.globals.locale ?? 'fa') as 'fa' | 'en'
      const theme = (context.globals.theme ?? 'light') as 'light' | 'dark'
      return (
        <StoryShell locale={locale} theme={theme}>
          <Story />
        </StoryShell>
      )
    },
  ],
}

export default preview
