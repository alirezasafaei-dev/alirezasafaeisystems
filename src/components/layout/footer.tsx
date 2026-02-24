'use client'

import Link from 'next/link'
import { Linkedin, Mail, Heart, Instagram, Send } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n-context'
import { brand } from '@/lib/brand'
import {
  ASDEV_PORTFOLIO_LABEL,
  ASDEV_PORTFOLIO_URL,
  ASDEV_SIGNATURE_TEXT,
  ASDEV_TELEGRAM_LABEL,
  ASDEV_TELEGRAM_URL,
  buildAsdevNetworkLinks,
} from '@/lib/asdev-network'

const quickLinks = [
  { key: 'quickHome', href: '/' },
  { key: 'quickServices', href: '/services' },
  { key: 'quickCaseStudies', href: '/case-studies' },
  { key: 'quickBrand', href: '/about-brand' },
  { key: 'quickContact', href: '/qualification' },
]

function withLocale(path: string, language: 'fa' | 'en'): string {
  const normalized = path.startsWith('/') ? path : `/${path}`
  return `/${language}${normalized === '/' ? '/' : normalized}`
}

export function Footer() {
  const { t, language } = useI18n()
  const currentYear = new Date().getFullYear()
  const networkLinks = buildAsdevNetworkLinks('asdev-portfolio', 'footer')
  const socialLinks = [
    {
      name: 'LinkedIn',
      href: brand.linkedinUrl,
      icon: Linkedin,
    },
    {
      name: 'Telegram',
      href: brand.telegramUrl,
      icon: Send,
    },
    {
      name: 'Instagram',
      href: brand.instagramUrl,
      icon: Instagram,
    },
  ].filter((social) => social.href)

  return (
    <footer className="border-t bg-muted/30 mt-auto">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand Section */}
          <div className="space-y-4">
            <h2 className="text-xl font-bold bg-gradient-to-r from-primary to-primary/70 bg-clip-text text-transparent">
              {brand.brandName}
            </h2>
            <p className="text-sm text-muted-foreground">
              {language === 'fa' ? brand.positioningFa : brand.positioningEn}
            </p>
            <p className="text-xs text-muted-foreground">
              {language === 'fa' ? 'تهران — همکاری حضوری/ریموت در سراسر ایران' : 'Tehran — on-site/remote collaboration across Iran'}
            </p>
          </div>

          {/* Quick Links */}
          <div className="space-y-4">
            <h3 className="font-semibold">{t('footer.quickLinks')}</h3>
            <ul className="space-y-2">
              {quickLinks.map((link) => (
                <li key={link.key}>
                  <Link
                    href={withLocale(link.href, language)}
                    className="text-sm text-muted-foreground hover:text-primary transition-colors inline-flex items-center gap-1 group"
                  >
                    {t(`footer.${link.key}`)}
                    <span className="opacity-0 group-hover:opacity-100 transition-opacity">
                      →
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Social Links */}
          <div className="space-y-4">
            <h3 className="font-semibold leading-snug">{t('footer.social')}</h3>
            <div className="flex flex-wrap items-center gap-2 sm:gap-3 max-w-full">
              {socialLinks.map((social) => (
                <div key={social.name}>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="rounded-full hover:bg-primary/10 h-10 w-10 sm:h-12 sm:w-12 card-hover relative overflow-hidden group"
                    asChild
                  >
                    <Link
                      href={social.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      aria-label={social.name}
                    >
                      <social.icon className="h-4 w-4 sm:h-5 sm:w-5" />
                    </Link>
                  </Button>
                </div>
              ))}
            </div>
          </div>

          {/* Contact Info */}
          <div className="space-y-4">
            <h3 className="font-semibold">{t('footer.getInTouch')}</h3>
            <p className="text-sm text-muted-foreground">
              {t('footer.haveProject')}
            </p>
            <div>
              <Button
                variant="default"
                className="w-full card-hover shine-effect gap-2"
                onClick={() => window.location.href = `mailto:${brand.contactEmail}`}
              >
                <Mail className="h-4 w-4" />
                {t('contact.sendMessage')}
              </Button>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="mt-8 pt-8 border-t flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-sm text-muted-foreground text-center md:text-left">
            © {currentYear} {brand.ownerName}. {t('footer.allRights')}
          </p>
          <div className="text-sm text-muted-foreground flex flex-col md:items-end gap-2 text-center md:text-right">
            <p className="flex items-center gap-1 justify-center md:justify-end flex-wrap">
              {t('ui.builtBy')}
              <Link href={withLocale('/about-brand', language)} className="font-semibold hover:text-primary transition-colors">
                {brand.ownerName} ({brand.brandName})
              </Link>
              {t('footer.madeWith')}
              <Heart className="h-4 w-4 fill-primary text-primary" />
            </p>
            <div className="flex flex-wrap gap-2 justify-center md:justify-end text-xs">
              <span className="font-semibold">{ASDEV_SIGNATURE_TEXT}</span>
              <span aria-hidden>•</span>
              <Link
                href={ASDEV_PORTFOLIO_URL}
                className="underline underline-offset-4 hover:text-primary"
                target="_blank"
                rel="noopener noreferrer"
              >
                {ASDEV_PORTFOLIO_LABEL}
              </Link>
              <span aria-hidden>•</span>
              <Link
                href={ASDEV_TELEGRAM_URL}
                className="underline underline-offset-4 hover:text-primary"
                target="_blank"
                rel="noopener noreferrer"
              >
                {ASDEV_TELEGRAM_LABEL}
              </Link>
            </div>
            <div className="flex flex-wrap gap-3 justify-center md:justify-end">
              {networkLinks.map((item) => (
                <Link
                  key={item.label}
                  href={item.href}
                  className="underline underline-offset-4 hover:text-primary"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {item.label}
                </Link>
              ))}
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}
