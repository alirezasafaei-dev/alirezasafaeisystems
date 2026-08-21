import { resolve } from 'node:path'
import { PrismaClient } from '@prisma/client'

const databaseUrl = process.env.DATABASE_URL
const expectedPath = resolve(process.cwd(), 'test-results/playwright.db')

if (!databaseUrl?.startsWith('file:')) {
  throw new Error('Playwright Discover seed requires a SQLite DATABASE_URL')
}

const rawPath = databaseUrl.slice('file:'.length).split('?', 1)[0]
const actualPath = resolve(rawPath)

if (actualPath !== expectedPath) {
  throw new Error(`Refusing to seed non-disposable database: ${actualPath}`)
}

const db = new PrismaClient({ datasourceUrl: databaseUrl })

const bilingual = {
  slug: 'playwright-discover-resource',
  title: 'منبع آزمایشی دیسکاور',
  description: 'منبع قطعی و موقت برای آزمون مرورگری دیسکاور.',
  content: 'این راهنمای کوتاه فقط داخل پایگاه داده موقت Playwright ساخته می‌شود.',
  titleEn: 'Playwright Discover Resource',
  descriptionEn: 'Deterministic Discover resource used only by browser tests.',
  contentEn: 'This quick guide is seeded only for disposable browser testing.',
  externalUrl: 'https://example.com/tool',
  category: 'ai',
  tags: 'playwright,testing',
  imageUrl: null,
  instagramUrl: null,
  telegramGuideUrl: 'https://t.me/asdev_test/123',
  featured: false,
  published: true,
  publishedEn: true,
  order: 9998,
  publishedAt: new Date('2026-08-19T00:00:00.000Z'),
}

const persianOnly = {
  slug: 'playwright-persian-only-resource',
  title: 'منبع فقط فارسی',
  description: 'این رکورد برای اثبات عدم انتشار نسخه انگلیسی استفاده می‌شود.',
  content: 'این محتوا فقط در مسیر فارسی باید قابل مشاهده باشد.',
  titleEn: null,
  descriptionEn: null,
  contentEn: null,
  externalUrl: 'https://example.com/fa-only-tool',
  category: 'general',
  tags: 'playwright,persian-only',
  imageUrl: null,
  instagramUrl: null,
  telegramGuideUrl: null,
  featured: false,
  published: true,
  publishedEn: false,
  order: 9999,
  publishedAt: new Date('2026-08-19T00:00:00.000Z'),
}

try {
  await db.discoverItem.upsert({
    where: { slug: bilingual.slug },
    create: bilingual,
    update: bilingual,
  })

  await db.discoverItem.upsert({
    where: { slug: persianOnly.slug },
    create: persianOnly,
    update: persianOnly,
  })
} finally {
  await db.$disconnect()
}
