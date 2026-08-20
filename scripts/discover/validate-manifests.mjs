import { readdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const manifestsDirectory = path.join(projectRoot, 'docs/discover/resources')
const schemaContractTest = 'src/__tests__/lib/discover-manifests.test.ts'

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
      JSON.parse(await readFile(path.join(manifestsDirectory, filename), 'utf8'))
    } catch (error) {
      console.error(`Discover manifest validation failed for ${filename}: ${error instanceof Error ? error.message : String(error)}`)
      process.exitCode = 1
      return
    }
  }

  const result = spawnSync(path.join(projectRoot, 'node_modules/.bin/vitest'), ['run', schemaContractTest], {
    cwd: projectRoot,
    stdio: 'inherit',
  })

  if (result.status !== 0) {
    process.exitCode = result.status ?? 1
    return
  }

  for (const filename of filenames) process.stdout.write(`VALID ${filename}\n`)
}

await main()