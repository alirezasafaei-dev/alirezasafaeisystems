import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('Discover production rollout contract', () => {
  it('smoke-checks public routes without curl-to-grep pipelines under pipefail', () => {
    const workflow = readFileSync(
      resolve(process.cwd(), '.github/workflows/deploy-vps.yml'),
      'utf8'
    )
    const smokeStart = workflow.indexOf('name: Post-deploy smoke check')
    const smokeEnd = workflow.indexOf('name: Live browser production verification', smokeStart)
    const smoke = workflow.slice(smokeStart, smokeEnd)

    expect(smokeStart).toBeGreaterThan(-1)
    expect(smokeEnd).toBeGreaterThan(smokeStart)
    expect(smoke).not.toMatch(/curl[^\n]*\|\s*grep/)
    expect(smoke).toContain("curl --connect-timeout 10 --max-time 30 -fsS --resolve '${BASE_HOST}:443:127.0.0.1' '${BASE_URL}/services' >/dev/null")
    expect(smoke).toContain("curl --connect-timeout 10 --max-time 30 -fsS --resolve '${BASE_HOST}:443:127.0.0.1' '${BASE_URL}/discover' >/dev/null")
    expect(smoke).toContain("--resolve '${BASE_HOST}:443:127.0.0.1' -o /tmp/portfolio-home.html '${BASE_URL}/'")
    expect(smoke).toContain('grep -Eq')
    expect(smoke).toContain('/tmp/portfolio-home.html')
    expect(smoke).toContain("--resolve '${BASE_HOST}:443:127.0.0.1' -o /tmp/portfolio-discover-en.html '${BASE_URL}/en/discover'")
    expect(smoke).toContain("grep -q 'lang=\\\"en\\\"' /tmp/portfolio-discover-en.html")
    expect(smoke).toContain("grep -q 'dir=\\\"ltr\\\"' /tmp/portfolio-discover-en.html")
    expect(smoke).toContain("--resolve '${BASE_HOST}:443:127.0.0.1' -o /tmp/portfolio-profile.html '${BASE_URL}/profile'")
    expect(smoke).toContain("grep -q 'alireza_safaei_network' /tmp/portfolio-profile.html")
  })

  it('runs two consecutive real-browser production verification passes and records exact release evidence', () => {
    const workflow = readFileSync(
      resolve(process.cwd(), '.github/workflows/deploy-vps.yml'),
      'utf8'
    )

    expect(workflow).toContain('statuses: write')
    expect(workflow).toContain('pnpm exec playwright install --with-deps chromium')
    expect(workflow).toContain('for PASS in 1 2; do')
    expect(workflow).toContain('node scripts/deploy/live-verify.mjs')
    expect(workflow).toContain('LIVE_VERIFY_BASE_URL="$BASE_URL"')
    expect(workflow).toContain('LIVE_VERIFY_RELEASE_SHA="$TARGET_REF"')
    expect(workflow).toContain('LIVE_VERIFY_REPORT_PATH="$GITHUB_WORKSPACE/live-verification-report-pass-${PASS}.md"')
    expect(workflow).toContain('actions/upload-artifact@v4')
    expect(workflow).toContain('live-verification-report-pass-*.md')
    expect(workflow).toContain('/statuses/$TARGET_REF')
    expect(workflow).toContain('production/live-verification')
    expect(workflow).toContain('steps.live_verify.outcome')
  })

  it('does not create secondary verification failures when live verification never ran', () => {
    const workflow = readFileSync(
      resolve(process.cwd(), '.github/workflows/deploy-vps.yml'),
      'utf8'
    )

    const uploadIndex = workflow.indexOf('name: Upload live verification evidence')
    const enforceIndex = workflow.indexOf('name: Enforce live verification gate')
    expect(uploadIndex).toBeGreaterThan(-1)
    expect(enforceIndex).toBeGreaterThan(uploadIndex)
    expect(workflow.slice(uploadIndex, uploadIndex + 240)).toContain("if: ${{ always() && steps.live_verify.outcome != 'skipped' }}")
    expect(workflow.slice(enforceIndex, enforceIndex + 180)).toContain("if: ${{ steps.live_verify.outcome == 'failure' }}")
    expect(workflow).toContain('Live browser verification was not executed because deployment failed or was blocked')
  })

  it('keeps deployment serialization while publishing queue observability before the deploy lock', () => {
    const workflow = readFileSync(
      resolve(process.cwd(), '.github/workflows/deploy-vps.yml'),
      'utf8'
    )

    const jobsIndex = workflow.indexOf('\njobs:')
    const deployIndex = workflow.indexOf('\n  deploy:')
    const workflowConcurrencyIndex = workflow.indexOf('\nconcurrency:')
    const deployConcurrencyIndex = workflow.indexOf('\n    concurrency:', deployIndex)
    const pendingStatusIndex = workflow.indexOf('Publish deployment pending status')

    expect(jobsIndex).toBeGreaterThan(-1)
    expect(deployIndex).toBeGreaterThan(jobsIndex)
    expect(workflowConcurrencyIndex === -1 || workflowConcurrencyIndex > jobsIndex).toBe(true)
    expect(deployConcurrencyIndex).toBeGreaterThan(deployIndex)
    expect(workflow).toContain('group: deploy-vps-${{ inputs.environment }}')
    expect(workflow).toContain('cancel-in-progress: false')
    expect(pendingStatusIndex).toBeGreaterThan(jobsIndex)
    expect(pendingStatusIndex).toBeLessThan(deployIndex)
    expect(workflow).toContain('production/deploy')
    expect(workflow).toContain('Deployment queued; quality gate running')
    expect(workflow).toContain('https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}')
    expect(workflow).toContain('deployment-status:')
    expect(workflow).toContain('needs: [quality-gate, deploy]')
    expect(workflow).toContain('QUALITY_RESULT: ${{ needs.quality-gate.result }}')
    expect(workflow).toContain('DEPLOY_RESULT: ${{ needs.deploy.result }}')
    expect(workflow).toContain('Deployment and live verification passed')
  })

  it('does not require a main landmark before validating the admin-login redirect', () => {
    const runner = readFileSync(
      resolve(process.cwd(), 'scripts/deploy/live-verify.mjs'),
      'utf8'
    )
    const adminLogin = readFileSync(
      resolve(process.cwd(), 'src/app/admin/login/page.tsx'),
      'utf8'
    )

    expect(adminLogin).not.toContain('<main')
    expect(runner).toContain("await goto(page, '/admin', { requireMain: false })")
  })
})
