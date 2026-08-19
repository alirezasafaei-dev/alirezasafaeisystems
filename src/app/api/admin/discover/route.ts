import { Prisma } from '@prisma/client'
import { NextRequest, NextResponse } from 'next/server'
import { checkRateLimit, createRequestId, enforceAdminAccess, withCommonApiHeaders } from '@/lib/api-security'
import { db } from '@/lib/db'
import { discoverCreateSchema, discoverUpdateSchema } from '@/lib/discover'
import { logger } from '@/lib/logger'
import { sanitizeInput } from '@/lib/validators'

function requiresJson(request: NextRequest): boolean {
  return (request.headers.get('content-type') || '').split(';', 1)[0].trim().toLowerCase() === 'application/json'
}

function isUniqueConstraintError(error: unknown): boolean {
  return error instanceof Prisma.PrismaClientKnownRequestError
    ? error.code === 'P2002'
    : Boolean(error && typeof error === 'object' && 'code' in error && error.code === 'P2002')
}

function validationResponse(requestId: string, headers: Record<string, string>, issues: string[]) {
  return withCommonApiHeaders(
    NextResponse.json({ error: 'Validation failed', details: issues }, { status: 400 }),
    requestId,
    headers,
  )
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

    return withCommonApiHeaders(NextResponse.json({ items }), requestId, limit.headers)
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
      return validationResponse(requestId, limit.headers, parsed.error.issues.map((issue) => issue.message))
    }

    const input = parsed.data
    const item = await db.discoverItem.create({
      data: {
        slug: input.slug,
        title: sanitizeInput(input.title, 140),
        description: sanitizeInput(input.description, 400),
        content: sanitizeInput(input.content, 8000),
        externalUrl: input.externalUrl,
        category: sanitizeInput(input.category, 60),
        tags: input.tags.join(','),
        imageUrl: input.imageUrl,
        instagramUrl: input.instagramUrl,
        telegramGuideUrl: input.telegramGuideUrl,
        featured: input.featured,
        published: input.published,
        order: input.order,
        publishedAt: input.published ? new Date() : null,
      },
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

    const parsed = discoverUpdateSchema.safeParse(await request.json())
    if (!parsed.success) {
      return validationResponse(requestId, limit.headers, parsed.error.issues.map((issue) => issue.message))
    }

    const { id, ...input } = parsed.data
    const publication = input.published === true
      ? await db.discoverItem.findUnique({ where: { id }, select: { publishedAt: true } })
      : null

    const data: Prisma.DiscoverItemUpdateInput = {
      ...(input.slug !== undefined ? { slug: input.slug } : {}),
      ...(input.title !== undefined ? { title: sanitizeInput(input.title, 140) } : {}),
      ...(input.description !== undefined ? { description: sanitizeInput(input.description, 400) } : {}),
      ...(input.content !== undefined ? { content: sanitizeInput(input.content, 8000) } : {}),
      ...(input.externalUrl !== undefined ? { externalUrl: input.externalUrl } : {}),
      ...(input.category !== undefined ? { category: sanitizeInput(input.category, 60) } : {}),
      ...(input.tags !== undefined ? { tags: input.tags.join(',') } : {}),
      ...(input.imageUrl !== undefined ? { imageUrl: input.imageUrl ?? null } : {}),
      ...(input.instagramUrl !== undefined ? { instagramUrl: input.instagramUrl ?? null } : {}),
      ...(input.telegramGuideUrl !== undefined ? { telegramGuideUrl: input.telegramGuideUrl ?? null } : {}),
      ...(input.featured !== undefined ? { featured: input.featured } : {}),
      ...(input.published !== undefined ? { published: input.published } : {}),
      ...(input.order !== undefined ? { order: input.order } : {}),
      ...(input.published === true && !publication?.publishedAt ? { publishedAt: new Date() } : {}),
    }

    const item = await db.discoverItem.update({ where: { id }, data })
    return withCommonApiHeaders(NextResponse.json({ item }), requestId, limit.headers)
  } catch (error) {
    if (isUniqueConstraintError(error)) {
      return withCommonApiHeaders(
        NextResponse.json({ error: 'Slug already exists' }, { status: 409 }),
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
