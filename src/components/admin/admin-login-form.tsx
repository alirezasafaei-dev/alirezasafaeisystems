'use client'

import { FormEvent, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { useI18n } from '@/lib/i18n-context'

export function AdminLoginForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { language, t } = useI18n()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const redirectPath = searchParams.get('redirect') || '/admin'
  const authConfigError = searchParams.get('error') === 'auth_not_configured'
  const dir = language === 'fa' ? 'rtl' : 'ltr'

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/admin/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      })

      if (!response.ok) {
        setError(t('admin.login.failed'))
        return
      }

      router.push(redirectPath)
      router.refresh()
    } catch {
      setError(t('admin.login.networkError'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="w-full max-w-md" dir={dir} data-testid="admin-login-form">
      <CardHeader>
        <CardTitle>{t('admin.login.title')}</CardTitle>
        <CardDescription>{t('admin.login.description')}</CardDescription>
      </CardHeader>
      <CardContent>
        {authConfigError && (
          <p className="mb-4 text-sm text-destructive">
            {t('admin.login.authNotConfigured')}
          </p>
        )}
        {error && (
          <p className="mb-4 text-sm text-destructive">{error}</p>
        )}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="username">{t('admin.login.username')}</Label>
            <Input
              id="username"
              autoComplete="username"
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="password">{t('admin.login.password')}</Label>
            <Input
              id="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
            />
          </div>
          <Button type="submit" className="w-full" disabled={loading}>
            {loading ? t('admin.login.signingIn') : t('admin.login.signIn')}
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}
