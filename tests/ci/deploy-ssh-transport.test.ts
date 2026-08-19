import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('Deploy VPS SSH transport contract', () => {
  it('uses an explicitly expanded SSH config path for rsync transport', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/deploy-vps.yml'), 'utf8')

    expect(workflow).toContain('-e "ssh -F $HOME/.ssh/config"')
    expect(workflow).not.toContain('-e "ssh -F ~/.ssh/config"')
  })

  it('fails closed instead of allowing SSH or rsync transport to hang until the whole deploy job times out', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/deploy-vps.yml'), 'utf8')

    expect(workflow.match(/ConnectTimeout 20/g)?.length).toBeGreaterThanOrEqual(2)
    expect(workflow.match(/ServerAliveInterval 15/g)?.length).toBeGreaterThanOrEqual(2)
    expect(workflow.match(/ServerAliveCountMax 4/g)?.length).toBeGreaterThanOrEqual(2)
    expect(workflow).toContain('rsync -az --delete --timeout=120')
  })

  it('triggers production verification when the deploy workflow itself changes', () => {
    const workflow = readFileSync(resolve(process.cwd(), '.github/workflows/deploy-vps.yml'), 'utf8')

    expect(workflow).toContain('- ".github/workflows/deploy-vps.yml"')
  })
})
