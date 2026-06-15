import { NextRequest, NextResponse } from 'next/server'
import { checkRateLimit, createRequestId, withCommonApiHeaders } from '@/lib/api-security'
import { notifyLeadSubmission } from '@/lib/lead-notifier'
import { logger } from '@/lib/logger'
import { hasSqlInjection, isLikelySpam } from '@/lib/security'
import { isValidEmail } from '@/lib/validators'
import { contactSchema, normalizeContactPayload, type ContactPayload } from '@/lib/api-schemas'

function containsMaliciousContent(payload: ContactPayload): boolean {
  return (
    hasSqlInjection(payload.name) ||
    hasSqlInjection(payload.subject) ||
    hasSqlInjection(payload.message) ||
    isLikelySpam(payload.message)
  )
}

export async function POST(request: NextRequest) {
  const requestId = createRequestId(request)
  const limit = await checkRateLimit(request, 'contact')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json(
        {
          success: false,
          message: 'Too many requests. Please try again later.',
          retryAt: limit.retryAt,
        },
        { status: 429 }
      ),
      requestId,
      limit.headers
    )
  }

  try {
    const body: unknown = await request.json()
    const parsed = contactSchema.safeParse(body)
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

    const payload = normalizeContactPayload(parsed.data)
    if (!isValidEmail(payload.email)) {
      return withCommonApiHeaders(
        NextResponse.json(
          {
            success: false,
            message: 'Please enter a valid email address',
          },
          { status: 400 }
        ),
        requestId,
        limit.headers
      )
    }

    if (containsMaliciousContent(payload)) {
      logger.warn('Blocked suspicious contact payload', {
        requestId,
        subject: payload.subject,
      })
      return withCommonApiHeaders(
        NextResponse.json(
          {
            success: false,
            message: 'Request blocked by security policy',
          },
          { status: 400 }
        ),
        requestId,
        limit.headers
      )
    }

    if (payload.website.trim().length > 0) {
      logger.warn('Honeypot trap triggered on contact endpoint', {
        requestId,
      })
      return withCommonApiHeaders(
        NextResponse.json({
          success: true,
          message: 'Message sent successfully',
        }),
        requestId,
        limit.headers
      )
    }

    await notifyLeadSubmission({
      type: 'contact',
      submittedAt: new Date().toISOString(),
      requestId,
      email: payload.email,
      name: payload.name,
      subject: payload.subject,
      summary: payload.message.slice(0, 280),
    })

    logger.info('Contact form submission accepted', {
      requestId,
      name: payload.name,
      email: payload.email,
      subject: payload.subject,
    })

    return withCommonApiHeaders(
      NextResponse.json({
        success: true,
        message: 'Message sent successfully',
      }),
      requestId,
      limit.headers
    )
  } catch (error) {
    logger.error('Contact form processing failed', {
      requestId,
      error: error instanceof Error ? error.message : 'unknown',
    })
    return withCommonApiHeaders(
      NextResponse.json(
        {
          success: false,
          message: 'An error occurred while sending your message',
        },
        { status: 500 }
      ),
      requestId,
      limit.headers
    )
  }
}

export async function GET(request: NextRequest) {
  const requestId = createRequestId(request)
  const limit = await checkRateLimit(request, 'contact:get')

  return withCommonApiHeaders(
    NextResponse.json(
      {
        message: 'This endpoint only accepts POST requests',
      },
      { status: 405 }
    ),
    requestId,
    limit.headers
  )
}
