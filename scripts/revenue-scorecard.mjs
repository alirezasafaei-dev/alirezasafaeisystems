import { PrismaClient } from '@prisma/client'
import { readFile } from 'node:fs/promises'

const prisma = new PrismaClient()

const targets = {
  qualified_prospects: 50,
  personalized_outreach: 40,
  positive_responses: 8,
  calls: 5,
  proposals: 3,
  paid_pilots: 1,
  call_to_paid_conversion: 0.2,
}

async function readManual(path) {
  if (!path) return {}
  try {
    return JSON.parse(await readFile(path, 'utf8'))
  } catch {
    return {}
  }
}

function row(actual, target, blocker = '', nextAction = '') {
  const variance = typeof actual === 'number' && typeof target === 'number' ? actual - target : 'not_available'
  return { actual, target, variance, blocker, next_action: nextAction }
}

async function main() {
  const manual = await readManual(process.argv[2])
  if (!process.env.DATABASE_URL) {
    const report = {
      generated_at: new Date().toISOString(),
      database: 'not_configured',
      qualified_prospects: row(0, targets.qualified_prospects, 'DATABASE_URL not configured in this environment', 'run against approved dev/reporting database'),
      personalized_outreach: row(manual.personalized_outreach?.actual ?? 0, targets.personalized_outreach, manual.personalized_outreach?.blocker ?? 'owner approval required before outreach', manual.personalized_outreach?.next_action ?? 'prepare prospects privately'),
      positive_responses: row(manual.positive_responses?.actual ?? 0, targets.positive_responses, manual.positive_responses?.blocker ?? 'no approved outreach sent', manual.positive_responses?.next_action ?? 'send after approval'),
      calls: row(manual.calls?.actual ?? 0, targets.calls, manual.calls?.blocker ?? 'no booked calls recorded', manual.calls?.next_action ?? 'book from positive responses'),
      proposals: row(manual.proposals?.actual ?? 0, targets.proposals, manual.proposals?.blocker ?? 'no proposals recorded', manual.proposals?.next_action ?? 'use productized offer template'),
      paid_pilots: row(manual.paid_pilots?.actual ?? 0, targets.paid_pilots, manual.paid_pilots?.blocker ?? 'payment activation not approved', manual.paid_pilots?.next_action ?? 'record won manually until payment is approved'),
      call_to_paid_conversion: row(0, targets.call_to_paid_conversion, 'no calls recorded', 'improve call qualification'),
      won_lost: {},
      lead_source: {},
      loss_reason: 'manual_private_register_until_schema_expansion',
    }
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`)
    return
  }
  const [qualified, wonLost, leadSources] = await Promise.all([
    prisma.lead.count({ where: { status: 'qualified' } }),
    prisma.lead.groupBy({ by: ['status'], _count: { status: true } }),
    prisma.lead.groupBy({ by: ['source'], _count: { source: true } }),
  ])

  const calls = manual.calls?.actual ?? 0
  const paidPilots = manual.paid_pilots?.actual ?? 0
  const callToPaid = calls > 0 ? paidPilots / calls : 0

  const report = {
    generated_at: new Date().toISOString(),
    qualified_prospects: row(qualified, targets.qualified_prospects, '', 'review new leads and qualify/disqualify'),
    personalized_outreach: row(manual.personalized_outreach?.actual ?? 0, targets.personalized_outreach, manual.personalized_outreach?.blocker ?? 'owner approval required before outreach', manual.personalized_outreach?.next_action ?? 'prepare prospects privately'),
    positive_responses: row(manual.positive_responses?.actual ?? 0, targets.positive_responses, manual.positive_responses?.blocker ?? 'no approved outreach sent', manual.positive_responses?.next_action ?? 'send after approval'),
    calls: row(calls, targets.calls, manual.calls?.blocker ?? 'no booked calls recorded', manual.calls?.next_action ?? 'book from positive responses'),
    proposals: row(manual.proposals?.actual ?? 0, targets.proposals, manual.proposals?.blocker ?? 'no proposals recorded', manual.proposals?.next_action ?? 'use productized offer template'),
    paid_pilots: row(paidPilots, targets.paid_pilots, manual.paid_pilots?.blocker ?? 'payment activation not approved', manual.paid_pilots?.next_action ?? 'record won manually until payment is approved'),
    call_to_paid_conversion: row(callToPaid, targets.call_to_paid_conversion, calls === 0 ? 'no calls recorded' : '', 'improve call qualification'),
    won_lost: Object.fromEntries(wonLost.map((item) => [item.status, item._count.status])),
    lead_source: Object.fromEntries(leadSources.map((item) => [item.source, item._count.source])),
    loss_reason: 'manual_private_register_until_schema_expansion',
  }

  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`)
}

main().finally(async () => prisma.$disconnect())
