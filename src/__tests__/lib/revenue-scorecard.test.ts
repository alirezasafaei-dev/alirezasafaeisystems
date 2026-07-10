import { execFileSync, spawnSync } from 'node:child_process'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'

type ScorecardModule = {
  readManual: (path?: string) => Promise<{ status: string; data: Record<string, unknown> }>
  buildScorecard: (input: { manual: Record<string, unknown>; databaseUrl?: string; now?: Date }) => Promise<Record<string, unknown>>
}

let scorecard: ScorecardModule
let tempDir: string
let previousDatabaseUrl: string | undefined
let databaseUrl: string

beforeAll(async () => {
  tempDir = mkdtempSync(join(tmpdir(), 'asdev-scorecard-'))
  previousDatabaseUrl = process.env.DATABASE_URL
  databaseUrl = `file:${join(tempDir, 'scorecard.db')}`
  // @ts-expect-error revenue scorecard is an executable ESM script.
  scorecard = await import('../../../scripts/revenue-scorecard.mjs')

  process.env.DATABASE_URL = databaseUrl
  execFileSync('pnpm', ['exec', 'prisma', 'db', 'push', '--skip-generate'], {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'pipe',
  })
})

afterAll(() => {
  if (previousDatabaseUrl === undefined) delete process.env.DATABASE_URL
  else process.env.DATABASE_URL = previousDatabaseUrl
  rmSync(tempDir, { recursive: true, force: true })
})

describe('revenue scorecard', () => {
  it('distinguishes no manual file from missing manual file', async () => {
    await expect(scorecard.readManual()).resolves.toMatchObject({ status: 'NO_MANUAL_FILE', data: {} })
    await expect(scorecard.readManual(join(tempDir, 'missing.json'))).rejects.toMatchObject({ reason: 'MANUAL_FILE_NOT_FOUND' })
  })

  it('fails malformed manual JSON with an explicit invalid-input verdict', () => {
    const badFile = join(tempDir, 'bad.json')
    writeFileSync(badFile, '{"calls":', 'utf8')

    const result = spawnSync('node', ['scripts/revenue-scorecard.mjs', badFile], {
      cwd: process.cwd(),
      env: { ...process.env, DATABASE_URL: '' },
      encoding: 'utf8',
    })

    expect(result.status).toBe(2)
    expect(JSON.parse(result.stdout)).toMatchObject({
      verdict: 'INVALID_MANUAL_INPUT',
      reason: 'MALFORMED_JSON',
      manual_file: 'bad.json',
    })
  })

  it('fails schema-invalid manual JSON', async () => {
    const invalidFile = join(tempDir, 'invalid.json')
    writeFileSync(invalidFile, JSON.stringify({ calls: { actual: 'five' } }), 'utf8')

    await expect(scorecard.readManual(invalidFile)).rejects.toMatchObject({ reason: 'SCHEMA_INVALID' })
  })

  it('rejects an invalid week_start', async () => {
    const invalidFile = join(tempDir, 'invalid-week.json')
    writeFileSync(invalidFile, JSON.stringify({ week_start: '2026-02-30' }), 'utf8')

    await expect(scorecard.readManual(invalidFile)).rejects.toMatchObject({ reason: 'SCHEMA_INVALID' })
  })

  it('uses the current UTC week and not_available values when DATABASE_URL is absent', async () => {
    const report = await scorecard.buildScorecard({
      manual: {},
      databaseUrl: undefined,
      now: new Date('2026-07-10T12:00:00Z'),
    })

    expect(report.database).toBe('not_configured')
    expect(report.reporting_period).toMatchObject({
      start: '2026-07-06T00:00:00.000Z',
      end_exclusive: '2026-07-13T00:00:00.000Z',
      timezone: 'UTC',
      source: 'current_utc_week',
    })
    expect(metric(report.qualified_prospects).actual).toBe('not_available')
    expect(metric(report.delivery_time).actual).toBe('not_available')
    expect(productAnalytics(report).status).toBe('not_available')
  })

  it('calculates zero-call conversion truthfully', async () => {
    const report = await scorecard.buildScorecard({
      manual: { calls: { actual: 0 }, paid_pilots: { actual: 0 } },
      databaseUrl: undefined,
    })

    expect(metric(report.call_to_paid_conversion).actual).toBe('not_available')
    expect(metric(report.call_to_paid_conversion).blocker).toContain('no calls')
  })

  it('flags paid pilots with zero calls as unavailable conversion denominator', async () => {
    const report = await scorecard.buildScorecard({
      manual: { calls: { actual: 0 }, paid_pilots: { actual: 1 } },
      databaseUrl: undefined,
    })

    expect(metric(report.call_to_paid_conversion).actual).toBe('not_available')
    expect(metric(report.call_to_paid_conversion).blocker).toContain('zero calls')
  })

  it('calculates call-to-paid conversion when calls exist', async () => {
    const report = await scorecard.buildScorecard({
      manual: { calls: { actual: 5 }, paid_pilots: { actual: 1 } },
      databaseUrl: undefined,
    })

    expect(metric(report.call_to_paid_conversion).actual).toBe(0.2)
  })

  it('emits won/lost manual counts', async () => {
    const report = await scorecard.buildScorecard({
      manual: { won_lost: { won: 2, lost: 3 } },
      databaseUrl: undefined,
    })

    expect(report.won_lost).toEqual({ won: 2, lost: 3 })
  })

  it('calculates real delivery time from timestamp pairs', async () => {
    const report = await scorecard.buildScorecard({
      manual: {
        delivery_time: {
          deliveries: [
            { started_at: '2026-07-01T10:00:00Z', delivered_at: '2026-07-02T10:00:00Z' },
            { started_at: '2026-07-03T00:00:00Z', delivered_at: '2026-07-03T12:00:00Z' },
          ],
        },
      },
      databaseUrl: undefined,
    })

    expect(metric(report.delivery_time).actual).toBe(18)
    expect(metric(report.delivery_time).target).toBe(72)
  })

  it('filters database metrics and product analytics to the selected week', async () => {
    const { PrismaClient } = await import('@prisma/client')
    const prisma = new PrismaClient({ datasources: { db: { url: databaseUrl } } })
    const emails = ['qualified@example.com', 'new@example.com', 'old-qualified@example.com']
    const sessions = ['scorecard-current-converted', 'scorecard-current-open', 'scorecard-old']

    await prisma.lead.createMany({
      data: [
        leadFixture({ email: emails[0], status: 'qualified', source: 'audit_hero', createdAt: new Date('2026-07-07T10:00:00Z') }),
        leadFixture({ email: emails[1], status: 'new', source: 'case_study', createdAt: new Date('2026-07-08T10:00:00Z') }),
        leadFixture({ email: emails[2], status: 'qualified', source: 'legacy', createdAt: new Date('2026-06-30T10:00:00Z') }),
      ],
    })
    await prisma.analyticsEvent.createMany({
      data: [
        { site: 'portfolio', event: 'audit_cta_click', createdAt: new Date('2026-07-07T11:00:00Z') },
        { site: 'portfolio', event: 'audit_cta_click', createdAt: new Date('2026-07-08T11:00:00Z') },
        { site: 'portfolio', event: 'old_event', createdAt: new Date('2026-06-30T11:00:00Z') },
      ],
    })
    await prisma.funnelConversion.createMany({
      data: [
        { sessionId: sessions[0], entryPoint: 'portfolio', converted: true, createdAt: new Date('2026-07-07T12:00:00Z') },
        { sessionId: sessions[1], entryPoint: 'portfolio', converted: false, createdAt: new Date('2026-07-08T12:00:00Z') },
        { sessionId: sessions[2], entryPoint: 'portfolio', converted: true, createdAt: new Date('2026-06-30T12:00:00Z') },
      ],
    })

    const report = await scorecard.buildScorecard({
      manual: { week_start: '2026-07-06' },
      databaseUrl,
      now: new Date('2026-07-10T12:00:00Z'),
    })

    await prisma.lead.deleteMany({ where: { email: { in: emails } } })
    await prisma.analyticsEvent.deleteMany({ where: { event: { in: ['audit_cta_click', 'old_event'] } } })
    await prisma.funnelConversion.deleteMany({ where: { sessionId: { in: sessions } } })
    await prisma.$disconnect()

    expect(report.database).toBe('connected')
    expect(report.reporting_period).toMatchObject({
      start: '2026-07-06T00:00:00.000Z',
      end_exclusive: '2026-07-13T00:00:00.000Z',
      source: 'manual.week_start',
    })
    expect(metric(report.qualified_prospects).actual).toBe(1)
    expect(report.system_status_counts).toEqual({ qualified: 1, new: 1 })
    expect(report.lead_source).toEqual({ audit_hero: 1, case_study: 1 })
    expect(productAnalytics(report)).toMatchObject({
      status: 'connected',
      events_by_name: { audit_cta_click: 2 },
      funnel_sessions: 2,
      converted_sessions: 1,
    })
  })
})

function leadFixture(overrides: { email: string; status: 'new' | 'qualified'; source: string; createdAt: Date }) {
  return {
    status: overrides.status,
    source: overrides.source,
    contactName: 'Test Lead',
    organizationName: 'Test Org',
    organizationType: 'ecommerce',
    email: overrides.email,
    teamSize: '1-5',
    currentStack: 'Next.js',
    criticalRisk: 'conversion',
    timeline: 'this_month',
    budgetRange: 'pilot',
    preferredContact: 'email',
    createdAt: overrides.createdAt,
  }
}

function metric(value: unknown) {
  return value as { actual: number | string; target: number; blocker: string }
}

function productAnalytics(report: Record<string, unknown>) {
  return report.product_analytics as {
    status: string
    events_by_name: Record<string, number>
    funnel_sessions: number | string
    converted_sessions: number | string
  }
}
