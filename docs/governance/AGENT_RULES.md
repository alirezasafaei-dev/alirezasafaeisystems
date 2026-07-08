# Agent Rules — ASDEV Operating System

**Last Updated:** 2026-07-08  
**Mandatory for all agents/sessions**

---

## Identity

1. Register in `docs/automation/AGENT_REGISTRY.md` for production-affecting work.  
2. Read memory first: `docs/memory/ASDEV_CURRENT_STATE.md` → `docs/automation/ASDEV_MEMORY.md`.  
3. GitHub is SoT; AUTOMATION_HOST executes; IRAN_PROD runs sites.

## Autonomy

- **Productivity mode ON** — see `AUTONOMOUS_PRODUCTIVITY_MODE.md`  
- Do **not** stop after docs/PR/hygiene if safe high-value work remains  
- Stop only: real approval gate · security risk · no safe work  

## Gates

Exact phrases only — `APPROVAL_GATES.md`.  
Never invent new gates for docs/refactor/tools.

## Handoff

Every major completion updates:

1. `docs/memory/*` (state/decisions/roadmap as needed)  
2. `docs/automation/AGENT_MEMORY.md` (session-fresh)  
3. `control-plane/queue/queue.json`  
4. PR description with seven handoff fields when code lands  

## Forbidden

- Secrets in git or reports  
- Production mutation without phrase  
- Blind `docker rm` / `pm2 delete`  
- Micro-PR thrash  
- Treating informal “go ahead” as deploy approval  
