'use client'

import Link from 'next/link'
import { Linkedin, Mail, Instagram, Send } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n-context'
import { brand } from '@/lib/brand'
import { PROFILE_SUMMARY_EN, PROFILE_SUMMARY_FA } from '@/lib/profile-copy'

const quickLinks = [
  { key: 'quickHome', href: '/' },
  { key: 'quickServices', href: '/services' },
  { key: 'quickCaseStudies', href: '/case-studies' },
  { key: 'quickBrand', href: '/about-brand' },
  { key: 'quickContact', href: '/qualification' },
]

function withLocale(path: string, language: 'fa' | 'en'): string {
  const normalized = path.startsWith('/') ? path : `/${path}`
  return language === 'fa' ? normalized : `/${language}${normalized === '/' ? '/' : normalized}`
}

export function Footer() {
  const { t, language } = useI18n()
  const currentYear = new Date().getFullYear()
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
  const summaryText =
    language === 'fa' ? PROFILE_SUMMARY_FA : PROFILE_SUMMARY_EN

  return (
    <footer className="border-t bg-muted/30 mt-auto">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand Section */}
          <div className="space-y-4">
            <h2 className="text-xl font-bold bg-gradient-to-r from-primary to-primary/70 bg-clip-text text-transparent">
              {brand.brandName}
            </h2>
            <p className="text-sm text-muted-foreground text-copy">{summaryText}</p>
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
        <div className="mt-8 pt-5 border-t text-xs text-muted-foreground flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <span>{language === 'fa' ? `© ${currentYear} علیرضا صفایی. همه حقوق محفوظ است.` : `© ${currentYear} Alireza Safaei. All rights reserved.`}</span>
          <span>
            {language === 'fa' ? 'طراحی و توسعه توسط ' : 'Designed and developed by '}
            <Link
              href="https://alirezasafaeisystems.ir/"
              target="_blank"
              rel="noopener noreferrer"
              className="underline underline-offset-4 hover:text-primary"
            >
              {language === 'fa' ? 'علیرضا صفایی مهندس سیستم های وب' : 'Alireza Safaei, Web Systems Engineer'}
            </Link>
          </span>
        </div>
      </div>
    </footer>
  )
}
