import { Prisma } from '@prisma/client'
import { z } from 'zod'
import { normalizeDiscoverCategory } from '@/lib/discover-categories'
import { discoverCreateSchema, discoverUpdateSchema } from '@/lib/discover'
import { sanitizeInput } from '@/lib/validators'

type DiscoverCreateInput = z.output<typeof discoverCreateSchema>
type DiscoverUpdateInput = Omit<z.output<typeof discoverUpdateSchema>, 'id'>
type DiscoverUpdateCurrent = {
  publishedAt: Date | null
  publishedEn: boolean
  titleEn: string | null
  descriptionEn: string | null
  contentEn: string | null
}

export class DiscoverEnglishPublicationError extends Error {
  constructor() {
    super('English content is required when publishedEn is true')
  }
}

export function normalizeDiscoverCreateInput(input: DiscoverCreateInput): Prisma.DiscoverItemCreateInput {
  return {
    slug: input.slug,
    title: sanitizeInput(input.title, 140),
    description: sanitizeInput(input.description, 400),
    content: sanitizeInput(input.content, 8000),
    titleEn: input.titleEn === null ? null : input.titleEn ? sanitizeInput(input.titleEn, 140) : null,
    descriptionEn: input.descriptionEn === null ? null : input.descriptionEn ? sanitizeInput(input.descriptionEn, 400) : null,
    contentEn: input.contentEn === null ? null : input.contentEn ? sanitizeInput(input.contentEn, 8000) : null,
    externalUrl: input.externalUrl,
    category: normalizeDiscoverCategory(input.category),
    tags: input.tags.join(','),
    imageUrl: input.imageUrl ?? null,
    instagramUrl: input.instagramUrl ?? null,
    telegramGuideUrl: input.telegramGuideUrl ?? null,
    featured: input.featured,
    published: input.published,
    publishedEn: input.publishedEn,
    order: input.order,
    publishedAt: input.published ? new Date() : null,
  }
}

export function normalizeDiscoverUpdateInput(
  input: DiscoverUpdateInput,
  current: DiscoverUpdateCurrent,
): Prisma.DiscoverItemUpdateInput {
  const publishedEn = input.publishedEn ?? current.publishedEn
  const titleEn = input.titleEn !== undefined ? input.titleEn : current.titleEn
  const descriptionEn = input.descriptionEn !== undefined ? input.descriptionEn : current.descriptionEn
  const contentEn = input.contentEn !== undefined ? input.contentEn : current.contentEn

  if (publishedEn && (!titleEn?.trim() || !descriptionEn?.trim() || !contentEn?.trim())) {
    throw new DiscoverEnglishPublicationError()
  }

  return {
    ...(input.slug !== undefined ? { slug: input.slug } : {}),
    ...(input.title !== undefined ? { title: sanitizeInput(input.title, 140) } : {}),
    ...(input.description !== undefined ? { description: sanitizeInput(input.description, 400) } : {}),
    ...(input.content !== undefined ? { content: sanitizeInput(input.content, 8000) } : {}),
    ...(input.titleEn !== undefined ? { titleEn: input.titleEn === null ? null : sanitizeInput(input.titleEn, 140) } : {}),
    ...(input.descriptionEn !== undefined ? { descriptionEn: input.descriptionEn === null ? null : sanitizeInput(input.descriptionEn, 400) } : {}),
    ...(input.contentEn !== undefined ? { contentEn: input.contentEn === null ? null : sanitizeInput(input.contentEn, 8000) } : {}),
    ...(input.externalUrl !== undefined ? { externalUrl: input.externalUrl } : {}),
    ...(input.category !== undefined ? { category: normalizeDiscoverCategory(input.category) } : {}),
    ...(input.tags !== undefined ? { tags: input.tags.join(',') } : {}),
    ...(input.imageUrl !== undefined ? { imageUrl: input.imageUrl ?? null } : {}),
    ...(input.instagramUrl !== undefined ? { instagramUrl: input.instagramUrl ?? null } : {}),
    ...(input.telegramGuideUrl !== undefined ? { telegramGuideUrl: input.telegramGuideUrl ?? null } : {}),
    ...(input.featured !== undefined ? { featured: input.featured } : {}),
    ...(input.published !== undefined ? { published: input.published } : {}),
    ...(input.publishedEn !== undefined ? { publishedEn: input.publishedEn } : {}),
    ...(input.order !== undefined ? { order: input.order } : {}),
    ...(input.published === true && !current.publishedAt ? { publishedAt: new Date() } : {}),
  }
}
