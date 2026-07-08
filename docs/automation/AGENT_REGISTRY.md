# ASDEV Agent Registry

**Version:** 1.0  
**Last Updated:** 2026-07-08  
**Authority:** Control plane — every agent must be registered here or rejected.

---

## Registry schema

| Field | Description |
|-------|-------------|
| id | stable snake-case id |
| name | human name |
| responsibility | one-line mission |
| permissions.allow | actions allowed |
| permissions.deny | hard blocks |
| input | expected inputs |
| output | expected outputs |
| memory | where it reads/writes memory |
| logs | log location pattern |
| runtime | how it runs (interactive / hermes / openclaw / script) |

---

## Registered agents

### `lead-platform-engineer`

| Field | Value |
|-------|-------|
| Responsibility | Platform deploy engine, CRITICAL_SITE orchestration, ops standards |
| Allow | docs, scripts, IRAN read-only, staging/prod **with phrases**, PR batching |
| Deny | secrets in git; edge/migration/timers without phrase; blind docker delete |
| Input | owner phrases, queue tasks, AGENT_MEMORY |
| Output | reports, PRs, deploy results |
| Memory | `docs/automation/AGENT_MEMORY.md` |
| Logs | session + `control-plane/logs/` |
| Runtime | interactive (Grok/Codex) + scripts |

### `deploy-agent`

| Field | Value |
|-------|-------|
| Responsibility | Deployment orchestration via `asdev-*.sh` |
| Allow | preflight dry-run always; staging with `APPROVE_PHASE_2_STAGING_DEPLOY`; production with `APPROVE_CRITICAL_SITE_PRODUCTION_DEPLOY` |
| Deny | production without phrase; nginx/DNS/SSL; migrations without migration phrase |
| Input | site id, env, commit SHA, approve-phrase |
| Output | release.meta, deploy reports |
| Memory | release pins + AGENT_MEMORY |
| Logs | IRAN `asdev-runtime.log` + report files |
| Runtime | bash on AUTOMATION_HOST → SSH IRAN |

### `sre-observer`

| Field | Value |
|-------|-------|
| Responsibility | Health/stability observation |
| Allow | all read-only probes local + IRAN |
| Deny | any mutation |
| Input | host aliases, ports |
| Output | stability/health reports |
| Memory | append observations |
| Logs | `control-plane/logs/sre-*.log` |
| Runtime | `scripts/monitoring/*`, `scripts/ops/automation-health-check.sh` |

### `automation-host-agent`

| Field | Value |
|-------|-------|
| Responsibility | Control plane hygiene on AUTOMATION_HOST |
| Allow | audit, docs, local scripts, queue maintenance, health |
| Deny | IRAN prod mutation; delete unknown files; restart random containers without approval |
| Input | full audit scope |
| Output | automation-host reports, control-plane updates |
| Memory | AGENT_MEMORY |
| Logs | `control-plane/logs/automation-host-*.log` |
| Runtime | interactive + control-plane scripts |

### `hermes-gateway`

| Field | Value |
|-------|-------|
| Responsibility | Hermes orchestration gateway (if enabled) |
| Allow | dispatch approved automation tasks per HERMES docs |
| Deny | bypass approval phrases; commit secrets |
| Input | command bus / issues |
| Output | task results to queue/GitHub |
| Memory | hermes handoff docs |
| Logs | Hermes local logs (outside git) |
| Runtime | process observed: `hermes_cli.main gateway run` |

### `openclaw-gateway`

| Field | Value |
|-------|-------|
| Responsibility | OpenClaw pilot gateway |
| Allow | pilot-scoped tasks only |
| Deny | production deploy; secret export |
| Input | pilot prompts |
| Output | pilot reports |
| Memory | `docs/automation/OPENCLAW_PILOT.md` |
| Logs | OpenClaw local |
| Runtime | `openclaw gateway --port 18789` |

### `docs-memory-agent`

| Field | Value |
|-------|-------|
| Responsibility | Keep memory, roadmaps, handoffs current |
| Allow | markdown updates, queue status |
| Deny | infra mutation |
| Input | completed work summaries |
| Output | AGENT_MEMORY, roadmaps, queue |
| Runtime | any agent at end of loop |

---

## Permission matrix (summary)

| Agent | Prod deploy | Edge | IRAN RO | Docs | Queue |
|-------|-------------|------|---------|------|-------|
| lead-platform-engineer | phrase | phrase | yes | yes | yes |
| deploy-agent | phrase | no | yes | report | yes |
| sre-observer | no | no | yes | yes | yes |
| automation-host-agent | no | no | limited | yes | yes |
| hermes-gateway | phrase only | phrase only | yes | limited | yes |
| openclaw-gateway | no | no | limited | limited | limited |
| docs-memory-agent | no | no | no | yes | yes |

---

## Onboarding a new agent

1. Add row to this registry  
2. Add profile under `control-plane/agents/<id>.md`  
3. Wire runner in `scripts/control-plane/` or agent-command-center  
4. Define log path  
5. Update AGENT_MEMORY  

Unregistered agents must not perform production-affecting work.
