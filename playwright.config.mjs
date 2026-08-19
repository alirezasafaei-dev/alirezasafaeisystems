import fs from 'node:fs'
import { resolve } from 'node:path'

const systemChromePath = '/usr/bin/google-chrome'
const disableWebServer = process.env.PLAYWRIGHT_DISABLE_WEBSERVER === 'true'
const playwrightDatabaseUrl = `file:${resolve(process.cwd(), 'test-results/playwright.db')}`
const launchOptions = fs.existsSync(systemChromePath)
  ? {
      executablePath: systemChromePath,
      args: ['--no-sandbox', '--disable-dev-shm-usage'],
    }
  : undefined

const config = {
  testDir: './e2e',
  outputDir: './test-results/playwright-artifacts',
  timeout: 30_000,
  retries: 1,
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://127.0.0.1:3100',
    headless: true,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'off',
    launchOptions,
  },
  webServer: disableWebServer
    ? undefined
    : {
        command: 'node -e "require(\'node:fs\').mkdirSync(\'test-results\',{recursive:true})" && pnpm prisma db push --skip-generate --accept-data-loss && node scripts/test/seed-playwright-discover.mjs && pnpm run build && node scripts/start-playwright-server.mjs',
        url: 'http://127.0.0.1:3100',
        reuseExistingServer: true,
        timeout: 240_000,
        env: {
          DATABASE_URL: playwrightDatabaseUrl,
        },
      },
}

export default config
