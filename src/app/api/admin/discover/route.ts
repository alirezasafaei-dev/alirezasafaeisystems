import { Prisma } from '@prisma/client'
import { NextRequest, NextResponse } from 'next/server'
import { checkRateLimit, createRequestId, enforceAdminAccess, withCommonApiHeaders } from '@/lib/api-security'
import { db } from '@/lib/db'
import { discoverCreateSchema, discoverUpdateSchema } from '@/lib/discover'
import { normalizeDiscoverCategory } from '@/lib/discover-categories'
import {
  DiscoverEnglishPublicationError,
  normalizeDiscoverCreateInput,
  normalizeDiscoverUpdateInput,
} from '@/lib/discover-service'
import { logger } from '@/lib/logger'
import { sanitizeInput } from '@/lib/validators'

function requiresJson(request: NextRequest): boolean {
  return (request.headers.get('content-type') || '').split(';', 1)[0].trim().toLowerCase() === 'application/json'
}

function hasPrismaErrorCode(error: unknown, code: string): boolean {
  return error instanceof Prisma.PrismaClientKnownRequestError
    ? error.code === code
    : Boolean(error && typeof error === 'object' && 'code' in error && error.code === code)
}

function isUniqueConstraintError(error: unknown): boolean {
  return hasPrismaErrorCode(error, 'P2002')
}

function isMissingUpdateTargetError(error: unknown): boolean {
  return hasPrismaErrorCode(error, 'P2025')
}

type ValidationDetail = string | { path: (string | number)[]; message: string }

function validationResponse(requestId: string, headers: Record<string, string>, issues: ValidationDetail[]) {
  return withCommonApiHeaders(
    NextResponse.json({ error: 'Validation failed', details: issues }, { status: 400 }),
    requestId,
    headers,
  )
}

function normalizeResponseCategory(category: string): string {
  try {
    return normalizeDiscoverCategory(category)
  } catch {
    return category
  }
}

function parseExpectedUpdatedAt(value: unknown): Date | null {
  if (typeof value !== 'string') return null
  const timestamp = Date.parse(value)
  return Number.isFinite(timestamp) ? new Date(timestamp) : null
}

export async function GET(request: NextRequest) {
  const requestId = createRequestId(request)
  const unauthorized = await enforceAdminAccess(request, requestId)
  if (unauthorized) return unauthorized

  const limit = await checkRateLimit(request, 'admin:discover:get')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Too many requests', retryAt: limit.retryAt }, { status: 429 }),
      requestId,
      limit.headers,
    )
  }

  try {
    const published = request.nextUrl.searchParams.get('published')
    const rawCategory = request.nextUrl.searchParams.get('category')
    const rawQuery = request.nextUrl.searchParams.get('q')

    if (published && !['all', 'true', 'false'].includes(published)) {
      return validationResponse(requestId, limit.headers, ['Invalid published filter'])
    }

    const category = rawCategory ? sanitizeInput(rawCategory, 60) : ''
    const query = rawQuery ? sanitizeInput(rawQuery, 100) : ''
    const where: Prisma.DiscoverItemWhereInput = {
      ...(published && published !== 'all' ? { published: published === 'true' } : {}),
      ...(category ? { category } : {}),
      ...(query
        ? {
            OR: [
              { title: { contains: query } },
              { description: { contains: query } },
              { category: { contains: query } },
              { tags: { contains: query } },
            ],
          }
        : {}),
    }

    const items = await db.discoverItem.findMany({
      where,
      orderBy: [{ featured: 'desc' }, { order: 'asc' }, { updatedAt: 'desc' }],
    })

    const normalizedItems = items.map((item) => ({
      ...item,
      category: normalizeResponseCategory(item.category),
    }))

    return withCommonApiHeaders(NextResponse.json({ items: normalizedItems }), requestId, limit.headers)
  } catch (error) {
    logger.error('Error fetching Discover items', {
      requestId,
      error: error instanceof Error ? error.message : 'unknown',
    })
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Failed to fetch Discover items' }, { status: 500 }),
      requestId,
      limit.headers,
    )
  }
}

export async function POST(request: NextRequest) {
  const requestId = createRequestId(request)
  const unauthorized = await enforceAdminAccess(request, requestId)
  if (unauthorized) return unauthorized

  const limit = await checkRateLimit(request, 'admin:discover:post')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Too many requests', retryAt: limit.retryAt }, { status: 429 }),
      requestId,
      limit.headers,
    )
  }

  try {
    if (!requiresJson(request)) {
      return withCommonApiHeaders(
        NextResponse.json({ error: 'Content-Type application/json is required' }, { status: 415 }),
        requestId,
        limit.headers,
      )
    }

    const parsed = discoverCreateSchema.safeParse(await request.json())
    if (!parsed.success) {
      return validationResponse(requestId, limit.headers, parsed.error.issues.map((issue) => ({ path: issue.path.map(String), message: issue.message })))
    }

    const input = parsed.data
    const item = await db.discoverItem.create({
      data: normalizeDiscoverCreateInput(input),
    })

    return withCommonApiHeaders(NextResponse.json({ item }, { status: 201 }), requestId, limit.headers)
  } catch (error) {
    if (isUniqueConstraintError(error)) {
      return withCommonApiHeaders(
        NextResponse.json({ error: 'Slug already exists' }, { status: 409 }),
        requestId,
        limit.headers,
      )
    }

    logger.error('Error creating Discover item', {
      requestId,
      error: error instanceof Error ? error.message : 'unknown',
    })
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Failed to create Discover item' }, { status: 500 }),
      requestId,
      limit.headers,
    )
  }
}

export async function PATCH(request: NextRequest) {
  const requestId = createRequestId(request)
  const unauthorized = await enforceAdminAccess(request, requestId)
  if (unauthorized) return unauthorized

  const limit = await checkRateLimit(request, 'admin:discover:patch')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Too many requests', retryAt: limit.retryAt }, { status: 429 }),
      requestId,
      limit.headers,
    )
  }

  try {
    if (!requiresJson(request)) {
      return withCommonApiHeaders(
        NextResponse.json({ error: 'Content-Type application/json is required' }, { status: 415 }),
        requestId,
        limit.headers,
      )
    }

    const body = await request.json() as Record<string, unknown>
    const expectedUpdatedAt = parseExpectedUpdatedAt(body.expectedUpdatedAt)
    if (body.expectedUpdatedAt !== undefined && !expectedUpdatedAt) {
      return validationResponse(requestId, limit.headers, [{ path: ['expectedUpdatedAt'], message: 'A valid editor snapshot timestamp is required' }])
    }

    const parsed = discoverUpdateSchema.safeParse(body)
    if (!parsed.success) {
      return validationResponse(requestId, limit.headers, parsed.error.issues.map((issue) => ({ path: issue.path.map(String), message: issue.message })))
    }

    const { id, ...input } = parsed.data
    const requiresCurrentItem = input.published === true
      || input.publishedEn !== undefined
      || input.titleEn !== undefined
      || input.descriptionEn !== undefined
      || input.contentEn !== undefined
    const currentItem = requiresCurrentItem
      ? await db.discoverItem.findUnique({
          where: { id },
          select: { publishedAt: true, publishedEn: true, titleEn: true, descriptionEn: true, contentEn: true },
        })
      : null

    const data = normalizeDiscoverUpdateInput(input, currentItem ?? {
      publishedAt: null,
      publishedEn: false,
      titleEn: null,
      descriptionEn: null,
      contentEn: null,
    })

    const item = await db.discoverItem.update({
      where: expectedUpdatedAt ? { id, updatedAt: expectedUpdatedAt } : { id },
      data,
    })
    return withCommonApiHeaders(NextResponse.json({ item }), requestId, limit.headers)
  } catch (error) {
    if (error instanceof DiscoverEnglishPublicationError) {
      return validationResponse(requestId, limit.headers, [error.message])
    }

    if (isUniqueConstraintError(error)) {
      return withCommonApiHeaders(
        NextResponse.json({ error: 'Slug already exists' }, { status: 409 }),
        requestId,
        limit.headers,
      )
    }

    if (isMissingUpdateTargetError(error)) {
      return withCommonApiHeaders(
        NextResponse.json({
          code: 'STALE_WRITE',
          error: 'This Discover item changed after the editor loaded it. Reload the latest server version before saving again.',
        }, { status: 409 }),
        requestId,
        limit.headers,
      )
    }

    logger.error('Error updating Discover item', {
      requestId,
      error: error instanceof Error ? error.message : 'unknown',
    })
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Failed to update Discover item' }, { status: 500 }),
      requestId,
      limit.headers,
    )
  }
}

export async function DELETE(request: NextRequest) {
  const requestId = createRequestId(request)
  const unauthorized = await enforceAdminAccess(request, requestId)
  if (unauthorized) return unauthorized

  const limit = await checkRateLimit(request, 'admin:discover:delete')
  if (!limit.allowed) {
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Too many requests', retryAt: limit.retryAt }, { status: 429 }),
      requestId,
      limit.headers,
    )
  }

  try {
    const id = request.nextUrl.searchParams.get('id')
    if (!id || id.trim().length < 10) {
      return validationResponse(requestId, limit.headers, ['Discover item ID is required'])
    }

    await db.discoverItem.delete({ where: { id } })
    return withCommonApiHeaders(NextResponse.json({ success: true }), requestId, limit.headers)
  } catch (error) {
    logger.error('Error deleting Discover item', {
      requestId,
      error: error instanceof Error ? error.message : 'unknown',
    })
    return withCommonApiHeaders(
      NextResponse.json({ error: 'Failed to delete Discover item' }, { status: 500 }),
      requestId,
      limit.headers,
    )
  }
}