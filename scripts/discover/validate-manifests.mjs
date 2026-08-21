import { readdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const manifestsDirectory = process.env.DISCOVER_MANIFESTS_DIR
  ? path.resolve(process.env.DISCOVER_MANIFESTS_DIR)
  : path.join(projectRoot, 'docs/discover/resources')
const schemaContractTest = 'src/__tests__/lib/discover-manifests.test.ts'

function getContractRunner() {
  const pnpmCliPath = process.env.npm_execpath
  if (!pnpmCliPath) throw new Error('pnpm execution path is unavailable')

  return {
    command: process.execPath,
    args: [pnpmCliPath, 'exec', 'vitest', 'run', schemaContractTest],
  }
}

function requireRecord(value, field) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${field} must be an object`)
  }
  return value
}

function validateCheckedAt(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new Error('evidence.checkedAt must use YYYY-MM-DD')
  }

  const parsed = new Date(`${value}T00:00:00.000Z`)
  if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    throw new Error('evidence.checkedAt must be a valid calendar date')
  }

  const today = new Date()
  const todayUtc = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate())
  if (parsed.getTime() > todayUtc) {
    throw new Error('evidence.checkedAt must not be in the future')
  }
}

function validateSources(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error('evidence.sources must be a non-empty array')
  }

  if (new Set(value).size !== value.length) {
    throw new Error('evidence.sources must contain unique URLs')
  }

  for (const source of value) {
    if (typeof source !== 'string') {
      throw new Error('evidence.sources entries must be HTTPS URLs')
    }

    let parsed
    try {
      parsed = new URL(source)
    } catch {
      throw new Error('evidence.sources entries must be HTTPS URLs')
    }

    if (parsed.protocol !== 'https:') {
      throw new Error('evidence.sources entries must be HTTPS URLs')
    }
  }
}

function validateManifestDocument(document) {
  const manifest = requireRecord(document, 'manifest')
  requireRecord(manifest.payload, 'payload')
  const evidence = requireRecord(manifest.evidence, 'evidence')
  validateCheckedAt(evidence.checkedAt)
  validateSources(evidence.sources)
}

async function main() {
  let filenames

  try {
    filenames = (await readdir(manifestsDirectory)).filter((filename) => filename.endsWith('.json')).sort()
  } catch (error) {
    console.error(`Discover manifest validation failed: ${error instanceof Error ? error.message : String(error)}`)
    process.exitCode = 1
    return
  }

  if (filenames.length === 0) {
    console.error('Discover manifest validation failed: no JSON manifests found')
    process.exitCode = 1
    return
  }

  for (const filename of filenames) {
    try {
      const document = JSON.parse(await readFile(path.join(manifestsDirectory, filename), 'utf8'))
      validateManifestDocument(document)
    } catch (error) {
      console.error(`Discover manifest validation failed for ${filename}: ${error instanceof Error ? error.message : String(error)}`)
      process.exitCode = 1
      return
    }
  }

  let result
  try {
    const runner = getContractRunner()
    result = spawnSync(runner.command, runner.args, { cwd: projectRoot, stdio: 'inherit' })
  } catch (error) {
    console.error(`Discover manifest validation failed: ${error instanceof Error ? error.message : String(error)}`)
    process.exitCode = 1
    return
  }

  if (result.error) {
    console.error(`Discover manifest validation failed: ${result.error.message}`)
    process.exitCode = 1
    return
  }

  if (result.status !== 0) {
    process.exitCode = result.status ?? 1
    return
  }

  for (const filename of filenames) process.stdout.write(`VALID ${filename}\n`)
}

if (process.argv[1] === fileURLToPath(import.meta.url)) await main()
