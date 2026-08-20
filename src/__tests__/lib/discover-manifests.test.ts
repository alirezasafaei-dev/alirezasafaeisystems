import { mkdtemp, readdir, readFile, rm, writeFile } from 'node:fs/promises'
import { spawnSync } from 'node:child_process'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
import { discoverCreateSchema } from '@/lib/discover'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..')
const manifestsDirectory = path.join(projectRoot, 'docs/discover/resources')
const validatorPath = path.join(projectRoot, 'scripts/discover/validate-manifests.mjs')
const schemaContractTest = 'src/__tests__/lib/discover-manifests.test.ts'

describe('Discover resource manifests', () => {
  it('keeps persisted payloads schema-valid and evidence metadata separate', async () => {
    const filenames = (await readdir(manifestsDirectory)).filter((filename) => filename.endsWith('.json'))

    expect(filenames).not.toEqual([])

    for (const filename of filenames) {
      const manifest = JSON.parse(await readFile(path.join(manifestsDirectory, filename), 'utf8')) as {
        payload: Record<string, unknown>
        evidence: Record<string, unknown>
      }

      expect(Object.keys(manifest).sort()).toEqual(['evidence', 'payload'])
      expect(manifest.payload).not.toHaveProperty('evidence')
      expect(manifest.payload).not.toHaveProperty('publishedEn')

      const parsed = discoverCreateSchema.safeParse(manifest.payload)
      expect(parsed.success, filename).toBe(true)
      if (!parsed.success) continue

      expect(Object.keys(parsed.data).filter((key) => Object.hasOwn(manifest.payload, key)).sort()).toEqual(Object.keys(manifest.payload).sort())
      expect(parsed.data).not.toHaveProperty('evidence')
      expect(parsed.data.publishedEn, filename).toBe(false)
    }
  })

  it('uses the invoking pnpm CLI instead of a Unix executable shim', async () => {
    const temporaryDirectory = await mkdtemp(path.join(os.tmpdir(), 'discover-manifest-validator-'))
    const pnpmCliPath = path.join(temporaryDirectory, 'pnpm.cjs')
    const recordPath = path.join(temporaryDirectory, 'runner.json')

    await writeFile(pnpmCliPath, "require('node:fs').writeFileSync(process.env.MANIFEST_RUNNER_RECORD, JSON.stringify(process.argv.slice(2)))")

    try {
      const result = spawnSync(process.execPath, [validatorPath], {
        cwd: projectRoot,
        env: { ...process.env, npm_execpath: pnpmCliPath, MANIFEST_RUNNER_RECORD: recordPath },
      })

      expect(result.status).toBe(0)
      expect(JSON.parse(await readFile(recordPath, 'utf8'))).toEqual(['exec', 'vitest', 'run', schemaContractTest])
    } finally {
      await rm(temporaryDirectory, { recursive: true, force: true })
    }
  })
})