import { execFileSync } from 'node:child_process'
import { describe, expect, it } from 'vitest'

describe('deploy script executable mode', () => {
  it('keeps the governed ASDEV deploy entrypoint executable in the Git index', () => {
    const staged = execFileSync(
      'git',
      ['ls-files', '--stage', '--', 'scripts/deploy/asdev-deploy.sh'],
      { encoding: 'utf8' },
    ).trim()

    expect(staged).toMatch(/^100755\s+[0-9a-f]{40}\s+0\tscripts\/deploy\/asdev-deploy\.sh$/)
  })
})
