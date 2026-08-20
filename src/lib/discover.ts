import { z } from 'zod'
import { normalizeDiscoverCategory } from '@/lib/discover-categories'
import { optionalTelegramUrlSchema } from '@/lib/telegram'

export const DISCOVER_ATTRIBUTION_KEYS = [
  'utm_source',
  'utm_medium',
  'utm_campaign',
  'utm_content',
] as const

export type DiscoverAttributionKey = (typeof DISCOVER_ATTRIBUTION_KEYS)[number]
export type DiscoverAttribution = Partial<Record<DiscoverAttributionKey, string>>

export const discoverSlugSchema = z
  .string()
  .trim()
  .min(2)
  .max(100)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Slug must use lowercase letters, digits, and hyphens only')

const discoverTitleSchema = z.string().trim().min(1).max(140)
const discoverDescriptionSchema = z.string().trim().min(1).max(400)
const discoverContentSchema = z.string().trim().min(1).max(8000)
const discoverTitleEnSchema = z.string().trim().min(1).max(140).nullable().optional()
const discoverDescriptionEnSchema = z.string().trim().min(1).max(400).nullable().optional()
const discoverContentEnSchema = z.string().trim().min(1).max(8000).nullable().optional()
const discoverCategorySchema = z
  .string()
  .trim()
  .refine((value) => {
    try {
      normalizeDiscoverCategory(value)
      return true
    } catch {
      return false
    }
  }, 'Unknown Discover category')
  .transform(normalizeDiscoverCategory)
const discoverOrderSchema = z.number().int().nonnegative()
const discoverTagSchema = z.string().trim().min(1).max(40)

export const discoverTagsSchema = z
  .union([z.array(discoverTagSchema), z.string()])
  .transform((value) => {
    const values = Array.isArray(value) ? value : value.split(',')
    return [...new Set(values.map((tag) => tag.trim()).filter(Boolean))]
  })
  .refine((tags) => tags.length <= 20, 'At most 20 tags are allowed')

function isSafeHttpsUrl(value: string): boolean {
  try {
    const url = new URL(value)
    return url.protocol === 'https:' && !url.username && !url.password
  } catch {
    return false
  }
}

export const discoverUrlSchema = z
  .string()
  .trim()
  .min(1)
  .max(2000)
  .refine(isSafeHttpsUrl, 'A credential-free HTTPS URL is required')

export const optionalDiscoverUrlSchema = z
  .union([z.literal(''), discoverUrlSchema])
  .optional()
  .transform((value) => (value === '' ? null : value))

export const discoverInstagramUrlSchema = z
  .union([
    z.literal(''),
    discoverUrlSchema.refine((value) => {
      const hostname = new URL(value).hostname.toLowerCase()
      return hostname === 'instagram.com' || hostname.endsWith('.instagram.com')
    }, 'Instagram URL must use instagram.com'),
  ])
  .optional()
  .transform((value) => (value === '' ? null : value))

export const discoverFieldsSchema = z.object({
  slug: discoverSlugSchema,
  title: discoverTitleSchema,
  description: discoverDescriptionSchema,
  content: discoverContentSchema,
  titleEn: discoverTitleEnSchema,
  descriptionEn: discoverDescriptionEnSchema,
  contentEn: discoverContentEnSchema,
  externalUrl: discoverUrlSchema,
  category: discoverCategorySchema,
  tags: discoverTagsSchema,
  imageUrl: optionalDiscoverUrlSchema,
  instagramUrl: discoverInstagramUrlSchema,
  telegramGuideUrl: optionalTelegramUrlSchema,
  featured: z.boolean().optional().default(false),
  published: z.boolean().optional().default(false),
  publishedEn: z.boolean().optional().default(false),
  order: discoverOrderSchema.optional().default(0),
})

export const discoverCreateSchema = discoverFieldsSchema.superRefine(validateEnglishPublication)

export const discoverUpdateSchema = z.object({
  id: z.string().trim().min(10).max(200),
  slug: discoverSlugSchema.optional(),
  title: discoverTitleSchema.optional(),
  description: discoverDescriptionSchema.optional(),
  content: discoverContentSchema.optional(),
  titleEn: discoverTitleEnSchema,
  descriptionEn: discoverDescriptionEnSchema,
  contentEn: discoverContentEnSchema,
  externalUrl: discoverUrlSchema.optional(),
  category: discoverCategorySchema.optional(),
  tags: discoverTagsSchema.optional(),
  imageUrl: optionalDiscoverUrlSchema,
  instagramUrl: discoverInstagramUrlSchema,
  telegramGuideUrl: optionalTelegramUrlSchema,
  featured: z.boolean().optional(),
  published: z.boolean().optional(),
  publishedEn: z.boolean().optional(),
  order: discoverOrderSchema.optional(),
}).superRefine(validateEnglishPublication)

function validateEnglishPublication(
  value: { publishedEn?: boolean; titleEn?: string | null; descriptionEn?: string | null; contentEn?: string | null },
  context: z.RefinementCtx
): void {
  if (!value.publishedEn) return

  for (const field of ['titleEn', 'descriptionEn', 'contentEn'] as const) {
    if (!value[field]?.trim()) {
      context.addIssue({ code: z.ZodIssueCode.custom, message: 'English content is required when publishedEn is true', path: [field] })
    }
  }
}

function normalizeAttributionValue(value: unknown): string | undefined {
  const raw = Array.isArray(value) ? value[0] : value
  if (typeof raw !== 'string') return undefined
  const normalized = raw
    .trim()
    .replace(/[\u0000-\u001f\u007f]/g, '')
    .slice(0, 100)
  return normalized || undefined
}

export function extractDiscoverAttribution(
  input: URLSearchParams | Record<string, string | string[] | undefined>
): DiscoverAttribution {
  const result: DiscoverAttribution = {}

  for (const key of DISCOVER_ATTRIBUTION_KEYS) {
    const rawValue = input instanceof URLSearchParams ? input.get(key) ?? undefined : input[key]
    const value = normalizeAttributionValue(rawValue)
    if (value) result[key] = value
  }

  return result
}

export function appendDiscoverAttribution(path: string, attribution: DiscoverAttribution): string {
  const [pathname, query = ''] = path.split('?', 2)
  const params = new URLSearchParams(query)

  for (const key of DISCOVER_ATTRIBUTION_KEYS) {
    const value = normalizeAttributionValue(attribution[key])
    if (value) params.set(key, value)
  }

  const serialized = params.toString()
  return serialized ? `${pathname}?${serialized}` : pathname
}

export function discoverAnalyticsMetadata(
  attribution: DiscoverAttribution,
  extra: Record<string, string | number | boolean> = {}
): Record<string, string | number | boolean> {
  const metadata: Record<string, string | number | boolean> = { ...extra }
  for (const key of DISCOVER_ATTRIBUTION_KEYS) {
    const value = normalizeAttributionValue(attribution[key])
    if (value) metadata[key] = value
  }
  return metadata
}
