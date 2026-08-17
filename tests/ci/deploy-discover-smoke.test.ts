import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('Discover production rollout contract', () => {
  it('smoke-checks the public Discover route after VPS deployment', () => {
    const workflow = readFileSync(
      resolve(process.cwd(), '.github/workflows/deploy-vps.yml'),
      'utf8'
    )

    const servicesCheck = workflow.indexOf("curl --connect-timeout 10 --max-time 30 -fsS '${BASE_URL}/services' >/dev/null")
    const discoverCheck = workflow.indexOf("curl --connect-timeout 10 --max-time 30 -fsS '${BASE_URL}/discover' >/dev/null")
    const profileCheck = workflow.indexOf("curl --connect-timeout 10 --max-time 30 -fsS '${BASE_URL}/profile' | grep -q 'alireza_safaei_network'")

    expect(servicesCheck).toBeGreaterThan(-1)
    expect(discoverCheck).toBeGreaterThan(servicesCheck)
    expect(profileCheck).toBeGreaterThan(discoverCheck)
  })
})
