import { NextRequest, NextResponse } from 'next/server'
import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { checkRateLimit, createRequestId, withCommonApiHeaders } from '@/lib/api-security'
import { db } from '@/lib/db'
import { notifyLeadSubmission } from '@/lib/lead-notifier'
import { logger } from '@/lib/logger'
import { validateLeadAttachment, sanitizeLeadAttachmentFileName } from '@/lib/lead-attachments'
import { isLikelySpam } from '@/lib/security'
import { isValidEmail } from '@/lib/validators'
import { leadSchema, normalizeLeadPayload, type LeadPayload } from '@/lib/api-schemas'

function containsMaliciousContent(payload: LeadPayload): boolean {
  const injectionLikePattern = /(;|--|\b(drop|delete|insert|update|union|select|exec|execute)\b)/i
  const fields = [
    payload.contactName,
    payload.organizationName,
    payload.currentStack,
    payload.criticalRisk,
    payload.notes,
    payload.attachmentPath,
  ]

  return fields.some((value) => injectionLikePattern.test(value) || isLikelySpam(value))
}

async function saveAttachment(file: File, requestId: string): Promise<string> {
  const validation = validateLeadAttachment(file)
  if (!validation.valid) {
    const messages = {
      empty: 'Attachment is empty',
      size: 'Attachment exceeds max size',
      type: 'Attachment type is not allowed',
    } as const
    throw new Error(messages[validation.reason])
  }

  const safeName = sanitizeLeadAttachmentFileName(file.name || 'attachment')
  const fileName = `${Date.now()}-${requestId}-${safeName}`
  const targetDir = path.join(process.cwd(), 'storage', 'leads')
  await mkdir(targetDir, { recursive: true })
  const targetPath = path.join(targetDir, fileName)
  const bytes = Buffer.from(await file.arrayBuffer())
  await writeFile(targetPath, bytes)
  return `storage/leads/${fileName}`
}

export async function POST(request: NextRequest) {
  const requestId = createRequestId(request)
  const limit = await checkRateLimit(request, 'leads')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ success: false, message: 'Too many requests', retryAt: limit.retryAt }, { status: 429 }),
      requestId,
      limit.headers
    )
  }

  try {
    const contentType = request.headers.get('content-type') || ''
    let rawPayload: Record<string, unknown>
    let attachmentFile: File | null = null

    if (contentType.includes('multipart/form-data')) {
      const form = await request.formData()
      const fileInput = form.get('attachment')
      attachmentFile = fileInput instanceof File ? fileInput : null

      const formString = (key: string) => {
        const value = form.get(key)
        return typeof value === 'string' ? value : undefined
      }

      rawPayload = {
        contactName: formString('contactName'),
        organizationName: formString('organizationName'),
        organizationType: formString('organizationType'),
        email: formString('email'),
        phone: formString('phone'),
        teamSize: formString('teamSize'),
        currentStack: formString('currentStack'),
        criticalRisk: formString('criticalRisk'),
        timeline: formString('timeline'),
        budgetRange: formString('budgetRange'),
        preferredContact: formString('preferredContact'),
        notes: formString('notes'),
        website: formString('website'),
        attachmentPath: '',
        utmSource: formString('utmSource'),
        utmMedium: formString('utmMedium'),
        utmCampaign: formString('utmCampaign'),
      }
    } else {
      rawPayload = (await request.json()) as Record<string, unknown>
    }

    const parsed = leadSchema.safeParse(rawPayload)
    if (!parsed.success) {
      return withCommonApiHeaders(
        NextResponse.json(
          {
            success: false,
            message: 'Validation failed',
            errors: parsed.error.issues.map((issue) => issue.message),
          },
          { status: 400 }
        ),
        requestId,
        limit.headers
      )
    }

    const payload = normalizeLeadPayload(parsed.data)
    if (!isValidEmail(payload.email)) {
      return withCommonApiHeaders(
        NextResponse.json({ success: false, message: 'Invalid email' }, { status: 400 }),
        requestId,
        limit.headers
      )
    }

    if (containsMaliciousContent(payload)) {
      logger.warn('Blocked suspicious lead payload', {
        requestId,
        organizationName: payload.organizationName,
      })
      return withCommonApiHeaders(
        NextResponse.json({ success: false, message: 'Request blocked by security policy' }, { status: 400 }),
        requestId,
        limit.headers
      )
    }

    if (payload.website.trim().length > 0) {
      logger.warn('Honeypot trap triggered on lead endpoint', {
        requestId,
        organizationName: payload.organizationName,
      })

      return withCommonApiHeaders(
        NextResponse.json({ success: true, message: 'Lead registered successfully' }, { status: 201 }),
        requestId,
        limit.headers
      )
    }

    if (attachmentFile) {
      payload.attachmentPath = await saveAttachment(attachmentFile, requestId)
    }

    await db.lead.create({
      data: {
        status: 'new',
        source: 'qualification_form',
        contactName: payload.contactName,
        organizationName: payload.organizationName,
        organizationType: payload.organizationType,
        email: payload.email,
        phone: payload.phone || undefined,
        teamSize: payload.teamSize,
        currentStack: payload.currentStack,
        criticalRisk: payload.criticalRisk,
        timeline: payload.timeline,
        budgetRange: payload.budgetRange,
        preferredContact: payload.preferredContact,
        notes: payload.notes || undefined,
        attachmentPath: payload.attachmentPath || undefined,
        utmSource: payload.utmSource || request.nextUrl.searchParams.get('utm_source') || undefined,
        utmMedium: payload.utmMedium || request.nextUrl.searchParams.get('utm_medium') || undefined,
        utmCampaign: payload.utmCampaign || request.nextUrl.searchParams.get('utm_campaign') || undefined,
      },
    })

    await notifyLeadSubmission({
      type: 'lead',
      submittedAt: new Date().toISOString(),
      requestId,
      email: payload.email,
      name: payload.contactName,
      organizationName: payload.organizationName,
      summary: payload.criticalRisk,
    })

    logger.info('Infrastructure lead captured', {
      requestId,
      organizationName: payload.organizationName,
      organizationType: payload.organizationType,
      budgetRange: payload.budgetRange,
    })

    return withCommonApiHeaders(
      NextResponse.json({ success: true, message: 'Lead registered successfully' }, { status: 201 }),
      requestId,
      limit.headers
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown'
    if (message.includes('Attachment')) {
      return withCommonApiHeaders(
        NextResponse.json({ success: false, message }, { status: 400 }),
        requestId,
        limit.headers
      )
    }

    logger.error('Lead capture failed', {
      requestId,
      error: message,
    })

    return withCommonApiHeaders(
      NextResponse.json({ success: false, message: 'An error occurred while processing your request' }, { status: 500 }),
      requestId,
      limit.headers
    )
  }
}
