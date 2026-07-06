# ASDEV

ASDEV is the parent brand for focused web systems, with **ASDEV Audit Platform** as the current primary product.

## Current Focus

**ASDEV Audit Platform** — https://audit.alirezasafaeisystems.ir/

## Product Roles

- **AuditSystems:** primary revenue product
- **AlirezaSafaeiSystems:** parent brand, trust hub, and ASDEV governance (this repo)
- **PersianToolbox:** traffic engine and acquisition channel
- **DevAtlas:** future premium Code Audit module (hold)
- **alirezasafaei-dev:** GitHub profile showcase

## Start Here (Agents & Strategy)

1. [ASDEV.md](ASDEV.md) — brand one-pager
2. [AGENTS.md](AGENTS.md) — agent operating rules
3. [docs/README.md](docs/README.md) — documentation index
4. [docs/strategy/FOCUS_POLICY.md](docs/strategy/FOCUS_POLICY.md) — what to work on (and what to reject)
5. [docs/strategy/ASDEV_AUDIT_MASTER_ROADMAP.md](docs/strategy/ASDEV_AUDIT_MASTER_ROADMAP.md) — master roadmap

## Live Sites

| Site | URL | Repository |
|---|---|---|
| ASDEV Brand | https://alirezasafaeisystems.ir/ | this repo |
| ASDEV Audit | https://audit.alirezasafaeisystems.ir/ | [auditsystems](https://github.com/alirezasafaei-dev/auditsystems) |
| PersianToolbox | https://persiantoolbox.ir/ | [persiantoolbox](https://github.com/alirezasafaei-dev/persiantoolbox) |

---

## Portfolio Application (this repository)

This repo is both the **ASDEV mother repository** (strategy, governance, agent rules) and the **live portfolio/brand website** (Next.js application).

### Quick Start

```bash
pnpm install
pnpm dev      # http://localhost:3001
pnpm build
pnpm start
```

### Technology Stack

- **Framework:** Next.js 16 (App Router) + React 19 + TypeScript
- **Styling:** Tailwind CSS 4 + shadcn/ui
- **Database:** PostgreSQL with Prisma ORM
- **Testing:** Vitest + Playwright
- **Deployment:** Standalone Node.js on VPS

### Key Commands

```bash
pnpm lint
pnpm type-check
pnpm test
pnpm test:e2e:smoke
bash scripts/vps-deploy.sh deploy production   # requires approval
```

### Application Docs

- [DOCUMENTATION.md](DOCUMENTATION.md) — feature and architecture detail
- [REVENUE_SYSTEM.md](REVENUE_SYSTEM.md) — analytics API role
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — runtime architecture

---

## Governance vs Product Code

| In this repo | In separate repos |
|---|---|
| ASDEV strategy and focus policy | AuditSystems application |
| Agent rules and project role cards | PersianToolbox application |
| Deployment index and ops overview | DevAtlas (hold) |
| Brand positioning | Secondary/hold experiments |

Do not dump all product code into this repo.

---

**Author:** [Alireza Safaei](https://alirezasafaeisystems.ir) · [@alirezasafaei-dev](https://github.com/alirezasafaei-dev)