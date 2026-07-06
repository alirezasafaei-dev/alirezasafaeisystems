# ASDEV Workspace Structure

**Last Updated:** 2026-07-06

---

## Target structure (local `~/my-project`)

```text
~/my-project/                          # Transitional: alirezasafaei-dev-meta-repo remote
├── sites/
│   ├── live/                          # Production focus
│   │   ├── alirezasafaeisystems       # Mother repo + brand site
│   │   ├── auditsystems               # ASDEV Audit Platform
│   │   └── persiantoolbox             # Traffic engine
│   ├── hold/                          # Parked until Audit traction
│   │   ├── devatlas                   # Future premium module
│   │   ├── creatormembership
│   │   └── microcatalog
│   └── secondary/                     # Frozen experiments
│       ├── rubika-bot-saas
│       ├── novax-price-alert
│       └── halo-secret
├── shared/packages/                   # Cross-site shared code
├── deploy/                            # Deployment script registry
├── docs/                              # Meta-repo execution docs (transitional)
├── ops/                               # Server operations (transitional)
└── scripts/                           # Workspace automation (transitional)
```

---

## Mother repo structure (`alirezasafaeisystems`)

Governance lives here. Product code stays in product repos.

```text
alirezasafaeisystems/
├── README.md              # ASDEV brand + portfolio app quick start
├── AGENTS.md              # Canonical agent rules (focus policy at top)
├── ASDEV.md               # Brand positioning one-pager
├── src/                   # Portfolio Next.js application
├── docs/
│   ├── README.md          # Documentation index
│   ├── strategy/          # Roadmap, focus, roles, frozen backlog
│   ├── projects/          # Per-repo role cards
│   ├── operations/        # Workspace, deploy, server ops
│   └── archive/           # Migration evidence
└── [product app files]    # prisma, scripts, e2e, etc.
```

---

## Current misplacements (move plan — not executed)

| Project | Current path | Target path | Risk |
|---|---|---|---|
| `devatlas` | `sites/live/devatlas` | `sites/hold/devatlas` | Independent git repo; update deploy refs after move |
| `novax-price-alert` | `sites/live/novax-price-alert` | `sites/secondary/novax-price-alert` | Independent git repo; update README/deploy index |

**Before moving:** verify `git status`, remote URLs, deploy scripts, and `IMPLEMENTATION-STATUS.md` references.

---

## Repository topology

Each live product is an **independent Git repository** on `main`. The meta-repo (`~/my-project`) is a transitional workspace shell — not the long-term mother repo.

| Repo | Remote | Role |
|---|---|---|
| `alirezasafaeisystems` | `github.com/alirezasafaei-dev/alirezasafaeisystems` | Mother + brand site |
| `auditsystems` | `github.com/alirezasafaei-dev/auditsystems` | Primary product |
| `persiantoolbox` | `github.com/alirezasafaei-dev/persiantoolbox` | Traffic engine |
| `alirezasafaei-dev` | `github.com/alirezasafaei-dev/alirezasafaei-dev` | Profile showcase |
| `alirezasafaei-dev-meta-repo` | `github.com/alirezasafaei-dev/alirezasafaei-dev-meta-repo` | **Deprecate** |
| `safaei-obsidian-vault` | `github.com/alirezasafaei-dev/safaei-obsidian-vault` | **Archive** |

---

## Agent read order

1. `ASDEV.md`
2. `AGENTS.md`
3. `docs/strategy/FOCUS_POLICY.md`
4. `docs/strategy/PROJECT_ROLES.md`
5. `docs/strategy/ASDEV_AUDIT_MASTER_ROADMAP.md`
6. `docs/projects/<relevant-project>.md`
7. Product `DOCUMENTATION.md` for implementation detail