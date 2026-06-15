'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Home, Workflow, Briefcase, ClipboardCheck } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n-context'
import { withLocale } from '@/lib/locale-utils'

export function BottomNav() {
  const { language } = useI18n()
  const pathname = usePathname()

  const navItems = [
    { key: 'home', name: language === 'en' ? 'Home' : 'خانه', href: '/', icon: Home },
    { key: 'services', name: language === 'en' ? 'Services' : 'خدمات', href: '/services', icon: Workflow },
    { key: 'case-studies', name: language === 'en' ? 'Cases' : 'نمونه‌ها', href: '/case-studies', icon: Briefcase },
    { key: 'qualification', name: language === 'en' ? 'Qualify' : 'ارزیابی', href: '/qualification', icon: ClipboardCheck },
  ] as const

  return (
    <nav className="fixed bottom-0 left-0 right-0 border-t border-border/80 bg-background/95 backdrop-blur-lg md:hidden z-50 pb-safe">
      <div className="mx-auto flex max-w-xl items-center justify-around px-3 py-2">
        {navItems.map((item) => {
          const target = withLocale(item.href, language)
          const isActive = pathname === target || pathname.startsWith(`${target}/`)
          const Icon = item.icon

          return (
            <Link
              key={item.key}
              href={target}
              aria-current={isActive ? 'page' : undefined}
              className={cn(
                'flex min-w-[72px] flex-col items-center gap-1 rounded-lg px-3 py-2 text-xs font-medium transition-all',
                isActive ? 'bg-primary/10 text-primary' : 'text-muted-foreground hover:bg-muted/50'
              )}
              aria-label={item.name}
            >
              <Icon className="h-4 w-4" strokeWidth={isActive ? 2.5 : 2} />
              <span className="text-xs">{item.name}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
