import { execSync } from 'node:child_process'
import { mkdirSync, writeFileSync } from 'node:fs'

const routeMap = [
  { route: '/fa/', file: 'src/app/page.tsx', priority: 1, changeFrequency: 'weekly' },
  { route: '/fa/services', file: 'src/app/services/page.tsx', priority: 0.95, changeFrequency: 'weekly' },
  {
    route: '/fa/services/infrastructure-localization',
    file: 'src/app/services/infrastructure-localization/page.tsx',
    priority: 0.95,
    changeFrequency: 'weekly',
  },
  { route: '/fa/qualification', file: 'src/app/qualification/page.tsx', priority: 0.9, changeFrequency: 'weekly' },
  { route: '/fa/profile', file: 'src/app/profile/page.tsx', priority: 0.88, changeFrequency: 'monthly' },
  { route: '/fa/standards', file: 'src/app/standards/page.tsx', priority: 0.84, changeFrequency: 'monthly' },
  { route: '/fa/case-studies', file: 'src/app/case-studies/page.tsx', priority: 0.85, changeFrequency: 'monthly' },
  {
    route: '/fa/case-studies/alirezasafaeidev-portfolio',
    file: 'src/app/case-studies/alirezasafaeidev-portfolio/page.tsx',
    priority: 0.82,
    changeFrequency: 'monthly',
  },
  {
    route: '/fa/case-studies/infrastructure-localization-rescue',
    file: 'src/app/case-studies/infrastructure-localization-rescue/page.tsx',
    priority: 0.8,
    changeFrequency: 'monthly',
  },
  {
    route: '/fa/case-studies/asdev-persiantoolbox-platform',
    file: 'src/app/case-studies/asdev-persiantoolbox-platform/page.tsx',
    priority: 0.82,
    changeFrequency: 'monthly',
  },
  {
    route: '/fa/case-studies/legacy-nextjs-replatform',
    file: 'src/app/case-studies/legacy-nextjs-replatform/page.tsx',
    priority: 0.8,
    changeFrequency: 'monthly',
  },
  {
    route: '/fa/case-studies/ci-cd-governance-hardening',
    file: 'src/app/case-studies/ci-cd-governance-hardening/page.tsx',
    priority: 0.8,
    changeFrequency: 'monthly',
  },
  { route: '/fa/about-brand', file: 'src/app/about-brand/page.tsx', priority: 0.8, changeFrequency: 'monthly' },
]

function getLastModified(file) {
  try {
    const lastCommit = execSync(`git log -1 --format=%cI -- "${file}"`, {
      stdio: ['ignore', 'pipe', 'ignore'],
      encoding: 'utf8',
    }).trim()
    return lastCommit || new Date().toISOString()
  } catch {
    return new Date().toISOString()
  }
}

const manifest = routeMap.map((entry) => ({
  route: entry.route,
  lastModified: getLastModified(entry.file),
  priority: entry.priority,
  changeFrequency: entry.changeFrequency,
}))

mkdirSync('src/generated', { recursive: true })
writeFileSync('src/generated/sitemap-manifest.json', `${JSON.stringify(manifest, null, 2)}\n`, 'utf8')
