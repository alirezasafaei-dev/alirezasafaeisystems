# alirezasafaeisystems

<p align="center">
  <img src="./assets/repo-preview.svg" alt="alirezasafaeisystems preview" width="100%" />
</p>

Portfolio and lead-generation platform for AliReza Safaei (Web Systems Engineer), built with Next.js App Router and a production-focused ops/governance workflow.

## Tech Stack
- Next.js 16 (App Router, TypeScript)
- Tailwind CSS + shadcn/ui
- Prisma + SQLite (upgrade path to Postgres via `DATABASE_URL`)
- Vitest + Playwright + Lighthouse CI
- PM2/Nginx VPS deployment scripts and governance automation

## Prerequisites
- Node.js `>=20 <23` (recommended: Node 20)
- pnpm `>=9 <11`

## Quick Start
```bash
pnpm install --frozen-lockfile
cp .env.example .env
pnpm run db:generate
pnpm run db:push
pnpm run dev
```

## Quality Gates
```bash
pnpm run verify
pnpm run test:e2e:smoke
pnpm run lighthouse:ci
```

## Key Scripts
- `pnpm run verify`: lint + type-check + tests + build + external scan
- `pnpm run enterprise:gate`: verify + dependency audit + secret scan + ownership gate (+ optional SLO check with `SITE_URL`)
- `pnpm run test:e2e:smoke`: release smoke tests
- `pnpm run lighthouse:ci`: performance/SEO/a11y budgets
- `pnpm run audit:high`: dependency high/critical audit gate
- `pnpm run scan:secrets`: local secret scanning

## Optional Font CDN Fallback
- Keep local fonts as default and enable CDN only when needed:
  - `NEXT_PUBLIC_FONT_CDN_ENABLED=true`
  - `NEXT_PUBLIC_FONT_CDN_URL=https://your-cdn-domain/fonts/persian.css`
- If CDN is unavailable, the app automatically falls back to local `IRANSansX`.

## Repository Structure
- `src/`: app, API routes, components, libs, tests
- `docs/`: architecture, operations, runtime checklist and incident docs
- `scripts/`: verification, security scans, deploy and release helpers
- `ops/`: deployment/runtime service and edge configs

## Documentation Entry Points
- `docs/README.md` (documentation index)
- `docs/ARCHITECTURE.md`
- `docs/DEPLOYMENT_PRECHECKLIST.md`
- `docs/10_10_CHECKLIST.md`
- `docs/runtime/README.md`

## Current Operational Status
- Use `docs/runtime/` as the canonical location for go/no-go, incident, and deployment validation evidence.
