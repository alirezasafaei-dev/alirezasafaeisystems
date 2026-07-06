# ASDEV Consolidation Audit

**Date:** 2026-07-06  
**Auditor:** Repository consolidation agent  
**Status:** Phase 1 complete — no destructive changes made

---

## Repos inspected

| Repo | Local access | GitHub | Role today | Target role |
|---|---|---|---|---|
| `alirezasafaeisystems` | `sites/live/alirezasafaeisystems` | ✅ exists, synced | Portfolio Next.js app + product docs | **ASDEV mother repo** (brand + governance + strategy) |
| `alirezasafaei-dev` | `backups/repo-mirrors/alirezasafaei-dev` (mirror) | ✅ exists | GitHub profile showcase | Keep lightweight showcase |
| `alirezasafaei-dev-meta-repo` | **`~/my-project` root** (same remote) | ✅ exists, active | Cross-project ops super-repo | **Deprecate after migration** |
| `safaei-obsidian-vault` | `backups/repo-mirrors/safaei-obsidian-vault` (mirror) | ✅ exists | Obsidian knowledge OS | **Archive after migration** |
| `auditsystems` | `sites/live/auditsystems` | ✅ exists | Primary product | Keep — ASDEV Audit Platform |
| `persiantoolbox` | `sites/live/persiantoolbox` | ✅ exists | Traffic engine | Keep — acquisition channel |
| `devatlas` | `sites/live/devatlas` (wrong tier) | ✅ exists | Treated as live/active in old docs | **Hold** — future premium module |

---

## Useful docs found

### In `alirezasafaei-dev-meta-repo` (`~/my-project`)

- `docs/roadmaps/ecosystem-growth-execution.md` — dependency-driven phase roadmap (still valid structure, needs ASDEV Audit focus)
- `docs/execution/task-registry.md` — canonical task status
- `docs/execution/checklists.md` — quality gates
- `.agents/CONTEXT.md` — shared agent memory
- `AGENTS.md` — agent operating guide
- `DEPLOYMENT_RULES.md` — port/path/domain allocation
- `deploy/DEPLOYMENT_STANDARD.md` — deploy script standards
- `deploy/{persiantoolbox,alirezasafaeisystems,auditsystems,devatlas}/` — per-project deploy scripts
- `IMPLEMENTATION-STATUS.md` — production evidence baseline

### In `safaei-obsidian-vault`

- `01-Projects/AuditSystems/PROJECT_BRIEF.md` — audit SaaS conversion goals (aligned with ASDEV focus)
- `02-Agent-Prompts/AGENT_PROMPTS_INDEX.md` — prompt registry pattern
- `02-Agent-Prompts/EXECUTION_PROMPT_PACK.md` — agent safety rules (useful, DevAtlas sections are frozen)
- `04-Decisions/ARCHITECTURE_DECISIONS.md` — ADR template
- `05-Launch/AUDITSYSTEMS_LAUNCH_CHECKLIST.md` — launch checklist
- `08-Templates/AGENT_REPORT_TEMPLATE.md` — report template
- `OPERATING_SYSTEM.md` — factory runtime model (partially useful)

### In `alirezasafaeisystems` (existing)

- `docs/BRAND_IDENTITY.md` — brand handles and positioning
- `REVENUE_SYSTEM.md` — analytics API role
- `docs/runtime/` — deployment evidence (keep in product repo, not migrate wholesale)

### In `alirezasafaei-dev` (profile repo)

- `README.md` — polished showcase (needs ASDEV branding + role correction)
- `docs/SHOWCASE_COPY.md` — copy reference
- `assets/screenshots/` — proof-of-work images

---

## Sensitive docs that must not be migrated

- `~/my-project/.env`, `.env.zarinpal`
- `~/my-project/.secrets/`
- `sites/live/*/.env` (all product env files)
- `hold/microcatalog/.env.production`
- Obsidian `.obsidian/plugins/obsidian-git/data.json` (may contain tokens)
- `docs/BRAND_IDENTITY.md` contains phone/email — keep in product repo only, not profile duplication
- `Projects/PersianToolbox/test-note*.md` in obsidian vault (scratch notes)
- Any VPS credentials, database passwords, API keys in runtime docs

---

## Duplicates

| Content | Locations | Resolution |
|---|---|---|
| Master roadmap | `03-Roadmaps/MASTER_ROADMAP.md` (vault + local stub), `docs/roadmaps/ecosystem-growth-execution.md` (meta-repo), `ROADMAP.md` (meta-repo) | Single source: `docs/strategy/ASDEV_AUDIT_MASTER_ROADMAP.md` in mother repo |
| Agent rules | `AGENTS.md` (meta-repo + each product), `02-Agent-Prompts/*` (vault) | Mother repo `AGENTS.md` is canonical; product repos keep scoped variants |
| Launch checklists | `05-Launch/` (vault + local stub), product repos | Audit launch checklist migrates; DevAtlas launch checklist → frozen backlog |
| Project briefs | Obsidian `01-Projects/`, meta-repo `PROJECT_CONTEXT.md` | Consolidate into `docs/projects/*.md` |
| Workspace structure | meta-repo README, obsidian `OPERATING_SYSTEM.md`, `DASHBOARD.md` | Replace with `docs/operations/WORKSPACE_STRUCTURE.md` |
| Deployment docs | meta-repo `DEPLOYMENT_RULES.md`, `deploy/`, product `docs/VPS_DEPLOYMENT.md` | Index in mother repo; scripts stay in meta-repo until workspace restructure |

---

## Conflicts

| Conflict | Old source | New policy |
|---|---|---|
| **DevAtlas as P0** | Obsidian `DASHBOARD.md`, `NEXT_EXECUTION_QUEUE.md` ranks DevAtlas auth #1 | DevAtlas is **hold** until ASDEV Audit has traction |
| **Novax highest priority** | `sites/secondary/ROADMAP_OBJECTIVES.md` — "Novax First, Strategic Balance" | Novax → **secondary/hold**, frozen |
| **DevAtlas listed as live** | meta-repo `README.md`, `IMPLEMENTATION-STATUS.md` | DevAtlas → `sites/hold/`, not live |
| **Novax in `sites/live/`** | `sites/live/novax-price-alert` | Move to `sites/secondary/` |
| **Three-engine model without ASDEV brand** | meta-repo uses "Unified Revenue Ecosystem" | Rebrand to **ASDEV** with Audit as sole primary product |
| **Meta-repo vs mother repo** | `~/my-project` remote = meta-repo; user wants `alirezasafaeisystems` as mother | Migrate strategy to `alirezasafaeisystems`; meta-repo becomes transitional workspace shell |
| **Obsidian vault vs GitHub** | Vault claims "GitHub is execution source, Obsidian is knowledge source" | Collapse into mother repo docs; vault archived |
| **Equal SaaS priority** | Obsidian `PROJECTS_INDEX.md` lists 4 equal "Active SaaS Projects" | Only AuditSystems is primary; others have defined subordinate roles |
| **Old GitHub org references** | `BRAND_IDENTITY.md` references `parsairaniiidev` | Use `alirezasafaei-dev` consistently |

---

## Recommended migration

1. **Create ASDEV governance tree** in `alirezasafaeisystems/docs/{strategy,projects,operations,archive}/`
2. **Rewrite** `alirezasafaeisystems/README.md`, `AGENTS.md`, add `ASDEV.md`
3. **Update** `alirezasafaei-dev` profile README with ASDEV focus and corrected project statuses
4. **Migrate** audit-aligned roadmap, focus policy, frozen backlog, project roles, deployment index
5. **Do not migrate** DevAtlas-first queues, Novax-first roadmaps, obsidian config, private notes
6. **Backup** meta-repo bundle + obsidian vault mirror to `backups/repo-mirrors/`
7. **Prepare** local workspace reclassification (devatlas → hold, novax → secondary) — moves deferred until git impact verified
8. **Archive** meta-repo and obsidian vault on GitHub after migration confirmation
9. **Delete** only after owner types: `CONFIRM DELETE META AND OBSIDIAN REPOS`