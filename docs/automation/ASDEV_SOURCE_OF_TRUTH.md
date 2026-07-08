# ASDEV Source of Truth

**Last Updated:** 2026-07-08
**Status:** Active

---

## Principle

**GitHub is the single source of truth for the ASDEV system.**

No planning, goal state, operating rules, agent memory, or deployment standards should live only on a local machine or server. All authoritative state must be committed to GitHub.

---

## What GitHub Is Source of Truth For

| Domain | What GitHub Holds |
|---|---|
| **Code** | All application code, scripts, configurations, schemas |
| **Roadmap** | TODAY.md, NEXT_7_DAYS.md, NEXT_30_DAYS.md, NEXT_90_DAYS.md |
| **Goals** | Operating doctrine, focus policy, product roles |
| **Operating Rules** | AGENTS.md, AGENT_OPERATING_RULES.md, approval gates |
| **Agent Memory** | AGENT_MEMORY.md — decisions, state, active PRs, blockers |
| **Task State** | ACTIVE_AUTONOMOUS_QUEUE.md — current task queue |
| **Deployment Standards** | Deploy policy, validation requirements, rollback procedures |
| **Project Structure** | ASDEV_TREE.md, PROJECT_REGISTRY.md |

---

## Environment Roles

### OWNER_PC (Working Copy Only)

- Local development machine
- Used for: coding, testing, debugging, exploration
- **Not** a source of truth for any planning or state
- Changes made here must be committed to GitHub
- Local-only notes are temporary and must be transcribed

### AUTOMATION_HOST (Executor/Orchestrator Only)

- Runs automated tasks: CI, monitoring, scheduled jobs
- Used for: executing approved workflows, running tests, posting reports
- **Not** a source of truth for planning or goals
- Reads state from GitHub, writes results to GitHub
- Never stores authoritative state locally

### IRAN_PROD (Runtime/Production Only)

- Live production servers
- Used for: serving the application, handling user requests
- **Not** a source of truth for code or planning
- Deploys come from GitHub via approved CI/CD
- Runtime state (logs, metrics) feeds back to GitHub

---

## What Must Never Be Local-Only

- Roadmap decisions
- Goal changes
- Agent memory
- Task queue state
- Deployment approvals
- Architecture decisions
- Project registry updates
- Operating rule changes

---

## What Must Never Be Committed

- `.env` files with secrets
- Private API keys
- Database credentials
- Session secrets
- SSH private keys
- Any file matching `.gitignore` patterns

---

## Conflict Resolution

When state diverges between environments:

1. GitHub wins — it is the source of truth
2. OWNER_PC must sync from GitHub before making changes
3. AUTOMATION_HOST must read from GitHub, never from OWNER_PC
4. IRAN_PROD must deploy from GitHub, never from local builds

---

## Verification

Agents must verify source of truth integrity:

- All planning docs exist in GitHub
- Agent memory is current in GitHub
- Task queue reflects actual state in GitHub
- No authoritative state exists only on OWNER_PC, AUTOMATION_HOST, or IRAN_PROD
