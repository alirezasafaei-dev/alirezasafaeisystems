# ASDEV Tree — Directory Structure Definition

**Last Updated:** 2026-07-08
**Status:** Active

---

## Purpose

This document defines what belongs in each environment and what must never be committed.

---

## What Belongs in GitHub

Everything that defines the ASDEV system. GitHub is the source of truth.

| Directory/File | Purpose |
|---|---|
| `src/` | Application code |
| `docs/` | All documentation, roadmaps, governance |
| `scripts/` | Deployment and automation scripts |
| `prisma/` | Database schema |
| `e2e/` | End-to-end tests |
| `AGENTS.md` | Agent governance |
| `ASDEV.md` | Brand one-pager |
| `README.md` | Repository overview |
| `docs/automation/` | Agent rules, memory, handoff, source of truth |
| `docs/roadmaps/` | Today, 7-day, 30-day, 90-day roadmaps |
| `docs/architecture/` | ASDEV tree, project registry |
| `docs/strategy/` | Focus policy, project roles, master roadmap |
| `.github/` | GitHub Actions, workflows, templates |
| `Dockerfile` | Container definition |
| `docker-compose.yml` | Container orchestration |
| `package.json` | Dependencies and scripts |
| `tsconfig.json` | TypeScript configuration |
| `next.config.ts` | Next.js configuration |
| `vitest.config.ts` | Test configuration |
| `playwright.config.mjs` | E2E test configuration |
| `eslint.config.mjs` | Linting configuration |
| `tailwind.config.ts` | Styling configuration |

---

## What Belongs Only on OWNER_PC

Local development environment. Working copy only.

| Item | Purpose |
|---|---|
| `.env` | Local environment variables (never committed) |
| `node_modules/` | Installed dependencies (never committed) |
| `.next/` | Build output (never committed) |
| `Local notes/scratch work` | Temporary — must be transcribed to GitHub |
| `Debugging artifacts` | Temporary — must be cleaned up |

**Rule:** Nothing on OWNER_PC is authoritative. All state must be committed to GitHub.

---

## What Belongs Only on AUTOMATION_HOST

Executor and orchestrator. Reads from GitHub, writes to GitHub.

| Item | Purpose |
|---|---|
| CI/CD pipeline state | Transient — not stored locally |
| Scheduled job state | Transient — read from GitHub |
| Monitoring results | Written to GitHub Issue #45 |
| Automation logs | Transient — summarized to GitHub |

**Rule:** AUTOMATION_HOST never stores authoritative state. It reads from GitHub and writes results back to GitHub.

---

## What Belongs Only on IRAN_PROD

Runtime and production. Serves the application.

| Item | Purpose |
|---|---|
| Running application | Deployed from GitHub |
| Database (production data) | Runtime state only |
| Logs | Operational data — feed back to GitHub |
| Metrics | Operational data — feed back to GitHub |

**Rule:** IRAN_PROD never stores source code, planning, or governance state. It runs what GitHub deploys.

---

## What Must Never Be Committed

| File/Pattern | Reason |
|---|---|
| `.env` | Contains secrets |
| `.env.*` | Contains secrets |
| `*.key` | Private keys |
| `*.pem` | Private keys |
| `node_modules/` | Dependencies (reproducible from package.json) |
| `.next/` | Build output |
| `dist/` | Build output |
| `*.log` | Log files |
| `.DS_Store` | OS artifacts |
| `Thumbs.db` | OS artifacts |
| `coverage/` | Test coverage output |
| `.vercel/` | Deployment artifacts |

---

## Directory Tree

```
ASDEV/
├── src/                    # Application code
│   ├── app/               # Next.js App Router
│   ├── components/        # React components
│   ├── hooks/             # Custom hooks
│   ├── lib/               # Core utilities
│   ├── __tests__/         # Tests
│   └── proxy.ts           # Middleware
├── docs/                   # Documentation
│   ├── automation/        # Agent rules, memory, handoff
│   ├── roadmaps/          # Time-based roadmaps
│   ├── architecture/      # ASDEV tree, project registry
│   ├── strategy/          # Focus policy, project roles
│   ├── agent-command-center/
│   ├── audits/
│   ├── deploy/
│   ├── execution/
│   ├── operations/
│   ├── ops/
│   ├── product/
│   ├── projects/
│   ├── resume/
│   ├── runtime/
│   └── strategy/
├── scripts/                # Deployment and automation
├── prisma/                 # Database schema
├── e2e/                    # End-to-end tests
├── public/                 # Static assets
├── db/                     # Database utilities
├── ops/                    # Operations
├── assets/                 # Project assets
├── reports/                # Generated reports
├── .github/                # GitHub configuration
├── AGENTS.md               # Agent governance
├── ASDEV.md                # Brand one-pager
├── README.md               # Repository overview
├── Dockerfile              # Container definition
├── docker-compose.yml      # Container orchestration
├── package.json            # Dependencies
├── tsconfig.json           # TypeScript config
├── next.config.ts          # Next.js config
└── vitest.config.ts        # Test config
```
