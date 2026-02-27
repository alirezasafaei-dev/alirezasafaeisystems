import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e/visual',
  testMatch: '**/*.spec.ts',
  timeout: 45_000,
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.015,
      animations: 'disabled',
      caret: 'hide',
    },
  },
  use: {
    baseURL: 'http://127.0.0.1:6006',
    viewport: { width: 1440, height: 1800 },
    colorScheme: 'light',
    channel: 'chrome',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'pnpm storybook --ci --port 6006 --no-open',
    url: 'http://127.0.0.1:6006',
    reuseExistingServer: true,
    timeout: 180_000,
  },
})
