const internalBaseUrl = (process.env.EVIDENCE_INTERNAL_BASE_URL || 'http://127.0.0.1:3002').replace(/\/$/, '')

if (!process.env.ADMIN_USERNAME || !process.env.ADMIN_PASSWORD) {
  throw new Error('Normal Admin session authentication is not configured')
}

const response = await fetch(`${internalBaseUrl}/api/admin/auth/login`, {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify({ username: process.env.ADMIN_USERNAME, password: process.env.ADMIN_PASSWORD }),
  redirect: 'manual',
})

if (!response.ok) throw new Error(`Normal Admin login failed with HTTP ${response.status}`)
const setCookie = response.headers.get('set-cookie') || ''
const match = setCookie.match(/(?:^|,\s*)asdev_admin_session=([^;]+)/)
if (!match?.[1]) throw new Error('Admin login did not return the expected session cookie')

// Deliberately emit only the ephemeral session-token value. The caller must mask
// it immediately and must never include it in artifacts or summaries.
process.stdout.write(match[1])
