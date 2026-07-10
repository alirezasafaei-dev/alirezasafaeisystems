# Agent Governance — ASDEV (AlirezaSafaeiSystems Mother Repo)

**Last Updated**: 2026-07-10
**Status**: Active

## Autonomous Loop Governance (mandatory)

**All automation agents must read first:**

> [`docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md`](docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md)

Core rule: **do not stop after a completed task** — select the highest-value *safe* next task and continue.

Also read:

- Environment roles + sync: [`docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md`](docs/governance/ENVIRONMENT_ROLES_AND_SYNC_POLICY.md)
- GitHub/local/server sync: [`docs/ops/GITHUB_LOCAL_SERVER_SYNC.md`](docs/ops/GITHUB_LOCAL_SERVER_SYNC.md)
- Post-deploy live verification: [`docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md`](docs/governance/POST_DEPLOY_LIVE_VERIFICATION_POLICY.md)
- Mode: [`docs/governance/AUTONOMOUS_PRODUCTIVITY_MODE.md`](docs/governance/AUTONOMOUS_PRODUCTIVITY_MODE.md)
- Gates: [`docs/governance/APPROVAL_GATES.md`](docs/governance/APPROVAL_GATES.md)
- Multi-agent (OWNER_PC): [`docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md`](docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md) — prefer **mimo** + **opencode** as first assistants
- Memory: [`docs/memory/ASDEV_CURRENT_STATE.md`](docs/memory/ASDEV_CURRENT_STATE.md) · [`docs/automation/ASDEV_MEMORY.md`](docs/automation/ASDEV_MEMORY.md)
- Workspace: `/home/dev13/ASDEV` (not legacy my-project path)

Stop only for: real approval gates · security risk · honest zero safe work.

---

## Environment naming rule (mandatory)

Agents must use these exact names:

| Name | Meaning |
|---|---|
| `LOCAL_PC` | The owner's own computer/workstation. MiMo is the primary commander here. |
| `AUTOMATION_SERVER` | External automation server, currently `asdev@91.107.153.223`. Always-on loops, GitHub sync, MCP, queue worker, and reporting run here. |
| `IRAN_PROD_SERVER` | Iran live production/deployment server. Strictly gated. |
| `GITHUB_MAIN` | GitHub `main` branch and source of truth. |

Agents must not say vague labels like "local", "server", "prod", "branch 45", or "synced" without exact environment/repo/branch/SHA context.

---

## Agent ownership rule (mandatory)

| Agent | Role |
|---|---|
| `MiMo` | Primary orchestration agent. |
| `OpenCode` | Implementation/patch agent. |
| `Hermes` | Telegram reporting/status/approval gateway. |
| `OpenClaw` | Gateway/diagnostic only unless explicitly approved otherwise. |
| `bot.js` | GitHub command bus if still needed. |

Hermes is the default Telegram owner. OpenClaw must not poll Telegram while Hermes is active.

---

## Sync rule (mandatory)

`AUTOMATION_SERVER` must automatically sync GitHub `main` using:

```bash
scripts/control-plane/sync-github-local-server.sh
```

and the user systemd timer:

```text
asdev-github-sync.timer
```

Prompt/policy/queue files committed to GitHub must become discoverable on `AUTOMATION_SERVER` without owner manual copy-paste.

---

## ASDEV Focus Rule (mandatory)

> The current strategic focus is ASDEV Audit Platform. Agents must not start unrelated product work, create new product scopes, revive frozen projects, or make DevAtlas standalone unless the task directly supports ASDEV Audit acquisition, conversion, retention, report quality, reliability, or revenue.

Every agent task must answer:

> **Which ASDEV Audit goal does this task support?**

Valid goals:

1. More submitted audits
2. Better and more trusted reports
3. More leads, signups, paid users, or agency contacts
4. Better production reliability, security, and operations
5. Lower audit cost, support cost, or execution time

If none apply, reject the task or move it to `docs/strategy/FROZEN_BACKLOG.md`.

**Read before working:** [ASDEV.md](ASDEV.md) → [docs/strategy/FOCUS_POLICY.md](docs/strategy/FOCUS_POLICY.md) → [docs/strategy/PROJECT_ROLES.md](docs/strategy/PROJECT_ROLES.md)

---

## Agent Guidelines

### Agent Working Directory
- **Base Path**: `/home/dev13/ASDEV`
- **Allowed Directories**: `src/`, `scripts/`, `prisma/`, `docs/`, `e2e/`
- **Restricted Directories**: `.git/`, `node_modules/`, `.next/`, `dist/`

### Key Constraints
- **No Global Installs**: Use project-local dependencies only
- **Testing Required**: All changes must pass `pnpm test` (191 tests) and `pnpm lint`
- **Type Safety**: Must pass `pnpm type-check`
- **Security First**: No hardcoded secrets, use environment variables
- **Performance**: Changes must not degrade Lighthouse scores below 75

### Project Architecture
- **Framework**: Next.js 16 (App Router) + React 19 + TypeScript 5.9
- **Styling**: Tailwind CSS 4 + shadcn/ui (10 active components)
- **Database**: Prisma 6 (SQLite dev, PostgreSQL prod)
- **i18n**: Custom hand-rolled (locale-utils.ts, i18n-context.tsx)
- **Middleware**: `src/proxy.ts` (Next.js 16 proxy system)
- **Testing**: Vitest 4 (191 tests) + Playwright (smoke + a11y)
- **Deployment**: Docker standalone + VPS with Nginx + systemd

---

## Execution Checklist

### Pre-Development
- [ ] Read relevant existing code and tests
- [ ] Understand the impact on existing features
- [ ] Check for similar implementations in the codebase
- [ ] Review security implications
- [ ] Consider performance impact

### During Development
- [ ] Follow existing code patterns
- [ ] Write/update tests for new functionality
- [ ] Use TypeScript strictly (no `any`)
- [ ] Follow accessibility best practices
- [ ] Implement proper error handling

### Post-Development (ALL MUST PASS)
```bash
pnpm lint          # ESLint - must pass
pnpm type-check    # TypeScript - must pass
pnpm test          # Vitest - 191 tests must pass
pnpm build         # Next.js build - must succeed
```

### Before Commit
- [ ] Write clear, conventional commit message
- [ ] Ensure changes are minimal and focused
- [ ] Check for accidentally committed files
- [ ] Verify environment variables are not committed

---

## Critical Rules

### NEVER
- Commit `.env` files or secrets
- Remove error handling without replacement
- Disable security features
- Skip tests for any reason
- Use `eval()` or similar dangerous functions
- Hardcode credentials or API keys
- Ignore TypeScript errors
- Commit `node_modules` or build artifacts
- Add comments unless explicitly asked
- Use `framer-motion` (removed, use CSS animations)
- Confuse `LOCAL_PC`, `AUTOMATION_SERVER`, and `IRAN_PROD_SERVER`
- Report deploy success without live verification
- Report sync success without branch/SHA evidence

### ALWAYS
- Use environment variables for configuration
- Write tests for new functionality
- Follow existing code patterns
- Consider accessibility implications
- Think about performance impact
- Handle errors gracefully
- Validate user inputs with Zod
- Use the project logger (`src/lib/logger.ts`) not `console.*`
- Import `withLocale` from `@/lib/locale-utils` (not duplicated)
- Use `t()` function for user-facing text (not inline ternaries)
- Report environment, repo, branch, local SHA, origin SHA, and dirty status when discussing sync or automation

---

## Common Tasks

### Adding New Component
```bash
# 1. Check existing components in src/components/ui/ for patterns
# 2. Use shadcn/ui conventions (button.tsx is the reference)
# 3. Include TypeScript interfaces
# 4. Add unit tests in src/__tests__/
# 5. Update relevant documentation
```

### Adding New Page
```bash
# 1. Create page in src/app/<route>/page.tsx
# 2. Add generateMetadata() with locale-conditional title/description
# 3. Add alternates.canonical for SEO
# 4. Add to sitemap-manifest.json via scripts/generate-sitemap-manifest.mjs
# 5. Add to lighthouserc.json URL list
# 6. Add a11y test in e2e/a11y.spec.ts
```

### Database Schema Change
```bash
# 1. Modify schema in prisma/schema.prisma
# 2. Run: pnpm db:push
# 3. Generate types: pnpm db:generate
# 4. Test in development environment
```

### API Route Addition
```bash
# 1. Create route in src/app/api/
# 2. Use shared schemas from src/lib/api-schemas.ts
# 3. Add rate limiting via checkRateLimit()
# 4. Add input validation with Zod
# 5. Include authentication if needed
# 6. Write API tests in src/__tests__/api/
```

---

## Project Structure

```
src/
├── app/                    # Next.js App Router pages
│   ├── api/               # API routes (15 endpoints)
│   ├── layout.tsx         # Root layout with providers
│   ├── page.tsx           # Home page
│   ├── loading.tsx        # Global loading state
│   ├── not-found.tsx      # 404 page
│   ├── error.tsx          # Error boundary
│   ├── sitemap.ts         # Dynamic sitemap
│   ├── robots.ts          # Dynamic robots.txt
│   ├── about-brand/       # About page
│   ├── asdev/             # Legacy redirect
│   ├── case-studies/      # 6 case studies
│   ├── profile/           # Profile page
│   ├── qualification/     # Lead form
│   ├── services/          # 2 service pages
│   ├── standards/         # Standards page
│   └── thank-you/         # Success page
├── components/
│   ├── ui/                # 12 active shadcn/ui components
│   ├── layout/            # Header, footer, bottom-nav
│   ├── sections/          # Page sections (hero, contact, etc.)
│   ├── admin/             # Admin dashboard
│   ├── analytics/         # Web vitals
│   ├── i18n/              # Language switcher
│   ├── search/            # Search bar
│   ├── seo/               # JSON-LD component
│   └── theme/             # Theme provider/toggle
├── hooks/                 # Custom React hooks
├── lib/                   # Core utilities
│   ├── api-schemas.ts     # Shared Zod schemas
│   ├── api-security.ts    # Rate limiting, auth helpers
│   ├── brand.ts           # Brand constants
│   ├── db.ts              # Prisma client
│   ├── env.ts             # Environment validation
│   ├── i18n-context.tsx   # i18n React context
│   ├── locale-utils.ts    # withLocale, swapLocale
│   ├── logger.ts          # Structured logging
│   ├── proxy.ts           # Middleware (Next.js 16)
│   ├── rate-limit.ts      # Rate limiting
│   ├── security.ts        # Security utilities
│   ├── seo.ts             # Schema.org generators
│   └── validators.ts      # Input validation
├── generated/             # Auto-generated files
│   └── sitemap-manifest.json
├── __tests__/             # Test files (26 files, 191 tests)
│   ├── api/               # API integration tests
│   ├── components/        # Component tests
│   ├── lib/               # Unit tests
│   └── seo/               # SEO tests
└── proxy.ts               # Next.js middleware
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `package.json` | Dependencies and scripts |
| `tsconfig.json` | TypeScript config (strict mode) |
| `next.config.ts` | Next.js config (standalone output) |
| `prisma/schema.prisma` | Database schema (7 models) |
