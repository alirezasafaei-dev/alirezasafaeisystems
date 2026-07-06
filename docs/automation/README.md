# ASDEV Automation Layer

**Status:** Hermes-first architecture **approved** (owner 2026-07-06)  
**Primary orchestrator:** Hermes Agent  
**Source of truth:** GitHub (PR #42 command thread)  
**n8n role:** Optional dashboard / notification glue only — **not** main orchestrator  
**Primary product:** ASDEV Audit Platform

---

## Architecture (approved)

```text
Hermes-first orchestration
GitHub = source of truth
n8n = optional dashboard / notifications / approval UI
```

---

## Documentation index

| Document | Purpose |
|---|---|
| [HERMES_FIRST_ORCHESTRATION.md](HERMES_FIRST_ORCHESTRATION.md) | Master architecture and lifecycle |
| [HERMES_VS_N8N_DECISION.md](HERMES_VS_N8N_DECISION.md) | Why Hermes-first; n8n deferred |
| [HERMES_AGENT_PROFILES.md](HERMES_AGENT_PROFILES.md) | Profile registry and routing |
| [HERMES_GITHUB_COMMAND_LOOP.md](HERMES_GITHUB_COMMAND_LOOP.md) | PR #42 poll → kanban → report |
| [HERMES_APPROVAL_GATES.md](HERMES_APPROVAL_GATES.md) | Tier 0/1/2 approval rules |
| [PERSIANTOOLBOX_PROTECTION.md](PERSIANTOOLBOX_PROTECTION.md) | Protected production policy |
| [HERMES_CAPABILITY_REVIEW.md](HERMES_CAPABILITY_REVIEW.md) | Local inspection (2026-07-06) |
| [MIMO_HANDOFF.md](MIMO_HANDOFF.md) | MiMo ↔ Hermes handoff protocol |
| [MIMO_AGENT_PROFILES.md](MIMO_AGENT_PROFILES.md) | MiMo role definitions and routing |
| [LOCAL_COMMAND_LOOP_P1.md](LOCAL_COMMAND_LOOP_P1.md) | Phase P1 setup guide and dry-run results |

---

## What automation may do

- Poll GitHub for approved prompts
- Route tasks via Hermes kanban + profiles
- Execute in git worktrees with validation
- Post standardized reports to PR #42
- Notify owner (Telegram / gateway)

---

## What automation must never do

- Bypass owner approval
- Auto-push, auto-deploy, auto-billing
- Use Hermes `--yolo` on ASDEV profiles
- Edit PersianToolbox runtime without special approval
- Override ASDEV focus policy

---

## Implementation status

| Phase | Status |
|---|---|
| P0 Docs | ✅ This package |
| P1 Hermes profiles + kanban | ✅ Local setup complete (2026-07-06) |
| P2 GitHub loop automation | 📋 Designed — monitor exists |
| P3 Telegram approval | 📋 Optional |
| P4 n8n glue | ⏸️ Only if owner requests |

**No production deploy. No n8n MVP. No ops/n8n scaffolding yet.**

---

## Related

- [../agent-command-center/README.md](../agent-command-center/README.md)
- [../strategy/FOCUS_POLICY.md](../strategy/FOCUS_POLICY.md)
- [PR #42](https://github.com/alirezasafaei-dev/alirezasafaeisystems/pull/42)