# ASDEV Focus Policy

**Effective:** 2026-07-06  
**Authority:** Canonical — overrides all older roadmaps, Obsidian queues, and secondary project objectives

---

## Current strategic focus

**ASDEV Audit Platform** (`auditsystems`) is the only primary execution path.

Everything else exists to support audit acquisition, conversion, retention, report quality, reliability, or revenue — or it is frozen.

---

## Mandatory agent rule

> The current strategic focus is ASDEV Audit Platform. Agents must not start unrelated product work, create new product scopes, revive frozen projects, or make DevAtlas standalone unless the task directly supports ASDEV Audit acquisition, conversion, retention, report quality, reliability, or revenue.

Every agent task must answer:

> **Which ASDEV Audit goal does this task support?**

### Valid goals

1. More submitted audits
2. Better and more trusted reports
3. More leads, signups, paid users, or agency contacts
4. Better production reliability, security, and operations
5. Lower audit cost, support cost, or execution time

If none apply, the task must be **rejected** or moved to [`FROZEN_BACKLOG.md`](FROZEN_BACKLOG.md).

---

## Project tier rules

| Tier | Projects | Agent behavior |
|---|---|---|
| **Primary** | `auditsystems` | Default work target |
| **Support** | `alirezasafaeisystems`, `persiantoolbox` | Only tasks that route traffic, build trust, or capture leads for Audit |
| **Showcase** | `alirezasafaei-dev` | Public-facing updates only; no operational clutter |
| **Hold** | `devatlas`, `creatormembership`, `microcatalog` | No new scope; bugfixes only if blocking primary product |
| **Secondary** | `rubika-bot-saas`, `novax-price-alert`, `halo-secret` | Frozen unless explicit unfreeze decision |

---

## What agents must not do

- Treat DevAtlas as a standalone product or YC-ready priority
- Revive "Novax First" or equal-priority SaaS models
- Create new product categories under the ASDEV brand
- Expand ASDEV into a vague umbrella of unrelated tools
- Copy secrets, `.env` files, or private Obsidian notes into governance docs
- Infer production readiness from local tests alone

---

## Approval required before

- Production deployment
- Production database migration
- Server configuration changes
- Public pricing publication
- Payment provider activation
- Repository deletion or force push
- Unfreezing a secondary/hold project

---

## Superseded documents

These are **historical only** and must not drive execution:

- Obsidian `DASHBOARD.md` DevAtlas-first queue
- Obsidian `NEXT_EXECUTION_QUEUE.md` (DevAtlas P0 tasks)
- `sites/secondary/ROADMAP_OBJECTIVES.md` ("Novax First")
- `sites/hold/ROADMAP_OBJECTIVES.md` (equal hold-project promotion)
- Meta-repo README "Unified Revenue Ecosystem" framing without ASDEV Audit primacy