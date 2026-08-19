import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const db =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'warn', 'error'] : ['warn', 'error'],
  })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db

export async function diagnoseDatabaseConnection(label: string): Promise<void> {
  if (process.env.ASDEV_DB_DIAGNOSTIC !== '1') return

  const rawDatabaseUrl = process.env.DATABASE_URL
  const safeDatabaseUrl = rawDatabaseUrl?.startsWith('file:')
    ? rawDatabaseUrl.split('?', 1)[0]
    : rawDatabaseUrl
      ? '<non-file>'
      : '<unset>'

  try {
    const databaseList = await db.$queryRawUnsafe('PRAGMA database_list')
    console.info('[db-diagnostic]', {
      label,
      cwd: process.cwd(),
      databaseUrl: safeDatabaseUrl,
      databaseList,
    })
  } catch (error) {
    console.info('[db-diagnostic]', {
      label,
      cwd: process.cwd(),
      databaseUrl: safeDatabaseUrl,
      error: error instanceof Error ? error.message : 'unknown',
    })
  }
}
