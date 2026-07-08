# GitHub Operation Model — ASDEV

**Version:** 1.0  
**Last Updated:** 2026-07-08

---

## Split of duties

| Layer | Owns |
|-------|------|
| **GitHub** | Source code, documentation, roadmaps, agent memory, PRs, issues (command bus) |
| **AUTOMATION_HOST** | Execution only: run scripts, SSH to IRAN, produce reports, open PRs |
| **IRAN_PROD** | Runtime for CRITICAL_SITE (and other sites) |

GitHub is the **only source of truth**.  
AUTOMATION_HOST must not become a long-term SoT for code or decisions.

---

## Workflow

```
1. Agent reads GitHub-backed docs (memory, queue, registry)
2. Executes on AUTOMATION_HOST / IRAN as allowed
3. Writes reports + code changes locally
4. Commits → push → PR (batched)
5. Human merges to main
6. Next agent pulls main (or works on PR branch)
```

---

## Branching & PRs

| Rule | Detail |
|------|--------|
| Batch | One PR per major phase |
| Avoid | Micro-PRs for related control-plane work |
| Secrets scan | Before every commit |
| Main | Protected mental model — production SoT after merge |

---

## What belongs in git

- Scripts, architecture, runbooks, reports (redacted)  
- Queue schema + seed tasks  
- Agent registry  

## What never belongs in git

- `.env`, tokens, private keys  
- Raw infrastructure secrets  
- Large binaries / `node_modules` / `.next`  

Private: `ASDEV_PRIVATE/` on AUTOMATION_HOST only.

---

## Command surfaces

| Surface | Use |
|---------|-----|
| PR description | Primary handoff for code changes |
| `docs/automation/AGENT_MEMORY.md` | Cross-session decisions |
| `docs/automation/ACTIVE_AUTONOMOUS_QUEUE.md` | Human queue |
| `control-plane/queue/queue.json` | Machine queue |
| Issue #45 (if used) | Optional command bus |

---

## Failure modes

| Failure | Response |
|---------|----------|
| GHA TLS / infra red | Local validation; don't thrash reruns |
| Push failure | Retry; keep commits local; no force-push to main |
| Diverged main | Rebase/ff only with care; no rewrite of published history without owner |

---

## Production linkage

Deploy **pins** (product SHA, release id) are recorded in git reports.  
Runtime lives on IRAN_PROD. GitHub never holds live processes.
