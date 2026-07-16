![Build](https://img.shields.io/badge/build-passing-brightgreen)
![Tests](https://img.shields.io/badge/tests-191%20passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen)

<br />

<img src="public/og-image.png" alt="ASDEV — Production Web Systems & Technical SEO" width="100%">

<br />

# ASDEV — Production Web Systems & Technical SEO

**One codebase. Two missions.** The mother repository for autonomous-agent-driven governance and the live portfolio brand at [alirezasafaeisystems.ir](https://alirezasafaeisystems.ir) — production-ready, multi-agent orchestrated, and built for the modern web.

<br />

---

## Repository Structure

| Layer | Purpose |
|---|---|
| **Mother Repo** | Strategy, governance, agent rules, automation policies, memory, and ops documentation for the ASDEV ecosystem |
| **Portfolio App** | Live Next.js 16 application — services, case studies, about brand, qualification forms, SEO-optimised with full i18n |

This split means governance lives alongside production code. Every commit can update both the agent operating system and the public-facing website.

---

## Tech Stack

| Category | Technology |
|---|---|
| **Framework** | Next.js 16 (App Router) + React 19 |
| **Language** | TypeScript 5.9 (strict mode) |
| **Styling** | Tailwind CSS 4 + shadcn/ui |
| **Database** | Prisma 6 (SQLite dev · PostgreSQL prod) |
| **Testing** | Vitest 4 (191 tests) · Playwright · Storybook |
| **i18n** | Custom hand-rolled Persian / English system |
| **SEO** | Dynamic sitemap · robots.txt · JSON-LD · OG images |
| **Deployment** | Docker standalone · Nginx · systemd · VPS |

---

## Key Features

**Autonomous Agent Governance**
- Multi-agent orchestration (MiMo, OpenCode, Hermes, OpenClaw)
- Autonomous loop with safe-next-task selection
- GitHub ↔ AUTOMATION_SERVER bidirectional sync
- Memory persistence, approval gates, post-deploy verification

**Live Portfolio Website**
- Bilingual Persian / English with hand-rolled i18n
- Services: Technical SEO Audit, Web Development, Performance Analysis
- 6 case studies, lead qualification form, about-brand page
- Revenue Scorecard, Enterprise Audit, Network Smoke Testing dashboards
- 191 passing tests · Lighthouse ≥ 75 · full a11y coverage

---

## Quick Start

```bash
pnpm install
pnpm dev                # → http://localhost:3001
pnpm build
pnpm start
```

### Environment

```bash
cp .env.example .env    # Fill in your DATABASE_URL, etc.
pnpm db:push            # Push Prisma schema
pnpm db:generate        # Generate Prisma client
```

---

## Testing

```bash
pnpm test               # Vitest — 191 tests
pnpm test:e2e:smoke     # Playwright smoke tests
pnpm test:e2e:a11y      # Playwright accessibility tests
pnpm lint               # ESLint
pnpm type-check         # TypeScript strict check
pnpm build              # Production build
```

All four post-development gates (`lint` → `type-check` → `test` → `build`) must pass before every commit.

---

## Live Sites

| Site | URL |
|---|---|
| ASDEV Brand | [alirezasafaeisystems.ir](https://alirezasafaeisystems.ir) |
| ASDEV Audit | [audit.alirezasafaeisystems.ir](https://audit.alirezasafaeisystems.ir) |
| PersianToolbox | [persiantoolbox.ir](https://persiantoolbox.ir) |

---

## Contributing

PRs are welcome. Read [ASDEV.md](ASDEV.md) and [AGENTS.md](AGENTS.md) first to understand the governance model, then open a pull request. All code must pass lint, type-check, tests, and build.

---

## License

MIT © [Alireza Safaei](https://github.com/alirezasafaei-dev)
