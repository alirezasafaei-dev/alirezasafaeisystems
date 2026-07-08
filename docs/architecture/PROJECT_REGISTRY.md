# Project Registry — ASDEV

**Last Updated:** 2026-07-08
**Status:** Active
**Source of Truth:** GitHub

---

## All Projects/Sites

| Project | Repository | URL | Role | Status |
|---|---|---|---|---|
| AlirezaSafaeiSystems | alirezasafaei-dev/alirezasafaeisystems | https://alirezasafaeisystems.ir/ | Parent brand, trust hub, governance | Live / Focus |
| AuditSystems | alirezasafaei-dev/auditsystems | https://audit.alirezasafaeisystems.ir/ | Primary revenue product | Live / Focus |
| PersianToolbox | alirezasafaei-dev/persiantoolbox | https://persiantoolbox.ir/ | Traffic engine, soft leads | Live / Maintain |
| DevAtlas | alirezasafaei-dev/devatlas | — | Future premium Code Audit module | Hold |
| alirezasafaei-dev | alirezasafaei-dev/alirezasafaei-dev | https://github.com/alirezasafaei-dev | GitHub profile showcase | Public |

---

## Project Details

### AlirezaSafaeiSystems (Mother Repo)

- **Repository:** alirezasafaei-dev/alirezasafaeisystems
- **URL:** https://alirezasafaeisystems.ir/
- **Role:** Parent brand, trust hub, ASDEV governance
- **Stack:** Next.js 16, React 19, TypeScript, Tailwind CSS 4, Prisma, PostgreSQL
- **Deployment:** Docker standalone on VPS
- **Owner:** Alireza Safaei

### AuditSystems

- **Repository:** alirezasafaei-dev/auditsystems
- **URL:** https://audit.alirezasafaeisystems.ir/
- **Role:** Primary revenue product — technical website audits
- **Stack:** (TBD — check auditsystems repo)
- **Deployment:** VPS
- **Owner:** Alireza Safaei

### PersianToolbox

- **Repository:** alirezasafaei-dev/persiantoolbox
- **URL:** https://persiantoolbox.ir/
- **Role:** Traffic engine, soft leads, acquisition channel
- **Stack:** (TBD — check persiantoolbox repo)
- **Deployment:** VPS
- **Owner:** Alireza Safaei
- **Protection:** Protected production policy — no changes without owner approval

### DevAtlas

- **Repository:** alirezasafaei-dev/devatlas
- **URL:** —
- **Role:** Future premium Code Audit module
- **Status:** Hold — not actively developed
- **Owner:** Alireza Safaei

---

## Repository Relationships

```
alirezasafaeisystems (mother repo)
├── ASDEV governance, roadmaps, agent rules
├── Live portfolio website
│
├── auditsystems (product repo)
│   ├── ASDEV Audit Platform
│   ├── Revenue product
│   └── Deployed to audit.alirezasafaeisystems.ir
│
├── persiantoolbox (product repo)
│   ├── PersianToolbox
│   ├── Traffic engine
│   └── Deployed to persiantoolbox.ir
│
└── devatlas (hold)
    └── Future Code Audit module
```

---

## Adding a New Project

When onboarding a new project:

1. Add entry to this registry
2. Create project-specific docs in `docs/projects/`
3. Define project role in `docs/strategy/PROJECT_ROLES.md`
4. Set up CI/CD pipeline
5. Configure monitoring
6. Document deployment process
7. Get owner approval

---

## Project Health Metrics

| Project | Last Health Check | Uptime | Known Issues |
|---|---|---|---|
| AlirezaSafaeiSystems | 2026-07-08 | — | (none reported) |
| AuditSystems | — | — | PR #12 needs splitting |
| PersianToolbox | — | — | Protected policy active |
| DevAtlas | — | — | On hold |
