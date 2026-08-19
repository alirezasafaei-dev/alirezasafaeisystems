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

try {
  await db.discoverItem.upsert({
    where: { slug: 'playwright-discover-resource' },
    create: {
      slug: 'playwright-discover-resource',
      title: 'Playwright Discover Resource',
      description: 'Deterministic Discover resource used only by browser tests.',
      content: 'This quick guide is seeded only for disposable browser testing.',
      externalUrl: 'https://example.com/tool',
      category: 'Testing',
      tags: 'playwright,testing',
      telegramGuideUrl: 'https://t.me/asdev_test/123',
      featured: false,
      published: true,
      order: 9999,
      publishedAt: new Date('2026-08-19T00:00:00.000Z'),
    },
    update: {
      title: 'Playwright Discover Resource',
      description: 'Deterministic Discover resource used only by browser tests.',
      content: 'This quick guide is seeded only for disposable browser testing.',
      externalUrl: 'https://example.com/tool',
      category: 'Testing',
      tags: 'playwright,testing',
      imageUrl: null,
      instagramUrl: null,
      telegramGuideUrl: 'https://t.me/asdev_test/123',
      featured: false,
      published: true,
      order: 9999,
      publishedAt: new Date('2026-08-19T00:00:00.000Z'),
    },
  })
} finally {
  await db.$disconnect()
}
