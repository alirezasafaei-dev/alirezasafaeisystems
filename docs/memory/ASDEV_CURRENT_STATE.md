# ASDEV Current State

**Updated:** 2026-07-09T00:50:00Z  
**Mode:** Autonomous Loop Governance **INSTALLED** (GitHub SoT)

---

## Multi-agent (OWNER_PC)

**Updated:** 2026-07-09T00:57:41Z  
**Orchestrator:** Grok · AUTO LOOP ON · complete work first / deploy last  
**Assistants active pattern:** `mimo` + `opencode` (non-interactive worktrees)  
**Policy:** `docs/automation/MULTI_AGENT_LOCAL_ORCHESTRATION.md`  
**Product pin advanced:** `persiantoolbox@d0ae88f` (inspect scrub for PM2; deploy still last)

## Platform

| Item | Value |
|------|-------|
| SoT | GitHub `main` |
| Workspace | `/home/dev13/ASDEV` |
| Control plane | `control-plane/` live |
| Loop policy | `docs/automation/ASDEV_AUTONOMOUS_LOOP_POLICY.md` |
| Productivity mode | ENABLED |

## CRITICAL_SITE (`persiantoolbox`)

| Item | Value |
|------|-------|
| Public product | LIVE on **public VPS** (ubuntu · nginx · PM2 **green:3003**) release `37ba347` |
| ASDEV IRAN app-layer | Separate host `:3100` (not DNS public) |
| Product GitHub | advanced (`9c8b626`+ quality/SEO/blog packs) — may be **ahead** of live `37ba347` |
| Product score | ~7.5–8.0/10 est. · **not 10/10** |
| Staging | public staging + ASDEV legacy paths |
| Rollback history | none (first prod) |
| Meta backup | IRAN daily 03:15 UTC · FRESH |

## AUTOMATION_HOST

| Item | Value |
|------|-------|
| Class | OPERATIONAL (control-plane synced, agent-loop active) |
| Control plane | `~/asdev-platform/control-plane/` — scripts synced from repo |
| Agent loop | `asdev-agent-loop.timer` — enabled, 30m interval, running |
| Linger | enabled (user systemd persistent) |
| Repo clone | `~/repos/alirezasafaeisystems` — main, up to date |
| Cron | `asdev-meta-backup.sh` daily 03:15 UTC |
| Node | bot.js running (Issue #45 command bus) |

## Gated (not running)

- Public edge  
- Live monitoring timers  
- Migrations  
- Production redeploy  

## Active build focus

**ASDEV Engineering Operating System** (governance, memory, registry, deploy model, observability prep) — not daily hygiene thrash.

**Quality note:** Product-side quality packs advance trust/report depth on github main; public score remains ~7.5 until edge is live and measured. Do not claim 10/10 or public prod edge deploy until edge + depth + uptime are proven.

## AUTOMATION_HOST runtime (2026-07-09T03:25:00Z)

- Classification: OPERATIONAL (control-plane scripts deployed, agent-loop tested)
- Control plane scripts: synced from GitHub repo (12 control-plane + 22 agent-command-center)
- Agent loop: `asdev-agent-loop.service` — ran successfully, 0 pending tasks
- Timer: `asdev-agent-loop.timer` — enabled, active, 30m interval
- Linger: enabled for persistent user systemd
- Node process: bot.js (Issue #45 command bus)
- Cron: asdev-meta-backup.sh daily 03:15 UTC
- Note: Hermes/OpenClaw not confirmed running (may need separate activation)

