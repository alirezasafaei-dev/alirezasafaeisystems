import { mkdtemp, mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises'
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

function expectValidCheckedAt(value: unknown, filename: string) {
  expect(typeof value, filename).toBe('string')
  expect(value, filename).toMatch(/^\d{4}-\d{2}-\d{2}$/)
  const parsed = new Date(`${String(value)}T00:00:00.000Z`)
  expect(Number.isNaN(parsed.getTime()), filename).toBe(false)
  expect(parsed.toISOString().slice(0, 10), filename).toBe(value)
  expect(parsed.getTime(), filename).toBeLessThanOrEqual(Date.now())
}

function expectValidSources(value: unknown, filename: string) {
  expect(Array.isArray(value), filename).toBe(true)
  if (!Array.isArray(value)) return
  expect(value.length, filename).toBeGreaterThan(0)
  expect(new Set(value).size, filename).toBe(value.length)
  for (const source of value) {
    expect(typeof source, filename).toBe('string')
    expect(() => new URL(String(source)), filename).not.toThrow()
    expect(new URL(String(source)).protocol, filename).toBe('https:')
  }
}

async function runValidatorWithManifest(manifest: Record<string, unknown>) {
  const temporaryDirectory = await mkdtemp(path.join(os.tmpdir(), 'discover-manifest-freshness-'))
  const manifestsPath = path.join(temporaryDirectory, 'resources')
  const pnpmCliPath = path.join(temporaryDirectory, 'pnpm.cjs')
  await mkdir(manifestsPath)
  await writeFile(path.join(manifestsPath, 'fixture.json'), `${JSON.stringify(manifest)}\n`)
  await writeFile(pnpmCliPath, 'process.exit(0)')

  const result = spawnSync(process.execPath, [validatorPath], {
    cwd: projectRoot,
    env: {
      ...process.env,
      npm_execpath: pnpmCliPath,
      DISCOVER_MANIFESTS_DIR: manifestsPath,
    },
    encoding: 'utf8',
  })

  await rm(temporaryDirectory, { recursive: true, force: true })
  return result
}

const validFreshnessManifest = {
  payload: { slug: 'fixture', published: false },
  evidence: {
    checkedAt: '2026-08-21',
    sources: ['https://example.com/source'],
  },
}

describe('Discover resource manifests', () => {
  it('keeps persisted payloads schema-valid and evidence metadata separate', async () => {
    const filenames = (await readdir(manifestsDirectory)).filter((filename) => filename.endsWith('.json'))

    expect(filenames).not.toEqual([])

    for (const filename of filenames) {
      const manifest = JSON.parse(await readFile(path.join(manifestsDirectory, filename), 'utf8')) as {
        payload: Record<string, unknown>
        evidence: { checkedAt?: unknown; sources?: unknown } & Record<string, unknown>
      }

      expect(Object.keys(manifest).sort()).toEqual(['evidence', 'payload'])
      expect(manifest.payload).not.toHaveProperty('evidence')
      expect(manifest.payload).not.toHaveProperty('checkedAt')
      expect(manifest.payload).not.toHaveProperty('sources')
      expect(manifest.payload).not.toHaveProperty('publishedEn')
      expectValidCheckedAt(manifest.evidence.checkedAt, filename)
      expectValidSources(manifest.evidence.sources, filename)

      const parsed = discoverCreateSchema.safeParse(manifest.payload)
      expect(parsed.success, filename).toBe(true)
      if (!parsed.success) continue

      expect(Object.keys(parsed.data).filter((key) => Object.hasOwn(manifest.payload, key)).sort()).toEqual(Object.keys(manifest.payload).sort())
      expect(parsed.data).not.toHaveProperty('evidence')
      expect(parsed.data.publishedEn, filename).toBe(false)
    }
  })

  it.each([
    ['missing checkedAt', { ...validFreshnessManifest, evidence: { sources: ['https://example.com/source'] } }, 'checkedAt'],
    ['invalid checkedAt', { ...validFreshnessManifest, evidence: { checkedAt: '2026-02-30', sources: ['https://example.com/source'] } }, 'checkedAt'],
    ['future checkedAt', { ...validFreshnessManifest, evidence: { checkedAt: '2999-01-01', sources: ['https://example.com/source'] } }, 'checkedAt'],
    ['empty sources', { ...validFreshnessManifest, evidence: { checkedAt: '2026-08-21', sources: [] } }, 'sources'],
    ['non-HTTPS source', { ...validFreshnessManifest, evidence: { checkedAt: '2026-08-21', sources: ['http://example.com/source'] } }, 'HTTPS'],
    ['duplicate sources', { ...validFreshnessManifest, evidence: { checkedAt: '2026-08-21', sources: ['https://example.com/source', 'https://example.com/source'] } }, 'unique'],
  ])('rejects %s freshness evidence before schema execution', async (_label, manifest, expectedError) => {
    const result = await runValidatorWithManifest(manifest)

    expect(result.status).not.toBe(0)
    expect(`${result.stdout}\n${result.stderr}`).toContain('fixture.json')
    expect(`${result.stdout}\n${result.stderr}`).toContain(expectedError)
  })

  it('accepts well-formed freshness evidence before schema execution', async () => {
    const result = await runValidatorWithManifest(validFreshnessManifest)

    expect(result.status).toBe(0)
    expect(result.stdout).toContain('VALID fixture.json')
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
