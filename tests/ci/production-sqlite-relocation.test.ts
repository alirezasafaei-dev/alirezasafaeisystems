import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('one-time production SQLite relocation', () => {
  it('runs the relocation helper before the normal remote deploy', () => {
    const workflow = readFileSync(
      resolve(process.cwd(), '.github/workflows/deploy-vps.yml'),
      'utf8',
    )

    const relocationIndex = workflow.indexOf('bash ops/deploy/migrate-legacy-sqlite.sh')
    const deployIndex = workflow.indexOf('bash ops/deploy/deploy.sh')

    expect(relocationIndex).toBeGreaterThan(-1)
    expect(deployIndex).toBeGreaterThan(relocationIndex)
  })

  it('is fail-closed, preserves the legacy database, and can only relocate once', () => {
    const helper = readFileSync(
      resolve(process.cwd(), 'ops/deploy/migrate-legacy-sqlite.sh'),
      'utf8',
    )

    expect(helper).toContain('PERSISTENT_DB_PATH="${PERSISTENT_DB_PATH:-/var/www/my-portfolio/shared/data/production.db}"')
    expect(helper).toContain('MIGRATION_MARKER=')
    expect(helper).toContain('relocation marker and persistent SQLite state verified')
    expect(helper).toContain('PREVIOUS_RELEASE="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"')
    expect(helper).toContain('LEGACY_CANDIDATE_COUNT=0')
    expect(helper).toContain('multiple legacy SQLite candidates were found')
    expect(helper).toContain('pm2 stop "$APP_NAME"')
    expect(helper).toContain('cp -a -- "$LEGACY_DB_PATH" "$PERSISTENT_DB_PATH"')
    expect(helper).toContain('ENV_BACKUP=')
    expect(helper).toContain('pm2 restart "$APP_NAME" --update-env')
    expect(helper).toContain('touch "$MIGRATION_MARKER"')
    expect(helper).not.toContain('rm -f -- "$LEGACY_DB_PATH"')
  })
})
