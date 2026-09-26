import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const root = process.cwd()
const migrationPath = join(
  root,
  'prisma/migrations/20260821153000_seed_instagram_discover_resources/migration.sql',
)

const expected = [
  {
    slug: 'google-flow',
    manifest: 'google-flow.json',
    reel: 'https://www.instagram.com/reel/Db5PQ_tMACT/',
    officialHost: 'labs.google',
  },
  {
    slug: 'ai-chat-chatbot-assistant',
    manifest: 'ai-chat-chatbot-assistant.json',
    reel: 'https://www.instagram.com/reel/Db35Do4MY0G/',
    officialHost: 'play.google.com',
  },
  {
    slug: 'vibe-by-mistral',
    manifest: 'vibe-by-mistral.json',
    reel: 'https://www.instagram.com/reel/Db_sO5lMvey/',
    officialHost: 'play.google.com',
  },
  {
    slug: 'alura-ai-photo-video-generator',
    manifest: 'alura-ai-photo-video-generator.json',
    reel: 'https://www.instagram.com/reel/Db6HFc7M00S/',
    officialHost: 'play.google.com',
  },
  {
    slug: 'qwen',
    manifest: 'qwen.json',
    reel: 'https://www.instagram.com/reel/DcMGDMKMqmE/',
    officialHost: 'qwen.ai',
  },
  {
    slug: 'chaton',
    manifest: 'chaton.json',
    reel: 'https://www.instagram.com/reel/DcOtzg9sCDe/',
    officialHost: 'play.google.com',
  },
] as const

describe('Instagram Discover seed resources', () => {
  it('has one staged manifest per approved published Reel and only official primary destinations', () => {
    for (const item of expected) {
      const path = join(root, 'docs/discover/resources', item.manifest)
      expect(existsSync(path), `${item.manifest} must exist`).toBe(true)
      const parsed = JSON.parse(readFileSync(path, 'utf8')) as {
        payload: {
          slug: string
          externalUrl: string
          instagramUrl: string
          published: boolean
          publishedEn?: boolean
        }
      }

      expect(parsed.payload.slug).toBe(item.slug)
      expect(parsed.payload.instagramUrl).toBe(item.reel)
      expect(new URL(parsed.payload.externalUrl).hostname).toBe(item.officialHost)
      expect(parsed.payload.published).toBe(false)
      expect(parsed.payload.publishedEn ?? false).toBe(false)
    }
  })

  it('seeds the six Persian resources as published without third-party premium APK routes', () => {
    expect(existsSync(migrationPath), 'seed migration must exist').toBe(true)
    const migration = readFileSync(migrationPath, 'utf8')

    for (const item of expected) {
      expect(migration).toContain(`'${item.slug}'`)
      expect(migration).toContain(item.reel)
    }

    expect(migration).toContain('"published"')
    expect(migration).toContain('"publishedEn"')
    expect(migration).not.toContain('farsroid.com')
    expect(migration).not.toContain('dl.farsroid.com')
    expect(migration).not.toContain('Premium-')
    expect(migration).not.toContain('Mod APK')
  })
})
