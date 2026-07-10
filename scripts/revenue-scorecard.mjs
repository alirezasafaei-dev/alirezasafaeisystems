import { access, readFile } from 'node:fs/promises'
import { basename } from 'node:path'
import { pathToFileURL } from 'node:url'

const targets = {
  qualified_prospects: 50,
  personalized_outreach: 40,
  positive_responses: 8,
  calls: 5,
  proposals: 3,
  paid_pilots: 1,
  delivery_time_hours: 72,
  call_to_paid_conversion: 0.2,
}

class ManualInputError extends Error {
  constructor(reason, path) {
    super(reason)
    this.reason = reason
    this.path = path ? basename(path) : null
  }
}

export async function readManual(path) {
  if (!path) return { status: 'NO_MANUAL_FILE', data: {} }

  try {
    await access(path)
  } catch {
    throw new ManualInputError('MANUAL_FILE_NOT_FOUND', path)
  }

  let parsed
  try {
    parsed = JSON.parse(await readFile(path, 'utf8'))
  } catch {
    throw new ManualInputError('MALFORMED_JSON', path)
  }

  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new ManualInputError('SCHEMA_INVALID', path)
  }
  validateManualSchema(parsed, path)
  return { status: 'MANUAL_FILE_VALID', data: parsed }
}

function validateManualSchema(data, path) {
  const metricKeys = ['personalized_outreach', 'positive_responses', 'calls', 'proposals', 'paid_pilots']
  for (const key of metricKeys) {
    if (data[key] !== undefined) validateMetricRow(data[key], key, path)
  }
  if (data.delivery_time !== undefined) validateDeliveryTime(data.delivery_time, path)
  if (data.won_lost !== undefined) {
    if (!isPlainObject(data.won_lost)) throw new ManualInputError('SCHEMA_INVALID', path)
    for (const key of ['won', 'lost']) {
      if (data.won_lost[key] !== undefined && !isNonNegativeNumber(data.won_lost[key])) {
        throw new ManualInputError('SCHEMA_INVALID', path)
      }
    }
  }
  if (data.loss_reason !== undefined && !isPlainObject(data.loss_reason)) {
    throw new ManualInputError('SCHEMA_INVALID', path)
  }
}

function validateMetricRow(value, _key, path) {
  if (!isPlainObject(value)) throw new ManualInputError('SCHEMA_INVALID', path)
  if (value.actual !== undefined && !isNonNegativeNumber(value.actual)) throw new ManualInputError('SCHEMA_INVALID', path)
  if (value.target !== undefined && !isNonNegativeNumber(value.target)) throw new ManualInputError('SCHEMA_INVALID', path)
  if (value.blocker !== undefined && typeof value.blocker !== 'string') throw new ManualInputError('SCHEMA_INVALID', path)
  if (value.next_action !== undefined && typeof value.next_action !== 'string') throw new ManualInputError('SCHEMA_INVALID', path)
}

function validateDeliveryTime(value, path) {
  if (!isPlainObject(value)) throw new ManualInputError('SCHEMA_INVALID', path)
  if (value.actual_hours !== undefined && !isNonNegativeNumber(value.actual_hours)) throw new ManualInputError('SCHEMA_INVALID', path)
  if (value.deliveries !== undefined) {
    if (!Array.isArray(value.deliveries)) throw new ManualInputError('SCHEMA_INVALID', path)
    for (const delivery of value.deliveries) {
      if (!isPlainObject(delivery) || typeof delivery.started_at !== 'string' || typeof delivery.delivered_at !== 'string') {
        throw new ManualInputError('SCHEMA_INVALID', path)
      }
      if (!Number.isFinite(Date.parse(delivery.started_at)) || !Number.isFinite(Date.parse(delivery.delivered_at))) {
        throw new ManualInputError('SCHEMA_INVALID', path)
      }
    }
  }
  if (value.blocker !== undefined && typeof value.blocker !== 'string') throw new ManualInputError('SCHEMA_INVALID', path)
  if (value.next_action !== undefined && typeof value.next_action !== 'string') throw new ManualInputError('SCHEMA_INVALID', path)
}

function row(actual, target, blocker = '', nextAction = '') {
  const variance = typeof actual === 'number' && typeof target === 'number' ? actual - target : 'not_available'
  return { actual, target, variance, blocker, next_action: nextAction }
}

function manualMetric(manual, key, fallbackBlocker, fallbackNextAction) {
  const value = manual[key] ?? {}
  return row(
    value.actual ?? 0,
    value.target ?? targets[key],
    value.blocker ?? fallbackBlocker,
    value.next_action ?? fallbackNextAction,
  )
}

function deliveryTimeRow(manual) {
  const delivery = manual.delivery_time
  if (!delivery) {
    return row(
      'not_available',
      targets.delivery_time_hours,
      'AuditSystems delivery timestamps are not available in this repository environment',
      'run the scorecard with approved AuditSystems delivery export after auditsystems#30 is merged',
    )
  }

  if (typeof delivery.actual_hours === 'number') {
    return row(delivery.actual_hours, delivery.target ?? targets.delivery_time_hours, delivery.blocker ?? '', delivery.next_action ?? 'reduce audit review handoff time')
  }

  if (Array.isArray(delivery.deliveries) && delivery.deliveries.length > 0) {
    const totalHours = delivery.deliveries.reduce((sum, item) => {
      return sum + ((Date.parse(item.delivered_at) - Date.parse(item.started_at)) / 3600000)
    }, 0)
    const averageHours = Number((totalHours / delivery.deliveries.length).toFixed(2))
    return row(averageHours, delivery.target ?? targets.delivery_time_hours, delivery.blocker ?? '', delivery.next_action ?? 'reduce audit review handoff time')
  }

  return row(
    'not_available',
    delivery.target ?? targets.delivery_time_hours,
    delivery.blocker ?? 'No delivered audit timestamp pairs recorded',
    delivery.next_action ?? 'record started_at and delivered_at for delivered audits',
  )
}

export async function buildScorecard({ manual, databaseUrl }) {
  const calls = manual.calls?.actual ?? 0
  const paidPilots = manual.paid_pilots?.actual ?? 0
  const callToPaid = calls > 0 ? paidPilots / calls : 'not_available'
  const conversionBlocker = calls === 0
    ? (paidPilots > 0 ? 'paid pilots recorded with zero calls; conversion denominator unavailable' : 'no calls recorded')
    : ''

  const base = {
    generated_at: new Date().toISOString(),
    personalized_outreach: manualMetric(manual, 'personalized_outreach', 'owner approval required before outreach', 'prepare prospects privately'),
    positive_responses: manualMetric(manual, 'positive_responses', 'no approved outreach sent', 'send only after owner approval'),
    calls: manualMetric(manual, 'calls', 'no booked calls recorded', 'book from positive responses'),
    proposals: manualMetric(manual, 'proposals', 'no proposals recorded', 'use productized offer template'),
    paid_pilots: manualMetric(manual, 'paid_pilots', 'payment activation not approved', 'record won manually until payment is approved'),
    delivery_time: deliveryTimeRow(manual),
    call_to_paid_conversion: row(callToPaid, targets.call_to_paid_conversion, conversionBlocker, 'improve call qualification'),
    won_lost: {
      won: manual.won_lost?.won ?? 0,
      lost: manual.won_lost?.lost ?? 0,
    },
    loss_reason: manual.loss_reason ?? {},
  }

  if (!databaseUrl) {
    return {
      ...base,
      database: 'not_configured',
      qualified_prospects: row('not_available', targets.qualified_prospects, 'DATABASE_URL not configured in this environment', 'run against approved dev/reporting database'),
      system_status_counts: {},
      lead_source: {},
    }
  }

  const { PrismaClient } = await import('@prisma/client')
  const prisma = new PrismaClient()
  try {
    const [qualified, statusCounts, leadSources] = await Promise.all([
      prisma.lead.count({ where: { status: 'qualified' } }),
      prisma.lead.groupBy({ by: ['status'], _count: { status: true } }),
      prisma.lead.groupBy({ by: ['source'], _count: { source: true } }),
    ])
    return {
      ...base,
      database: 'connected',
      qualified_prospects: row(qualified, targets.qualified_prospects, '', 'review new leads and qualify/disqualify'),
      system_status_counts: Object.fromEntries(statusCounts.map((item) => [item.status, item._count.status])),
      lead_source: Object.fromEntries(leadSources.map((item) => [item.source, item._count.source])),
    }
  } finally {
    await prisma.$disconnect()
  }
}

function invalidManualReport(error) {
  return {
    verdict: 'INVALID_MANUAL_INPUT',
    reason: error.reason,
    manual_file: error.path,
  }
}

async function main(argv = process.argv.slice(2), env = process.env) {
  try {
    const manualResult = await readManual(argv[0])
    const report = await buildScorecard({ manual: manualResult.data, databaseUrl: env.DATABASE_URL })
    process.stdout.write(`${JSON.stringify({ manual_input: manualResult.status, ...report }, null, 2)}\n`)
  } catch (error) {
    if (error instanceof ManualInputError) {
      process.stdout.write(`${JSON.stringify(invalidManualReport(error), null, 2)}\n`)
      process.exitCode = 2
      return
    }
    throw error
  }
}

function isPlainObject(value) {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value)
}

function isNonNegativeNumber(value) {
  return typeof value === 'number' && Number.isFinite(value) && value >= 0
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main()
}
