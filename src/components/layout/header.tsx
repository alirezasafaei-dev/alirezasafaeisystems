'use client'

import Link from 'next/link'
import { useState, useEffect } from 'react'
import { usePathname, useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n-context'
import { brand } from '@/lib/brand'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Sheet,
  SheetContent,
  SheetTrigger,
} from '@/components/ui/sheet'
import { Languages, X, Menu, Sparkles } from 'lucide-react'

const navItems = [
  { key: 'home', name: 'nav.home', href: '/' },
  { key: 'services', name: 'nav.services', href: '/services' },
  { key: 'caseStudies', name: 'nav.caseStudies', href: '/case-studies' },
  { key: 'contact', name: 'nav.contact', href: '/qualification' },
]

function withLocale(path: string, lang: 'fa' | 'en'): string {
  const normalized = path.startsWith('/') ? path : `/${path}`
  return `/${lang}${normalized === '/' ? '/' : normalized}`
}

function getLocalizedPathname(pathname: string, lang: 'fa' | 'en'): string {
  const withoutLocale = pathname.replace(/^\/(fa|en)(?=\/|$)/, '') || '/'
  return withLocale(withoutLocale, lang)
}

export function Header() {
  const { t, language, setLanguage } = useI18n()
  const pathname = usePathname()
  const router = useRouter()

  const [isScrolled, setIsScrolled] = useState(false)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const changeLanguage = (lang: 'en' | 'fa') => {
    setLanguage(lang)
    const localizedPath = getLocalizedPathname(pathname, lang)
    router.push(localizedPath)
    router.refresh()
  }

  const getNavText = (name: string): string => {
    return t(name)
  }

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? 'bg-background/75 backdrop-blur-xl border-b shadow-sm'
          : 'bg-transparent'
      }`}
    >
      <nav className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <Link
            href={withLocale('/', language)}
            className="text-2xl font-bold gradient-text hover:opacity-80 transition-opacity flex items-center gap-2"
            onClick={() => setMobileMenuOpen(false)}
          >
            <Sparkles className="h-6 w-6" />
            {brand.brandName}
          </Link>

          <div className="hidden md:flex items-center gap-6 rounded-full border border-border/70 bg-card/70 px-4 py-2 shadow-sm">
            {navItems.map((item) => {
              const target = withLocale(item.href, language)
              const active = pathname === target || pathname.startsWith(`${target}/`)
              return (
                <Link
                  key={item.key}
                  href={target}
                  aria-current={active ? 'page' : undefined}
                  className={`text-sm font-medium transition-colors relative group px-2 py-1 rounded-md ${
                    active ? 'text-primary bg-primary/10' : 'text-muted-foreground hover:text-primary hover:bg-muted/60'
                  }`}
                >
                  {getNavText(item.name)}
                  <span className={`absolute -bottom-1 left-0 h-0.5 bg-primary transition-all ${active ? 'w-full' : 'w-0 group-hover:w-full'}`} />
                </Link>
              )
            })}

            <div className="flex items-center gap-2">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-10 w-10 card-hover"
                    aria-label={t('ui.changeLanguage')}
                  >
                    <Languages className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem onClick={() => changeLanguage('en')}>
                    {t('nav.english')}
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => changeLanguage('fa')}>
                    {t('nav.persian')}
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>

          <Sheet open={mobileMenuOpen} onOpenChange={setMobileMenuOpen}>
            <SheetTrigger asChild className="md:hidden">
              <Button
                variant="ghost"
                size="icon"
                aria-label={mobileMenuOpen ? t('ui.closeMenu') : t('ui.openMenu')}
              >
                {mobileMenuOpen ? <X /> : <Menu />}
              </Button>
            </SheetTrigger>
            <SheetContent side={language === 'fa' ? 'left' : 'right'} className="w-72">
              <nav className="flex flex-col gap-4 mt-8">
                {navItems.map((item) => {
                  const target = withLocale(item.href, language)
                  const active = pathname === target || pathname.startsWith(`${target}/`)
                  return (
                    <Link
                      key={item.key}
                      href={target}
                      aria-current={active ? 'page' : undefined}
                      onClick={() => setMobileMenuOpen(false)}
                      className={`text-lg font-medium px-4 py-2 rounded-lg transition-colors ${language === 'fa' ? 'text-right' : 'text-left'} ${
                        active ? 'bg-primary/10 text-primary' : 'hover:bg-muted text-foreground/90'
                      }`}
                    >
                      {getNavText(item.name)}
                    </Link>
                  )
                })}
              </nav>
              <div className="mt-8 pt-8 border-t space-y-4">
                <div className="flex items-center justify-between px-4">
                  <span className="text-sm text-muted-foreground">{t('ui.language')}</span>
                  <div className="flex items-center gap-2">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => changeLanguage(language === 'en' ? 'fa' : 'en')}
                    >
                      {language === 'en' ? 'FA' : 'EN'}
                    </Button>
                  </div>
                </div>
              </div>
            </SheetContent>
          </Sheet>
        </div>
      </nav>
    </header>
  )
}
