import { readdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
import { discoverCreateSchema } from '@/lib/discover'

const manifestsDirectory = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '../../../docs/discover/resources'
)

describe('Discover resource manifests', () => {
  it('keeps persisted payloads schema-valid and evidence metadata separate', async () => {
    const filenames = (await readdir(manifestsDirectory)).filter((filename) => filename.endsWith('.json'))

    expect(filenames).not.toEqual([])

    for (const filename of filenames) {
      const manifest = JSON.parse(await readFile(path.join(manifestsDirectory, filename), 'utf8')) as unknown

      expect(manifest).toMatchObject({ payload: expect.any(Object), evidence: expect.any(Object) })

      const { payload } = manifest as { payload: unknown }
      expect(discoverCreateSchema.safeParse(payload).success, filename).toBe(true)
    }
  })
})