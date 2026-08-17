import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'

describe('production database migration safety', () => {
  it('backs up persistent SQLite state and fails back to the previous app on migration errors', () => {
    const deploy = readFileSync(resolve(process.cwd(), 'ops/deploy/deploy.sh'), 'utf8')

    const buildIndex = deploy.indexOf('pnpm run build')
    const migrationIndex = deploy.indexOf('pnpm exec prisma migrate deploy')
    const replaceAppIndex = deploy.indexOf('pm2 delete "$APP_NAME"')

    expect(deploy).toContain('DATABASE_URL must use an absolute SQLite file URL')
    expect(deploy).toContain('DB_PATH="${DATABASE_URL#file:}"')
    expect(deploy).toContain('BACKUP_DIR="$BASE_DIR/shared/backups/$ENVIRONMENT"')
    expect(deploy).toContain('pm2 stop "$APP_NAME"')
    expect(deploy).toContain('snapshot_database')
    expect(deploy).toContain('restore_database_snapshot')
    expect(deploy).toContain('pm2 restart "$APP_NAME" --update-env')
    expect(buildIndex).toBeGreaterThan(-1)
    expect(migrationIndex).toBeGreaterThan(buildIndex)
    expect(replaceAppIndex).toBeGreaterThan(migrationIndex)
  })
})
