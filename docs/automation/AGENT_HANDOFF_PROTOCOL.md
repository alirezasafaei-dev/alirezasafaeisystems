# Agent Handoff Protocol — ASDEV

**Last Updated:** 2026-07-08
**Status:** Active

---

## Purpose

Every agent, when completing or passing work to another agent or the owner, MUST leave a structured handoff. This ensures continuity, prevents duplication, and maintains accountability.

---

## Required Handoff Fields

Every handoff MUST include all seven fields. Incomplete handoffs are rejected.

### 1. What Changed

Describe exactly what was modified, created, or deleted.

```
What Changed:
- Modified src/components/Header.tsx: added mobile nav toggle
- Created src/__tests__/components/Header.test.tsx: 3 test cases
- Updated docs/automation/AGENT_MEMORY.md: recorded decision
```

### 2. Where

List every file path that was touched.

```
Where:
- src/components/Header.tsx
- src/__tests__/components/Header.test.tsx
- docs/automation/AGENT_MEMORY.md
```

### 3. Why

Explain the purpose and the goal this serves.

```
Why:
- Mobile nav was broken on viewport < 768px
- Supports ASDEV Audit goal #4: production reliability
```

### 4. Validation

What checks were run and their results.

```
Validation:
- pnpm lint: PASS
- pnpm type-check: PASS
- pnpm test: PASS (191/191)
- pnpm build: PASS
- Manual smoke test: PASS
```

### 5. Risks

Known risks, edge cases, or concerns.

```
Risks:
- None identified
  OR
- Risk: Animation may cause layout shift on slow devices
- Mitigation: Added will-change property, tested on 3G throttle
```

### 6. Next Command

The exact command the next agent or owner should run.

```
Next Command:
- Review PR: gh pr view <number>
- Merge: gh pr merge <number> --squash
- Or: run `pnpm test` to verify independently
```

### 7. Next Owner Approval Needed

Whether owner approval is required and for what.

```
Owner Approval:
- Not needed (docs-only change, auto-merge eligible)
  OR
- Required: merge approval for PR #X
- Required: deploy approval for production push
```

---

## Handoff Format Template

```markdown
## Handoff — [Task ID] [Brief Title]

**Agent:** [Agent Name]
**Date:** [YYYY-MM-DD HH:MM UTC]
**PR:** [PR number or "no PR"]

### What Changed
[Description]

### Where
[File paths]

### Why
[Purpose and goal alignment]

### Validation
[Command results]

### Risks
[Known risks or "None"]

### Next Command
[Exact commands]

### Owner Approval
[Required/Not required + what for]
```

---

## Where to Post Handoffs

1. **In the PR description or review comment** — primary location
2. **In Issue #45** — summary for command center visibility
3. **In AGENT_MEMORY.md** — append if decision or blocker discovered
4. **In this file** — append to history section below

---

## Handoff History

| Date | Task | Agent | Status |
|---|---|---|---|
| 2026-07-08 | ASDEV governance docs | MiMo | Complete |
| 2026-07-08 | Production app-layer + Ops Loop v1 | Grok/ASDEV Lead | Complete (edge gated) |

---

## Latest handoff — Autonomous Production Ops Loop v1

**Date:** 2026-07-08T22:25:00Z  
**PR:** pending this branch

### What Changed
- Confirmed production app-layer HEALTHY on IRAN_PROD `:3100`
- Added post-deploy reports, public-edge plan + nginx 3100 template (not applied)
- Monitoring standard + `check-prod-app-layer` / `check-deploy-status`
- DR runbook, automation-host health, site-standard template, clean-root standard
- Roadmaps + AGENT_MEMORY + queue refresh
- ASDEV site backup helper (dry-run safe)

### Where
- `docs/reports/*`, `docs/ops/*`, `docs/automation/*`, `docs/architecture/*`
- `docs/roadmaps/*`, `TODAY_ROADMAP.md`, `NEXT_WEEK_ROADMAP.md`, `MONTHLY_ROADMAP.md`
- `scripts/monitoring/*`, `scripts/deploy/asdev-backup-site.sh`
- `ops/nginx/critical-site-production-3100.conf.template`
- `templates/site-standard/**`

### Why
- Continue ASDEV as production platform after first cutover without micro-task stop
- Supports reliability + repeatable multi-site ops

### Validation
- Remote: ready/health 200 on `:3100`; staging 200 on `:3000`
- Local: automation-host DEGRADED_NON_BLOCKING; disk OK
- New scripts: `--dry-run` PASS

### Risks
- No backup artifacts yet on IRAN_PROD
- First prod has no previous_release
- Public not exposed

### Next Command
```bash
# After merge: implement live onsite backup on IRAN_PROD (no nginx)
# Only with phrase:
# APPROVE_CRITICAL_SITE_PUBLIC_EDGE
```

### Owner Approval
- Required for public edge / live timers / migration
- Not required for docs+scripts PR merge (owner review still recommended)

---

## Rules

- Never skip a handoff field
- Never assume the next agent has context — write it down
- Never leave validation results blank — run the commands
- Never mark "no owner approval needed" for deploy, merge, or production changes
- Always reference the source of truth (GitHub) — not local state
